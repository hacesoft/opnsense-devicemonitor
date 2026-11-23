# Technical reference

[Project overview](../../README.md) · [Česky](../cz/04_TECHNICKA_DOKUMENTACE.md)

## Plugin structure

```
src/
├── etc/
│   ├── rc.d/
│   │   └── devicemonitor              # FreeBSD rc.d service script
│   └── inc/
│       └── plugins.inc.d/
│           └── devicemonitor.inc      # Service registration for Diagnostics → Services
├── opnsense/
│   ├── mvc/app/
│   │   ├── controllers/OPNsense/DeviceMonitor/
│   │   │   ├── IndexController.php
│   │   │   └── Api/
│   │   │       ├── ConfigController.php
│   │   │       ├── DevicesController.php
│   │   │       └── ServiceController.php
│   │   ├── models/OPNsense/DeviceMonitor/
│   │   │   ├── DeviceMonitor.php
│   │   │   ├── DeviceMonitor.xml
│   │   │   ├── defaults.json
│   │   │   ├── Metadata/
│   │   │   │   └── service.xml        # MVC service metadata
│   │   │   ├── Menu/Menu.xml
│   │   │   └── ACL/ACL.xml
│   │   └── views/OPNsense/DeviceMonitor/
│   │       ├── devices.volt
│   │       ├── settings.volt
│   │       └── service_widget.volt
│   ├── scripts/OPNsense/DeviceMonitor/
│   │   ├── monitor_daemon.py          # Background daemon
│   │   ├── smtp_send.py               # Direct SMTP
│   │   ├── config_hostnames.py        # Kea DHCPv4 reservations
│   │   ├── scan_network.py            # Network scan script
│   │   ├── daemon_status.sh           # Reliable status check via pidfile
│   │   ├── NotificationHandler.php
│   │   ├── notify_email.php
│   │   └── notify_webhook.php
│   ├── service/conf/actions.d/
│   │   └── actions_devicemonitor.conf # configd action definitions
│   └── www/js/widgets/
│       ├── DeviceMonitor.js           # Lobby dashboard widget
│       └── Metadata/
│           └── DeviceMonitor.xml      # Widget metadata and endpoints
```

### Runtime files

```
/var/run/devicemonitor.pid             # Daemon PID
/var/log/devicemonitor.log             # Log file
/var/db/devicemonitor/
├── devices.db                         # SQLite device database
└── config.json                        # Runtime configuration
/etc/rc.conf.d/devicemonitor           # Autostart flag
```

### API endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/devicemonitor/devices/stats` | Total and online device count |
| GET | `/api/devicemonitor/service/status` | Daemon status (running/stopped) |
| POST | `/api/devicemonitor/service/start` | Start daemon |
| POST | `/api/devicemonitor/service/stop` | Stop daemon |
| POST | `/api/devicemonitor/service/restart` | Restart daemon |
| POST | `/api/devicemonitor/service/scan` | Trigger manual scan |
| GET | `/api/devicemonitor/config/get` | Get configuration |
| POST | `/api/devicemonitor/config/set` | Save configuration |
| POST | `/api/devicemonitor/config/testemail` | Send test email |
| POST | `/api/devicemonitor/config/testwebhook` | Send test webhook |

## How the daemon works

```
monitor_daemon.py (background process)
    │
    ├── reads /var/db/devicemonitor/config.json  (scan interval, enabled flag)
    ├── reads /var/db/hostwatch/hosts.db          (OPNsense native discovery)
    ├── writes /var/db/devicemonitor/devices.db   (known devices, notification queue)
    └── writes /var/log/devicemonitor.log

configd (OPNsense configuration daemon)
    │
    ├── devicemonitor start   → service devicemonitor start || true
    ├── devicemonitor stop    → service devicemonitor stop || true
    ├── devicemonitor restart → service devicemonitor restart || true
    └── devicemonitor status  → daemon_status.sh (pidfile check, always exit 0)

rc.d/devicemonitor
    │
    ├── uses /usr/sbin/daemon -f -p /var/run/devicemonitor.pid python3 monitor_daemon.py
    ├── procname="/usr/local/bin/python3"   (needed for stop to find the process)
    └── default: devicemonitor_enable="NO"  (activated by /etc/rc.conf.d/devicemonitor)
```
