# Administrator reference

[Project overview](../../README.md) · [Česky](../cz/04_TECHNICKA_DOKUMENTACE.md)

## Privileges

In OPNsense, go to **System → Access → Users** or **Groups**.

| Privilege | Scope |
|-----------|-------|
| **Services: Device Monitor (read only)** | Device list, CSV export and service status. |
| **Services: Device Monitor (manage)** | Also allows device edits, manual ping, settings, test notifications and service controls. |
| **Firewall Sessions** | Access to optional firewall activity data. |

OPNsense accounts with full access can manage the plugin. When upgrading from a release older than 2.4.14, the existing delegated Device Monitor privilege becomes read-only.

## Data and logs

| Path | Purpose |
|------|---------|
| `/var/db/devicemonitor/devices.db` | Device list, manual names, known-device marks and pending notifications. |
| `/var/db/devicemonitor/config.json` | Settings, including saved credentials. The file has `0600` permissions. |
| `/var/log/devicemonitor.log` | Operational log. Once it reaches approximately 1 MiB, the system rotates it on the next run and retains up to five compressed copies. |

To back up settings and inventory, keep a copy of the entire `/var/db/devicemonitor` directory in a protected location. A damaged configuration file pauses automatic refresh and delivery. Pending notifications stay in the database. A retry may deliver a duplicate if the destination accepted the message just before the service stopped.

## Common API operations

Use an account or API key with the relevant privilege. The settings API reports whether the SMTP password and webhook URL are saved.

| Method | Path under `/api/devicemonitor/` | Result |
|--------|----------------------------------|--------|
| GET | `devices/stats` | Total devices and the active count from Hostwatch. |
| GET | `service/status` | Service status. |
| GET | `config/get` | Settings with the saved password and webhook URL omitted. |
| POST | `config/set` | Validate and save settings. |
| POST | `config/testemail`, `config/testWebhook` | Test delivery. |
