# Version history

[Project overview](../../README.md) · [Česky](../cz/HISTORIE_VERZI.md)

## v2.4.16

- Validate Hostwatch observations, API input and saved configuration before use.

## v2.4.15

- Bound memory use when reading PF and sending notifications, isolate persistent email and webhook queues, and install operational log rotation.

## v2.4.14

- Separate read and management privileges, hide stored SMTP passwords and webhook URLs, verify webhook TLS, protect CSV export and enforce API methods.

## v2.4.13

- Add optional help for all settings, including field descriptions and expected values. The browser remembers the preference.

## v2.4.12

- Add an email batching mode that waits for a pause after the last discovery, with no maximum delay.

## v2.4.11

- Group discoveries in summary emails with a configurable 15-second wait and a default 45-second maximum.

## v2.4.10

- Scroll the wide table inside the page on mobile. Combine Hostwatch and firewall counters in the device activity column and show the source.

## v2.4.9

- Use a fixed 15-minute service review for the header countdown. Reopening the page resumes the countdown using server time.

## v2.4.8

- Collect PF counters with the browser closed. Show a countdown to the next activity expiry among the displayed devices.

## v2.4.7

- Preserve the running packet count when PF returns zero, goes unavailable or its counters decrease. Reset the count after 15 minutes without an observed increase.

## v2.4.6

- Read PF packet counters alongside the device list using one cached configd action. Removed both separate browser diagnostics calls and the byte counter.

## v2.4.5

- Distinguish unchanged, lower, and unavailable PF counters and expose raw sampled values on hover.

## v2.4.4

- Prefer PF Sessions to obtain packet counters and handle unavailable diagnostics in the device list without an OPNsense error dialog.

## v2.4.3

- Show changes in byte counters and, when available, packet counters between PF readings.

## v2.4.2

- Recent firewall traffic can use the older PF diagnostics API, including on OPNsense 26.7.10.

## v2.4.1

- Made built-in Direct SMTP the fresh-install default. Saved mail settings carry over on upgrade.
- Added OPNsense integration checks for Hostwatch, PF, Direct SMTP and Monit.

## v2.4.0

- Added a persistent known-device mark and filter for issue #4.
- Added browser-saved column selection for the device list.

## v2.3.9

- Documented the ntfy message format, Android client verification, and troubleshooting for raw JSON notifications.

## v2.3.8

