# Installation, upgrade and removal

[Project overview](../../README.md) · [Česky](../cz/01_INSTALACE.md)

## Requirements

- **OPNsense 26.1.5 or newer**
- **SSH access** (System → Settings → Administration → Secure Shell)
- **Root account** or admin with CLI access

> ⚠️ Versions prior to 26.1.5 are not supported. The plugin uses APIs and mechanisms introduced in 26.x.

## Installation

### Install from Windows with WinSCP and SSH

1. Download the Device Monitor 2.3.2 installation ZIP.
2. Enable SSH if needed under **System → Settings → Administration → Secure Shell**.
3. Use WinSCP to upload the ZIP to `/tmp/` on OPNsense.
4. Open an SSH session, obtain root privileges, and run:

```sh
cd /tmp
unzip opnsense-devicemonitor-2.3.2.zip
cd opnsense-devicemonitor
sh install.sh
```

### Download version 2.3 directly over SSH

The link below points to the previously published version 2.3. Use the ZIP from the section above for version 2.3.2. On OPNsense, run the following as root:

```sh
cd /tmp
fetch https://raw.githubusercontent.com/hacesoft/opnsense-devicemonitor/main/release/opnsense-devicemonitor28082026_1812.zip
unzip opnsense-devicemonitor28082026_1812.zip
cd opnsense-devicemonitor
sh install.sh
```

Open **System → Diagnostics → Services** to verify that the `devicemonitor` service is running. A firewall reboot is not required.

### Upgrade an existing installation

Run `install.sh` from the newer package. The installer detects the existing installation and uses silent removal to preserve the device database. Follow the [configuration guide](02_CONFIGURATION_AND_USAGE.md) after installation.

### What install.sh does

1. Checks OPNsense version (minimum 26.1.5)
2. Runs `uninstall.sh --silent` if an old installation is detected (preserves database)
3. Creates all required directories
4. Copies RC script and registers the service in `plugins.inc.d`
5. Installs the dashboard widget
6. Compiles translation files
7. Copies MVC controllers, models, views
8. Copies Python, shell, and PHP scripts
9. Copies configd actions
10. Kills any zombie daemon processes, starts fresh via `configctl devicemonitor start`

## Uninstallation

### Method 1: uninstall.sh (recommended)

```bash
cd /path/to/opnsense-devicemonitor
sh uninstall.sh
```

This removes all files, stops the daemon, disables autostart, and clears caches. The database `/var/db/devicemonitor/devices.db` is deleted.

### Method 2: Silent uninstall (preserves database)

```bash
sh uninstall.sh --silent
```

Used internally by `install.sh` during upgrades. Removes all files but keeps the database.

### Method 3: Manual

```bash
pkill -f monitor_daemon.py
rm -f /var/run/devicemonitor.pid
rm -f /etc/rc.conf.d/devicemonitor
rm -f /usr/local/etc/rc.d/devicemonitor
rm -f /etc/rc.d/devicemonitor
rm -f /usr/local/etc/inc/plugins.inc.d/devicemonitor.inc
rm -rf /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor
rm -rf /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor
rm -rf /usr/local/opnsense/mvc/app/views/OPNsense/DeviceMonitor
rm -rf /usr/local/opnsense/scripts/OPNsense/DeviceMonitor
rm -f /usr/local/opnsense/service/conf/actions.d/actions_devicemonitor.conf
rm -f /usr/local/opnsense/www/js/widgets/DeviceMonitor.js
rm -f /usr/local/opnsense/www/js/widgets/Metadata/DeviceMonitor.xml
rm -rf /var/db/devicemonitor        # WARNING: deletes device database
rm -f /var/log/devicemonitor.log
/usr/local/etc/rc.configure_plugins
service configd restart
```
