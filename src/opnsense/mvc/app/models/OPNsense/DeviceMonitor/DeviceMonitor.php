<?php

// Předpony: arr = pole, b = příznak, i = celé číslo, o = objekt, s = řetězec, x = hodnota proměnlivého typu.
// Historie: 2.4.16 – omezené čtení a typová kontrola konfigurace.
// 2.4.14 – atomické uložení konfigurace a ověření adresy zařízení.
// 2.4.1 – starší uložené nastavení e-mailu zachová původní transport.
// 2.4.0 – trvalé označení známého zařízení podle MAC adresy.
// 2.3.7 – sjednocení typových předpon proměnných.

// Historie: 2.3.5 – čas Hostwatch předávaný jako unixová časová značka.

namespace OPNsense\DeviceMonitor;

class DeviceMonitor
{
    // ================================================================
    // CESTY - VŠECHNO NA JEDNOM MÍSTĚ!
    //
    //          Ukazatel na konfigurační soubor s výchozími hodnotami
    //
    // ================================================================
    private const I_MAX_CONFIG_BYTES = 64 * 1024;
    private const ARR_NUMBER_RANGES = [
        'scan_interval' => [60, 3600],
        'smtp_port' => [1, 65535],
        'email_batch_wait' => [0, 3600],
        'email_batch_max' => [1, 3600],
    ];
    private static $sDefaultsFile = '/usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/defaults.json';
    private static $arrData = null;

    private static function loadDefaults()
    {
        if (self::$arrData === null) {
            $sJson = file_get_contents(self::$sDefaultsFile);
            self::$arrData = json_decode($sJson, true);
        }
        return self::$arrData;
    }

    public static function getPaths()
    {
        $arrData = self::loadDefaults();
        return $arrData['paths'];
    }
    
    public static function getPath($sKey)
    {
        $arrPaths = self::getPaths();
        return isset($arrPaths[$sKey]) ? $arrPaths[$sKey] : null;
    }

    public static function getConfig()
    {
        $arrData = self::loadDefaults();
        $sConfigFilePath = $arrData['paths']['configFile'];
        
        // Pokud existuje config.json, načti z něj
        if (file_exists($sConfigFilePath)) {
            $sJson = @file_get_contents($sConfigFilePath, false, null, 0, self::I_MAX_CONFIG_BYTES + 1);
            $oSavedConfig = $sJson !== false && strlen($sJson) <= self::I_MAX_CONFIG_BYTES ? json_decode($sJson) : null;
            $arrSavedConfig = is_object($oSavedConfig)
                ? array_intersect_key((array)$oSavedConfig, $arrData['config'])
                : null;
            foreach ($arrSavedConfig ?? [] as $sField => $xValue) {
                [$iMin, $iMax] = self::ARR_NUMBER_RANGES[$sField] ?? [null, null];
                $bValid = $iMin !== null
                    ? (is_int($xValue) || (is_string($xValue) && preg_match('/^[0-9]{1,10}$/D', $xValue)))
                        && (int)$xValue >= $iMin && (int)$xValue <= $iMax
                    : is_string($xValue) && strlen($xValue) <= 4096 && !preg_match('/[\x00-\x1f\x7f]/', $xValue);
                if (!$bValid || (in_array($sField, ['enabled', 'email_enabled', 'webhook_enabled', 'firewall_traffic_enabled'], true)
                    && !in_array($xValue, ['0', '1'], true))) {
                    $arrSavedConfig = null;
                    break;
                }
            }
            
            // Merge saved values over current defaults. This makes newly
            // added settings (for example Direct SMTP) available immediately
            // after an upgrade without deleting the existing config.json.
            if ($arrSavedConfig !== null && is_array($arrSavedConfig)) {
                unset($arrSavedConfig['paths']);
                // Konfigurace z verzí před Direct SMTP mohla metodu vůbec neobsahovat.
                $arrSavedConfig['email_method'] ??= 'sendmail';
                $arrSavedConfig['email_enabled'] ??= '1';
                $arrConfig = array_merge($arrData['config'], $arrSavedConfig);
                $arrConfig['paths'] = $arrData['paths'];
                return $arrConfig;
            }
        }
        
        // Jinak vrať defaults
        $arrConfig = $arrData['config'];
        $arrConfig['paths'] = $arrData['paths'];
        return $arrConfig;
    }


