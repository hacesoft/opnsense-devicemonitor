<?php

// Předpony: arr = pole, b = příznak, i = celé číslo, o = objekt, s = řetězec, x = hodnota proměnlivého typu.
// Historie: 2.4.16 – kontrola typů a formátu identifikátorů zařízení.
// 2.4.14 – ochrana změn a omezení ručního pingu na uložená zařízení.
// 2.4.10 – čas serveru pro společné vyhodnocení aktivity.
// 2.4.9 – termín a výsledek přehledu PF.
// 2.4.8 – čtení souhrnů PF ze služby Device Monitor.
// 2.4.6 – čítače paketů PF s oprávněním diagnostiky v odpovědi seznamu.
// 2.4.0 – uložení ručního označení známého zařízení.
// 2.3.7 – sjednocení typových předpon proměnných.

// Historie: 2.3.3 – ruční ping je oddělený od stavu Hostwatch (#10).
// 2.3.5 – řazení Last Seen podle unixové časové značky.

namespace OPNsense\DeviceMonitor\Api;

use OPNsense\Base\ApiControllerBase;
use OPNsense\Core\ACL;
use OPNsense\DeviceMonitor\DeviceMonitor;

/**
 * DevicesController
 * 
 * API controller pro správu zařízení
 */
class DevicesController extends ApiControllerBase
{
    private function getPaths()
    {
        $sDefaultsFile = '/usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/defaults.json';
        
        if (file_exists($sDefaultsFile)) {
            $arrDefaults = json_decode(file_get_contents($sDefaultsFile), true);
            return $arrDefaults['paths'];  // ← Cesty z defaults.json
        }
        
        // Fallback pokud defaults.json neexistuje
        return [-1];
    }

    /** Vstup: hodnota z API. Výstup: zda má očekávaný formát MAC. */
    private function isDeviceMac($xMac): bool
    {
        return is_string($xMac) && preg_match('/^(?:[0-9a-f]{2}:){5}[0-9a-f]{2}$/iD', $xMac) === 1;
    }

    /**
     * Aktualizace custom hostname
     * POST /api/devicemonitor/devices/updatehostname
     */
    public function updatehostnameAction()
    {
        if ($this->request->isPost()) {
            $this->throwReadOnly();
            $sDeviceMac = $this->request->getPost('mac');
            $sHostname = $this->request->getPost('hostname');
            
            if (!$this->isDeviceMac($sDeviceMac) || !is_string($sHostname)
                || strlen($sHostname) > 1024 || preg_match('/[\x00-\x1f\x7f]/', $sHostname)) {
                return ['result' => 'failed', 'error' => 'Invalid MAC or hostname'];
            }
            
            $oModel = new DeviceMonitor();
            if ($oModel->updateHostname(strtolower($sDeviceMac), $sHostname)) {
                return ['result' => 'saved'];
            }
        }
        return ['result' => 'failed'];
    }

    /** Vstup: POST s MAC a is_known (0 nebo 1). Výstup: výsledek uložení. */
    public function setknownAction()
    {
        if (!$this->request->isPost()) {
            return ['result' => 'failed'];
        }
        $this->throwReadOnly();

        $sDeviceMac = $this->request->getPost('mac');
        $sKnown = $this->request->getPost('is_known', 'string', '');
        if (!$this->isDeviceMac($sDeviceMac) || !in_array($sKnown, ['0', '1'], true)) {
            return ['result' => 'failed'];
        }

        $oModel = new DeviceMonitor();
        return ['result' => $oModel->setKnownDevice(strtolower($sDeviceMac), $sKnown === '1') ? 'saved' : 'failed'];
    }

