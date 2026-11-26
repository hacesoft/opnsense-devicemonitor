<?php

// Předpony: arr = pole, b = příznak, i = celé číslo, o = objekt, r = zdroj, s = řetězec.
// Historie: 2.4.16 – délkový limit adresy webhooku.
// 2.4.15 – omezené dávky pro oba kanály.
// 2.4.14 – omezení webhooků na HTTP(S) a ověřování TLS.
// 2.4.1 – výchozí transport pro novou instalaci je Direct SMTP.
// 2.3.7 – sjednocení typových předpon proměnných.
/**
 * Shared notification handler
 * Historie: 2.4.11 – e-mail přijímá konkrétní dávku z fronty.
 * Předpony v sendWebhook: arr = pole, b = příznak, i = číslo, o = objekt, s = řetězec.
 * Historie: 2.3.3 – volitelný formát webhooku nezávislý na doméně (#8).
 * Path: /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/NotificationHandler.php
 */

// Načtení třídy DeviceMonitor
require_once('/usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/DeviceMonitor.php');

class NotificationHandler
{
    public const WEBHOOK_TYPES = ['auto', 'ntfy', 'discord', 'generic'];

    private const I_MAX_BATCH_BYTES = 4 * 1024 * 1024;
    private const I_MAX_BATCH_ROWS = 100;
    private $sLogFile = '/var/log/devicemonitor.log';
    
    public function fLog($sLogMessage, $sContext = 'NOTIFICATION') {
        $sTimestamp = date('Y-m-d H:i:s');
        file_put_contents($this->sLogFile, "[{$sTimestamp}] [PHP-{$sContext}] {$sLogMessage}\n", FILE_APPEND);
    }

    
    /** Načte omezenou dávku prostřednictvím stdin. Při neplatném vstupu vrátí null. */
    public static function readNotificationBatch(): ?array
    {
        $sJson = stream_get_contents(STDIN, self::I_MAX_BATCH_BYTES + 1);
        if ($sJson === false || strlen($sJson) > self::I_MAX_BATCH_BYTES) {
            return null;
        }
        $arrDevices = json_decode($sJson, true);
        if (!is_array($arrDevices) || !array_is_list($arrDevices) || !$arrDevices
            || count($arrDevices) > self::I_MAX_BATCH_ROWS) {
            return null;
        }
        foreach ($arrDevices as $arrDevice) {
            if (!is_array($arrDevice) || !is_string($arrDevice['mac'] ?? null)) {
                return null;
            }
        }
        return $arrDevices;
    }

    /**
     * Načte zařízení z databáze s notification_pending = 1
     */
    private function loadDevicesFromDb()
    {
        $sDatabasePath = \OPNsense\DeviceMonitor\DeviceMonitor::getPath('dbFile');
        
        if (!file_exists($sDatabasePath)) {
            return null;
        }
        
        try {
            $oDatabase = new \SQLite3($sDatabasePath, SQLITE3_OPEN_READONLY);
            $oQueryResult = $oDatabase->query("SELECT * FROM devices WHERE notification_pending = 1 ORDER BY first_seen DESC LIMIT " . self::I_MAX_BATCH_ROWS);
            
            $arrEmailDevices = [];
            while ($arrRow = $oQueryResult->fetchArray(SQLITE3_ASSOC)) {
                $arrEmailDevices[] = $arrRow;
            }
            
            $oDatabase->close();
            return $arrEmailDevices;
            
        } catch (\Exception $oEmailException) {
            return null;
        }
    }


    

