#!/usr/local/bin/php
<?php

// Include shared handler
require_once('/usr/local/opnsense/scripts/OPNsense/DeviceMonitor/NotificationHandler.php');

// Zavolej funkci
$handler = new NotificationHandler(); // Žádný namespace = GLOBÁLNÍ NAMESPACE
$handler->fLog("Preparing to send webhook", 'WEBHOOK');
$result = $handler->sendWebhook(false);  // false = REAL mode

// Loguj výsledek
//$handler->fLog("Result: " . json_encode($result), "WEBHOOK-SCRIPT");
$logMessage = "Webhook notification result: " . ($result['result'] === 'sent' ? "SUCCESS" : "FAILED");
if ($result['result'] !== 'sent') {
    $logMessage .= " | Reason: " . ($result['message'] ?? 'Unknown error');
}
$handler->fLog($logMessage, "NOTIFY_WEBHOOK.php");

// V CLI scriptu MUSÍ být echo + exit!
echo json_encode($result);
exit($result['result'] === 'sent' ? 0 : 1);

