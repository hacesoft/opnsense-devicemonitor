# Configuration and usage

[Project overview](../../README.md) · [Česky](../cz/02_NASTAVENI_A_POUZITI.md)

## Configuration

Go to: **Services → DeviceMonitor → Settings**

### Basic

| Setting | Description |
|---------|-------------|
| Enable Device Monitor | Enable/disable scanning |
| Scan Interval | How often to scan (5–30 minutes) |

### Email notifications

Device Monitor offers two independent email delivery methods:

- **Local Sendmail / Postfix** — the default and backward-compatible method. It uses `/usr/local/sbin/sendmail`, so a working local mail transport such as the OPNsense `os-postfix` plugin must be configured.
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
| Test Email | Save the current settings and test the selected delivery method |

Existing installations continue to use **Local Sendmail / Postfix** after upgrading unless Direct SMTP is explicitly selected.

### Webhook notifications

| Setting | Description |
|---------|-------------|
| Enable Webhook | Enable webhook notifications |
| Webhook URL | Target URL |
| Test Webhook | Send a test payload |

**Supported webhook types:**

- **ntfy.sh** — `https://ntfy.sh/yourSecretTopic`
- **Discord** — `https://discord.com/api/webhooks/...`
- **Generic** — any HTTP POST endpoint receiving JSON

## Usage

### Lobby dashboard widget

After installation, add the **Device Monitor** widget to the Lobby dashboard. It shows:
- Daemon status (Running / Stopped)
- Total device count
- Online device count

### Device list

**Services → DeviceMonitor → Devices**

Columns: MAC, Vendor, IP, Hostname, First Seen, Last Seen, Actions

Device names follow this priority: a name set manually in Device Monitor, Dnsmasq Host Overrides, Kea DHCPv4 reservations, then ISC DHCP static mappings. In a Kea reservation the hostname takes precedence over the description. The reservation is matched by MAC address.

The periodic scan uses the time last seen in Hostwatch. **Check online** runs a separate reachability check. Its result may be superseded by the next scan.

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
