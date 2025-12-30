<?php

namespace OPNsense\DeviceMonitor\Api;

use OPNsense\Base\ApiControllerBase;

class OuiController extends ApiControllerBase
{
    /**
     * Status OUI databáze
     */
    public function statusAction()
    {
        $model = new \OPNsense\DeviceMonitor\DeviceMonitor();
        $ouiFile = $model->getOuiFilePath();
        
        if (file_exists($ouiFile)) {
            $size = filesize($ouiFile);
            $sizeFormatted = $this->formatBytes($size);
            
            // Počet výrobců (řádky s "base 16")
            $count = 0;
            $handle = fopen($ouiFile, 'r');
            if ($handle) {
                while (($line = fgets($handle)) !== false) {
                    if (strpos($line, '(base 16)') !== false || strpos($line, '(hex)') !== false) {
                        $count++;
                    }
                }
                fclose($handle);
            }
            
            $updated = date('Y-m-d H:i:s', filemtime($ouiFile));
            
            return [
                'exists' => true,
                'size' => $sizeFormatted,
                'count' => number_format($count, 0, ',', ' '),
                'updated' => $updated
            ];
        } else {
            return [
                'exists' => false
            ];
        }
    }
    
    /**
     * Načtení OUI konfigurace
     * Vrací jen sekci 'oui' ze sjednoceného configu
     */
    public function getconfigAction()
    {
        $model = new \OPNsense\DeviceMonitor\DeviceMonitor();
        $config = $model->getConfig();
        
        // Vrať jen OUI sekci
        return isset($config['oui']) ? $config['oui'] : [
            'urls' => [],
            'auto_update_enabled' => '0',
            'update_hour' => '3'
        ];
    }
    
    /**
     * Uložení OUI konfigurace
     * Ukládá jen sekci 'oui' do sjednoceného configu
     */
    public function setconfigAction()
    {
        if ($this->request->isPost()) {
            $json = $this->request->getRawBody();
            $data = json_decode($json, true);
            
            if (!$data) {
                return ['result' => 'failed', 'message' => 'Invalid JSON'];
            }
            
            // Validace
            if (empty($data['urls']) || !is_array($data['urls'])) {
                return ['result' => 'failed', 'message' => 'URLs must be an array'];
            }
            
            // Načti celý config
            $model = new \OPNsense\DeviceMonitor\DeviceMonitor();
            $config = $model->getConfig();
            
            // Uprav jen OUI sekci
            $config['oui'] = $data;
            
            // Ulož celý config
            if ($model->setConfig($config)) {
                // Nastav cron pokud je auto-update zapnutý
                if (isset($data['auto_update_enabled']) && $data['auto_update_enabled'] == '1') {
                    $this->setupCron($model, $data['update_hour']);
                } else {
                    $this->removeCron($model);
                }
                
                return ['result' => 'saved', 'message' => 'Configuration saved'];
            }
            
            return ['result' => 'failed', 'message' => 'Failed to save configuration'];
        }
        
        return ['result' => 'failed'];
    }

