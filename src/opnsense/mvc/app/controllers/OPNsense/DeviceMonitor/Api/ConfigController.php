<?php

namespace OPNsense\DeviceMonitor\Api;

use OPNsense\Base\ApiControllerBase;
use OPNsense\DeviceMonitor\DeviceMonitor;

/**
 * ConfigController
 * 
 * API controller pro správu konfigurace
 */
class ConfigController extends ApiControllerBase
{
    /**
     * Načtení konfigurace
     * GET /api/devicemonitor/config/get
     */
    public function getAction()
    {
        $model = new DeviceMonitor();
        return $model->getConfig();
    }

    /**
     * Uložení konfigurace
     * POST /api/devicemonitor/config/set
     */
    public function setAction()
    {
        if (!$this->request->isPost()) {
            return [
                'result' => 'failed',
                'message' => 'Musí být POST request'
            ];
        }

        $model = new DeviceMonitor();
        
        // Načti data z POST
        $enabled = $this->request->getPost('enabled', 'string', '0');
        $email_to = $this->request->getPost('email_to', 'string', '');
        $email_from = $this->request->getPost('email_from', 'string', 'devicemonitor@opnsense.local');
        $scan_interval = $this->request->getPost('scan_interval', 'int', 300);
        $show_domain = $this->request->getPost('show_domain', 'string', '0');
        
        // Validace emailů (jen pokud je monitoring zapnutý)
        if ($enabled == '1') {
            if (empty($email_to) || !filter_var($email_to, FILTER_VALIDATE_EMAIL)) {
                return [
                    'result' => 'failed',
                    'message' => 'Neplatná emailová adresa příjemce'
                ];
            }
            
            if (!empty($email_from) && !filter_var($email_from, FILTER_VALIDATE_EMAIL)) {
                return [
                    'result' => 'failed',
                    'message' => 'Neplatná emailová adresa odesílatele'
                ];
            }
        }

        // Validace scan_interval
        if ($scan_interval < 60 || $scan_interval > 3600) {
            return [
                'result' => 'failed',
                'message' => 'Scan interval musí být mezi 60-3600 sekundami'
            ];
        }
        
        // Načti celý config (zachová OUI sekci)
        $config = $model->getConfig();
        
        // Uprav jen základní sekci
        $config['enabled'] = $enabled;
        $config['email_to'] = $email_to;
        $config['email_from'] = $email_from;
        $config['scan_interval'] = (int)$scan_interval;
        $config['show_domain'] = $show_domain;
        
        // Ulož pomocí modelu
        if ($model->setConfig($config)) {
            return [
                'result' => 'saved',
                'message' => 'Konfigurace uložena'
            ];
        }
        
        return [
            'result' => 'failed',
            'message' => 'Nepodařilo se uložit konfiguraci'
        ];
    }

    /**
     * Test odeslání emailu
     * POST /api/devicemonitor/config/testemail
     */
    public function testemailAction()
    {
        if (!$this->request->isPost()) {
            return ['result' => 'failed', 'message' => 'Musí být POST request'];
        }

        $model = new DeviceMonitor();
        $config = $model->getConfig();
        
        if (empty($config['email_to'])) {
            return [
                'result' => 'failed',
                'message' => 'Nejprve ulož emailovou adresu příjemce'
            ];
        }
        
        $email_to = $config['email_to'];
        $email_from = $config['email_from'];
        
        try {
            $subject = 'Test - OPNsense Device Monitor';
            $hostname = gethostname();
            $timestamp = date('Y-m-d H:i:s');
            
            // Vytvoř HTML email
            $html = "<html><body>\n";
            $html .= "<h2>Device Monitor - Test Email</h2>\n";
            $html .= "<p>Pokud vidíš tuto zprávu, <strong>email funguje správně!</strong></p>\n";
            $html .= "<hr>\n";
            $html .= "<table border='0' cellpadding='5'>\n";
            $html .= "<tr><td><strong>Server:</strong></td><td>$hostname</td></tr>\n";
            $html .= "<tr><td><strong>Čas:</strong></td><td>$timestamp</td></tr>\n";
            $html .= "<tr><td><strong>Příjemce:</strong></td><td>$email_to</td></tr>\n";
            $html .= "<tr><td><strong>Odesílatel:</strong></td><td>$email_from</td></tr>\n";
            $html .= "</table>\n";
            $html .= "</body></html>\n";
            
            // Sestavení emailu pro sendmail
            $message = "From: $email_from\n";
            $message .= "To: $email_to\n";
            $message .= "Subject: $subject\n";
            $message .= "Content-Type: text/html; charset=UTF-8\n\n";
            $message .= $html;
            
            // Odešli přes sendmail
            $descriptorspec = [
                0 => ["pipe", "r"],
                1 => ["pipe", "w"],
                2 => ["pipe", "w"]
            ];
            
            $process = proc_open('/usr/local/sbin/sendmail -t', $descriptorspec, $pipes);
            
            if (is_resource($process)) {
                fwrite($pipes[0], $message);
                fclose($pipes[0]);
                
                $stdout = stream_get_contents($pipes[1]);
                fclose($pipes[1]);
                
                $stderr = stream_get_contents($pipes[2]);
                fclose($pipes[2]);
                
                $return_value = proc_close($process);
                
                if ($return_value === 0) {
                    return [
                        'result' => 'sent',
                        'message' => "Email odeslán na: $email_to"
                    ];
                } else {
                    return [
                        'result' => 'failed',
                        'message' => "Sendmail selhal (kod: $return_value)"
                    ];
                }
            } else {
                return [
                    'result' => 'failed',
                    'message' => 'Nepodařilo se spustit sendmail'
                ];
            }
            
        } catch (\Exception $e) {
            return [
                'result' => 'failed',
                'message' => 'Chyba: ' . $e->getMessage()
            ];
        }
    }
}