#!/usr/local/bin/php
<?php

// Předpony: arr = pole, o = objekt, s = řetězec.
// Historie: 2.4.15 – vlastní dávka ze stdin.
// 2.3.7 – sjednocení typových předpon proměnných.

// Include shared handler
require_once('/usr/local/opnsense/scripts/OPNsense/DeviceMonitor/NotificationHandler.php');

$arrQueuedDevices = null;
if (($argv[1] ?? '') === '--batch-stdin') {
    $arrQueuedDevices = NotificationHandler::readNotificationBatch();
    if ($arrQueuedDevices === null) {
        echo json_encode(['result' => 'failed', 'message' => 'Invalid or oversized webhook batch']);
        exit(1);
    }
}

// Zavolej funkci
$oHandler = new NotificationHandler(); // Žádný namespace = GLOBÁLNÍ NAMESPACE
$oHandler->fLog("Preparing to send webhook", 'WEBHOOK');
$arrResult = $oHandler->sendWebhook(false, null, null, $arrQueuedDevices);

// Loguj výsledek
//$handler->fLog("Result: " . json_encode($result), "WEBHOOK-SCRIPT");
$sLogMessage = "Webhook notification result: " . ($arrResult['result'] === 'sent' ? "SUCCESS" : "FAILED");
if ($arrResult['result'] !== 'sent') {
    $sLogMessage .= " | Reason: " . ($arrResult['message'] ?? 'Unknown error');
}
$oHandler->fLog($sLogMessage, "NOTIFY_WEBHOOK.php");

// V CLI scriptu MUSÍ být echo + exit!
echo json_encode($arrResult);
exit($arrResult['result'] === 'sent' ? 0 : 1);

