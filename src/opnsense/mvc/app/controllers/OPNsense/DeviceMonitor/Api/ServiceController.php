<?php

// Předpony: arr = pole, i = celé číslo, o = objekt, s = řetězec.
// Historie: 2.4.14 – kontrola PID a práv pro ovládání služby.
// 2.3.7 – sjednocení typových předpon proměnných.

namespace OPNsense\DeviceMonitor\Api;

use OPNsense\Base\ApiControllerBase;
use OPNsense\Core\Backend;

class ServiceController extends ApiControllerBase
{
    /**
     * Spuštění manuálního skenu
     */
    public function scanAction()
    {
        if ($this->request->isPost()) {
            $this->throwReadOnly();
            $oBackend = new Backend();
            $sResponse = $oBackend->configdRun("devicemonitor scan");
            return ['result' => 'ok', 'output' => $sResponse];
        }
        
        return ['result' => 'failed'];
    }

    /**
     * Status daemona
     */
    public function statusAction()
    {
        $oModel = new \OPNsense\DeviceMonitor\DeviceMonitor();
        $sPidFile = $oModel->getPidFilePath();
        
        if (file_exists($sPidFile)) {
            $sPid = trim(file_get_contents($sPidFile));
            
            if (!preg_match('/^[1-9][0-9]{0,9}$/D', $sPid)) {
                return ['result' => 'stopped', 'message' => 'Invalid daemon PID'];
            }
            exec('/bin/ps -p ' . escapeshellarg($sPid), $arrCommandOutput, $iExitCode);
            
            if ($iExitCode === 0) {
                return [
                    'result' => 'running',
                    'pid' => $sPid,
                    'message' => 'Daemon is running'
                ];
            } else {
                return [
                    'result' => 'stopped',
                    'message' => 'Daemon is not running (stale pidfile)'
                ];
            }
        } else {
            return [
                'result' => 'stopped',
                'message' => 'Daemon is not running'
            ];
        }
    }

    /**
     * Start daemona
     */
    public function startAction()
    {
        if ($this->request->isPost()) {
            $this->throwReadOnly();
            $arrStatus = $this->statusAction();
            if ($arrStatus['result'] === 'running') {
                return ['result' => 'already_running', 'message' => 'Daemon is already running'];
            }

            $oBackend = new Backend();
            $oBackend->configdRun('devicemonitor start');
            sleep(1);

            $arrStatus = $this->statusAction();
            if ($arrStatus['result'] === 'running') {
                return ['result' => 'started', 'message' => 'Daemon started successfully'];
            } else {
                return ['result' => 'failed', 'message' => 'Failed to start daemon'];
            }
        }
        return ['result' => 'failed'];
    }

    /**
     * Stop daemona
     */
    public function stopAction()
    {
        if ($this->request->isPost()) {
            $this->throwReadOnly();
            $oBackend = new Backend();
            $oBackend->configdRun('devicemonitor stop');
            sleep(1);

            $arrStatus = $this->statusAction();
            if ($arrStatus['result'] === 'stopped') {
                return ['result' => 'stopped', 'message' => 'Daemon stopped successfully'];
            } else {
                return ['result' => 'failed', 'message' => 'Failed to stop daemon'];
            }
        }
        return ['result' => 'failed'];
    }

    /**
     * Restart daemona
     */
    public function restartAction()
    {
        if ($this->request->isPost()) {
            $this->throwReadOnly();
            $oBackend = new Backend();
            $oBackend->configdRun('devicemonitor restart');
            sleep(2);
            return $this->statusAction();
        }
        return ['result' => 'failed'];
    }
}