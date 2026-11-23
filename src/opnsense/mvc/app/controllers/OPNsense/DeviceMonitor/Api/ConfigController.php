<?php

/*
 * Předpony: arr = pole, i = celé číslo, o = objekt, s = řetězec.
 * Historie: 2.3.1 – lokalizace validace nastavení (#5) a sjednocení názvů proměnných.
 */

namespace OPNsense\DeviceMonitor\Api;

use OPNsense\Base\ApiControllerBase;
use OPNsense\DeviceMonitor\DeviceMonitor;

require_once('/usr/local/opnsense/scripts/OPNsense/DeviceMonitor/NotificationHandler.php');

/**
 * API controller pro správu konfigurace
 */
class ConfigController extends ApiControllerBase
{
    /** Bez vstupu vrátí aktuální nastavení pluginu. */
    public function getAction()
    {
        $oModel = new DeviceMonitor();
        return $oModel->getConfig();
    }

    /** Bez vstupu vrátí číslo verze z výchozí konfigurace. */
    public function getversionAction()
    {
        $sDefaultsFile = '/usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/defaults.json';
        $arrDefaults = json_decode(file_get_contents($sDefaultsFile), true);
        return ['version' => $arrDefaults['version'] ?? '2.0'];
    }

    /** Bez vstupu vrátí mapu názvů síťových rozhraní. */
    public function getinterfacesAction()
    {
        $arrResult = [];
        try {
            $oXml = @simplexml_load_file('/conf/config.xml');
            if ($oXml && isset($oXml->interfaces)) {
                foreach ($oXml->interfaces->children() as $sIfName => $oIfData) {
                    $sInterface = trim((string)($oIfData->if ?? ''));
                    $sDescription = trim((string)($oIfData->descr ?? ''));
                    if (empty($sInterface)) continue;
                    if (empty($sDescription)) $sDescription = strtoupper($sIfName);
                    if (preg_match('/vlan\d+\.(\d+)/i', $sInterface, $arrMatches)) {
                        $sKey = 'VLAN' . $arrMatches[1];
                    } else {
                        $sKey = strtoupper($sInterface);
                    }
                    $arrResult[$sKey] = $sDescription;
                }
            }
        } catch (\Exception $oException) {}
        return $arrResult;
    }

    /**
     * Vstup: anglický klíč zprávy. Výstup: překlad v jazyce aktuální relace nebo anglický klíč.
     */
    private function translateMessage(string $sMessage): string
    {
        bindtextdomain('devicemonitor', '/usr/local/share/locale');
        bind_textdomain_codeset('devicemonitor', 'UTF-8');
        return dgettext('devicemonitor', $sMessage);
    }