    /**
     * Odešle zprávu přes interní Direct SMTP helper (Python stdlib smtplib).
     * SMTP heslo není předáváno v command line; helper si načte config.json.
     */
    private function sendViaDirectSmtp($sSubject, $sHtml)
    {
        $sHelperPath = '/usr/local/opnsense/scripts/OPNsense/DeviceMonitor/smtp_send.py';
        if (!file_exists($sHelperPath)) {
            return ['result' => 'failed', 'message' => 'Direct SMTP helper not found'];
        }

        $sPlain = html_entity_decode(strip_tags(
            str_replace(['<br>', '<br/>', '<br />', '</p>', '</tr>'], ["\n", "\n", "\n", "\n", "\n"], $sHtml)
        ), ENT_QUOTES | ENT_HTML5, 'UTF-8');
        $sPlain = preg_replace('/[ \t]+/', ' ', $sPlain);
        $sPlain = preg_replace('/\n{3,}/', "\n\n", $sPlain);
        $sPlain = trim($sPlain);

        $sPayload = json_encode([
            'subject' => $sSubject,
            'html' => $sHtml,
            'text' => $sPlain,
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

        if ($sPayload === false) {
            return ['result' => 'failed', 'message' => 'Cannot encode email payload'];
        }

        $rProcess = proc_open('/usr/local/bin/python3 ' . escapeshellarg($sHelperPath), [
            0 => ['pipe', 'r'],
            1 => ['pipe', 'w'],
            2 => ['pipe', 'w'],
        ], $arrPipes);

        if (!is_resource($rProcess)) {
            return ['result' => 'failed', 'message' => 'Cannot start Direct SMTP helper'];
        }

        fwrite($arrPipes[0], $sPayload);
        fclose($arrPipes[0]);
        $sStdout = stream_get_contents($arrPipes[1]);
        $sStderr = stream_get_contents($arrPipes[2]);
        fclose($arrPipes[1]);
        fclose($arrPipes[2]);
        $iExitCode = proc_close($rProcess);

        $arrResponse = json_decode(trim($sStdout), true);
        if ($iExitCode === 0 && is_array($arrResponse) && ($arrResponse['result'] ?? '') === 'sent') {
            return $arrResponse;
        }

        $sDetail = is_array($arrResponse) ? ($arrResponse['message'] ?? '') : '';
        if ($sDetail === '') {
            $sDetail = trim($sStderr) !== '' ? trim($sStderr) : (trim($sStdout) !== '' ? trim($sStdout) : "Exit code: {$iExitCode}");
        }
        return ['result' => 'failed', 'message' => 'Direct SMTP error: ' . $sDetail];
    }

    /**
     * Původní transport přes lokální /usr/local/sbin/sendmail (typicky os-postfix).
     */
    private function sendViaSendmail($sEmailTo, $sEmailFrom, $sSubject, $sHtml)
    {
        $sSendmailPath = '/usr/local/sbin/sendmail';
        if (!is_executable($sSendmailPath)) {
            return [
                'result' => 'failed',
                'message' => 'Sendmail is not available. Install/configure a local mailer or select Direct SMTP.'
            ];
        }

        $sLogMessage = "From: $sEmailFrom\r\n";
        $sLogMessage .= "To: $sEmailTo\r\n";
        $sLogMessage .= "Subject: $sSubject\r\n";
        $sLogMessage .= "MIME-Version: 1.0\r\n";
        $sLogMessage .= "Content-Type: text/html; charset=UTF-8\r\n";
        $sLogMessage .= "\r\n$sHtml";

        $rProcess = proc_open($sSendmailPath . ' -t -i', [
            0 => ['pipe', 'r'],
            1 => ['pipe', 'w'],
            2 => ['pipe', 'w'],
        ], $arrPipes);

        if (!is_resource($rProcess)) {
            return ['result' => 'failed', 'message' => 'Cannot start sendmail'];
        }

        fwrite($arrPipes[0], $sLogMessage);
        fclose($arrPipes[0]);
        $sStdout = stream_get_contents($arrPipes[1]);
        $sStderr = stream_get_contents($arrPipes[2]);
        fclose($arrPipes[1]);
        fclose($arrPipes[2]);
        $iExitCode = proc_close($rProcess);

        if ($iExitCode === 0) {
            return ['result' => 'sent', 'message' => 'Email sent', 'transport' => 'sendmail'];
        }

        $sDetail = trim($sStderr) !== '' ? trim($sStderr) : (trim($sStdout) !== '' ? trim($sStdout) : "Exit code: {$iExitCode}");
        return ['result' => 'failed', 'message' => 'Sendmail error: ' . $sDetail, 'exit_code' => $iExitCode];
    }

    /**
     * UNIVERZÁLNÍ EMAIL - test i real - S INLINE STYLES!
     */
    public function sendEmail($bEmailTest = false, ?array $arrQueuedDevices = null)
    {
        //$this->fLog("=== sendEmail START === Mode: " . ($is_test ? 'TEST' : 'REAL'), 'EMAIL');
        
        $oModel = new \OPNsense\DeviceMonitor\DeviceMonitor();
        $arrEmailConfig = $oModel->getConfig();
        
        // Check enabled
        if ($arrEmailConfig['email_enabled'] != '1' || empty($arrEmailConfig['email_to'])) {
            $this->fLog("Email disabled in config", 'EMAIL');
            return ['result' => 'skipped', 'message' => 'Email disabled'];
        }
        
        $sEmailTo = $arrEmailConfig['email_to'];
        $sEmailFrom = $arrEmailConfig['email_from'] ?? 'devicemonitor@opnsense.local';
        
        if ($bEmailTest) {
            // === TEST MODE ===
            $sSubject = 'Test - OPNsense Device Monitor';
            $sRouterHostname = gethostname();
            $sTimestamp = date('Y-m-d H:i:s');
            
            $sHtml = <<<HTML
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; background-color: #f5f7fa; margin: 0; padding: 20px;">
    <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
        <div style="background: linear-gradient(135deg, #f6821f 0%, #e65100 100%); color: white; padding: 30px; text-align: center;">
            <div style="font-size: 48px; margin-bottom: 10px;">🧪</div>
            <h1 style="margin: 0; font-size: 24px;">Test Email</h1>
        </div>
        <div style="padding: 20px;">
            <p style="font-size: 16px; color: #2d3748;">If you see this, <strong>email works correctly!</strong></p>
            <table style="width: 100%; margin: 20px 0;">
                <tr>
                    <td style="padding: 8px 0; color: #6c757d; font-weight: 600;">Server:</td>
                    <td style="padding: 8px 0; font-family: monospace; color: #2d3748;">$sRouterHostname</td>
                </tr>
                <tr>
                    <td style="padding: 8px 0; color: #6c757d; font-weight: 600;">Time:</td>
                    <td style="padding: 8px 0; font-family: monospace; color: #2d3748;">$sTimestamp</td>
                </tr>
                <tr>
                    <td style="padding: 8px 0; color: #6c757d; font-weight: 600;">To:</td>
                    <td style="padding: 8px 0; font-family: monospace; color: #2d3748;">$sEmailTo</td>
                </tr>
            </table>
        </div>
    </div>
</body>
</html>
HTML;
            
        } else {
            // === REAL MODE - načti z DB ===
            $arrEmailDevices = $arrQueuedDevices ?? $this->loadDevicesFromDb();
            
            if ($arrEmailDevices === null) {
                $this->fLog("FAILED: Cannot load devices from database", 'EMAIL');
                return ['result' => 'failed', 'message' => 'Cannot load devices'];
            }
            
            if (empty($arrEmailDevices)) {
                $this->fLog("SKIPPED: No pending notifications", 'EMAIL');
                return ['result' => 'skipped', 'message' => 'No pending notifications'];
            }
            
            $iDeviceCount = count($arrEmailDevices);
            $sSubject = "OPNsense: {$iDeviceCount} new device(s) detected";
            $sRouterHostname = gethostname();
            $sTimestamp = date('Y-m-d H:i:s');
            
            $this->fLog("Preparing email for {$iDeviceCount} devices", 'EMAIL');
            
            // === INLINE STYLES EMAIL ===
            $sHtml = <<<HTML
<!DOCTYPE html>
<html>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; background-color: #f5f7fa; margin: 0; padding: 20px; color: #2d3748;">
    <div style="max-width: 800px; margin: 0 auto; background: white; border-radius: 12px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); overflow: hidden;">
        
        <!-- Header -->
        <div style="background: linear-gradient(135deg, #f6821f 0%, #e65100 100%); color: white; padding: 30px; text-align: center;">
            <div style="font-size: 48px; margin-bottom: 10px;">🔔</div>
            <h1 style="margin: 0; font-size: 28px; font-weight: 600;">Device Monitor Alert</h1>
        </div>
        
        <!-- Summary -->
        <div style="background: #fff3e0; border-left: 4px solid #f6821f; padding: 20px; margin: 20px; border-radius: 8px;">
            <strong style="color: #e65100; font-size: 20px;">{$iDeviceCount} new device(s)</strong> detected and require your attention
        </div>
        
        <!-- Content -->
        <div style="padding: 20px;">
            <!-- Info Boxes -->
            <div style="background: #f8f9fa; border-radius: 8px; padding: 15px; margin-bottom: 15px;">
                <span style="font-weight: 600; color: #6c757d;">📡 Server:</span>
                <span style="font-family: 'Courier New', monospace; background: white; padding: 5px 12px; border-radius: 4px; border: 1px solid #dee2e6; margin-left: 10px;">{$sRouterHostname}</span>
            </div>
            <div style="background: #f8f9fa; border-radius: 8px; padding: 15px; margin-bottom: 20px;">
                <span style="font-weight: 600; color: #6c757d;">⏰ Detection Time:</span>
                <span style="font-family: 'Courier New', monospace; background: white; padding: 5px 12px; border-radius: 4px; border: 1px solid #dee2e6; margin-left: 10px;">{$sTimestamp}</span>
            </div>
            
            <h3 style="margin-top: 30px; color: #2c3e50;">🖥️ Detected Devices</h3>
            
            <!-- Table -->
            <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
                <thead>
                    <tr>
                        <th style="background: #2c3e50; color: white; padding: 12px; text-align: left; font-weight: 600; font-size: 12px; text-transform: uppercase;">MAC</th>
                        <th style="background: #2c3e50; color: white; padding: 12px; text-align: left; font-weight: 600; font-size: 12px; text-transform: uppercase;">Vendor</th>
                        <th style="background: #2c3e50; color: white; padding: 12px; text-align: left; font-weight: 600; font-size: 12px; text-transform: uppercase;">IP</th>
                        <th style="background: #2c3e50; color: white; padding: 12px; text-align: left; font-weight: 600; font-size: 12px; text-transform: uppercase;">Hostname</th>
                        <th style="background: #2c3e50; color: white; padding: 12px; text-align: left; font-weight: 600; font-size: 12px; text-transform: uppercase;">VLAN</th>
                        <th style="background: #2c3e50; color: white; padding: 12px; text-align: left; font-weight: 600; font-size: 12px; text-transform: uppercase;">First Seen</th>
                    </tr>
                </thead>
                <tbody>
HTML;
            
            foreach ($arrEmailDevices as $arrNotificationDevice) {
                $sMac = htmlspecialchars($arrNotificationDevice['mac']);
                $sVendor = htmlspecialchars($arrNotificationDevice['vendor'] ?? 'Unknown');
                $sIp = htmlspecialchars($arrNotificationDevice['ip'] ?? 'No IP');
                $sDeviceHostname = htmlspecialchars($arrNotificationDevice['hostname'] ?? 'Unknown');
                $sVlan = htmlspecialchars($arrNotificationDevice['vlan'] ?? '-');
                $sFirstSeen = htmlspecialchars($arrNotificationDevice['first_seen'] ?? '');
                
                $sHtml .= <<<ROW
                    <tr>
                        <td style="padding: 12px; border-bottom: 1px solid #e9ecef;">
                            <span style="font-family: 'Courier New', monospace; background: #e3f2fd; padding: 4px 8px; border-radius: 4px; color: #1976d2; font-weight: 600;">{$sMac}</span>
                        </td>
                        <td style="padding: 12px; border-bottom: 1px solid #e9ecef; color: #2d3748; font-weight: 500;">{$sVendor}</td>
                        <td style="padding: 12px; border-bottom: 1px solid #e9ecef; font-family: 'Courier New', monospace; color: #6c757d;">{$sIp}</td>
                        <td style="padding: 12px; border-bottom: 1px solid #e9ecef;">{$sDeviceHostname}</td>
                        <td style="padding: 12px; border-bottom: 1px solid #e9ecef;">
                            <span style="background: #e8f5e9; color: #2e7d32; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: 600;">{$sVlan}</span>
                        </td>
                        <td style="padding: 12px; border-bottom: 1px solid #e9ecef; font-size: 13px;">{$sFirstSeen}</td>
                    </tr>
ROW;
            }
            
            $sHtml .= <<<HTML
                </tbody>
            </table>
        </div>
        
        <!-- Footer -->
        <div style="background: #f8f9fa; padding: 20px; text-align: center; color: #6c757d; font-size: 12px; border-top: 1px solid #e9ecef;">
            <div>🛡️ <strong>OPNsense Device Monitor</strong></div>
            <div style="font-family: 'Courier New', monospace; color: #495057; margin-top: 5px;">Generated: {$sTimestamp}</div>
        </div>
    </div>
</body>
</html>
HTML;
        }
        
        // Odešli email zvoleným transportem.
        $sEmailMethod = strtolower($arrEmailConfig['email_method'] ?? 'smtp');
        try {
            if ($sEmailMethod === 'smtp') {
                $arrSendResult = $this->sendViaDirectSmtp($sSubject, $sHtml);
            } else {
                $arrSendResult = $this->sendViaSendmail($sEmailTo, $sEmailFrom, $sSubject, $sHtml);
                $sEmailMethod = 'sendmail';
            }

            if (($arrSendResult['result'] ?? '') === 'sent') {
                $sMode = $bEmailTest ? 'TEST' : 'REAL';
                $iLoggedCount = $bEmailTest ? 0 : count($arrEmailDevices ?? []);
                $this->fLog("SUCCESS: Email sent ({$sMode}, transport={$sEmailMethod}, {$iLoggedCount} devices)", 'EMAIL');
                return [
                    'result' => 'sent',
                    'message' => "Email sent to: $sEmailTo",
                    'transport' => $sEmailMethod,
                    'test' => $bEmailTest,
                    'count' => $iLoggedCount,
                ];
            }

            $sErrorDetail = $arrSendResult['message'] ?? 'Unknown email transport error';
            $this->fLog("FAILED: {$sEmailMethod} - {$sErrorDetail}", 'EMAIL');
            return [
                'result' => 'failed',
                'message' => $sErrorDetail,
                'transport' => $sEmailMethod,
            ];
        } catch (\Exception $oEmailException) {
            $this->fLog("FAILED: Exception - " . $oEmailException->getMessage(), 'EMAIL');
            return ['result' => 'failed', 'message' => $oEmailException->getMessage(), 'transport' => $sEmailMethod];
        }
    }

    /**
     * Odešle testovací nebo provozní webhook.
     * Vstup: testovací režim a volitelně URL a formát; jinak použije uložené nastavení.
     * Výstup: pole s výsledkem odeslání, případně s důvodem chyby.
     */
    /** Vstup: cíl webhooku. Výstup: zda je to platná adresa HTTP nebo HTTPS. */
    public static function isValidWebhookUrl(string $sUrl): bool
    {
        return strlen($sUrl) <= 4096 && filter_var($sUrl, FILTER_VALIDATE_URL) !== false
            && in_array(strtolower((string)parse_url($sUrl, PHP_URL_SCHEME)), ['http', 'https'], true);
    }

    public function sendWebhook($bIsTest = false, $sWebhookUrl = null, $sType = null, ?array $arrQueuedDevices = null)
    {
        if ($sWebhookUrl === null) {
            $arrConfig = \OPNsense\DeviceMonitor\DeviceMonitor::getConfig();
            if ($arrConfig['webhook_enabled'] != '1' || empty($arrConfig['webhook_url'])) {
                return ['result' => 'skipped', 'message' => 'Webhook disabled'];
            }
            $sWebhookUrl = $arrConfig['webhook_url'];
            $sType = $sType ?? ($arrConfig['webhook_type'] ?? 'auto');
        }

        if (!self::isValidWebhookUrl($sWebhookUrl)) {
            return ['result' => 'failed', 'message' => 'Webhook URL must use HTTP or HTTPS'];
        }

        $sType = $sType ?? 'auto';
        if (!in_array($sType, self::WEBHOOK_TYPES, true)) {
            return ['result' => 'failed', 'message' => 'Invalid webhook type'];
        }

        // Automatická volba zachovává chování stávajících instalací.
        if ($sType === 'auto') {
            if (stripos($sWebhookUrl, 'ntfy') !== false) {
                $sType = 'ntfy';
            } elseif (stripos($sWebhookUrl, 'discord') !== false) {
                $sType = 'discord';
            } else {
                $sType = 'generic';
            }
        }

        try {
            if ($bIsTest) {
                // === TEST MODE ===

                if ($sType === 'ntfy') {
                    // Testovací zpráva ntfy
                    $sBody = 'Device Monitor webhook is working! ✅';
                    $arrHeaders = [
                        'Content-Type: text/plain; charset=UTF-8',
                        'Title: 🧪 OPNsense Test',
                        'Tags: test,opnsense',
                        'Priority: 3'
                    ];

                } elseif ($sType === 'discord') {
                    // DISCORD TEST
                    $arrPayload = [
                        'username' => 'OPNsense Device Monitor',
                        'embeds' => [[
                            'title' => '🧪 Test Notification',
                            'description' => 'Device Monitor webhook is working! ✅',
                            'color' => 3447003,
                            'fields' => [[
                                'name' => 'Hostname',
                                'value' => gethostname(),
                                'inline' => true
                            ], [
                                'name' => 'Timestamp',
                                'value' => date('Y-m-d H:i:s'),
                                'inline' => true
                            ]],
                            'footer' => ['text' => 'OPNsense Device Monitor']
                        ]]
                    ];

                    $sBody = json_encode($arrPayload);
                    $arrHeaders = ['Content-Type: application/json'];

                } else {
                    // GENERIC TEST
                    $arrPayload = [
                        'event' => 'test',
                        'title' => '🧪 OPNsense Device Monitor - Test',
                        'message' => 'This is a test notification!',
                        'timestamp' => date('Y-m-d H:i:s'),
                        'hostname' => gethostname(),
                        'test' => true
                    ];

                    $sBody = json_encode($arrPayload);
                    $arrHeaders = ['Content-Type: application/json'];
                }

            } else {
                // === REAL MODE - načti z DB ===
                $arrDevices = $arrQueuedDevices ?? $this->loadDevicesFromDb();

                if ($arrDevices === null) {
                    return ['result' => 'failed', 'message' => 'Cannot load devices'];
                }

                if (empty($arrDevices)) {
                    return ['result' => 'skipped', 'message' => 'No pending notifications'];
                }

                $iCount = count($arrDevices);
                $sHostname = gethostname();

                if ($sType === 'ntfy') {
                    // Provozní zpráva ntfy
                    $sMessage = "{$iCount} new device(s) detected:\n\n";
                    foreach (array_slice($arrDevices, 0, 5) as $arrDevice) {
                        $sMessage .= "• {$arrDevice['mac']} - {$arrDevice['vendor']} ({$arrDevice['ip']})\n";
                    }
                    if ($iCount > 5) {
                        $sMessage .= "\n... and " . ($iCount - 5) . " more";
                    }

                    $sBody = $sMessage;
                    $arrHeaders = [
                        'Content-Type: text/plain; charset=UTF-8',
                        "Title: 🔔 OPNsense: {$iCount} new device(s)",
                        'Tags: opnsense,network',
                        'Priority: ' . (($iCount > 3) ? '4' : '3')
                    ];

                } elseif ($sType === 'discord') {
                    // DISCORD REAL
                    $arrFields = [];
                    foreach (array_slice($arrDevices, 0, 10) as $arrDevice) {
                        $arrFields[] = [
                            'name' => $arrDevice['mac'],
                            'value' => "**{$arrDevice['vendor']}**\nIP: `{$arrDevice['ip']}`\nVLAN: `{$arrDevice['vlan']}`",
                            'inline' => true
                        ];
                    }

                    $arrPayload = [
                        'username' => 'OPNsense Device Monitor',
                        'embeds' => [[
                            'title' => "🔔 {$iCount} New Device(s) Detected",
                            'description' => "Server: `$sHostname`",
                            'color' => 3447003,
                            'fields' => $arrFields,
                            'footer' => ['text' => 'OPNsense • ' . date('Y-m-d H:i:s')]
                        ]]
                    ];

                    $sBody = json_encode($arrPayload);
                    $arrHeaders = ['Content-Type: application/json'];

                } else {
                    // GENERIC REAL
                    $arrPayload = [
                        'event' => 'new_devices',
                        'hostname' => $sHostname,
                        'timestamp' => date('Y-m-d H:i:s'),
                        'device_count' => $iCount,
                        'devices' => $arrDevices
                    ];

                    $sBody = json_encode($arrPayload);
                    $arrHeaders = ['Content-Type: application/json'];
                }
            }

            // Použij stejný HTTP transport pro všechny formáty webhooku.
            $oCurl = curl_init($sWebhookUrl);
            curl_setopt($oCurl, CURLOPT_POST, 1);
            curl_setopt($oCurl, CURLOPT_POSTFIELDS, $sBody);
            curl_setopt($oCurl, CURLOPT_HTTPHEADER, $arrHeaders);
            if (defined('CURLOPT_PROTOCOLS_STR')) {
                curl_setopt($oCurl, CURLOPT_PROTOCOLS_STR, 'http,https');
            } else {
                curl_setopt($oCurl, CURLOPT_PROTOCOLS, CURLPROTO_HTTP | CURLPROTO_HTTPS);
            }
            curl_setopt($oCurl, CURLOPT_FOLLOWLOCATION, false);
            curl_setopt($oCurl, CURLOPT_WRITEFUNCTION, static fn ($oHandle, string $sChunk): int => strlen($sChunk));
            curl_setopt($oCurl, CURLOPT_TIMEOUT, 10);
            curl_setopt($oCurl, CURLOPT_SSL_VERIFYPEER, true);
            curl_setopt($oCurl, CURLOPT_SSL_VERIFYHOST, 2);
            $bSent = curl_exec($oCurl);
            $iCurlError = curl_errno($oCurl);
            $iHttpCode = curl_getinfo($oCurl, CURLINFO_HTTP_CODE);
            curl_close($oCurl);

            if ($bSent === false) {
                return ['result' => 'failed', 'message' => 'Webhook transport error: ' . curl_strerror($iCurlError)];
            }
            if ($iHttpCode >= 200 && $iHttpCode < 300) {
                return [
                    'result' => $bIsTest ? 'ok' : 'sent',
                    'message' => "Webhook sent (HTTP $iHttpCode)",
                    'type' => $sType,
                    'test' => $bIsTest,
                    'count' => $bIsTest ? 0 : count($arrDevices ?? [])
                ];
            } else {
                return ['result' => 'failed', 'message' => "HTTP $iHttpCode"];
            }

        } catch (\Exception $oException) {
            return ['result' => 'failed', 'message' => $oException->getMessage()];
        }
    }
}
