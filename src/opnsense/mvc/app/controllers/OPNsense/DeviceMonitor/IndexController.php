<?php

namespace OPNsense\DeviceMonitor;

class IndexController extends \OPNsense\Base\IndexController
{
    public function indexAction()
    {
        $this->view->pick('OPNsense/DeviceMonitor/index');
    }
    
    public function devicesAction()
    {
        $this->view->pick('OPNsense/DeviceMonitor/devices');
    }
    
    public function settingsAction()
    {
        $this->view->pick('OPNsense/DeviceMonitor/settings');
    }
}