    // ========================================
    // GETTERY PRO CESTY (pro Controllery)
    // ========================================


    /**
     * Vrátí cestu k PID souboru
     */
    public function getPidFilePath()
    {
        return self::getPath('pidFile');
    }

    
    /**
     * Vrátí cestu k databázi
     */
    public function getDbFilePath()
    {
        return self::getPath('dbFile');
    }
    
    /**
     * Vrátí cestu ke konfiguračnímu souboru
     */
    public function getConfigFilePath()
    {
        return self::getPath('configFile');
    }
    
    /** Vstup: MAC a požadovaný příznak. Výstup: zda se označení podařilo uložit. */
    public function setKnownDevice(string $sMac, bool $bKnown): bool
    {
        $oDatabase = $this->getDb();
        $oDatabase->enableExceptions(true);

        try {
            $oDatabase->exec('BEGIN IMMEDIATE');
            $oColumns = $oDatabase->query('PRAGMA table_info(devices)');
            $bHasKnownColumn = false;
            while ($arrColumn = $oColumns->fetchArray(SQLITE3_ASSOC)) {
                if ($arrColumn['name'] === 'is_known') {
                    $bHasKnownColumn = true;
                    break;
                }
            }
            $oColumns->finalize();
            // První označení bezpečně doplní sloupec i do databází ze starších verzí.
            if (!$bHasKnownColumn) {
                $oDatabase->exec('ALTER TABLE devices ADD COLUMN is_known INTEGER NOT NULL DEFAULT 0');
            }

            $oStatement = $oDatabase->prepare('UPDATE devices SET is_known = :known WHERE mac = :mac');
            $oStatement->bindValue(':known', (int)$bKnown, SQLITE3_INTEGER);
            $oStatement->bindValue(':mac', $sMac, SQLITE3_TEXT);
            $oResult = $oStatement->execute();
            $oResult->finalize();
            $oStatement->close();
            $bSaved = $oDatabase->changes() > 0;
            $oDatabase->exec('COMMIT');
            return $bSaved;
        } catch (\Exception $oException) {
            syslog(LOG_ERR, 'DeviceMonitor known device: ' . $oException->getMessage());
            return false;
        } finally {
            $oDatabase->close();
        }
    }

    public function updateHostname($sMac, $sHostname)
    {
        $oDatabaseConnection = $this->getDb();
        $sHostname = trim($sHostname);
        
        if ($sHostname === '') {
            $oStatement = $oDatabaseConnection->prepare('UPDATE devices SET custom_hostname = NULL WHERE mac = :mac');
            $oStatement->bindValue(':mac', $sMac, SQLITE3_TEXT);
        } else {
            $oStatement = $oDatabaseConnection->prepare('UPDATE devices SET custom_hostname = :hn, hostname = :hn WHERE mac = :mac');
            $oStatement->bindValue(':hn', $sHostname, SQLITE3_TEXT);
            $oStatement->bindValue(':mac', $sMac, SQLITE3_TEXT);
        }
        
        $oStatement->execute();
        $iChanges = $oDatabaseConnection->changes();
        $oDatabaseConnection->close();
        return $iChanges > 0;
    }