    /**
     * Vyhledání zařízení (pro Bootgrid tabulku)
     * GET/POST /api/devicemonitor/devices/search
     */
    public function searchAction()
    {
        
        try {
            $oModel = new DeviceMonitor();
            $arrDevices = $oModel->getDevices();
            $bIncludePf = $this->request->isPost()
                && $this->request->getPost('include_pf_packets', 'string', '0') === '1';
            
            // Zpracuj parametry z Bootgrid - bezpečně
            $iCurrentPage = 1;
            $iRowCount = -1;
            $sSearchPhrase = '';
            $arrSort = [];
            
            if ($this->request->has('current')) {
                $iCurrentPage = intval($this->request->get('current'));
            }
            if ($this->request->has('rowCount')) {
                $iRowCount = intval($this->request->get('rowCount'));
            }
            if ($this->request->has('searchPhrase')) {
                $sSearchPhrase = (string)$this->request->get('searchPhrase');
            }
            if ($this->request->has('sort')) {
                $xSortData = $this->request->get('sort');
                if (is_array($xSortData)) {
                    $arrSort = $xSortData;
                }
            }
            
            // === 1. FILTROVÁNÍ ===
            if (!empty($sSearchPhrase) && strlen(trim($sSearchPhrase)) > 0) {
                $sSearchPhrase = strtolower(trim($sSearchPhrase));
                $arrFiltered = [];
                
                foreach ($arrDevices as $arrDevice) {
                    $bMatch = false;
                    
                    // Kontrola všech polí
                    if (isset($arrDevice['mac']) && strpos(strtolower($arrDevice['mac']), $sSearchPhrase) !== false) {
                        $bMatch = true;
                    }
                    if (isset($arrDevice['ip']) && strpos(strtolower($arrDevice['ip']), $sSearchPhrase) !== false) {
                        $bMatch = true;
                    }
                    if (isset($arrDevice['hostname']) && strpos(strtolower($arrDevice['hostname']), $sSearchPhrase) !== false) {
                        $bMatch = true;
                    }
                    if (isset($arrDevice['vendor']) && strpos(strtolower($arrDevice['vendor']), $sSearchPhrase) !== false) {
                        $bMatch = true;
                    }
                    if (isset($arrDevice['vlan']) && strpos(strtolower($arrDevice['vlan']), $sSearchPhrase) !== false) {
                        $bMatch = true;
                    }
                    if (isset($arrDevice['status']) && strpos(strtolower($arrDevice['status']), $sSearchPhrase) !== false) {
                        $bMatch = true;
                    }
                    
                    if ($bMatch) {
                        $arrFiltered[] = $arrDevice;
                    }
                }
                
                $arrDevices = $arrFiltered;
            }
            
            $iTotal = count($arrDevices);
            
            // === 2. ŘAZENÍ ===
            if (!empty($arrSort) && is_array($arrSort)) {
                $sSortColumn = key($arrSort);
                $sSortOrder = $arrSort[$sSortColumn];

                if (in_array($sSortColumn, ['mac', 'ip', 'hostname', 'vendor', 'vlan', 'first_seen', 'last_seen', 'status'], true)) {
                    // Seřadí dva řádky podle vybraného pole a směru řazení.
                    $sSortField = $sSortColumn === 'last_seen' ? 'last_seen_at' : $sSortColumn;
                    usort($arrDevices, function ($arrLeft, $arrRight) use ($sSortField, $sSortOrder) {
                        $xLeft = $arrLeft[$sSortField] ?? '';
                        $xRight = $arrRight[$sSortField] ?? '';
                        $iComparison = $xLeft <=> $xRight;
                        return $sSortOrder === 'desc' ? -$iComparison : $iComparison;
                    });
                }
            }

            // === 3. STRÁNKOVÁNÍ ===
            if ($iRowCount > 0) {
                $iOffset = ($iCurrentPage - 1) * $iRowCount;
                $arrDevices = array_slice($arrDevices, $iOffset, $iRowCount);
            }
            
            // Re-index pole (bootgrid vyžaduje indexed array)
            $arrDevices = array_values($arrDevices);
            
            $arrResult = [
                'rows' => $arrDevices,
                'rowCount' => count($arrDevices),
                'total' => $iTotal,
                'current' => $iCurrentPage,
                'server_time' => time()
            ];
            if ($bIncludePf) {
                $arrResult['pf_packets'] = $this->readPfPackets($arrDevices);
            }
            return $arrResult;

        } catch (\Exception $oException) {
            // V případě chyby vrať prázdná data
            return [
                'rows' => [],
                'rowCount' => 0,
                'total' => 0,
                'current' => 1,
                'error' => $oException->getMessage()
            ];
        }
    }

    /** Vstup: řádky odpovědi. Výstup: souhrny PF pro tyto řádky a čas serveru. */
    private function readPfPackets(array $arrDevices): ?array
    {
        if ((string)(DeviceMonitor::getConfig()['firewall_traffic_enabled'] ?? '0') !== '1') {
            return null;
        }
        $oAcl = new ACL();
        $sUser = $this->getUserName();
        if (!$oAcl->hasPrivilege($sUser, 'page-all')
            && !$oAcl->hasPrivilege($sUser, 'page-diagnostics-system-pftop')) {
            return null;
        }

        $sPath = DeviceMonitor::getPath('pfTrafficFile') ?? '';
        if ($sPath === '' || !is_readable($sPath)) {
            return null;
        }
        $arrSnapshot = json_decode((string)@file_get_contents($sPath), true);
        $iNow = time();
        $iSampleAt = $arrSnapshot['sampleAt'] ?? 0;
        if (!is_array($arrSnapshot['rows'] ?? null) || !is_int($iSampleAt)) {
            return null;
        }

        $arrRows = [];
        foreach ($arrDevices as $arrDevice) {
            $sKey = $arrDevice['mac'] . '|' . $arrDevice['ip'];
            if (isset($arrSnapshot['rows'][$sKey])) {
                $arrRows[$sKey] = $arrSnapshot['rows'][$sKey];
            }
        }
        return [
            'now' => $iNow,
            'nextReviewAt' => $arrSnapshot['nextReviewAt'] ?? 0,
            'lastReview' => $arrSnapshot['lastReview'] ?? null,
            'available' => ($arrSnapshot['available'] ?? false) && $iSampleAt <= $iNow && $iNow - $iSampleAt <= 75,
            'rows' => (object)$arrRows
        ];
    }

