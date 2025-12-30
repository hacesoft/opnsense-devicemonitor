<?php

namespace OPNsense\DeviceMonitor\Api;

use OPNsense\Base\ApiControllerBase;
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
        $defaultsFile = '/usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/defaults.json';
        
        if (file_exists($defaultsFile)) {
            $defaults = json_decode(file_get_contents($defaultsFile), true);
            return $defaults['paths'];  // ← Cesty z defaults.json
        }
        
        // Fallback pokud defaults.json neexistuje
        return [-1];
    }


    /**
     * Vyhledání zařízení (pro Bootgrid tabulku)
     * GET/POST /api/devicemonitor/devices/search
     */
    public function searchAction()
    {
        $this->sessionClose();
        
        try {
            $model = new DeviceMonitor();
            $devices = $model->getDevices();
            
            // Zpracuj parametry z Bootgrid - bezpečně
            $current = 1;
            $rowCount = -1;
            $searchPhrase = '';
            $sort = [];
            
            if ($this->request->has('current')) {
                $current = intval($this->request->get('current'));
            }
            if ($this->request->has('rowCount')) {
                $rowCount = intval($this->request->get('rowCount'));
            }
            if ($this->request->has('searchPhrase')) {
                $searchPhrase = (string)$this->request->get('searchPhrase');
            }
            if ($this->request->has('sort')) {
                $sortData = $this->request->get('sort');
                if (is_array($sortData)) {
                    $sort = $sortData;
                }
            }
            
            // === 1. FILTROVÁNÍ ===
            if (!empty($searchPhrase) && strlen(trim($searchPhrase)) > 0) {
                $searchPhrase = strtolower(trim($searchPhrase));
                $filtered = [];
                
                foreach ($devices as $device) {
                    $match = false;
                    
                    // Kontrola všech polí
                    if (isset($device['mac']) && strpos(strtolower($device['mac']), $searchPhrase) !== false) {
                        $match = true;
                    }
                    if (isset($device['ip']) && strpos(strtolower($device['ip']), $searchPhrase) !== false) {
                        $match = true;
                    }
                    if (isset($device['hostname']) && strpos(strtolower($device['hostname']), $searchPhrase) !== false) {
                        $match = true;
                    }
                    if (isset($device['vendor']) && strpos(strtolower($device['vendor']), $searchPhrase) !== false) {
                        $match = true;
                    }
                    if (isset($device['vlan']) && strpos(strtolower($device['vlan']), $searchPhrase) !== false) {
                        $match = true;
                    }
                    if (isset($device['status']) && strpos(strtolower($device['status']), $searchPhrase) !== false) {
                        $match = true;
                    }
                    
                    if ($match) {
                        $filtered[] = $device;
                    }
                }
                
                $devices = $filtered;
            }
            
            $total = count($devices);
            
            // === 2. ŘAZENÍ ===
            if (!empty($sort) && is_array($sort)) {
                $sortColumn = key($sort);
                $sortOrder = $sort[$sortColumn];
                
                if ($sortColumn && in_array($sortColumn, ['mac', 'ip', 'hostname', 'vendor', 'vlan', 'first_seen', 'last_seen', 'status'])) {
                    usort($devices, function($a, $b) use ($sortColumn, $sortOrder) {
                        $valA = isset($a[$sortColumn]) ? $a[$sortColumn] : '';
                        $valB = isset($b[$sortColumn]) ? $b[$sortColumn] : '';
                        
                        // Porovnání
                        if ($valA == $valB) {
                            return 0;
                        }
                        
                        $result = ($valA < $valB) ? -1 : 1;
                        
                        // Podle směru řazení
                        return ($sortOrder === 'desc') ? -$result : $result;
                    });
                }
            }
            
            // === 3. STRÁNKOVÁNÍ ===
            if ($rowCount > 0) {
                $offset = ($current - 1) * $rowCount;
                $devices = array_slice($devices, $offset, $rowCount);
            }
            
            // Re-index pole (bootgrid vyžaduje indexed array)
            $devices = array_values($devices);
            
            return [
                'rows' => $devices,
                'rowCount' => count($devices),
                'total' => $total,
                'current' => $current
            ];
            
        } catch (\Exception $e) {
            // V případě chyby vrať prázdná data
            return [
                'rows' => [],
                'rowCount' => 0,
                'total' => 0,
                'current' => 1,
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Statistiky zařízení
     * GET /api/devicemonitor/devices/stats
     */
    public function statsAction()
    {
        $this->sessionClose();
        
        $paths = $this->getPaths();
        $result = ['total' => 0, 'online' => 0];
        
        try {
            if (file_exists($paths['dbFile'])) {
                $db = new \SQLite3($paths['dbFile']);
                
                $result['total'] = (int)$db->querySingle(
                    "SELECT COUNT(*) FROM devices"
                );
                
                $result['online'] = (int)$db->querySingle(
                    "SELECT COUNT(*) FROM devices WHERE is_active = 1"
                );
                
                $db->close();
            }
        } catch (\Exception $e) {
            syslog(LOG_ERR, "DeviceMonitor stats error: " . $e->getMessage());
        }
        
        return $result;
    }

    /**
     * Rychlá aktualizace online/offline statusu (pfctl only)
     * POST /api/devicemonitor/devices/updatestatus
     */
    public function updatestatusAction()
    {
        $this->sessionClose();
        
        $paths = $this->getPaths();
        
        // Zavolej scan_network.py s --update-only
        exec("{$paths['scanScript']} --update-only 2>&1", $output, $return_code);
        
        if ($return_code === 0) {
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
            $mac = $this->request->getPost('mac');
            $model = new DeviceMonitor();

            if ($model->deleteDevice($mac)) {
                return ['result' => 'deleted'];
            }
        }

        return ['result' => 'failed'];
    }

    /**
     * Vyčištění celé databáze
     * POST /api/devicemonitor/devices/clear
     */
    public function clearAction()
    {
        if ($this->request->isPost()) {
            $model = new DeviceMonitor();
            $model->clearAll();
            return ['result' => 'cleared'];
        }

        return ['result' => 'failed'];
    }
}