    /**
     * Uložení konfigurace
     * @param array $data Data k uložení
     * @return bool True pokud se podařilo uložit
     */
    public function setConfig($arrData)
    {
        $sConfigFile = self::getPath('configFile');
        $sConfigDirectory = dirname($sConfigFile);
        if (!is_dir($sConfigDirectory) && !@mkdir($sConfigDirectory, 0755, true) && !is_dir($sConfigDirectory)) {
            return false;
        }
        unset($arrData['paths']);
        $sJson = json_encode($arrData, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
        if ($sJson === false || strlen($sJson) > self::I_MAX_CONFIG_BYTES) {
            return false;
        }

        $sTemporaryFile = @tempnam($sConfigDirectory, '.dm-config-');
        if ($sTemporaryFile === false) {
            return false;
        }
        try {
            return dirname($sTemporaryFile) === $sConfigDirectory
                && @chmod($sTemporaryFile, 0600)
                && @file_put_contents($sTemporaryFile, $sJson) === strlen($sJson)
                && @rename($sTemporaryFile, $sConfigFile);
        } finally {
            if (file_exists($sTemporaryFile)) {
                @unlink($sTemporaryFile);
            }
        }
    }

    
    // ========================================
    // DATABÁZE
    // ========================================
    
    private function getDb()
    {
        $sDbFilePath = self::getPath('dbFile');
        $sDatabaseDirectory = dirname($sDbFilePath);
        if (!is_dir($sDatabaseDirectory)) {
            mkdir($sDatabaseDirectory, 0755, true);
        }

        if (!file_exists($sDbFilePath)) {
            $this->initDatabase();
        }

        $oDatabaseConnection = new \SQLite3($sDbFilePath);
        $oDatabaseConnection->busyTimeout(5000);

        // Migration for existing installations: getDb() is also used by GUI
        // actions, so do not rely on scan_network.py having run first.
        $oDatabaseConnection->exec('CREATE TABLE IF NOT EXISTS deleted_devices (
            mac TEXT PRIMARY KEY,
            last_seen DATETIME,
            deleted_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )');

        return $oDatabaseConnection;
    }


    private function initDatabase()
    {
        $sDbFilePath = self::getPath('dbFile');
        $oDatabaseConnection = new \SQLite3($sDbFilePath);
        
        $oDatabaseConnection->exec('CREATE TABLE IF NOT EXISTS devices (
            mac TEXT PRIMARY KEY,
            ip TEXT,
            hostname TEXT,
            vendor TEXT,
            vlan TEXT,
            last_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
            notified INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 0,
            notification_pending INTEGER DEFAULT 0
        )');

        $oDatabaseConnection->exec('CREATE INDEX IF NOT EXISTS idx_last_seen ON devices(last_seen)');

        $oDatabaseConnection->exec('CREATE TABLE IF NOT EXISTS deleted_devices (
            mac TEXT PRIMARY KEY,
            last_seen DATETIME,
            deleted_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )');

        // Migration: add columns for older databases
        @$oDatabaseConnection->exec('ALTER TABLE devices ADD COLUMN first_seen DATETIME DEFAULT CURRENT_TIMESTAMP');
        @$oDatabaseConnection->exec('ALTER TABLE devices ADD COLUMN custom_hostname TEXT DEFAULT NULL');
        
        $oDatabaseConnection->close();
        chmod($sDbFilePath, 0644);
    }

    // ========================================
    // ZAŘÍZENÍ - CRUD OPERACE
    // ========================================
    
    /** Vstup: MAC a IP. Výstup: zda jsou spolu uložené v databázi zařízení. */
    public function hasDeviceAddress(string $sMac, string $sIp): bool
    {
        $sDatabasePath = self::getPath('dbFile');
        if (!is_file($sDatabasePath)) {
            return false;
        }
        $oDatabase = new \SQLite3($sDatabasePath, SQLITE3_OPEN_READONLY);
        try {
            $oStatement = $oDatabase->prepare('SELECT 1 FROM devices WHERE mac = :mac AND ip = :ip');
            if ($oStatement === false) {
                return false;
            }
            $oStatement->bindValue(':mac', $sMac, SQLITE3_TEXT);
            $oStatement->bindValue(':ip', $sIp, SQLITE3_TEXT);
            $oResult = $oStatement->execute();
            return $oResult !== false && $oResult->fetchArray(SQLITE3_NUM) !== false;
        } finally {
            $oDatabase->close();
        }
    }

    /**
     * Bez vstupu vrátí zařízení se stavem a časem posledního záznamu Hostwatch.
     * Pole last_seen_at nese sekundy od unixové epochy, nebo null, pokud čas chybí.
     */
    public function getDevices()
    {
        $arrDevices = [];
        $sDatabasePath = self::getPath('dbFile');

        if (file_exists($sDatabasePath)) {
            $oDatabase = new \SQLite3($sDatabasePath);
            // SQLite čte čas bez explicitní zóny v UTC, tak jak ho ukládá Hostwatch.
            $oResult = $oDatabase->query(
                "SELECT *, CAST(strftime('%s', last_seen) AS INTEGER) AS last_seen_at
                 FROM devices ORDER BY last_seen DESC"
            );

            while ($arrRow = $oResult->fetchArray(SQLITE3_ASSOC)) {
                $arrRow['is_known'] = (int)($arrRow['is_known'] ?? 0);
                $arrRow['status'] = (isset($arrRow['is_active']) && $arrRow['is_active'] == 1) ? 'online' : 'offline';
                if (empty($arrRow['vendor'])) {
                    $arrRow['vendor'] = 'Unknown';
                }

                // Ponech formát původního pole pro stávající klienty API.
                if (!empty($arrRow['last_seen'])) {
                    $iLegacyTimestamp = strtotime($arrRow['last_seen']);
                    if ($iLegacyTimestamp !== false) {
                        $arrRow['last_seen'] = date('d.m.Y - H:i:s', $iLegacyTimestamp);
                    }
                }

                $arrDevices[] = $arrRow;
            }

            $oDatabase->close();
        }

        return $arrDevices;
    }

    public function deleteDevice($sMac)
    {
        $oDatabaseConnection = $this->getDb();
        $sMac = strtolower(trim($sMac));

        $oDatabaseConnection->exec('BEGIN IMMEDIATE TRANSACTION');
        try {
            $oStatement = $oDatabaseConnection->prepare('SELECT last_seen FROM devices WHERE mac = :mac');
            $oStatement->bindValue(':mac', $sMac, SQLITE3_TEXT);
            $oDeleteResult = $oStatement->execute();
            $arrDeletedDevice = $oDeleteResult ? $oDeleteResult->fetchArray(SQLITE3_ASSOC) : false;

            if (!$arrDeletedDevice) {
                $oDatabaseConnection->exec('ROLLBACK');
                $oDatabaseConnection->close();
                return false;
            }

            // Remember the newest Hostwatch timestamp already represented by
            // this row. The same historical record must not recreate it.
            $oStatement = $oDatabaseConnection->prepare('INSERT OR REPLACE INTO deleted_devices (mac, last_seen, deleted_at) VALUES (:mac, :last_seen, CURRENT_TIMESTAMP)');
            $oStatement->bindValue(':mac', $sMac, SQLITE3_TEXT);
            $oStatement->bindValue(':last_seen', $arrDeletedDevice['last_seen'] ?? '', SQLITE3_TEXT);
            $oStatement->execute();

            $oStatement = $oDatabaseConnection->prepare('DELETE FROM devices WHERE mac = :mac');
            $oStatement->bindValue(':mac', $sMac, SQLITE3_TEXT);
            $oStatement->execute();
            $iChanges = $oDatabaseConnection->changes();

            $oDatabaseConnection->exec('COMMIT');
            $oDatabaseConnection->close();
            return $iChanges > 0;
        } catch (\Exception $oException) {
            $oDatabaseConnection->exec('ROLLBACK');
            $oDatabaseConnection->close();
            return false;
        }
    }

    public function clearAll()
    {
        $oDatabaseConnection = $this->getDb();
        $oDatabaseConnection->exec('BEGIN IMMEDIATE TRANSACTION');
        try {
            // Treat Clear All like repeated manual deletion: remember the
            // current last_seen value for every device so old Hostwatch
            // history does not immediately repopulate the table.
            $oDatabaseConnection->exec('INSERT OR REPLACE INTO deleted_devices (mac, last_seen, deleted_at) SELECT mac, last_seen, CURRENT_TIMESTAMP FROM devices');
            $oDatabaseConnection->exec('DELETE FROM devices');
            $oDatabaseConnection->exec('COMMIT');
            $oDatabaseConnection->close();
            return true;
        } catch (\Exception $oException) {
            $oDatabaseConnection->exec('ROLLBACK');
            $oDatabaseConnection->close();
            return false;
        }
    }
}