    /**
     * Statistiky zařízení
     * GET /api/devicemonitor/devices/stats
     */
    public function statsAction()
    {
        
        $arrPaths = $this->getPaths();
        $arrStats = ['total' => 0, 'online' => 0];
        
        try {
            if (file_exists($arrPaths['dbFile'])) {
                $oDatabase = new \SQLite3($arrPaths['dbFile']);
                
                $arrStats['total'] = (int)$oDatabase->querySingle(
                    "SELECT COUNT(*) FROM devices"
                );
                
                $arrStats['online'] = (int)$oDatabase->querySingle(
                    "SELECT COUNT(*) FROM devices WHERE is_active = 1"
                );
                
                $oDatabase->close();
            }
        } catch (\Exception $oException) {
            syslog(LOG_ERR, "DeviceMonitor stats error: " . $oException->getMessage());
        }
        
        return $arrStats;
    }

    /**
    * Rychlá aktualizace online/offline statusu (hostwatch DB)
     * POST /api/devicemonitor/devices/updatestatus
     */
    public function updatestatusAction()
    {
        if (!$this->request->isPost()) {
            return ['result' => 'failed'];
        }
        $this->throwReadOnly();
        
        $arrPaths = $this->getPaths();
        
        // Zavolej scan_network.py s --update-only
        exec(escapeshellarg($arrPaths['scanScript']) . ' --update-only 2>&1', $arrCommandOutput, $iCommandExitCode);
        
        if ($iCommandExitCode === 0) {
            // Znovu načti statistiky z DB
            return $this->statsAction();  // ← Správně!
        }
        
        // Pokud scan selhal, vrať error
        return ['result' => 'error', 'online' => 0, 'total' => 0];
    }

    /**
     * Smazání jednoho zařízení
     * POST /api/devicemonitor/devices/delete
     */
    public function deleteAction()
    {
        if ($this->request->isPost()) {
            $this->throwReadOnly();
            $sDeviceMac = $this->request->getPost('mac');
            $oModel = new DeviceMonitor();

            if ($this->isDeviceMac($sDeviceMac) && $oModel->deleteDevice(strtolower($sDeviceMac))) {
                return ['result' => 'deleted'];
            }
        }

        return ['result' => 'failed'];
    }

    /**
     * Provede ruční ping bez zápisu do stavu Hostwatch.
     * Vstup: IP a MAC adresa v POST. Výstup: výsledek pingu a čas kontroly.
     */
    public function pingdeviceAction()
    {
        if (!$this->request->isPost()) {
            return ['result' => 'failed'];
        }
        $this->throwReadOnly();

        $sIp = $this->request->getPost('ip', 'string', '');
        $sMac = $this->request->getPost('mac', 'string', '');
        if (!is_string($sIp) || !$this->isDeviceMac($sMac)) {
            return ['result' => 'failed', 'error' => 'IP and MAC required'];
        }
        if (!filter_var($sIp, FILTER_VALIDATE_IP)) {
            return ['result' => 'failed', 'error' => 'Invalid IP'];
        }

        if (!(new DeviceMonitor())->hasDeviceAddress(strtolower($sMac), $sIp)) {
            return ['result' => 'failed', 'error' => 'Device address changed or unknown'];
        }

        // FreeBSD očekává dobu čekání v milisekundách.
        exec('/sbin/ping -c 2 -W 1000 ' . escapeshellarg($sIp) . ' > /dev/null 2>&1', $arrOutput, $iExitCode);
        if ($iExitCode !== 0 && $iExitCode !== 2) {
            return ['result' => 'failed', 'error' => 'Ping failed'];
        }

        return [
            'result' => $iExitCode === 0 ? 'online' : 'offline',
            'ip' => $sIp,
            'mac' => $sMac,
            'checked_at' => time(),
        ];
    }

    /**
     * Vyčištění celé databáze
     * POST /api/devicemonitor/devices/clear
     */
    public function clearAction()
    {
        if ($this->request->isPost()) {
            $this->throwReadOnly();
            $oModel = new DeviceMonitor();
            return ['result' => $oModel->clearAll() ? 'cleared' : 'failed'];
        }

        return ['result' => 'failed'];
    }
}