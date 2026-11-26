# Configuration and usage

[Project overview](../../README.md) · [Česky](../cz/02_NASTAVENI_A_POUZITI.md)

## Configuration

Go to: **Services → DeviceMonitor → Settings**

The **Show setting help** switch above the tabs reveals field descriptions, expected values, and button behavior. Help is off by default. The switch takes effect immediately, and the browser remembers it for this OPNsense address. **Apply** saves the settings from all tabs.

The plugin checks setting types, ranges, the SMTP server and interface lists when saving. Invalid updates leave the current settings file intact.

### Management access and secrets

In **System → Access → Users** or **Groups**, use **Services: Device Monitor (read only)** for the device list and export, or **Services: Device Monitor (manage)** for device edits, settings, manual ping, tests, and service controls. On upgrade, the existing privilege becomes read-only. OPNsense accounts with full access can still manage the plugin.

The saved SMTP password and webhook URL are hidden from both the form and API responses. Leave a field empty to retain its saved value, enter a value to replace it, or select the corresponding removal option. Disable the webhook before removing its URL. A test can use the saved URL and the current format.

Webhooks accept HTTP or HTTPS. HTTPS requires a trusted certificate and a matching server name. For a private ntfy server or another internal destination, OPNsense must trust its certificate authority. HTTP is unencrypted. Redirects are disabled, so enter the final URL.

### Basic

| Setting | Description |
|---------|-------------|
| Enable Device Monitor | Enable or disable automatic Hostwatch monitoring |
| Hostwatch Refresh Interval | Time between reads of the Hostwatch database (60–3600 seconds) |

### Recent firewall traffic

In **Settings → Other Settings**, select **Recent firewall traffic** and apply the settings. The option is off by default. Packet counters are loaded with the device list. Your account needs permission to access the Firewall Sessions diagnostics. If the enabled column was hidden, use **Columns** to show it.

- **What it detects.** The Device Monitor service reads PF packet counters about every 30 seconds, including when the browser is closed. An observed increase turns **Traffic observed** green for 15 minutes. Hover over the status to see the time of the last increase in the browser’s local time. After 15 minutes without an observed increase, the column reports **No traffic observed in the last 15 minutes** when data is available.
- **Packet counters.** The displayed count adds up observed increases and resets after 15 minutes without an increase. The next increase starts a new count. The first positive reading establishes a baseline. A zero, missing reading or unchanged value preserves the displayed total. A lower positive reading starts a new baseline and preserves the total. After 15 minutes without a positive reading, the next positive reading also establishes a fresh baseline. Reloading or closing the page preserves the count. Restarting the service or turning off the option resets collection. The header counts down to the next shared 15-minute review on the service. It shows the same deadline after leaving and reopening the page. Hover to see when the last review ran and how many devices had observed traffic. Each device keeps its own inactivity window based on the last increase.
- **What it can miss.** PF covers traffic recorded in firewall states. Traffic switched within one VLAN can bypass the firewall, and short-lived states can disappear between readings. The expiry of one state can mask increases in other states for the same IP. Device Monitor skips IP addresses shared by multiple listed devices. Traffic involving an IP can include packets sent to that IP.
- **Silent devices.** A fully functional device can stay connected and send no packets for more than 15 minutes. In that case passive monitoring alone cannot establish reachability. Use **Manual ping** for an on-demand check if the device answers ICMP, or configure the device to send periodic telemetry if it supports that. The option adds no automatic ping or scanning. **Last Seen** and notifications use Hostwatch.

### Email notifications

#### Email batching

Under **Email Notifications**, choose an **Email batching mode** and a **Wait after the last discovery** (15 seconds by default).

- **Wait for a pause, with a maximum** is the default. New discoveries restart the wait until the maximum from the first discovery is reached (45 seconds by default).
- **Wait for a pause, without a maximum** sends the batch once the full wait after the latest discovery has elapsed. Each discovery restarts the timer, so a continuous series can keep delaying the email. Set the wait to 45 seconds to send 45 seconds after the last discovery.

The wait can be 0–3600 seconds. A wait of 0 sends one email for each discovery group as soon as the refresh detects it. In the bounded mode, the maximum must be 1–3600 seconds and at least as long as the wait. Timing starts when Device Monitor reads a discovery. To combine discoveries across refreshes, set the wait longer than the Hostwatch refresh interval. In bounded mode, the maximum must also cover that interval. The test email is sent immediately. Webhooks, including ntfy, use their own delivery path.

- **Local Sendmail / Postfix** — an optional method for existing local mail transports. It uses `/usr/local/sbin/sendmail`, so a working local mail transport such as the OPNsense `os-postfix` plugin must be configured.
- **Direct SMTP (built into Device Monitor)** — connects directly to the configured SMTP server using Python `smtplib`, without requiring Postfix or Monit for message delivery.

| Setting | Description |
|---------|-------------|
| Enable Email | Enable email notifications |
| Email (To) | Recipient address |
| Email (From) | Sender address |
| Email delivery method | Select Local Sendmail/Postfix or Direct SMTP |
| SMTP Server | SMTP hostname or IP address (Direct SMTP only) |
| SMTP Port | SMTP port, typically 587 for STARTTLS or 465 for SSL/TLS |
| Encryption | STARTTLS, SSL/TLS, or None |
| SMTP Username | Optional SMTP authentication username |
| SMTP Password | Optional SMTP authentication password |
| Notify for interfaces | Interfaces that trigger email alerts. An empty selection includes all interfaces. |
| Test Email | Save the current settings and test the selected delivery method |