- Restored reverse DNS for unnamed devices using the native OPNsense lookup API ([#9](https://github.com/hacesoft/opnsense-devicemonitor/issues/9)).

## v2.3.7

- Standardized Hungarian variable naming across the plugin, including the web interface, daemon, notification tools, and installation scripts.

## v2.3.6

- Added **Recent firewall traffic** as an opt-in column using native OPNsense PF statistics from PR #11180.
- Added English and Czech guidance on enabling the column, firmware requirements, and the limits of passive monitoring.

## v2.3.5

- Last Seen and Manual ping use the same date and time format in the browser’s local time zone. Last Seen is sorted chronologically and uses local time in CSV exports.

## v2.3.4

- Hostwatch status text is green for devices seen in the last 15 minutes and red for other devices.

## v2.3.3

- Select the webhook format independently of the URL, including ntfy on a custom domain (#8).
- Show Hostwatch activity separately from the timestamped manual ping result. Manual pings no longer change automatic status (#10).

## v2.3.2

- Install and uninstall messages are now in English. Source comments remain in Czech, with Czech and English section headings.
- The installer now finds its bundled uninstaller during upgrades and stops if that uninstaller reports failure.

## v2.3.1

- Fix the documented direct download link for the previously published ZIP (#6).
- Install translation catalogs in the standard OPNsense locale directories and localize configuration validation messages (#5, #7).
- Read hostnames and descriptions from Kea DHCPv4 reservations, based on the contribution by ptrsmk (PR #11).
- Render device names as plain text in the device table.

## v2.3 (August 2026) — Direct SMTP and notification improvements

- Added selectable **Email delivery method** in Device Monitor settings.
- **Local Sendmail / Postfix** remains the default and preserves existing installations.
- Added built-in **Direct SMTP** delivery using Python `smtplib`; no additional Python package is required.
- Direct SMTP supports **STARTTLS**, **SSL/TLS**, and unencrypted SMTP.
- Added SMTP server, port, username and password configuration to the UI.
- **Test Email** now uses the currently selected delivery method.
- Existing configuration files are merged with new defaults automatically, so upgrading does not require a configuration reset.
- SMTP credentials are read from the protected Device Monitor configuration instead of being passed on the process command line.
- Configuration containing SMTP credentials is stored with restrictive file permissions.
- Includes the v2.2 Hostwatch fixes: newest Hostwatch record is selected per MAC, deleted devices no longer return from historical records, VLAN notification filtering was corrected, and real Hostwatch `last_seen` values are preserved during quick status updates.

## v2.1 (April 2026) — Dnsmasq hostname support

1. Dnsmasq hostname resolution — `get_dnsmasq_descriptions()`
OPNsense users who migrated from the deprecated ISC DHCPv4 to Dnsmasq DNS & DHCP (the recommended replacement as of OPNsense 25.7+) had empty hostnames in Device Monitor. The previous code only read hostnames from `config.xml → dhcpd` (ISC DHCP static mappings).
A new function reads hostname data from the Dnsmasq Host Overrides section of `config.xml`. The correct XML structure for Dnsmasq entries is:
```xml
<hosts uuid="...">
  <host>MyDevice</host>          ← hostname field
  <hwaddr>aa:bb:cc:dd:ee:ff</hwaddr>  ← MAC address (note: hwaddr, NOT hw)
  <ip>192.168.1.100</ip>
  <descr>My Device Description</descr>
</hosts>
```
> ⚠️ The MAC address field is `<hwaddr>` — not `<hw>` as one might expect. This was confirmed by inspecting a live `config.xml`.
2. ISC DHCP disabled interfaces are now skipped
When an ISC DHCP interface is disabled (checkbox unchecked in the UI), OPNsense sets no `<enable>` child element inside that interface's config block. The updated `get_dhcp_descriptions()` function skips any ISC interface that lacks the `<enable>` tag, preventing stale data from disabled interfaces from appearing as hostnames.
3. Hostname source priority
Hostname resolution now follows a clear priority chain:
```
1. custom_hostname  (manually set in Device Monitor UI — highest priority)
2. Dnsmasq          (Host Overrides with MAC → hostname mapping)
3. ISC DHCP         (static mappings, hostname field preferred over descr)
```
Dnsmasq overwrites ISC data for the same MAC address via `dict.update()`:
```python
dhcp_descriptions = get_dhcp_descriptions()     # ISC DHCP (enabled interfaces only)
dnsmasq_descriptions = get_dnsmasq_descriptions()  # Dnsmasq Host Overrides
dhcp_descriptions.update(dnsmasq_descriptions)  # Dnsmasq wins on conflict
```
4. Hostname field preference within ISC DHCP
Previously, the ISC DHCP reader used only `<descr>` (the description/note field). It now prefers `<hostname>` and falls back to `<descr>` only when `<hostname>` is absent or empty. This matches how hostnames actually appear in DNS and DHCP lease tables.


## v2.0 (April 2026) — Major overhaul

This version is a complete architectural rewrite focused on deep integration with OPNsense 26.x. Many components that were previously custom-built are now replaced by native OPNsense mechanisms.

### What changed and why

**1. Service registration — `plugins.inc.d/devicemonitor.inc`**

In previous versions, the daemon was completely invisible to OPNsense. It did not appear in *System → Diagnostics → Services*, so there was no way to start/stop/restart it from the GUI.

The fix is a new file `src/etc/inc/plugins.inc.d/devicemonitor.inc` which registers the service using OPNsense's native `plugins_services()` mechanism.

```php
function devicemonitor_services()
{
    $services = [];
    $services[] = [
        'description' => gettext('Device Monitor - network device tracking'),
        'configd' => [
            'restart' => ['devicemonitor restart'],
            'start'   => ['devicemonitor start'],
            'stop'    => ['devicemonitor stop'],
        ],
        'name'    => 'devicemonitor',
        'pidfile' => '/var/run/devicemonitor.pid',
    ];
    return $services;
}
```

**2. Daemon status check — `daemon_status.sh`**

The previous approach used `service devicemonitor status` in the configd `[status]` action. On FreeBSD, this command returns exit code 1 even when the service is running normally (it returns 1 = "not managed by rc.d in the traditional sense"). Because configd type `script_output` treats any non-zero exit as an error, every status check produced `Execute error`.

The fix is a dedicated shell script that checks the pidfile directly:

```sh
#!/bin/sh
PIDFILE="/var/run/devicemonitor.pid"
if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "running"
        exit 0
    fi
    rm -f "$PIDFILE"   # stale pidfile cleanup
fi
echo "stopped"
exit 0
```

**3. `actions_devicemonitor.conf` — `|| true` on start/stop/restart**

Without `|| true`, if the daemon was already running and configd tried to start it again, `service devicemonitor start` returned a non-zero exit code (daemon already running), which configd interpreted as an error and showed `Error (1)`. Adding `|| true` ensures configd always sees success.

The `[status]` action now calls `daemon_status.sh` instead of `service devicemonitor status`.

**4. `rc.d/devicemonitor` — added `procname`, fixed default**

Two fixes:
- Default changed from `"YES"` to `"NO"` — FreeBSD convention: the script itself must default to disabled; activation is done by `/etc/rc.conf.d/devicemonitor`
- Added `procname="/usr/local/bin/python3"` — without this, `rc.d` cannot find the running process and every `start` creates a new zombie process.

**5. `service.xml` — fixed tag name, added `<pidfile>`, fixed `<commands>`**

Three bugs in one file:
- `<n>DeviceMonitor</n>` → `<name>DeviceMonitor</name>` — OPNsense did not recognize the `<n>` tag
- Added `<pidfile>/var/run/devicemonitor.pid</pidfile>` — needed for the green/red status dot
- `<commands>` changed from shell commands (`service devicemonitor start`) to configd action names (`devicemonitor start`)

**6. `ServiceController.php` — start/stop/restart via `configdRun()`**

Previously, the PHP API controller called `exec('service devicemonitor start')` directly. This bypasses OPNsense's privilege model. All service control now goes through `$backend->configdRun('devicemonitor start')`.

**7. Dashboard widget — fixed detached DOM issue**

The widget's `onWidgetTick()` method was updating `this.$container.find('.dm-total')`. However, OPNsense's widget framework copies the markup into the DOM rather than inserting the original jQuery object, so `this.$container` pointed to a detached element — `.find()` worked silently but changes were never visible on screen.

Fixed by giving each element a unique `id` and selecting directly from the document:

```javascript
// Before (broken — updates detached element)
this.$container.find('.dm-total').text(stats.total);

// After (correct — selects from live DOM)
$('#dm-total').text(stats.total);
```

Also fixed: the widget was calling `/api/devicemonitor/service/status` for device counts (which returns daemon status, not stats). It now correctly calls `/api/devicemonitor/devices/stats`.

**8. `install.sh` — complete rewrite**

Key changes:
- Zombie process cleanup before daemon start (`pkill -f monitor_daemon.py`)
- Daemon started via `configctl devicemonitor start` instead of `service devicemonitor start`
- Daemon verified via pidfile + `kill -0` instead of `service devicemonitor status`
- Removed broken `service php-fpm restart` and `configctl webgui restart` calls
- Added `plugins.inc.d/devicemonitor.inc` installation step
- Fixed step numbering (was `[6/11]` followed by `[6/10]`)

**9. `uninstall.sh` — fixed daemon stop**

Previously used `service devicemonitor status` which returned exit 1, causing the stop to fail. Now uses `pkill -f monitor_daemon.py` which always works regardless of pidfile state.

Also removed broken `configctl webgui restart` and `service php-fpm restart` calls — these are either not available or unnecessary on OPNsense 26.x.

---

## v1.x (January 2026)

- **OPNsense 26.x compatibility fix:** Removed `$this->sessionClose()` calls from controllers. This function was removed in OPNsense 26.0 and caused crashes when called. Added automatic version detection to maintain backward compatibility with 25.x.
