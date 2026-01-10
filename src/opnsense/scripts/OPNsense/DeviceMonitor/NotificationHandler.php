<?php
/**
 * Shared notification handler
 * Path: /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/NotificationHandler.php
 */

// Načtení třídy DeviceMonitor
require_once('/usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/DeviceMonitor.php');

class NotificationHandler
{
    private $log_file = '/var/log/devicemonitor.log';
    
    public function fLog($message, $context = 'NOTIFICATION') {
        $timestamp = date('Y-m-d H:i:s');
        file_put_contents($this->log_file, "[{$timestamp}] [PHP-{$context}] {$message}\n", FILE_APPEND);
    }

    
    /**
     * Načte zařízení z databáze s notification_pending = 1
     */
    private function loadDevicesFromDb()
    {
        $db_file = '/var/db/devicemonitor/devices.db';
        
        if (!file_exists($db_file)) {
            return null;
        }
        
        try {
            $db = new \SQLite3($db_file, SQLITE3_OPEN_READONLY);
            $result = $db->query("SELECT * FROM devices WHERE notification_pending = 1 ORDER BY first_seen DESC");
            
            $devices = [];
            while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
                $devices[] = $row;
            }
            
            $db->close();
            return $devices;
            
        } catch (\Exception $e) {
            return null;
        }
    }

    
    /**
     * Načte konfiguraci
     */
    private function loadConfig() {
        $config_file = '/var/db/devicemonitor/config.json';
        
        if (!file_exists($config_file)) {
            $this->fLog("Config not found", 'CONFIG');
            return null;
        }
        
        $config = json_decode(file_get_contents($config_file), true);
        $this->fLog("Config loaded", 'CONFIG');
        return $config;
    }
    
    /**
     * UNIVERZÁLNÍ EMAIL - test i real - S INLINE STYLES!
     */
    public function sendEmail($is_test = false)
    {
        //$this->fLog("=== sendEmail START === Mode: " . ($is_test ? 'TEST' : 'REAL'), 'EMAIL');
        
        $model = new \OPNsense\DeviceMonitor\DeviceMonitor();
        $config = $model->getConfig();
        
        // Check enabled
        if ($config['email_enabled'] != '1' || empty($config['email_to'])) {
            $this->fLog("Email disabled in config", 'EMAIL');
            return ['result' => 'skipped', 'message' => 'Email disabled'];
        }
        
        $email_to = $config['email_to'];
        $email_from = $config['email_from'] ?? 'devicemonitor@opnsense.local';
        
        if ($is_test) {
            // === TEST MODE ===
            $subject = 'Test - OPNsense Device Monitor';
            $hostname = gethostname();
            $timestamp = date('Y-m-d H:i:s');
            
            $html = <<<HTML
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
                    <td style="padding: 8px 0; font-family: monospace; color: #2d3748;">$hostname</td>
                </tr>
                <tr>
                    <td style="padding: 8px 0; color: #6c757d; font-weight: 600;">Time:</td>
                    <td style="padding: 8px 0; font-family: monospace; color: #2d3748;">$timestamp</td>
                </tr>
                <tr>
                    <td style="padding: 8px 0; color: #6c757d; font-weight: 600;">To:</td>
                    <td style="padding: 8px 0; font-family: monospace; color: #2d3748;">$email_to</td>
                </tr>
            </table>
        </div>
    </div>
</body>
</html>
HTML;
            
        } else {
            // === REAL MODE - načti z DB ===
            $devices = $this->loadDevicesFromDb();
            
            if ($devices === null) {
                $this->fLog("FAILED: Cannot load devices from database", 'EMAIL');
                return ['result' => 'failed', 'message' => 'Cannot load devices'];
            }
            
            if (empty($devices)) {
                $this->fLog("SKIPPED: No pending notifications", 'EMAIL');
                return ['result' => 'skipped', 'message' => 'No pending notifications'];
            }
            
            $count = count($devices);
            $subject = "OPNsense: {$count} new device(s) detected";
            $hostname = gethostname();
            $timestamp = date('Y-m-d H:i:s');
            
            $this->fLog("Preparing email for {$count} devices", 'EMAIL');
            
            // === INLINE STYLES EMAIL ===
            $html = <<<HTML
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
            <strong style="color: #e65100; font-size: 20px;">{$count} new device(s)</strong> detected and require your attention
        </div>
        
        <!-- Content -->
        <div style="padding: 20px;">
            <!-- Info Boxes -->
            <div style="background: #f8f9fa; border-radius: 8px; padding: 15px; margin-bottom: 15px;">
                <span style="font-weight: 600; color: #6c757d;">📡 Server:</span>
                <span style="font-family: 'Courier New', monospace; background: white; padding: 5px 12px; border-radius: 4px; border: 1px solid #dee2e6; margin-left: 10px;">{$hostname}</span>
            </div>
            <div style="background: #f8f9fa; border-radius: 8px; padding: 15px; margin-bottom: 20px;">
                <span style="font-weight: 600; color: #6c757d;">⏰ Detection Time:</span>
                <span style="font-family: 'Courier New', monospace; background: white; padding: 5px 12px; border-radius: 4px; border: 1px solid #dee2e6; margin-left: 10px;">{$timestamp}</span>
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
            
            foreach ($devices as $d) {
                $mac = htmlspecialchars($d['mac']);
                $vendor = htmlspecialchars($d['vendor']);
                $ip = htmlspecialchars($d['ip'] ?? 'No IP');
                $hostname_val = htmlspecialchars($d['hostname'] ?? 'Unknown');
                $vlan = htmlspecialchars($d['vlan'] ?? '-');
                $first_seen = htmlspecialchars($d['first_seen']);
                
                $html .= <<<ROW
                    <tr>
                        <td style="padding: 12px; border-bottom: 1px solid #e9ecef;">
                            <span style="font-family: 'Courier New', monospace; background: #e3f2fd; padding: 4px 8px; border-radius: 4px; color: #1976d2; font-weight: 600;">{$mac}</span>
                        </td>
                        <td style="padding: 12px; border-bottom: 1px solid #e9ecef; color: #2d3748; font-weight: 500;">{$vendor}</td>
                        <td style="padding: 12px; border-bottom: 1px solid #e9ecef; font-family: 'Courier New', monospace; color: #6c757d;">{$ip}</td>
                        <td style="padding: 12px; border-bottom: 1px solid #e9ecef;">{$hostname_val}</td>
                        <td style="padding: 12px; border-bottom: 1px solid #e9ecef;">
                            <span style="background: #e8f5e9; color: #2e7d32; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: 600;">{$vlan}</span>
                        </td>
                        <td style="padding: 12px; border-bottom: 1px solid #e9ecef; font-size: 13px;">{$first_seen}</td>
                    </tr>
ROW;
            }
            
            $html .= <<<HTML
                </tbody>
            </table>
        </div>
        
        <!-- Footer -->
        <div style="background: #f8f9fa; padding: 20px; text-align: center; color: #6c757d; font-size: 12px; border-top: 1px solid #e9ecef;">
            <div>🛡️ <strong>OPNsense Device Monitor</strong></div>
            <div style="font-family: 'Courier New', monospace; color: #495057; margin-top: 5px;">Generated: {$timestamp}</div>
        </div>
    </div>
</body>
</html>
HTML;
        }
        
        // Odešli email
        try {
            //$this->fLog("Sending email to: {$email_to}", 'EMAIL');
            
            $message = "From: $email_from\r\n";
            $message .= "To: $email_to\r\n";
            $message .= "Subject: $subject\r\n";
            $message .= "MIME-Version: 1.0\r\n";
            $message .= "Content-Type: text/html; charset=UTF-8\r\n";
            $message .= "\r\n$html";
            
            $proc = proc_open('/usr/local/sbin/sendmail -t -i', [
                0 => ["pipe", "r"],
                1 => ["pipe", "w"],
                2 => ["pipe", "w"]
            ], $pipes);
            
            if (!is_resource($proc)) {
                $this->fLog("FAILED: Cannot start sendmail process", 'EMAIL');
                return ['result' => 'failed', 'message' => 'Cannot start sendmail'];
            }
            
            fwrite($pipes[0], $message);
            fclose($pipes[0]);
            
            $stdout = stream_get_contents($pipes[1]);
            $stderr = stream_get_contents($pipes[2]);
            
            fclose($pipes[1]);
            fclose($pipes[2]);
            $ret = proc_close($proc);
            
            if ($ret === 0) {
                $mode = $is_test ? 'TEST' : 'REAL';
                $count_info = $is_test ? '0' : count($devices ?? []);
                $this->fLog("SUCCESS: Email sent ({$mode} mode, {$count_info} devices)", 'EMAIL');
                
                return [
                    'result' => 'sent',
                    'message' => "Email sent to: $email_to",
                    'test' => $is_test,
                    'count' => $count_info
                ];
            } else {
                $error_detail = !empty($stderr) ? $stderr : "Exit code: $ret";
                $this->fLog("FAILED: Sendmail error - {$error_detail}", 'EMAIL');
                
                return [
                    'result' => 'failed', 
                    'message' => "Sendmail error: {$error_detail}",
                    'exit_code' => $ret
                ];
            }
            
        } catch (\Exception $e) {
            $this->fLog("FAILED: Exception - " . $e->getMessage(), 'EMAIL');
            return ['result' => 'failed', 'message' => $e->getMessage()];
        }
    }
    
    /**
     * UNIVERZÁLNÍ WEBHOOK - test i real
     * POST /api/devicemonitor/config/sendWebhook
     */
    public function sendWebhook($is_test = false, $webhook_url = null)
    {
        
        
        // Pokud není webhook_url předán, načti z configu
        if ($webhook_url === null) {
            $model = new \OPNsense\DeviceMonitor\DeviceMonitor();
            $config = $model->getConfig();
            
            if ($config['webhook_enabled'] != '1' || empty($config['webhook_url'])) {
                return ['result' => 'skipped', 'message' => 'Webhook disabled'];
            }
            
            $webhook_url = $config['webhook_url'];
        }
        
        
        // DETEKCE TYPU WEBHOOKU
        $type = 'generic';
        if (stripos($webhook_url, 'ntfy') !== false) {
            $type = 'ntfy';
        } elseif (stripos($webhook_url, 'discord') !== false) {
            $type = 'discord';
        }
        
        try {
            if ($is_test) {
                // === TEST MODE ===
                
                if ($type === 'ntfy') {
                    // NTFY.SH TEST
                    $ch = curl_init($webhook_url);
                    curl_setopt($ch, CURLOPT_POST, 1);
                    curl_setopt($ch, CURLOPT_POSTFIELDS, 'Device Monitor webhook is working! ✅');
                    curl_setopt($ch, CURLOPT_HTTPHEADER, [
                        'Title: 🧪 OPNsense Test',
                        'Tags: test,opnsense',
                        'Priority: 3'
                    ]);
                    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
                    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                    
                } elseif ($type === 'discord') {
                    // DISCORD TEST
                    $payload = [
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
                    
                    $ch = curl_init($webhook_url);
                    curl_setopt($ch, CURLOPT_POST, 1);
                    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
                    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
                    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
                    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                    
                } else {
                    // GENERIC TEST
                    $payload = [
                        'event' => 'test',
                        'title' => '🧪 OPNsense Device Monitor - Test',
                        'message' => 'This is a test notification!',
                        'timestamp' => date('Y-m-d H:i:s'),
                        'hostname' => gethostname(),
                        'test' => true
                    ];
                    
                    $ch = curl_init($webhook_url);
                    curl_setopt($ch, CURLOPT_POST, 1);
                    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
                    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
                    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
                    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                }
                
            } else {
                // === REAL MODE - načti z DB ===
                $devices = $this->loadDevicesFromDb();
                
                if ($devices === null) {
                    return ['result' => 'failed', 'message' => 'Cannot load devices'];
                }
                
                if (empty($devices)) {
                    return ['result' => 'skipped', 'message' => 'No pending notifications'];
                }
                
                $count = count($devices);
                $hostname = gethostname();
                
                if ($type === 'ntfy') {
                    // NTFY.SH REAL
                    $msg = "{$count} new device(s) detected:\n\n";
                    foreach (array_slice($devices, 0, 5) as $d) {
                        $msg .= "• {$d['mac']} - {$d['vendor']} ({$d['ip']})\n";
                    }
                    if ($count > 5) {
                        $msg .= "\n... and " . ($count - 5) . " more";
                    }
                    
                    $ch = curl_init($webhook_url);
                    curl_setopt($ch, CURLOPT_POST, 1);
                    curl_setopt($ch, CURLOPT_POSTFIELDS, $msg);
                    curl_setopt($ch, CURLOPT_HTTPHEADER, [
                        "Title: 🔔 OPNsense: {$count} new device(s)",
                        'Tags: opnsense,network',
                        'Priority: ' . (($count > 3) ? '4' : '3')
                    ]);
                    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
                    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                    
                } elseif ($type === 'discord') {
                    // DISCORD REAL
                    $fields = [];
                    foreach (array_slice($devices, 0, 10) as $d) {
                        $fields[] = [
                            'name' => $d['mac'],
                            'value' => "**{$d['vendor']}**\nIP: `{$d['ip']}`\nVLAN: `{$d['vlan']}`",
                            'inline' => true
                        ];
                    }
                    
                    $payload = [
                        'username' => 'OPNsense Device Monitor',
                        'embeds' => [[
                            'title' => "🔔 {$count} New Device(s) Detected",
                            'description' => "Server: `$hostname`",
                            'color' => 3447003,
                            'fields' => $fields,
                            'footer' => ['text' => 'OPNsense • ' . date('Y-m-d H:i:s')]
                        ]]
                    ];
                    
                    $ch = curl_init($webhook_url);
                    curl_setopt($ch, CURLOPT_POST, 1);
                    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
                    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
                    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
                    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                    
                } else {
                    // GENERIC REAL
                    $payload = [
                        'event' => 'new_devices',
                        'hostname' => $hostname,
                        'timestamp' => date('Y-m-d H:i:s'),
                        'device_count' => $count,
                        'devices' => $devices
                    ];
                    
                    $ch = curl_init($webhook_url);
                    curl_setopt($ch, CURLOPT_POST, 1);
                    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
                    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
                    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
                    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                }
            }
            
            // Odešli webhook
            $response = curl_exec($ch);
            $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            
            if ($http_code >= 200 && $http_code < 300) {
                return [
                    'result' => $is_test ? 'ok' : 'sent',
                    'message' => "Webhook sent (HTTP $http_code)",
                    'type' => $type,
                    'test' => $is_test,
                    'count' => $is_test ? 0 : count($devices ?? [])
                ];
            } else {
                return ['result' => 'failed', 'message' => "HTTP $http_code"];
            }
            
        } catch (\Exception $e) {
            return ['result' => 'failed', 'message' => $e->getMessage()];
        }
    }
}