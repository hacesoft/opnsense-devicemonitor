# OPNsense Device Monitor

**[🇨🇿 Česká verze](README_CZ.md)** | **[👨‍💻 Author's Projects](https://github.com/hacesoft?tab=repositories)**

---

Automatic network device monitoring plugin for OPNsense firewall. Detects new devices via ARP scanning and sends email notifications.

![License](https://img.shields.io/badge/license-BSD--2--Clause-green) ![OPNsense](https://img.shields.io/badge/OPNsense-24.x-orange)

---

## 📋 Table of Contents

- [What It Does](#what-it-does)
- [Features](#features)
- [Installation](#installation)
  - [Method 1: WinSCP + Manual Install](#method-1-winscp--manual-install-recommended)
  - [Method 2: Direct SSH Install](#method-2-direct-ssh-install)
- [Configuration](#configuration)
- [Usage](#usage)
- [Plugin Structure](#plugin-structure)
- [Troubleshooting](#troubleshooting)
- [Versioning](#versioning)
- [Uninstallation](#uninstallation)

---

## What It Does

This plugin automatically monitors your network and notifies you about:

- 🆕 **New devices** connecting to your network
- 🔄 **IP address changes** of existing devices
- 📊 **Device history** with first/last seen timestamps
- 🌐 **VLAN filtering** - monitor only specific network segments

---

## Features

✅ **Automatic ARP scanning** - detects devices every 5-30 minutes  
✅ **Email notifications** - instant alerts for new devices and IP changes  
✅ **VLAN filtering** - monitor only selected VLANs (e.g., LAN, VLAN20, VLAN50)  
✅ **IP history tracking** - multiple IP addresses per MAC address  
✅ **Web dashboard** - view statistics, run manual scans  
✅ **Device management** - delete individual devices or clear entire database  
✅ **Configurable intervals** - scan every 5, 10, 15, or 30 minutes  
✅ **Test email button** - verify SMTP configuration  

---

## Installation

### Requirements

- OPNsense 24.x or newer
- Working SMTP configuration (System → Settings → Notifications)
- SSH access enabled (System → Settings → Administration → Secure Shell)
- Root password

---

### Method 1: WinSCP + Manual Install (Recommended)

This method is easiest for users not familiar with command line.

#### Step 1: Download Latest Version

Go to [**Releases**](../../releases) and download the latest archive:

```
opnsense-devicemonitor31122025_1254.zip
```

**File naming:**
- `opnsense-devicemonitor` = plugin name
- `31122025` = date (DD.MM.YYYY)
- `1254` = time (HH:MM)
- `.zip` = archive format

**Example:** `opnsense-devicemonitor31122025_1254.zip` = December 31, 2025 at 12:54

**Note:** Older versions can be found in `/old/` folder in releases.

#### Step 2: Enable SSH on OPNsense

```
1. Login to OPNsense web interface
2. Go to: System → Settings → Administration
3. Enable "Secure Shell"
4. Check "Permit root user login"
5. Login Shell: /bin/csh (default is OK)
6. Save
```

#### Step 3: Upload File via WinSCP

**Download WinSCP:** https://winscp.net/

**Connect to OPNsense:**
```
Host:     your.opnsense.ip.address
Port:     22
User:     root
Password: your-root-password
```

**Upload steps:**
1. In WinSCP, navigate to `/tmp/`
2. Drag & drop `opnsense-devicemonitor31122025_1254.zip` into the window

#### Step 4: Install via SSH

Use PuTTY (Windows) or Terminal (Mac/Linux) to connect:

```bash
ssh root@your.opnsense.ip
```

Then run:

```bash
# Navigate to archive location
cd /tmp

# Extract archive
unzip opnsense-devicemonitor31122025_1254.zip
cd opnsense-devicemonitor

# Run installation
sh install.sh
```

**Note:** OPNsense restart is **NOT required** - installation script handles everything!

---

### Method 2: Direct SSH Install

For advanced users comfortable with command line:

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

To install an older version, modify URL:

```bash
fetch https://github.com/hacesoft/opnsense-devicemonitor/releases/download/old/opnsense-devicemonitorDDMMYYYY_HHMM.zip
```

---

## Configuration

After installation, navigate to: **Services → DeviceMonitor → Settings**

### Basic Configuration

| Setting | Description | Example |
|---------|-------------|---------|
| **Enable Device Monitor** | Turn monitoring on/off | ✅ Checked |
| **Email (To)** | Your email for alerts | `admin@example.com` |
| **Email (From)** | Sender address | `opnsense@yourdomain.com` |
| **Scan Interval** | How often to scan | `5 minutes` |
| **VLAN Filter** | Which VLANs to monitor | `LAN,VLAN20,VLAN50` |

### VLAN Filter Examples

**Monitor all networks:**
```
LAN,VLAN11,VLAN20,VLAN30,VLAN50,VLAN70,VLAN80
```

**Monitor only LAN and guest network:**
```
LAN,VLAN50
```

**Monitor single VLAN:**
```
VLAN20
```

**Important:** VLAN names must match your interface names exactly!

### Test Configuration

1. Click **Test Email** button
2. Check your inbox
3. If email doesn't arrive:
   - Verify SMTP settings: System → Settings → Notifications
   - Check spam folder
   - Review logs: `grep devicemonitor /var/log/system.log`

---

## Usage

### Dashboard

**Location:** Services → DeviceMonitor → Dashboard

**Shows:**
- 📊 Total Devices - all devices ever seen
- 🆕 New Today - devices detected today
- ⏰ Last Cron Run - timestamp of last automatic scan
- 🔄 Scan Now - manual scan button
- 📋 View All Devices - link to device list

### Device List

**Location:** Services → DeviceMonitor → Devices

**Table columns:**
- MAC Address
- IP Address
- Hostname (resolved via reverse DNS)
- VLAN (network segment)
- First Seen (first detection date/time)
- Last Seen (most recent detection)
- Actions (delete icon)

**Operations:**
- ☑️ **Select multiple** - checkbox on left
- 🗑️ **Delete Selected** - remove checked devices
- 🗑️ **Individual delete** - trash icon per device

### Settings Page

**Location:** Services → DeviceMonitor → Settings

**Actions:**
- 💾 **Save** - store configuration
- ✉️ **Test Email** - verify SMTP works
- ⚠️ **Clear Database** - delete ALL device records (confirmation required)

---

## Plugin Structure

### Directory Structure

```
opnsense-devicemonitor/
├── install.sh                          # Installation script
├── uninstall.sh                        # Uninstallation script
├── README.md                           # Documentation (EN)
├── README_CZ.md                        # Documentation (CZ)
├── LICENSE                             # BSD 2-Clause license
├── +MANIFEST                           # PKG metadata
├── +INSTALL                            # Post-install hook
├── +DEINSTALL                          # Post-uninstall hook
├── etc/
│   └── inc/
│       └── plugins.inc.d/
│           └── devicemonitor.inc       # Plugin hook
└── usr/
    └── local/
        └── opnsense/
            ├── mvc/app/
            │   ├── controllers/
            │   │   └── OPNsense/DeviceMonitor/
            │   │       ├── IndexController.php       # Main controller
            │   │       ├── Api/
            │   │       │   ├── SettingsController.php   # Settings API
            │   │       │   ├── DevicesController.php    # Devices API
            │   │       │   └── ServiceController.php    # Service API
            │   │       └── forms/
            │   │           └── general.xml              # Form definition
            │   ├── models/
            │   │   └── OPNsense/DeviceMonitor/
            │   │       ├── DeviceMonitor.xml         # Model XML
            │   │       ├── DeviceMonitor.php         # Model PHP
            │   │       ├── Menu/
            │   │       │   └── Menu.xml              # Menu definition
            │   │       └── ACL/
            │   │           └── ACL.xml               # ACL definition
            │   └── views/
            │       └── OPNsense/DeviceMonitor/
            │           ├── index.volt                # Dashboard view
            │           ├── devices.volt              # Devices view
            │           └── settings.volt             # Settings view
            ├── scripts/devicemonitor/
            │   ├── scan.sh                           # ARP scanner script
            │   └── testemail.sh                      # Test email script
            └── service/conf/actions.d/
                └── actions_devicemonitor.conf        # Configd actions
```

### Database and Logs

```
/var/db/known_devices.db                # SQLite device database
/var/log/devicemonitor_cron.log         # Cron run log
```

### Database Format

**File:** `/var/db/known_devices.db`

**Format:** Pipe-separated values (|)

```
MAC|IP|Hostname|FirstSeen|LastSeen|Source|Interface|VLAN
```

**Example entry:**
```
aa:bb:cc:dd:ee:ff|192.168.1.100|PC-John|2025-11-30 10:15:23|2025-12-01 08:45:12|ARP|igc0|LAN
```

---

## How It Works

### Technical Overview

1. **Cron Job**: OPNsense cron runs scan script every X minutes (configured interval)
2. **ARP Scan**: Script executes `arp -an` to get current devices
3. **VLAN Filtering**: Only devices on allowed VLANs are processed
4. **Database Check**: Compares current devices with stored database
5. **Email Alerts**: Sends notification for:
   - New MAC address detected
   - Existing MAC with different IP address
6. **Database Update**: Records device information to SQLite database
7. **Logging**: Writes timestamp to `/var/log/devicemonitor_cron.log`

### Manual Commands

```bash
# Test email notification
configctl devicemonitor testemail

# Run manual scan
configctl devicemonitor scan

# View raw database
cat /var/db/known_devices.db

# Check last cron execution
cat /var/log/devicemonitor_cron.log

# View plugin logs
grep devicemonitor /var/log/system.log | tail -20
```

---

## Troubleshooting

### Menu Not Appearing After Install

**Symptoms:** Can't find "DeviceMonitor" in Services menu

**Solution 1 - Clear cache:**
```bash
rm -f /tmp/opnsense_menu_cache.xml
rm -f /tmp/opnsense_acl_cache.json
configctl webgui restart
```

**Solution 2 - Restart OPNsense:**
```bash
shutdown -r now
```

---

### Settings Page Empty

**Symptoms:** Settings page shows only buttons, no form fields

**Diagnosis:**
```bash
# Check if forms file exists
ls -la /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/forms/general.xml
```

**Solution:**
```bash
# Restart webgui
configctl webgui restart

# If still broken, reinstall plugin
cd /tmp/opnsense-devicemonitor
sh install.sh
```

---

### Emails Not Sending

**Check SMTP configuration:**
1. System → Settings → Notifications
2. Test using OPNsense built-in test: System → Settings → Notifications → Test
3. If OPNsense test fails, fix SMTP settings first

**Check plugin configuration:**
1. Services → DeviceMonitor → Settings
2. Click "Test Email"
3. Check email address is correct

**Check logs:**
```bash
# View plugin logs
grep devicemonitor /var/log/system.log

# View SMTP logs
grep sendmail /var/log/maillog
```

---

### Devices Not Being Detected

**Check scan is running:**
```bash
# View last cron run time
cat /var/log/devicemonitor_cron.log

# Should show recent timestamp like: 2025-12-01 14:30:15
```

**Check VLAN filter:**
- Ensure VLAN names match your interfaces exactly
- Case sensitive: `VLAN20` ≠ `vlan20`
- Check interface names: Interfaces → Assignments

**Run manual scan:**
```bash
# Should output device detections
configctl devicemonitor scan
```

---

### Installation Script Fails

**Error: "Command not found" or "not found" messages**

**Cause:** Windows line endings (CRLF) in script files

**Solution:**
```bash
cd /tmp/opnsense-devicemonitor
sed -i '' 's/\r$//' install.sh
sed -i '' 's/\r$//' uninstall.sh
sh install.sh
```

---

## Versioning

### Release Naming Convention

**Archive format:**
```
opnsense-devicemonitorDDMMYYYY_HHMM.zip
```

Where:
- `DD` = Day (01-31)
- `MM` = Month (01-12)
- `YYYY` = Year (4 digits)
- `HH` = Hour (00-23, 24-hour format)
- `MM` = Minutes (00-59)

**Examples:**
- `opnsense-devicemonitor31122025_1254.zip` = December 31, 2025 at 12:54 PM
- `opnsense-devicemonitor15012026_0920.zip` = January 15, 2026 at 9:20 AM

### Version Organization

**Current version:**
- Latest release is always on main [Releases](../../releases) page
- Full archive contains entire plugin ready to install

**Old versions:**
- Previous releases moved to `/old/` folder
- Available for rollback if needed
- Named with same timestamp format

### Changes from Previous Version

**Version 31122025_1254:**
- First public release
- Complete PKG structure
- Documentation in Czech and English

---

## Uninstallation

### Remove Plugin

```bash
# Navigate to installation directory
cd /tmp/opnsense-devicemonitor

# Run uninstall script
sh uninstall.sh
```

**What gets removed:**
- All plugin files from `/usr/local/opnsense/`
- Plugin hook from `/etc/inc/plugins.inc.d/`
- Cron jobs
- Menu cache

**What is preserved:**
- Database: `/var/db/known_devices.db`
- Logs: `/var/log/devicemonitor_cron.log`

### Complete Removal

To also remove database and logs:

```bash
rm -f /var/db/known_devices.db
rm -f /var/log/devicemonitor_cron.log
```

---

## Support

### Get Help

- 🐛 **Bug Reports:** [GitHub Issues](../../issues/new)
- 💬 **Questions:** [GitHub Discussions](../../discussions)
- 📧 **Email:** hacesoft@mujmail.cz

---

## License

BSD 2-Clause License - see [LICENSE](LICENSE) file

---

## Author

**Hacesoft**

- 🌐 Website: [hacesoft.cz](https://hacesoft.cz)
- 📧 Email: hacesoft@mujmail.cz
- 💻 GitHub: [@hacesoft](https://github.com/hacesoft)
- 📦 **All Projects:** [github.com/hacesoft?tab=repositories](https://github.com/hacesoft?tab=repositories)

---

**[⬆ Back to top](#opnsense-device-monitor)**
