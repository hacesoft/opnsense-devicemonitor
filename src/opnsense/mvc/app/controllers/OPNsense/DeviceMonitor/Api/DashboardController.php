<?php

namespace OPNsense\DeviceMonitor;

class DashboardController extends \OPNsense\Base\IndexController
{
    public function serviceWidgetAction()
    {
        // Tento action vrací widget pro dashboard
        return $this->getView();
    }
}