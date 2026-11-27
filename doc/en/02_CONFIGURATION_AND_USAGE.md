# Configuration and usage

[Project overview](../../README.md) · [Česky](../cz/02_NASTAVENI_A_POUZITI.md)

## First run

1. Open **Services → Device Monitor → Settings**.
2. In **Other Settings**, turn on **Enable Monitoring**. The service periodically reads the Hostwatch database. The default interval is **300 seconds**, with a supported range of **60–3600 seconds**.
3. Configure email or webhooks if needed. A fresh installation starts with notifications off.
4. Click **Apply** and open **Device Monitor → Devices**. Use the magnifying glass in the device list if you want to refresh from Hostwatch immediately.

The **Show setting help** switch above the tabs explains each field. The browser remembers the setting. **Apply** saves settings from all tabs.

## Device list

| Field | What it means |
|-------|---------------|
| **Device activity** | Green means Hostwatch observed the device or the firewall packet counter increased in the last 15 minutes. The label shows the source. Red means neither available source recorded recent activity. A quiet device can still be connected. |
| **Last Seen** | The last Hostwatch observation in the browser’s local time. It can be older in a green row whose activity came from the firewall. |
| **Manual ping** | Requests a one-time ICMP reply. The result stays visible while the page remains open. |
| **Known device** | The star is saved for that MAC address. Use it to flag devices you recognize. A MAC address alone does not authenticate a device. |

Filter the list by VLAN, activity or known-device status. **Columns** controls what the current browser displays. CSV export uses the current filters and its own set of columns. On mobile, scroll the table horizontally.

Click a device’s hostname to edit it. A manual name takes priority over names from Dnsmasq, Kea DHCPv4 and ISC DHCP. For unnamed devices the plugin attempts a reverse DNS lookup.

The **Device Monitor** Lobby widget shows service status, the total device count and the count active in the last 15 minutes. It uses the same Hostwatch and firewall activity rules as the Devices table. Each device counts once.

### Recent firewall traffic

Find this option under **Other Settings**. It is off by default. When enabled, the service passively reads existing firewall counters about every 30 seconds. The account needs permission to access **Firewall Sessions** diagnostics.

The service keeps counting with the browser closed. After 15 minutes without an increase, that device’s count resets. The timer above the table shows the time until the service’s shared review. Each device’s own 15-minute window starts at its last increase.

Traffic switched within a VLAN can bypass the firewall. A quiet device may still respond to a manual ping. Firewall counters can include packets sent to an IP address.

## Email notifications

In **Email Notifications**, enable email and enter the recipient and an allowed sender address. Choose a delivery method:

- **Direct SMTP** connects to your mail server. Enter the server, port and encryption required by your provider. Enter credentials if the server requires them.
- **Local Sendmail / Postfix** uses the local mail service configured on OPNsense.

**Test Email** saves the current settings and sends a message immediately. The saved password is hidden. Leave the field blank to keep it, enter a new value to replace it, or use the removal checkbox below the field.

### Summary emails

| Mode | When the message is sent |
|------|--------------------------|
| **Wait for a pause, with a maximum** (default) | Each discovery restarts the wait. The default wait is **15 s** and the maximum from the first discovery is **45 s**. |
| **Wait for a pause, without a maximum** | The message is sent after the configured pause following the last discovery. A continuous series can keep delaying delivery. |

A wait of **0 s** sends a group from one refresh immediately. Timing starts when Device Monitor reads a discovery from Hostwatch. To group two refreshes 300 seconds apart, for example, set the wait to 310 seconds and use a maximum of 650 seconds in bounded mode.

## Webhooks and ntfy

In **Webhook Notifications**, enable webhooks and enter the destination URL. Choose **ntfy**, **Discord**, **Generic JSON** or **Automatic**. Select **ntfy** explicitly when using a custom ntfy server.

In the **ntfy Android app**, subscribe to the topic in the URL, for example `https://push.example.com/my-topic`. **Send Test** uses the current format and the entered or saved URL. Click **Apply** to save settings.

Enter the final URL. Webhooks do not follow redirects. For HTTPS, OPNsense must trust the server’s certificate. The saved URL works like the SMTP password field. Disable the webhook before removing its URL.

### Interfaces and delivery

Email and webhooks use separate **Notify for interfaces** filters. An empty selection includes all interfaces. Each message covers up to **100 devices**. Larger groups are split. ntfy lists the first five devices in each message and reports the remaining count.

Pending notifications survive service restarts. After a failure, the service retries in about one minute. Turning off a notification channel clears its pending queue.

## Privileges and help

Use the [administrator privilege reference](04_TECHNICAL_REFERENCE.md) to delegate access. If the list stays empty or notifications do not arrive, see [troubleshooting](03_TROUBLESHOOTING.md).