New installations select **Direct SMTP** and keep email alerts disabled until you configure and enable them. Upgrades preserve saved email settings, including existing local mail delivery. To switch, enter your SMTP server and use **Test Email** to verify delivery.

Email and webhook notifications use separate persistent queues. After a delivery error, the service retries in about one minute. Each message covers up to 100 devices, so larger groups are split. The ntfy format still lists up to five items in each message and reports how many remain.

### Webhook notifications

| Setting | Description |
|---------|-------------|
| Enable Webhook | Enable webhook notifications |
| Webhook type | Automatic, ntfy, Discord or Generic JSON |
| Webhook URL | Target URL; for ntfy include the topic in the URL |
| Notify for interfaces | Interfaces that trigger webhooks. An empty selection includes all interfaces. |
| Test Webhook | Test the URL and format currently selected on the form |

#### ntfy on Android

In **Webhook type**, select **ntfy** and enter the full topic URL, for example `https://push.example.com/my-topic`. In the **ntfy Android app**, subscribe to the same topic on the same server. Click **Apply** to save the settings, then **Send Test** to check delivery. For live alerts, turn on **Enable Webhook** and ensure the device's VLAN is included if a VLAN filter is set.

Device Monitor sends an HTTP `POST` to the topic URL. The body is UTF-8 plain text. The title, tags and priority are sent as separate HTTP headers, so the Android app can display the title separately and preserve the line breaks and list in the message.

| Message | What Device Monitor sends |
|---------|---------------------------|
| Test | Title `🧪 OPNsense Test`, body `Device Monitor webhook is working! ✅`, tags `test,opnsense`, priority 3 |
| New devices | Title `🔔 OPNsense: N new device(s)`, total count, and up to five entries with MAC address, vendor and IP address. The message includes the remaining count when more devices are detected. Tags are `opnsense,network`, with priority 3 for up to three devices and priority 4 for four or more. |

If the app displays JSON containing `"event":"test"` or `"event":"new_devices"`, check that **Webhook type** is **ntfy**. **Automatic** still chooses the format based on the URL and can select **Generic JSON** on a custom domain.

The project maintainer confirmed notification formatting in the **ntfy app for Android**. The Android app version was not recorded. A separate test captured both the test and new-device HTTP requests with a local receiver and verified the plain-text body and ntfy headers.

- **ntfy.sh** — `https://ntfy.sh/yourSecretTopic`
- **Discord** — `https://discord.com/api/webhooks/...`
- **Generic** — any HTTP POST endpoint receiving JSON

## Usage

### Lobby dashboard widget

After installation, add the **Device Monitor** widget to the Lobby dashboard. It shows:
- Daemon status (Running / Stopped)
- Total device count
- Number of devices seen by Hostwatch in the last 15 minutes

### Device list

**Services → DeviceMonitor → Devices**

The table includes **Device activity**, **Last Seen**, **Manual ping**, and optionally **Recent firewall traffic**.

**Device activity** is green if Hostwatch observed the device or its PF packet counter increased in the last 15 minutes. The label lists each source that saw activity. The column turns red when neither available source shows recent activity. The filter, header summary and CSV use the same status. On mobile, scroll the table horizontally within the page. **Last Seen** shows the Hostwatch timestamp.

Device names follow this priority: a name set manually in Device Monitor, Dnsmasq Host Overrides, Kea DHCPv4 reservations, then ISC DHCP static mappings. In a Kea reservation the hostname takes precedence over the description. The reservation is matched by MAC address.

If those sources leave the name empty, the Devices page requests the IP’s PTR record through the native OPNsense reverse DNS API, as used by the OPNsense Hostwatch page since 26.7.9. OPNsense resolves the name on the firewall, so the firewall’s resolver must be able to reach the relevant reverse DNS zone. The result is shown in the table and included in its CSV export. It is held for the lifetime of the page and never saved as a manual name. Reload the page to run the lookup again. If the API is unavailable or returns no name, the field remains empty.

**Run manual ping** checks the current IP on demand. The result and time appear in **Manual ping** and remain visible through table refreshes while the page is open.

### Known devices and visible columns

Click the star in the **Known device** column to mark a device you recognize. Click it again to remove the mark. The mark follows the MAC address and is stored in the plugin database, so it is shared across browsers. When you delete the device from the list, its mark is removed with it. Use the **All devices / Known devices / Unmarked devices** filter to narrow the list. This works alongside the VLAN and device activity filters. The mark records that you recognize the device, regardless of how its IP address was assigned.

Open **Columns** to choose the fields you want to see. The selection is saved in the current browser for this OPNsense address, including after a reload. Choose **Show all columns** to reset the view. The CSV keeps its existing columns and uses the same device filters as the table.

### Service control

**System → Diagnostics → Services → devicemonitor**

Start, stop, restart the daemon directly from the GUI. The green/red status dot reflects the actual process state via pidfile.

### Logs

```bash
# Live log
tail -f /var/log/devicemonitor.log

# Filter by type
grep EMAIL /var/log/devicemonitor.log
grep WEBHOOK /var/log/devicemonitor.log
grep SCAN /var/log/devicemonitor.log
```
