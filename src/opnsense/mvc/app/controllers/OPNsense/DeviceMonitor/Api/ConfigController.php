<?php

// Předpony: arr = pole, i = celé číslo, o = objekt, s = řetězec, x = proměnlivý typ.
// Historie: 2.4.16 – kontrola typů, rozsahů a SMTP adresy.
// 2.4.14 – maskování tajných údajů, URL a metody testů.
// 2.4.12 – volitelný režim bez maximálního čekání.
// 2.4.11 – kontrola časů dávkování e-mailů.
// 2.3.7 – sjednocení typových předpon proměnných.

/*
 * Předpony: arr = pole, i = celé číslo, o = objekt, s = řetězec.
 * Historie: 2.4.1 – při uložení bez volby transportu zachová aktuální metodu.
 * 2.3.1 – lokalizace validace nastavení (#5) a sjednocení názvů proměnných.
 * 2.3.3 – uložený formát webhooku a test podle formuláře (#8).
 * 2.3.6 – uložení volby pasivních statistik PF.
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
        $arrConfig = DeviceMonitor::getConfig();
        $this->response->setHeader('Cache-Control', 'no-store');
        $arrConfig['smtp_password_set'] = (string)($arrConfig['smtp_password'] ?? '') !== '';
        $arrConfig['webhook_url_set'] = (string)($arrConfig['webhook_url'] ?? '') !== '';
        unset($arrConfig['smtp_password'], $arrConfig['webhook_url'], $arrConfig['paths']);
        return $arrConfig;
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

        $this->throwReadOnly();
        $oModel = new DeviceMonitor();
        $arrConfig = $oModel->getConfig();

        // Prázdná pole jsou přípustná jen tam, kde je dovolují příslušné kontroly.
        foreach (array_keys($arrConfig) as $sField) {
            if ($sField === 'paths') {
                continue;
            }
            $xValue = $this->request->getPost($sField);
            if ($xValue !== null && ((!is_string($xValue) && !is_int($xValue))
                || (is_string($xValue) && (strlen($xValue) > 4096 || preg_match('/[\x00-\x1f\x7f]/', $xValue))))) {
                return ['result' => 'failed', 'message' => $this->translateMessage('Invalid configuration field type')];
            }
        }
        foreach (['enabled', 'email_enabled', 'webhook_enabled', 'firewall_traffic_enabled'] as $sField) {
            $xValue = $this->request->getPost($sField);
            if ($xValue !== null && !in_array((string)$xValue, ['0', '1'], true)) {
                return ['result' => 'failed', 'message' => $this->translateMessage('Invalid configuration switch value')];
            }
        }

        $sEnabled = (string)$this->request->getPost('enabled', 'string', '0');
        $sEmailEnabled = (string)$this->request->getPost('email_enabled', 'string', '0');
        $sEmailTo = trim($this->request->getPost('email_to', 'string', ''));
        $sEmailFrom = trim($this->request->getPost('email_from', 'string', 'devicemonitor@opnsense.local'));
        $sEmailMethod = strtolower(trim($this->request->getPost('email_method', 'string', $arrConfig['email_method'])));
        $sEmailBatchMode = $this->request->getPost('email_batch_mode', 'string', $arrConfig['email_batch_mode']);
        if (!in_array($sEmailBatchMode, ['quiet', 'bounded'], true)) {
            return ['result' => 'failed', 'message' => $this->translateMessage('Invalid email batching mode')];
        }
        $iEmailBatchWait = filter_var(
            $this->request->getPost('email_batch_wait', 'string', (string)$arrConfig['email_batch_wait']),
            FILTER_VALIDATE_INT,
            ['options' => ['min_range' => 0, 'max_range' => 3600]]
        );
        $iEmailBatchMax = filter_var(
            $this->request->getPost('email_batch_max', 'string', (string)$arrConfig['email_batch_max']),
            FILTER_VALIDATE_INT,
            ['options' => ['min_range' => 1, 'max_range' => 3600]]
        );
        if ($iEmailBatchWait === false || $iEmailBatchMax === false
            || ($sEmailBatchMode === 'bounded' && $iEmailBatchWait > $iEmailBatchMax)) {
            return ['result' => 'failed', 'message' => $this->translateMessage(
                'Use whole seconds. Wait can be 0–3600 seconds. When enabled, the maximum must be 1–3600 seconds and at least as long as the wait.'
            )];
        }

        $sSmtpHost = trim($this->request->getPost('smtp_host', 'string', ''));
        $iSmtpPort = filter_var($this->request->getPost('smtp_port') ?? 587, FILTER_VALIDATE_INT);
        $sSmtpEncryption = strtolower(trim($this->request->getPost('smtp_encryption', 'string', 'starttls')));
        $sSmtpUsername = trim($this->request->getPost('smtp_username', 'string', ''));
        $sSmtpPassword = (string)($this->request->getPost('smtp_password') ?? ($arrConfig['smtp_password'] ?? ''));

        $sWebhookEnabled = (string)$this->request->getPost('webhook_enabled', 'string', '0');
        $sWebhookUrl = trim($this->request->getPost('webhook_url', 'string', $arrConfig['webhook_url'] ?? ''));
        $iScanInterval = filter_var($this->request->getPost('scan_interval') ?? 300, FILTER_VALIDATE_INT);
        $sEmailVlans = $this->request->getPost('email_vlans', 'string', '');
        $sWebhookVlans = $this->request->getPost('webhook_vlans', 'string', '');

        foreach ([$sEmailVlans, $sWebhookVlans] as $sVlanList) {
            if ($sVlanList !== '' && !preg_match('/^[a-zA-Z0-9_.:-]+(?:,[a-zA-Z0-9_.:-]+)*$/D', $sVlanList)) {
                return ['result' => 'failed', 'message' => $this->translateMessage('Invalid interface list')];
            }
        }

        if (!in_array($sEmailMethod, ['sendmail', 'smtp'], true)) {
            return ['result' => 'failed', 'message' => $this->translateMessage('Invalid email delivery method')];
        }

        if (!in_array($sSmtpEncryption, ['none', 'starttls', 'ssl'], true)) {
            return ['result' => 'failed', 'message' => $this->translateMessage('Invalid SMTP encryption type')];
        }

        if ($iSmtpPort === false || $iSmtpPort < 1 || $iSmtpPort > 65535) {
            return ['result' => 'failed', 'message' => $this->translateMessage('SMTP port must be between 1 and 65535')];
        }
        if ($sSmtpHost !== '' && !filter_var($sSmtpHost, FILTER_VALIDATE_IP)
            && !filter_var($sSmtpHost, FILTER_VALIDATE_DOMAIN, FILTER_FLAG_HOSTNAME)) {
            return ['result' => 'failed', 'message' => $this->translateMessage('SMTP server must be a hostname or IP address')];
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
            }
        }

        if ($sWebhookEnabled == '1') {
            if (empty($sWebhookUrl)) {
                return ['result' => 'failed', 'message' => $this->translateMessage('Webhook URL is required')];
            }
        }

        if ($sWebhookUrl !== '' && ($sWebhookEnabled === '1' || $sWebhookUrl !== ($arrConfig['webhook_url'] ?? ''))
            && !\NotificationHandler::isValidWebhookUrl($sWebhookUrl)) {
            return ['result' => 'failed', 'message' => $this->translateMessage('Webhook URL must use HTTP or HTTPS')];
        }

        if ($iScanInterval < 60 || $iScanInterval > 3600) {
            return ['result' => 'failed', 'message' => $this->translateMessage('Scan interval must be between 60 and 3600 seconds')];
        }

        $arrConfig['enabled'] = $sEnabled;
        $arrConfig['email_enabled'] = $sEmailEnabled;
        $arrConfig['email_to'] = $sEmailTo;
        $arrConfig['email_from'] = $sEmailFrom;
        $arrConfig['email_method'] = $sEmailMethod;
        $arrConfig['email_batch_mode'] = $sEmailBatchMode;
        $arrConfig['email_batch_wait'] = $iEmailBatchWait;
        $arrConfig['email_batch_max'] = $iEmailBatchMax;
        $arrConfig['smtp_host'] = $sSmtpHost;
        $arrConfig['smtp_port'] = $iSmtpPort;
        $arrConfig['smtp_encryption'] = $sSmtpEncryption;
        $arrConfig['smtp_username'] = $sSmtpUsername;
        $arrConfig['smtp_password'] = $sSmtpPassword;
        $sWebhookType = $this->request->getPost('webhook_type', 'string', $arrConfig['webhook_type'] ?? 'auto');
        if (!in_array($sWebhookType, \NotificationHandler::WEBHOOK_TYPES, true)) {
            return ['result' => 'failed', 'message' => $this->translateMessage('Invalid webhook type')];
        }
        $arrConfig['webhook_type'] = $sWebhookType;
        $arrConfig['webhook_enabled'] = $sWebhookEnabled;
        $arrConfig['webhook_url'] = $sWebhookUrl;
        $arrConfig['scan_interval'] = $iScanInterval;
        $sFirewallTrafficEnabled = (string)$this->request->getPost(
            'firewall_traffic_enabled',
            'string',
            $arrConfig['firewall_traffic_enabled'] ?? '0'
        );
        $arrConfig['firewall_traffic_enabled'] = $sFirewallTrafficEnabled === '1' ? '1' : '0';
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
        if (!$this->request->isPost()) {
            return ['result' => 'failed', 'message' => $this->translateMessage('A POST request is required')];
        }
        $this->throwReadOnly();
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

    /** Načte URL a formát z POST, odešle zkušební webhook a vrátí výsledek. */
    public function testWebhookAction()
    {
        if (!$this->request->isPost()) {
            return ['result' => 'failed', 'message' => $this->translateMessage('A POST request is required')];
        }
        $this->throwReadOnly();
        $oHandler = new \NotificationHandler();
        $oHandler->fLog("Preparing to send test webhook", 'WEBHOOK');
        $sWebhookType = $this->request->getPost('webhook_type', 'string', 'auto');
        if (!in_array($sWebhookType, \NotificationHandler::WEBHOOK_TYPES, true)) {
            return ['result' => 'failed', 'message' => $this->translateMessage('Invalid webhook type')];
        }
        $arrConfig = DeviceMonitor::getConfig();
        $xWebhookUrl = $this->request->getPost('webhook_url') ?? '';
        if (!is_string($xWebhookUrl) || strlen($xWebhookUrl) > 4096) {
            return ['result' => 'failed', 'message' => $this->translateMessage('Invalid configuration field type')];
        }
        $sWebhookUrl = trim($xWebhookUrl);
        if ($sWebhookUrl === '') {
            $sWebhookUrl = $arrConfig['webhook_url'] ?? '';
        }
        $arrResult = $oHandler->sendWebhook(true, $sWebhookUrl, $sWebhookType);

        $sLogMessage = "Test webhook result: " . (($arrResult['result'] === 'sent' || $arrResult['result'] === 'ok') ? "SUCCESS" : "FAILED");
        if ($arrResult['result'] !== 'sent' && $arrResult['result'] !== 'ok') {
            $sLogMessage .= " | Reason: " . ($arrResult['message'] ?? 'Unknown error');
        }
        $oHandler->fLog($sLogMessage, "WEBHOOK-ConfigController");
        return $arrResult;
    }
}
