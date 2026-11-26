#!/usr/local/bin/php
<?php

// Předpony: arr = pole, o = objekt, s = řetězec.
// Historie: 2.4.15 – společná kontrola velikosti vstupu.
// 2.4.11 – konkrétní dávka může přijít přes standardní vstup.
// 2.3.7 – sjednocení typových předpon proměnných.

// Include shared handler
require_once('/usr/local/opnsense/scripts/OPNsense/DeviceMonitor/NotificationHandler.php');

// Prázdná nebo neplatná dávka nesmí spustit původní načtení příznaků.
$arrQueuedDevices = null;
if (($argv[1] ?? '') === '--batch-stdin') {
    $arrQueuedDevices = NotificationHandler::readNotificationBatch();
    if ($arrQueuedDevices === null) {
        echo json_encode(['result' => 'failed', 'message' => 'Invalid or oversized email batch']);
        exit(1);
    }
}

// Zavolej funkci
$oHandler = new NotificationHandler(); // Žádný namespace = GLOBÁLNÍ NAMESPACE
$oHandler->fLog("Preparing to send email", 'EMAIL');
$arrResult = $oHandler->sendEmail(false, $arrQueuedDevices);

// Loguj výsledek
//$handler->fLog("Result: " . json_encode($result), "EMAIL-SCRIPT");
$sLogMessage = "Email notification result: " . ($arrResult['result'] === 'sent' ? "SUCCESS" : "FAILED");
if ($arrResult['result'] !== 'sent') {
    $sLogMessage .= " | Reason: " . ($arrResult['message'] ?? 'Unknown error');
}
$oHandler->fLog($sLogMessage, "NOTIFY_EMAIL.php");

// V CLI scriptu MUSÍ být echo + exit!
echo json_encode($arrResult);
exit($arrResult['result'] === 'sent' ? 0 : 1);