    /** Načte hodnoty z POST, ověří je a vrátí výsledek uložení konfigurace. */
    public function setAction()
    {
        if (!$this->request->isPost()) {
            return ['result' => 'failed', 'message' => $this->translateMessage('A POST request is required')];
        }

        $oModel = new DeviceMonitor();

        $sEnabled = $this->request->getPost('enabled', 'string', '0');
        $sEmailEnabled = $this->request->getPost('email_enabled', 'string', '0');
        $sEmailTo = trim($this->request->getPost('email_to', 'string', ''));
        $sEmailFrom = trim($this->request->getPost('email_from', 'string', 'devicemonitor@opnsense.local'));
        $sEmailMethod = strtolower(trim($this->request->getPost('email_method', 'string', 'sendmail')));
        $sSmtpHost = trim($this->request->getPost('smtp_host', 'string', ''));
        $iSmtpPort = (int)$this->request->getPost('smtp_port', 'int', 587);
        $sSmtpEncryption = strtolower(trim($this->request->getPost('smtp_encryption', 'string', 'starttls')));
        $sSmtpUsername = trim($this->request->getPost('smtp_username', 'string', ''));
        $sSmtpPassword = $this->request->getPost('smtp_password', 'string', '');

        $sWebhookEnabled = $this->request->getPost('webhook_enabled', 'string', '0');
        $sWebhookUrl = $this->request->getPost('webhook_url', 'string', '');
        $iScanInterval = (int)$this->request->getPost('scan_interval', 'int', 300);
        $sEmailVlans = $this->request->getPost('email_vlans', 'string', '');
        $sWebhookVlans = $this->request->getPost('webhook_vlans', 'string', '');

        if (!in_array($sEmailMethod, ['sendmail', 'smtp'], true)) {
            return ['result' => 'failed', 'message' => $this->translateMessage('Invalid email delivery method')];
        }

        if (!in_array($sSmtpEncryption, ['none', 'starttls', 'ssl'], true)) {
            return ['result' => 'failed', 'message' => $this->translateMessage('Invalid SMTP encryption type')];
        }

        if ($sEmailEnabled == '1') {
            if (empty($sEmailTo) || !filter_var($sEmailTo, FILTER_VALIDATE_EMAIL)) {
                return ['result' => 'failed', 'message' => $this->translateMessage('Invalid recipient email address')];
            }

            if (empty($sEmailFrom) || !filter_var($sEmailFrom, FILTER_VALIDATE_EMAIL)) {
                return ['result' => 'failed', 'message' => $this->translateMessage('Invalid sender email address')];
            }

            if ($sEmailMethod === 'smtp') {
                if ($sSmtpHost === '') {
                    return ['result' => 'failed', 'message' => $this->translateMessage('SMTP server is required')];
                }
                if ($iSmtpPort < 1 || $iSmtpPort > 65535) {
                    return ['result' => 'failed', 'message' => $this->translateMessage('SMTP port must be between 1 and 65535')];
                }
            }
        }

        if ($sWebhookEnabled == '1') {
            if (empty($sWebhookUrl)) {
                return ['result' => 'failed', 'message' => $this->translateMessage('Webhook URL is required')];
            }
            if (!filter_var($sWebhookUrl, FILTER_VALIDATE_URL)) {
                return ['result' => 'failed', 'message' => $this->translateMessage('Invalid webhook URL')];
            }
        }

        if ($iScanInterval < 60 || $iScanInterval > 3600) {
            return ['result' => 'failed', 'message' => $this->translateMessage('Scan interval must be between 60 and 3600 seconds')];
        }

        $arrConfig = $oModel->getConfig();
        $arrConfig['enabled'] = $sEnabled;
        $arrConfig['email_enabled'] = $sEmailEnabled;
        $arrConfig['email_to'] = $sEmailTo;
        $arrConfig['email_from'] = $sEmailFrom;
        $arrConfig['email_method'] = $sEmailMethod;
        $arrConfig['smtp_host'] = $sSmtpHost;
        $arrConfig['smtp_port'] = $iSmtpPort;
        $arrConfig['smtp_encryption'] = $sSmtpEncryption;
        $arrConfig['smtp_username'] = $sSmtpUsername;
        $arrConfig['smtp_password'] = $sSmtpPassword;
        $arrConfig['webhook_enabled'] = $sWebhookEnabled;
        $arrConfig['webhook_url'] = $sWebhookUrl;
        $arrConfig['scan_interval'] = $iScanInterval;
        $arrConfig['email_vlans'] = $sEmailVlans;
        $arrConfig['webhook_vlans'] = $sWebhookVlans;

        if ($oModel->setConfig($arrConfig)) {
            return ['result' => 'saved', 'message' => $this->translateMessage('Configuration saved')];
        }

        return ['result' => 'failed', 'message' => $this->translateMessage('Error saving configuration')];
    }

    /** Bez vstupu odešle zkušební e-mail a vrátí výsledek odeslání. */
    public function testemailAction()
    {
        $oHandler = new \NotificationHandler();
        $oHandler->fLog("Preparing to send test email", 'EMAIL');
        $arrResult = $oHandler->sendEmail(true);

        $sLogMessage = "Test email result: " . (($arrResult['result'] === 'sent' || $arrResult['result'] === 'ok') ? "SUCCESS" : "FAILED");
        if ($arrResult['result'] !== 'sent' && $arrResult['result'] !== 'ok') {
            $sLogMessage .= " | Reason: " . ($arrResult['message'] ?? 'Unknown error');
        }
        $oHandler->fLog($sLogMessage, "EMAIL-ConfigController");
        return $arrResult;
    }

    /** Načte volitelnou URL z POST, odešle zkušební webhook a vrátí výsledek. */
    public function testWebhookAction()
    {
        $oHandler = new \NotificationHandler();
        $oHandler->fLog("Preparing to send test webhook", 'WEBHOOK');
        $arrResult = $oHandler->sendWebhook(true, $this->request->getPost('webhook_url', 'string', ''));

        $sLogMessage = "Test webhook result: " . (($arrResult['result'] === 'sent' || $arrResult['result'] === 'ok') ? "SUCCESS" : "FAILED");
        if ($arrResult['result'] !== 'sent' && $arrResult['result'] !== 'ok') {
            $sLogMessage .= " | Reason: " . ($arrResult['message'] ?? 'Unknown error');
        }
        $oHandler->fLog($sLogMessage, "WEBHOOK-ConfigController");
        return $arrResult;
    }
}
