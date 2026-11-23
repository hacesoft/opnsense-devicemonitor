# Troubleshooting

[Project overview](../../README.md) · [Česky](../cz/03_RESENI_PROBLEMU.md)

## Plugin does not appear in Services

```bash
# Verify the .inc file exists (NOT .php!)
ls /usr/local/etc/inc/plugins.inc.d/devicemonitor.inc

# Verify PHP can load the function
php -r "require_once('/usr/local/etc/inc/plugins.inc.d/devicemonitor.inc'); var_dump(devicemonitor_services());"

# Reload plugin registry
/usr/local/etc/rc.configure_plugins
```

## Daemon control shows "Execute error"

```bash
# Check that daemon_status.sh exists and is executable
ls -la /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/daemon_status.sh

# Test it manually (must print "running" or "stopped", never an error)
sh /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/daemon_status.sh

# Check configd actions are loaded
configctl configd actions | grep devicemonitor
```

## Multiple zombie daemon processes

```bash
# Check how many are running
ps aux | grep monitor_daemon | grep -v grep

# Kill all instances
pkill -f monitor_daemon.py
rm -f /var/run/devicemonitor.pid

# Start fresh
configctl devicemonitor start
```

Root cause: the RC script was missing `procname`, so `rc.d` could not detect the running process and started a new one every time. Fixed in v2.0 by adding `procname="/usr/local/bin/python3"` to the RC script.

## Widget shows dashes, no data

```bash
# Verify the stats endpoint works
curl -k -u "APIKEY:APISECRET" https://localhost/api/devicemonitor/devices/stats
# Should return: {"total": N, "online": N}

# Verify the status endpoint works
curl -k -u "APIKEY:APISECRET" https://localhost/api/devicemonitor/service/status
# Should return: {"result": "running", ...}
```

If the endpoints return data but the widget still shows dashes, clear browser cache (Ctrl+Shift+R) and check the browser console for JavaScript errors.

## Email notifications not working

```bash
# Test from command line
php /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/notify_email.php

# Check logs
grep EMAIL /var/log/devicemonitor.log
```

## Daemon won't start

```bash
# Check log for startup errors
tail -30 /var/log/devicemonitor.log

# Run daemon manually to see errors
/usr/local/bin/python3 /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/monitor_daemon.py

# Check that defaults.json is readable
cat /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/defaults.json
```

## Corrupted database

```bash
cp /var/db/devicemonitor/devices.db /var/db/devicemonitor/devices.db.backup
rm /var/db/devicemonitor/devices.db
configctl devicemonitor restart
```
