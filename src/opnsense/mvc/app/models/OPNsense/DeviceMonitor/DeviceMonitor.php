<?php

namespace OPNsense\DeviceMonitor;

class DeviceMonitor
{
    // ================================================================
    // CESTY - VŠECHNO NA JEDNOM MÍSTĚ!
    //
    //          Ukazatel na konfigurační soubor s výchozími hodnotami
    //
    // ================================================================
    private static $defaultsFile = '/usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/defaults.json';
    private static $data = null;
    
    //private $dbFile = '/var/db/devicemonitor/devices.db';       // Databáze zařízení
    //private $ouiFile = '/var/db/devicemonitor/oui.txt';         // OUI databáze vendorů
    //private $configFile = '/var/db/devicemonitor/config.json';  // Konfigurace (včetně OUI)
    //private $cronFile = '/etc/cron.d/devicemonitor_oui';        // Cron soubor pro auto-update

    private static function loadDefaults()
    {
        if (self::$data === null) {
            $json = file_get_contents(self::$defaultsFile);
            self::$data = json_decode($json, true);
        }
        return self::$data;
    }

    public static function getPaths()
    {
        $data = self::loadDefaults();
        return $data['paths'];
    }
    
    public static function getPath($key)
    {
        $paths = self::getPaths();
        return isset($paths[$key]) ? $paths[$key] : null;
    }

    public static function getConfig()
    {
        $data = self::loadDefaults();
        $configFilePath = $data['paths']['configFile'];
        
        // Pokud existuje config.json, načti z něj
        if (file_exists($configFilePath)) {
            $json = file_get_contents($configFilePath);
            $savedConfig = json_decode($json, true);
            
            // Použij uložené hodnoty, ale zachovej cesty z defaults
            if ($savedConfig !== null && is_array($savedConfig)) {
                $savedConfig['paths'] = $data['paths'];
                return $savedConfig;
            }
        }
        
        // Jinak vrať defaults
        $config = $data['config'];
        $config['paths'] = $data['paths'];
        return $config;
    }


    // ========================================
    // GETTERY PRO CESTY (pro Controllery)
    // ========================================

    /**
     * Vrátí cestu k download OUI scriptu
     */
    public function getOuiDownloadScriptPath()
    {
        return self::getPath('ouiDownloadScript');
    }

    /**
     * Vrátí cestu k PID souboru
     */
    public function getPidFilePath()
    {
        return self::getPath('pidFile');
    }
    
    /**
     * Vrátí cestu k OUI souboru
     */
    public function getOuiFilePath()
    {
        return self::getPath('ouiFile');
    }
    
