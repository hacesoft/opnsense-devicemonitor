# OPNsense Device Monitor

**[🇨🇿 Czech version](README_CZ.md)** | **[👨‍💻 More projects by the author](https://github.com/hacesoft?tab=repositories)**

---

Plugin for automatic network device monitoring in OPNsense firewall. Detects new devices using ARP scanning and sends email or webhook notifications about new devices on the network.

---

## 📋 Table of Contents

- [What the plugin does](#what-the-plugin-does)
- [Features](#features)
- [Installation](#installation)
  - [Method 1: WinSCP + Manual installation](#method-1-winscp--manual-installation-recommended)
  - [Method 2: Direct SSH installation](#method-2-direct-ssh-installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Plugin structure](#plugin-structure)
- [Troubleshooting](#troubleshooting)
- [Versioning](#versioning)
- [Uninstallation](#uninstallation)

---

## What the plugin does

The plugin automatically monitors the network and alerts you about:

- 🆕 **New devices** connecting to the network
- 📊 **Device history** with first/last detection timestamps
- 📧 **Email notifications** with professional HTML design
- 🔔 **Webhook notifications** (ntfy.sh, Discord, custom)

---

## Features

### 🎯 **Core features**

✅ **Automatic ARP scanning** - device detection every 5-30 minutes  
✅ **Email notifications** - beautiful HTML emails with professional design  
✅ **Webhook notifications** - support for ntfy.sh, Discord, and custom webhooks  
✅ **Device history** - tracking first and last detection  
✅ **Vendor lookup** - automatic manufacturer detection from MAC address

### 📧 **Notifications**

✅ **Beautiful HTML emails** - professional design with inline CSS (works everywhere!)  
✅ **Test buttons** - verify emails and webhooks directly from GUI  
✅ **Detailed logging** - track success/failure of sending  
✅ **Webhook support**:
  - **ntfy.sh** - simple notification server
  - **Discord** - webhooks to Discord channels
  - **Generic** - any HTTP webhook endpoint

### 🖥️ **Web interface**

✅ **Dashboard** - statistics overview, manual scan trigger  
✅ **Device management** - delete individual devices or entire database  
✅ **Configurable intervals** - scanning every 5, 10, 15 or 30 minutes  
✅ **Responsive design** - works on mobile and tablet  

### 📊 **Technical features**

✅ **SQLite database** - fast storage and search  
✅ **Vendor lookup** - automatic manufacturer detection from MAC address (IEEE OUI database)  
✅ **Daemon process** - runs in background as system service  
✅ **Logging** - detailed logs in `/var/log/devicemonitor.log`  

### 🚀 **Planned features (future versions)**

🔜 **VLAN filtering** - monitoring only selected network segments  
🔜 **GUI for logs** - viewing logs directly from web interface  
🔜 **IP address history** - tracking IP changes for each device  

---

## Installation

### Requirements

- **OPNsense 24.x or newer**
- **SSH access enabled** (System → Settings → Administration → Secure Shell)
- **Admin account** with CLI access (via PuTTY, Terminal, etc.)
- **Working SMTP configuration** (System → Settings → Notifications) - **required for plugin operation**

**Note:** The plugin requires working SMTP for sending notifications. Without SMTP configuration, the plugin will not work correctly.

---

### Method 1: WinSCP + Manual installation (Recommended)

This method is easiest for users not familiar with command line.

#### Step 1: Download the latest version

Go to [**Releases**](../../releases) and download the latest archive:

```
opnsense-devicemonitor31122025_1339.zip
```

**Filename format:**
- `opnsense-devicemonitor` = plugin name
- `31122025` = date (DD.MM.YYYY)
- `1339` = time (HH:MM)
- `.zip` = archive format

**Example:** `opnsense-devicemonitor31122025_1254.zip` = December 31, 2025 at 13:39

**Note:** Older versions can be found in the `/old/` folder in releases.

#### Step 2: Enable SSH on OPNsense

```
1. Log in to OPNsense web interface (as admin)
2. Go to: System → Settings → Administration
3. Enable "Secure Shell"
4. Check "Permit root user login" (or use admin account)
5. Login Shell: /bin/csh (default is OK)
6. Save
```

**Note:** You can log in as either `root` or `admin` - both have full permissions for installation.

#### Step 3: Upload file via WinSCP

**Download WinSCP:** https://winscp.net/

**Connect to OPNsense:**
```
Host:     your.opnsense.ip.address
Port:     22
Username: root (or admin)
Password: your-password
```

**Note:** Use either `root` or `admin` account - both work.

**Upload procedure:**
1. In WinSCP, navigate to `/tmp/`
2. Drag and drop `opnsense-devicemonitor31122025_1254.zip` into the window

#### Step 4: Installation via SSH

Use PuTTY (Windows) or Terminal (Mac/Linux) to connect:

```bash
ssh root@your.opnsense.ip
```

Then run:

```bash
# Navigate to the folder with the archive
cd /tmp

# Extract archive
unzip opnsense-devicemonitor31122025_1254.zip
cd opnsense-devicemonitor

# Run installation
sh install.sh
```

**Note:** OPNsense restart is **NOT needed** - the installation script handles everything!

---

### Method 2: Direct SSH installation

For advanced users familiar with command line:

```bash
# Connect via SSH
ssh root@your.opnsense.ip

# Download latest version (UPDATE URL!)
cd /tmp
fetch https://github.com/hacesoft/opnsense-devicemonitor/releases/download/v31122025_1254/opnsense-devicemonitor31122025_1254.zip

# Extract
unzip opnsense-devicemonitor31122025_1254.zip
cd opnsense-devicemonitor

# Install
sh install.sh
```

**For older versions:**

If you want to install an older version, modify the URL:

```bash
fetch https://github.com/hacesoft/opnsense-devicemonitor/releases/download/old/opnsense-devicemonitorDDMMYYYY_HHMM.zip
```

---

## Configuration

After installation, go to: **Services → DeviceMonitor → Settings**

### Basic configuration

| Setting | Description | Example |
|---------|-------------|---------|
| **Enable Device Monitor** | Enable/disable monitoring | ✅ Checked |
| **Scan Interval** | How often to scan | `5 minutes` |
| **Show .local Domain** | Show `.local` in hostname | ❌ Unchecked |

---

### Email notifications

**⚠️ IMPORTANT:** The plugin requires working SMTP configuration! Without SMTP, notifications will not work.

**SMTP configuration:**
```
System → Settings → Notifications → E-Mail
```
Configure SMTP server, port, authentication (username/password).

| Setting | Description | Example |
|---------|-------------|---------|
| **Enable Email** | Enable email notifications | ✅ Checked |
| **Email (To)** | Your email for notifications | `admin@example.com` |
| **Email (From)** | Sender email address | `opnsense@yourdomain.com` |
| **Test Email** | Send test email | 🧪 Button |

**Email format:**
- 🎨 **Professional HTML design** with OPNsense colors
- 📱 **Responsive** - works on all devices
- 🎯 **Inline CSS** - displays correctly in Gmail, Outlook, etc.
- 📊 **Clear table** with MAC, Vendor, IP, Hostname
- 🔔 **Beautiful header** with gradient and icons

### Webhook notifications

| Setting | Description | Example |
|---------|-------------|---------|
| **Enable Webhook** | Enable webhook notifications | ✅ Checked |
| **Webhook URL** | URL for webhook | `https://ntfy.sh/mytopic` |
| **Test Webhook** | Send test webhook | 🧪 Button |

**Supported webhook types:**

#### 1. **ntfy.sh** (Recommended for beginners)
```
https://ntfy.sh/mySecretWord123
```
- ✅ Free, no registration
- ✅ Mobile app (iOS/Android)
- ✅ Web interface
- 📱 Instant push notifications on mobile

**How to set up:**
1. Think of a unique name (e.g., `mySecretWord123`)
2. URL: `https://ntfy.sh/mySecretWord123`
3. Download ntfy app: https://ntfy.sh/
4. Add topic `mySecretWord123`
5. Done! Now you'll receive notifications on your phone 📱

#### 2. **Discord**
```
https://discord.com/api/webhooks/1234567890/AbCdEfGhIjKlMnOpQrStUvWxYz
```
- ✅ Notifications to Discord channel
- ✅ Embed messages with formatting
- ✅ Ideal for teams

**How to get Discord webhook:**
1. Go to Discord server
2. Click on channel → Edit channel → Integrations → Webhooks
3. Create new webhook
4. Copy URL

#### 3. **Generic (Custom)**
Any HTTP POST endpoint:
```
https://my.domain.com/webhook
```
- ✅ Your own webhook server
- ✅ JSON payload with device data
- ✅ For advanced users

### Test configuration

**Buttons in GUI:**
- 🧪 **Test Email** - sends test email (verifies SMTP configuration)
- 🧪 **Test Webhook** - sends test webhook (verifies URL and availability)

**What is tested:**
- ✅ Configuration correctness
- ✅ SMTP server / webhook URL availability
- ✅ Message format
- ✅ Result logging

**Test result:**
- ✅ **Success** - everything works correctly
- ❌ **Failed** - check configuration (see logs)

---

## Usage

### Dashboard

**Services → DeviceMonitor → Dashboard**

**Displays:**
- 📊 **Total device count**
- 🆕 **New devices (today)**
- 🔔 **Pending notifications**
- ⏰ **Last scan**

**Actions:**
- 🔄 **Scan Now** - immediate scan trigger
- 📧 **Send Notifications** - manual notification sending

### Device list

**Services → DeviceMonitor → Devices**

**Table:**
| Column | Description |
|--------|-------------|
| **MAC** | Device MAC address (with vendor info) |
| **Vendor** | Manufacturer (from IEEE OUI database) |
| **IP** | Current IP address |
| **Hostname** | Device name (from DNS) |
| **First Seen** | First detection |
| **Last Seen** | Last activity |
| **Actions** | 🗑️ Delete device |

**Features:**
- 🔍 **Search** - filter by MAC, IP, Vendor...
- 📊 **Sorting** - click on column to sort
- 🗑️ **Deletion** - delete individual devices or all at once

### Logging

**All operations are logged to:**
```
/var/log/devicemonitor.log
```

**Log types:**
- `[DAEMON]` - daemon process (startup, scanning...)
- `[EMAIL]` - email notifications (success/error)
- `[WEBHOOK]` - webhook notifications (success/error)
- `[SCAN]` - network scanning
- `[DATABASE]` - database operations

**Example log:**
```
[2026-01-10 15:34:25] [PHP-EMAIL] Preparing email for 38 devices
[2026-01-10 15:34:26] [PHP-EMAIL] SUCCESS: Email sent (REAL mode, 38 devices)
[2026-01-10 15:35:00] [PHP-WEBHOOK] SUCCESS: Webhook sent (REAL mode, 38 devices) - HTTP 200
```

**Viewing logs:**
```bash
# Recent entries
tail -50 /var/log/devicemonitor.log

# Real-time monitoring
tail -f /var/log/devicemonitor.log

# Filter only email logs
grep EMAIL /var/log/devicemonitor.log
```

---

## Plugin structure

### Plugin files

```
/usr/local/opnsense/
├── mvc/app/
│   ├── controllers/OPNsense/DeviceMonitor/
│   │   ├── IndexController.php           # GUI pages
│   │   └── Api/
│   │       ├── ConfigController.php       # Configuration API
│   │       ├── DevicesController.php      # Devices API
│   │       ├── ServiceController.php      # Service API
│   │       ├── DashboardController.php    # Dashboard API
│   │       └── OuiController.php          # OUI database API
│   ├── models/OPNsense/DeviceMonitor/
│   │   ├── DeviceMonitor.php             # Model
│   │   ├── DeviceMonitor.xml             # Configuration
│   │   ├── defaults.json                 # Default values
│   │   ├── Menu/Menu.xml                 # Menu
│   │   └── ACL/ACL.xml                   # Permissions
│   └── views/OPNsense/DeviceMonitor/
│       ├── index.volt                    # Dashboard
│       ├── settings.volt                 # Settings
│       └── devices.volt                  # Device list
├── scripts/OPNsense/DeviceMonitor/
│   ├── monitor_daemon.py                 # Main daemon
│   ├── scan_network.py                   # Scanning script
│   ├── NotificationHandler.php           # Email/Webhook handler
│   ├── notify_email.php                  # Email CLI script
│   ├── notify_webhook.php                # Webhook CLI script
│   └── download_oui.py                   # OUI database download
├── service/conf/actions.d/
│   └── actions_devicemonitor.conf        # Configd actions
└── /var/db/devicemonitor/
    ├── devices.db                        # SQLite database
    ├── config.json                       # Runtime configuration
    └── oui.txt                           # IEEE OUI database
```

### Database structure

**devices.db (SQLite3):**
```sql
CREATE TABLE devices (
    id INTEGER PRIMARY KEY,
    mac TEXT UNIQUE NOT NULL,
    vendor TEXT,
    ip TEXT,
    hostname TEXT,
    vlan TEXT,
    first_seen TEXT,
    last_seen TEXT,
    notification_pending INTEGER DEFAULT 1
);
```

### API Endpoints

**Configuration:**
- `GET  /api/devicemonitor/config/get` - Get configuration
- `POST /api/devicemonitor/config/set` - Save configuration
- `POST /api/devicemonitor/config/testemail` - Test email
- `POST /api/devicemonitor/config/testwebhook` - Test webhook

**Devices:**
- `GET  /api/devicemonitor/devices/list` - Device list
- `POST /api/devicemonitor/devices/delete` - Delete device
- `POST /api/devicemonitor/devices/deleteall` - Delete all

**Dashboard:**
- `GET  /api/devicemonitor/dashboard/stats` - Statistics

**Service:**
- `POST /api/devicemonitor/service/start` - Start daemon
- `POST /api/devicemonitor/service/stop` - Stop daemon
- `POST /api/devicemonitor/service/restart` - Restart daemon
- `GET  /api/devicemonitor/service/status` - Daemon status
- `POST /api/devicemonitor/service/scan` - Manual scan

---

## Troubleshooting

### Plugin doesn't appear in menu

```bash
# Restart configd
service configd restart

# Restart web interface
service php-fpm restart

# Clear cache
rm -rf /tmp/templates_c/*
```

### Daemon won't start

```bash
# Check status
service devicemonitor status

# Check logs
tail -50 /var/log/devicemonitor.log

# Manual start
/usr/local/opnsense/scripts/OPNsense/DeviceMonitor/monitor_daemon.py
```

### Email notifications not working

**1. Check SMTP settings:**
```
System → Settings → Notifications
```

**2. Test email from GUI:**
```
Services → DeviceMonitor → Settings → Test Email
```

**3. Check logs:**
```bash
tail -50 /var/log/devicemonitor.log | grep EMAIL
```

**Common issues:**
- ❌ **SMTP server not available** - check firewall rules
- ❌ **Invalid email** - check email address format
- ❌ **Authentication failed** - check SMTP credentials

### Webhook notifications not working

**1. Test webhook from GUI:**
```
Services → DeviceMonitor → Settings → Test Webhook
```

**2. Check logs:**
```bash
tail -50 /var/log/devicemonitor.log | grep WEBHOOK
```

**3. Check availability:**
```bash
# Test ntfy.sh
curl -d "test" https://ntfy.sh/mySecretWord123

# Test Discord (UPDATE URL!)
curl -X POST -H "Content-Type: application/json" \
     -d '{"content": "test"}' \
     https://discord.com/api/webhooks/YOUR_WEBHOOK_URL
```

**Common issues:**
- ❌ **URL not available** - check firewall, internet connection
- ❌ **Invalid URL format** - check it starts with `https://`
- ❌ **Discord webhook expired** - create a new one

---

### Devices not being detected

**1. Manual scan test:**
```bash
/usr/local/opnsense/scripts/OPNsense/DeviceMonitor/scan_network.py
```

**2. Check ARP table:**
```bash
arp -an
```

**3. Check logs:**
```bash
tail -50 /var/log/devicemonitor.log | grep SCAN
```

**4. Check that daemon is running:**
```bash
service devicemonitor status
```

---

### Database is corrupted

```bash
# Backup current database
cp /var/db/devicemonitor/devices.db /var/db/devicemonitor/devices.db.backup

# Delete corrupted database
rm /var/db/devicemonitor/devices.db

# Restart daemon (will create new one)
service devicemonitor restart
```

---

### High CPU load

**Increase scan interval:**
```
Services → DeviceMonitor → Settings → Scan Interval
```
Set to 15 or 30 minutes instead of 5.

---

## Versioning

**Version format:**
```
DDMMYYYY_HHMM
```

**Example:**
- `31122025_1339` = December 31, 2025, 13:39
- `01012026_0900` = January 1, 2026, 09:00

**Where to find version:**
```bash
# In GUI
Services → DeviceMonitor → Settings (in footer)

# In files
head -10 /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/monitor_daemon.py
```

---

## Uninstallation

### Method 1: Uninstall script (Recommended)

```bash
ssh root@opnsense

cd /tmp
# Download plugin (or use existing)
unzip opnsense-devicemonitor*.zip
cd opnsense-devicemonitor

# Run uninstall
sh uninstall.sh
```

### Method 2: Manual uninstallation

```bash
# Stop daemon
service devicemonitor stop

# Delete files
rm -rf /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor
rm -rf /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor
rm -rf /usr/local/opnsense/mvc/app/views/OPNsense/DeviceMonitor
rm -rf /usr/local/opnsense/scripts/OPNsense/DeviceMonitor
rm -f /usr/local/opnsense/service/conf/actions.d/actions_devicemonitor.conf
rm -f /etc/rc.d/devicemonitor

# Delete data (OPTIONAL - you'll lose database!)
rm -rf /var/db/devicemonitor
rm -f /var/log/devicemonitor.log

# Restart services
service configd restart
service php-fpm restart
```

**Note:** After uninstallation, the plugin will disappear from the menu. You may need to clear browser cache (Ctrl+Shift+R).

---

## Support

**GitHub Issues:**
https://github.com/hacesoft/opnsense-devicemonitor/issues

**Author:**
- GitHub: [@hacesoft](https://github.com/hacesoft)
- Web: [hacesoft.cz](https://hacesoft.cz)

---

## License

MIT License - see [LICENSE](LICENSE) file

---

**🎉 Done! Enjoy automatic device monitoring in OPNsense!**