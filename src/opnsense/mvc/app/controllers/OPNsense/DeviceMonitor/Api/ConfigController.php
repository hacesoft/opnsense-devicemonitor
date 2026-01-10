<?php

namespace OPNsense\DeviceMonitor\Api;

use OPNsense\Base\ApiControllerBase;
use OPNsense\DeviceMonitor\DeviceMonitor;


// Include shared handler
require_once('/usr/local/opnsense/scripts/OPNsense/DeviceMonitor/NotificationHandler.php');

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
        $email_enabled = $this->request->getPost('email_enabled', 'string', '0');
        $email_to = $this->request->getPost('email_to', 'string', '');
        $email_from = $this->request->getPost('email_from', 'string', 'devicemonitor@opnsense.local');
        $webhook_enabled = $this->request->getPost('webhook_enabled', 'string', '0');
        $webhook_url = $this->request->getPost('webhook_url', 'string', '');
        $scan_interval = $this->request->getPost('scan_interval', 'int', 300);
        $show_domain = $this->request->getPost('show_domain', 'string', '0');
        
        // Validace emailů (jen pokud je email zapnutý)
        if ($email_enabled == '1') {
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

        // Validace webhook URL (jen pokud je webhook zapnutý)
        if ($webhook_enabled == '1') {
            if (empty($webhook_url)) {
                return [
                    'result' => 'failed',
                    'message' => 'Webhook URL nesmí být prázdné'
                ];
            }
            
            if (!filter_var($webhook_url, FILTER_VALIDATE_URL)) {
                return [
                    'result' => 'failed',
                    'message' => 'Neplatná webhook URL'
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
        $config['email_enabled'] = $email_enabled;
        $config['email_to'] = $email_to;
        $config['email_from'] = $email_from;
        $config['webhook_enabled'] = $webhook_enabled;
        $config['webhook_url'] = $webhook_url;
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
     * Test email (volá se z GUI)
     * POST /api/devicemonitor/config/testemail
     */
    public function testemailAction()
    {
        $handler = new \NotificationHandler();
        //              ↑
        //    Tento backslash říká: "Hledej v GLOBÁLNÍM namespace!"

        $handler->fLog("Preparing to send test email", 'EMAIL');

        $result = $handler->sendEmail(true);

        // Loguj výsledek
        $logMessage = "Test email result: " . ($result['result'] === 'sent' || $result['result'] === 'ok' ? "SUCCESS" : "FAILED");
        if ($result['result'] !== 'sent' && $result['result'] !== 'ok') {
            $logMessage .= " | Reason: " . ($result['message'] ?? 'Unknown error');
        }
        $handler->fLog($logMessage, "EMAIL-ConnfigController");

        return $result;
    }

    /**
     * Test webhook (volá se z GUI)
     * POST /api/devicemonitor/config/testWebhook
     */
    public function testWebhookAction()
    {
        $handler = new \NotificationHandler();
        //              ↑
        //    Tento backslash říká: "Hledej v GLOBÁLNÍM namespace!"

        $handler->fLog("Preparing to send test webhook", 'WEBHOOK');

         $result = $handler->sendWebhook(true, $this->request->getPost('webhook_url', 'string', ''));

        // Loguj výsledek
        $logMessage = "Test webhook result: " . ($result['result'] === 'sent' || $result['result'] === 'ok' ? "SUCCESS" : "FAILED");
        if ($result['result'] !== 'sent' && $result['result'] !== 'ok') {
            $logMessage .= " | Reason: " . ($result['message'] ?? 'Unknown error');
        }
        $handler->fLog($logMessage, "WEBHOOK-ConnfigController");

        return $result;
    }    
}
