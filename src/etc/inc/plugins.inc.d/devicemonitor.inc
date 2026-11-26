<?php

// Předpony: arr = pole.
// Historie: 2.3.7 – sjednocení typových předpon proměnných.

function devicemonitor_services()
{
    $arrServices = [];
    $arrServices[] = [
        'description' => gettext('Device Monitor - network device tracking'),
        'configd' => [
            'restart' => ['devicemonitor restart'],
            'start'   => ['devicemonitor start'],
            'stop'    => ['devicemonitor stop'],
        ],
        'name'    => 'devicemonitor',
        'pidfile' => '/var/run/devicemonitor.pid',
    ];
    return $arrServices;
}