# Technická dokumentace

[Přehled projektu](../../README_CZ.md) · [English](../en/04_TECHNICAL_REFERENCE.md)

## Struktura pluginu

```
src/
├── etc/
│   ├── rc.d/
│   │   └── devicemonitor              # FreeBSD rc.d servisní skript
│   └── inc/
│       └── plugins.inc.d/
│           └── devicemonitor.inc      # Registrace služby pro Diagnostics → Services
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
│   │   ├── monitor_daemon.py          # Hlavní daemon
│   │   ├── smtp_send.py               # Direct SMTP
│   │   ├── config_hostnames.py        # Rezervace Kea DHCPv4
│   │   ├── scan_network.py            # Skenovací skript
│   │   ├── daemon_status.sh           # Spolehlivá kontrola stavu přes pidfile
│   │   ├── NotificationHandler.php
│   │   ├── notify_email.php
│   │   └── notify_webhook.php
│   ├── service/conf/actions.d/
│   │   └── actions_devicemonitor.conf # Definice configd akcí
│   └── www/js/widgets/
│       ├── DeviceMonitor.js           # Lobby dashboard widget
│       └── Metadata/
│           └── DeviceMonitor.xml      # Metadata a endpointy widgetu
```

### Runtime soubory

```
/var/run/devicemonitor.pid             # PID daemona
/var/log/devicemonitor.log             # Log soubor
/var/db/devicemonitor/
├── devices.db                         # SQLite databáze zařízení
└── config.json                        # Runtime konfigurace
/etc/rc.conf.d/devicemonitor           # Příznak autostartu
```

### API endpointy

| Metoda | Endpoint | Popis |
|--------|----------|-------|
| GET | `/api/devicemonitor/devices/stats` | Celkový a online počet zařízení |
| GET | `/api/devicemonitor/service/status` | Stav daemona (running/stopped) |
| POST | `/api/devicemonitor/service/start` | Spustit daemon |
| POST | `/api/devicemonitor/service/stop` | Zastavit daemon |
| POST | `/api/devicemonitor/service/restart` | Restartovat daemon |
| POST | `/api/devicemonitor/service/scan` | Spustit ruční skenování |
| GET | `/api/devicemonitor/config/get` | Načíst konfiguraci |
| POST | `/api/devicemonitor/config/set` | Uložit konfiguraci |
| POST | `/api/devicemonitor/config/testemail` | Odeslat testovací email |
| POST | `/api/devicemonitor/config/testwebhook` | Odeslat testovací webhook |

## Jak daemon funguje

```
monitor_daemon.py (proces na pozadí)
    │
    ├── čte /var/db/devicemonitor/config.json   (scan interval, příznak enabled)
    ├── čte /var/db/hostwatch/hosts.db           (nativní detekce OPNsense)
    ├── zapisuje /var/db/devicemonitor/devices.db (known devices, fronta notifikací)
    └── zapisuje /var/log/devicemonitor.log

configd (konfigurační daemon OPNsense)
    │
    ├── devicemonitor start   → service devicemonitor start || true
    ├── devicemonitor stop    → service devicemonitor stop || true
    ├── devicemonitor restart → service devicemonitor restart || true
    └── devicemonitor status  → daemon_status.sh (kontrola pidfile, vždy exit 0)

rc.d/devicemonitor
    │
    ├── používá /usr/sbin/daemon -f -p /var/run/devicemonitor.pid python3 monitor_daemon.py
    ├── procname="/usr/local/bin/python3"   (potřebné aby stop našel proces)
    └── výchozí: devicemonitor_enable="NO"  (aktivováno přes /etc/rc.conf.d/devicemonitor)
```
