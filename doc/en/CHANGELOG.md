# Version history

[Project overview](../../README.md) · [Česky](../cz/HISTORIE_VERZI.md)

## v2.4.16

- Validate Hostwatch observations, API input and saved configuration before use.
- Reorganize the user guide and administrator reference.

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

- Added **Recent firewall traffic** as an opt-in column using native OPNsense PF statistics.
- Added English and Czech guidance on enabling the column, firmware requirements, and the limits of passive monitoring.

## v2.3.5

- Last Seen and Manual ping use the same date and time format in the browser’s local time zone. Last Seen is sorted chronologically and uses local time in CSV exports.

## v2.3.4

- Hostwatch status text is green for devices seen in the last 15 minutes and red for other devices.

## v2.3.3

- Select the webhook format independently of the URL, including ntfy on a custom domain (#8).
- Show Hostwatch activity separately from the timestamped manual ping result. Manual pings no longer change automatic status (#10).

## v2.3.2

- Install and uninstall messages are now in English.
- The installer now finds its bundled uninstaller during upgrades and stops if that uninstaller reports failure.

## v2.3.1

- Fix the documented direct download link for the previously published ZIP (#6).
- Install translation catalogs in the standard OPNsense locale directories and localize configuration validation messages (#5, #7).
- Read hostnames and descriptions from Kea DHCPv4 reservations, based on the contribution by ptrsmk (PR #11).
- Render device names as plain text in the device table.

## v2.3

- Added Direct SMTP, a delivery method selector and test email using the selected method.
- Improved VLAN filtering and handling of newly detected or manually deleted devices.

## v2.1

- Added names from Dnsmasq Host Overrides and updated hostname source priority.

## v2.0

- Integrated the service with OPNsense 26.x and revised service controls, installation and the dashboard widget.

## v1.x

- Compatibility fixes for OPNsense 26.x.