    /**
     * Vrátí cestu k cron souboru
     */
    public function getCronFilePath()
    {
        return self::getPath('cronFile');
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
    

    /**
     * Uložení konfigurace (včetně OUI)
     * @param array $data Data k uložení
     * @return bool True pokud se podařilo uložit
     */
    public function setConfig($data)
    {
        $file_name = self::getPath('configFile');
        
        // Bezpečné zajištění adresáře - nesmí blokovat uložení!
        $dir = dirname($file_name);
        if (!is_dir($dir)) {
            try {
                @mkdir($dir, 0755, true);
            } catch (\Exception $e) {
                // Ignoruj chybu - zkusíme uložit soubor i tak
            }
        }
        
        // Ulož jako JSON s potlačením varování
        $json = json_encode($data, JSON_PRETTY_PRINT);
        $result = @file_put_contents($file_name, $json);
        
        if ($result !== false) {
            @chmod($file_name, 0644);
            return true;
        }
        
        return false;
    }

    
    // ========================================
    // DATABÁZE
    // ========================================
    
    private function getDb()
    {
        $file_mame = self::getPath('dbFile');
        $dbDir = dirname($file_mame);
        if (!is_dir($dbDir)) {
            mkdir($dbDir, 0755, true);
        }

        if (!file_exists($file_mame)) {
            $this->initDatabase();
        }

        $db = new \SQLite3($file_mame);
        $db->busyTimeout(5000);
        return $db;
    }


    private function initDatabase()
    {
        $file_mame = self::getPath('dbFile');
        $db = new \SQLite3($file_mame);
        
        $db->exec('CREATE TABLE IF NOT EXISTS devices (
            mac TEXT PRIMARY KEY,
            ip TEXT,
            hostname TEXT,
            vendor TEXT,
            vlan TEXT,
            last_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
            notified INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 0
        )');
        
        $db->exec('CREATE INDEX IF NOT EXISTS idx_last_seen ON devices(last_seen)');
        $db->exec('CREATE INDEX IF NOT EXISTS idx_vlan ON devices(vlan)');
        
        $db->close();
        chmod($file_mame, 0644);
    }

    // ========================================
    // OUI VENDOR LOOKUP
    // ========================================
    
    private function lookupVendor($mac)
    {
        $file_mame = self::getPath('ouiFile');
        if (!file_exists($file_mame)) {
            return 'Unknown';
        }
        
        // Vezmi prvních 6 hex znaků (bez oddělovačů)
        $prefix = strtoupper(str_replace([':', '-', '.'], '', substr($mac, 0, 8)));
        $handle = @fopen($file_mame, 'r');
        if (!$handle) {
            return 'Unknown';
        }
        
        while (($line = fgets($handle)) !== false) {
            if (strpos($line, $prefix) === 0) {
                // Parsuj řádek: "F490EA     (base 16)"
                if (preg_match('/\(base 16\)\s+(.+)$/i', $line, $matches)) {
                    fclose($handle);
                    return trim($matches[1]);
                }
            }
        }
        
        fclose($handle);
        return 'Unknown';
    }

    // ========================================
    // ZAŘÍZENÍ - CRUD OPERACE
    // ========================================
    
    /**
     * Získání všech zařízení z databáze
     * @return array Seznam zařízení (upravený podle konfigurace)
     */
    public function getDevices()
    {
        $devices = [];
        $config = $this->getConfig();
        $file_mame = self::getPath('dbFile');
        
        if (file_exists($file_mame)) {
            $db = new \SQLite3($file_mame);
            $result = $db->query('SELECT * FROM devices ORDER BY last_seen DESC');
            
            $currentTime = time();
            
            while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
                // Aplikuj show_domain nastavení
                if (isset($config['show_domain']) && $config['show_domain'] === '0') {
                    $row['hostname'] = $this->stripDomainFromHostname($row['hostname']);
                }
                
                // Vypočítej status: ONLINE pokud last_seen < 5 minut
                $lastSeenTimestamp = strtotime($row['last_seen']);
                $timeDiff = $currentTime - $lastSeenTimestamp;
                
                // Status podle is_active sloupce (místo času)
                $row['status'] = (isset($row['is_active']) && $row['is_active'] == 1) ? 'online' : 'offline';
                
                // Vendor může být NULL - oprav to
                if (empty($row['vendor'])) {
                    $row['vendor'] = 'Unknown';
                }

                // Formátuj datum do českého formátu: 29.12.2025 - 18:37:51
                if (!empty($row['last_seen'])) {
                    $timestamp = strtotime($row['last_seen']);
                    if ($timestamp !== false) {
                        $row['last_seen'] = date('d.m.Y - H:i:s', $timestamp);
                    }
                }
                
                $devices[] = $row;
            }
            
            $db->close();
        }
        
        return $devices;
    }

    public function getDeviceCount()
    {
        $db = $this->getDb();
        $count = $db->querySingle('SELECT COUNT(*) FROM devices');
        $db->close();
        return (int)$count;
    }

    public function getNewDevicesToday()
    {
        // Vrátí počet ONLINE zařízení (viděných za posledních 5 minut)
        $db = $this->getDb();
        
        // Vypočítej timestamp před 5 minutami
        $fiveMinutesAgo = date('Y-m-d H:i:s', strtotime('-5 minutes'));
        
        $stmt = $db->prepare('SELECT COUNT(*) FROM devices WHERE last_seen >= :threshold');
        
        if ($stmt === false) {
            $db->close();
            return 0;
        }
        
        $stmt->bindValue(':threshold', $fiveMinutesAgo, SQLITE3_TEXT);
        $result = $stmt->execute();
        
        if ($result === false) {
            $db->close();
            return 0;
        }
        
        $row = $result->fetchArray(SQLITE3_NUM);
        $count = $row ? (int)$row[0] : 0;
        
        $db->close();
        return $count;
    }

    public function deleteDevice($mac)
    {
        $db = $this->getDb();
        $stmt = $db->prepare('DELETE FROM devices WHERE mac = :mac');
        $stmt->bindValue(':mac', $mac, SQLITE3_TEXT);
        $stmt->execute();
        $changes = $db->changes();
        $db->close();
        return $changes > 0;
    }

    public function clearAll()
    {
        $db = $this->getDb();
        $db->exec('DELETE FROM devices');
        $db->close();
        return true;
    }

    // ========================================
    // POMOCNÉ FUNKCE
    // ========================================
    
    /**
     * Odstranění domény z hostname
     */
    private function stripDomainFromHostname($hostname)
    {
        if (empty($hostname)) {
            return $hostname;
        }
        
        // Odstraň doménu (.localdomain, .local, atd.)
        $parts = explode('.', $hostname);
        return $parts[0];
    }
}