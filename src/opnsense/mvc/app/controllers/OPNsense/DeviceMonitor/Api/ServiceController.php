<?php

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
            $backend = new Backend();
            $response = $backend->configdRun("devicemonitor scan");
            return ['result' => 'ok', 'output' => $response];
        }
        
        return ['result' => 'failed'];
    }

    /**
     * Status daemona
     */
    public function statusAction()
    {
        $model = new \OPNsense\DeviceMonitor\DeviceMonitor();
        $pidFile = $model->getPidFilePath();
        
        if (file_exists($pidFile)) {
            $pid = trim(file_get_contents($pidFile));
            
            // Zkontroluj jestli proces běží
            exec("ps -p $pid", $output, $return);
            
            if ($return === 0) {
                return [
                    'result' => 'running',
                    'pid' => $pid,
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
            // Zkontroluj jestli už neběží
            $status = $this->statusAction();
            if ($status['result'] === 'running') {
                return [
                    'result' => 'already_running',
                    'message' => 'Daemon is already running'
                ];
            }
            
            // Spusť daemon
            exec('service devicemonitor start 2>&1', $output, $return);
            
            sleep(1); // Počkej na start
            
            $status = $this->statusAction();
            if ($status['result'] === 'running') {
                return [
                    'result' => 'started',
                    'message' => 'Daemon started successfully'
                ];
            } else {
                return [
                    'result' => 'failed',
                    'message' => 'Failed to start daemon',
                    'output' => implode("\n", $output)
                ];
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
            exec('service devicemonitor stop 2>&1', $output, $return);
            
            sleep(1); // Počkej na stop
            
            $status = $this->statusAction();
            if ($status['result'] === 'stopped') {
                return [
                    'result' => 'stopped',
                    'message' => 'Daemon stopped successfully'
                ];
            } else {
                return [
                    'result' => 'failed',
                    'message' => 'Failed to stop daemon',
                    'output' => implode("\n", $output)
                ];
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
            // Stop
            $this->stopAction();
            sleep(2);
            
            // Start
            return $this->startAction();
        }
        
        return ['result' => 'failed'];
    }
}