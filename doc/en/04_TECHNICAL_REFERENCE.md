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

### Optional PF traffic summary

With `firewall_traffic_enabled` enabled, the Device Monitor service reads existing PF states through the `filter diag top` configd action about every 30 seconds. A worker thread tracks baselines, running totals and last increases for unique MAC and IP pairs in the device database. It publishes summaries atomically to `/var/run/devicemonitor-pf.json`. The normal device-list request with `include_pf_packets` verifies Firewall Sessions permissions and attaches summaries for the returned rows. The countdown uses server time. When collection stops, the page marks snapshots older than 75 seconds as unavailable.

The device view combines `last_seen_at` from Hostwatch and `seenAt` from PF packet increases, comparing both with the server time returned by the device list. The table, filtering, sorting, header summary and CSV use the combined status.

The snapshot also contains the next shared 15-minute review deadline and the result of the last review when data was available. The service sets this deadline independently of open pages and individual packet increases.

### API endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/devicemonitor/devices/stats` | Total devices and number seen by Hostwatch in the last 15 minutes (the API field remains `online`) |
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

### Email queue

A new device and its `email_queued_at` value are stored in the same transaction when email is enabled and the device matches the VLAN filter. The daemon waits for a pause after the latest discovery. When the maximum is enabled, the deadline from the first discovery caps the wait. After successful transport submission, it removes only the sent entries. The queue survives a service restart and retries after about one minute when delivery fails. An email can be repeated if the transport accepts it before the process can acknowledge it in the database. Turning off email notifications clears unsent entries.

### Inline settings help

The settings help switch updates the visibility of field descriptions and their `aria-describedby` associations. The preference is stored in `localStorage` per browser and OPNsense address.

### Security boundaries

Read and management use separate ACL privileges. Side-effecting actions require POST and check write permissions. Manual ping is scoped to the stored MAC and IP pair. The configuration API returns only presence flags for secrets. The configuration file is replaced atomically with 0600 permissions. CSV prefixes cells that could be interpreted as formulas with a tab and apostrophe, then quotes the cell. The prefix can be part of the value during programmatic import.

### Webhook queue and operational limits

Webhooks use `webhook_queued_at`, set in the same transaction that saves the new device. Manual and scheduled Hostwatch reads preserve the existing queue. The service sends webhooks in groups from each refresh. Both channels have separate locks, send up to 100 devices per message, and retry failures after about a minute. Disabling one channel clears its pending entries. In either channel, a retry can duplicate a message if the destination accepts it just before the process fails to confirm it.

A PF read is limited to 16 MiB of command output and 20 seconds. Exceeding a limit marks the latest snapshot as unavailable. The limit applies to the input, and parsed JSON may require more memory. Hostwatch reads rows incrementally and retains the most recent one for each MAC.

The installer adds `/usr/local/etc/newsyslog.conf.d/devicemonitor.conf`. The active log has 0600 permissions. Once it reaches approximately 1 MiB, it is rotated on the next `newsyslog` run. The system retains up to five compressed archives.

### Input validation

A Hostwatch observation must contain a valid MAC, IPv4 address and last-seen timestamp. Invalid observations and timestamps more than a minute into the future are skipped. The newest observation is selected using timestamps normalized to UTC. A well-formed MAC or IP address on its own does not authenticate a device.

Saved configuration must be a JSON object and is limited to 64 KiB. A damaged file or invalid field type pauses automatic refresh and delivery. Queued notifications remain in the database. A manual refresh can still update the inventory from valid Hostwatch observations. The API rejects invalid changes before the atomic write.