    /**
     * Stažení OUI databáze
     */
    public function downloadAction()
    {
        if ($this->request->isPost()) {
            // ✅ DEBUG LOG - otevři soubor pro debug
            $debugFile = '/tmp/devicemonitor_debug.log';
            file_put_contents($debugFile, "=== DOWNLOAD START ===\n", FILE_APPEND);
            
            $model = new \OPNsense\DeviceMonitor\DeviceMonitor();
            $ouiFile = $model->getOuiFilePath();
            
            file_put_contents($debugFile, "OUI File: $ouiFile\n", FILE_APPEND);
            
            // Vytvoř adresář pokud neexistuje
            $dir = dirname($ouiFile);
            if (!is_dir($dir)) {
                mkdir($dir, 0755, true);
            }
            
            // ✅ NAČTI CONFIG A VYPIŠ CO PŘIŠLO
            $fullConfig = $model->getConfig();
            file_put_contents($debugFile, "Full Config:\n" . print_r($fullConfig, true) . "\n", FILE_APPEND);
            
            // Zkus vzít OUI sekci
            $ouiConfig = isset($fullConfig['oui']) ? $fullConfig['oui'] : [];
            file_put_contents($debugFile, "OUI Config:\n" . print_r($ouiConfig, true) . "\n", FILE_APPEND);
            
            // Zkus vzít URLs
            $urls = isset($ouiConfig['urls']) ? $ouiConfig['urls'] : [];
            file_put_contents($debugFile, "URLs:\n" . print_r($urls, true) . "\n", FILE_APPEND);
            file_put_contents($debugFile, "URLs count: " . count($urls) . "\n", FILE_APPEND);
            
            if (empty($urls)) {
                file_put_contents($debugFile, "ERROR: URLs are empty!\n", FILE_APPEND);
                return [
                    'result' => 'failed',
                    'message' => 'No URLs configured',
                    'log' => "Check debug log: $debugFile"
                ];
            }
            
            $success = false;
            $lastError = '';
            $attemptLog = [];
            
            foreach ($urls as $index => $url) {
                $attemptNumber = $index + 1;
                $attemptLog[] = "Attempt $attemptNumber: $url";
                
                // Použij curl
                $cmd = sprintf(
                    'curl -f -s -L -o %s --connect-timeout 30 --max-time 300 %s 2>&1',
                    escapeshellarg($ouiFile),
                    escapeshellarg($url)
                );
                
                exec($cmd, $output, $return);
                
                if ($return === 0 && file_exists($ouiFile) && filesize($ouiFile) > 1000) {
                    chmod($ouiFile, 0644);
                    $success = true;
                    $attemptLog[] = "✓ SUCCESS on attempt $attemptNumber";
                    break;
                } else {
                    $errorDetail = implode(' ', $output);
                    if (empty($errorDetail)) {
                        $errorDetail = "Return code: $return";
                    }
                    $attemptLog[] = "✗ FAILED: $errorDetail";
                    $lastError = "URL $attemptNumber failed: $url - $errorDetail";
                }
            }
            
            if ($success) {
                $size = filesize($ouiFile);
                return [
                    'result' => 'success',
                    'message' => 'OUI database downloaded successfully',
                    'size' => $this->formatBytes($size),
                    'attempts' => count($attemptLog),
                    'log' => implode("\n", $attemptLog)
                ];
            } else {
                return [
                    'result' => 'failed',
                    'message' => 'All download attempts failed',
                    'error' => $lastError,
                    'attempts' => count($urls),
                    'log' => implode("\n", $attemptLog)
                ];
            }
        }
        
        return ['result' => 'failed', 'message' => 'Not a POST request'];
    }
    
    /**
     * Smazání OUI databáze
     */
    public function deleteAction()
    {
        if ($this->request->isPost()) {
            $model = new \OPNsense\DeviceMonitor\DeviceMonitor();
            $ouiFile = $model->getOuiFilePath();
            
            if (file_exists($ouiFile)) {
                unlink($ouiFile);
                return [
                    'result' => 'success',
                    'message' => 'OUI database deleted'
                ];
            } else {
                return [
                    'result' => 'failed',
                    'message' => 'Database does not exist'
                ];
            }
        }
        
        return ['result' => 'failed'];
    }
    
    /**
     * Nastavení cron jobu
     * @param object $model Instance DeviceMonitor modelu
     * @param string $hour Hodina pro spuštění
     */
    private function setupCron($model, $hour)
    {
        $cronFile = $model->getCronFilePath();
        $minute = '0';
        $downloadScript = $model->getOuiDownloadScriptPath();
        $cronLine = sprintf(
            "%s %s * * * root /usr/local/bin/python3 %s >/dev/null 2>&1\n",
            $minute,
            $hour,
            $downloadScript
        );
        
        file_put_contents($cronFile, $cronLine);
        chmod($cronFile, 0644);
        
        // Restart crond
        exec('service cron restart  2>&1', $output, $return);
        
        // Log pro debug
        if ($return !== 0) {
            error_log("DeviceMonitor: Cron restart failed: " . implode(' ', $output));
        }
        
        return ($return === 0);
    }
        
    /**
     * Odstranění cron jobu
     * @param object $model Instance DeviceMonitor modelu
     */
    private function removeCron($model)
    {
        $cronFile = $model->getCronFilePath();
        
        if (file_exists($cronFile)) {
            unlink($cronFile);
            exec('service cron restart');
        }
    }
    
    /**
     * Formátování velikosti
     */
    private function formatBytes($bytes)
    {
        $units = ['B', 'KB', 'MB', 'GB'];
        $i = 0;
        
        while ($bytes >= 1024 && $i < count($units) - 1) {
            $bytes /= 1024;
            $i++;
        }
        
        return round($bytes, 2) . ' ' . $units[$i];
    }
}