# Installation Guide

This guide provides detailed installation instructions for the OPNsense Device Monitor Plugin.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation Methods](#installation-methods)
  - [Method 1: Using Makefile (Recommended)](#method-1-using-makefile-recommended)
  - [Method 2: Using install.sh Script](#method-2-using-installsh-script)
  - [Method 3: Manual Installation](#method-3-manual-installation)
- [Post-Installation](#post-installation)
- [Verification](#verification)
- [First Run](#first-run)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements

| Requirement | Specification |
|-------------|---------------|
| **Operating System** | OPNsense 24.x or newer |
| **Architecture** | amd64, arm64 |
| **Python** | 3.8+ (included in OPNsense) |
| **PHP** | 8.1+ (included in OPNsense) |
| **Disk Space** | 10 MB minimum, 50 MB recommended |
| **RAM** | 100 MB available |

### Dependencies

**Pre-installed in OPNsense:**
- Python 3.8+
- PHP 8.1+
- SQLite3
- sendmail (postfix)
- System tools: `arp`, `tcpdump`, `pfctl`, `ifconfig`

**Required Configuration:**
- SMTP server configured (System → Settings → Notifications → SMTP)
- Root SSH access (for installation)

---

## Installation Methods

### Method 1: Using Makefile (Recommended)

This is the fastest and most reliable installation method.

#### Step 1: Download Plugin

```bash
# Option A: Download from GitHub releases
wget https://github.com/yourusername/opnsense-devicemonitor/releases/latest/download/DeviceMonitor_plugin.zip

# Option B: Clone repository
git clone https://github.com/yourusername/opnsense-devicemonitor.git
cd opnsense-devicemonitor
```

#### Step 2: Extract and Navigate

```bash
# If downloaded as ZIP
unzip DeviceMonitor_plugin.zip
cd DeviceMonitor_plugin

# If cloned from git
cd opnsense-devicemonitor
```

#### Step 3: Install

```bash
# Install the plugin
make install
```

**What this does:**
- Copies MVC components to `/usr/local/opnsense/mvc/`
- Copies scripts to `/usr/local/opnsense/scripts/`
- Sets proper permissions (755 for scripts, 644 for configs)
- Creates data directory `/var/db/devicemonitor/`
- Initializes empty SQLite database
- Copies rc.d service script
- Copies configd actions
- Restarts configd

#### Step 4: Restart Web Interface

```bash
make restart-web
```

Or manually:
```bash
/usr/local/etc/rc.restart_webgui
```

#### Step 5: Start Daemon

```bash
# Using make
make start

# Or directly
service devicemonitor start
```

#### Step 6: Verify

```bash
# Check daemon status
make status

# Or directly
service devicemonitor status
```

**Expected output:**
```
devicemonitor is running as pid 12345.
```

---

### Method 2: Using install.sh Script

Alternative installation using the provided shell script.

#### Step 1: Download and Extract

```bash
wget https://github.com/yourusername/opnsense-devicemonitor/releases/latest/download/DeviceMonitor_plugin.zip
unzip DeviceMonitor_plugin.zip
cd DeviceMonitor_plugin
```

#### Step 2: Make Script Executable

```bash
chmod +x install.sh
```

#### Step 3: Run Installer

```bash
./install.sh
```

**Script output:**
```
===================================
OPNsense Device Monitor - Installer
===================================

[1/8] Checking requirements...
✓ Python 3.8+ found
✓ PHP 8.1+ found
✓ SQLite3 found

[2/8] Creating directories...
✓ Created /var/db/devicemonitor/

[3/8] Copying MVC components...
✓ Controllers copied
✓ Models copied
✓ Views copied

[4/8] Copying scripts...
✓ Scripts copied and made executable

[5/8] Copying service files...
✓ rc.d script copied
✓ configd actions copied

[6/8] Initializing database...
✓ Database created

[7/8] Restarting services...
✓ configd restarted
✓ Web GUI restarted

[8/8] Starting daemon...
✓ Daemon started

===================================
Installation completed successfully!
===================================

Access the plugin:
https://your-opnsense-ip/ui/devicemonitor

Next steps:
1. Configure SMTP (System > Settings > Notifications)
2. Configure Device Monitor (Services > DeviceMonitor > Settings)
3. Download OUI database (Services > DeviceMonitor > OUI Management)
```

#### Step 4: Verify

```bash
service devicemonitor status
```

---

### Method 3: Manual Installation

Complete manual installation steps.

#### Step 1: Create Directory Structure

```bash
mkdir -p /var/db/devicemonitor
chmod 755 /var/db/devicemonitor
```

#### Step 2: Copy MVC Components

```bash
# Controllers
cp -R src/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor \
   /usr/local/opnsense/mvc/app/controllers/OPNsense/

# Models
cp -R src/opnsense/mvc/app/models/OPNsense/DeviceMonitor \
   /usr/local/opnsense/mvc/app/models/OPNsense/

# Views
cp -R src/opnsense/mvc/app/views/OPNsense/DeviceMonitor \
   /usr/local/opnsense/mvc/app/views/OPNsense/

# Languages (optional)
cp -R src/opnsense/mvc/app/languages/*devicemonitor* \
   /usr/local/opnsense/mvc/app/languages/
```

#### Step 3: Copy Scripts

```bash
# Copy scripts
cp -R src/opnsense/scripts/OPNsense/DeviceMonitor \
   /usr/local/opnsense/scripts/OPNsense/

# Make executable
chmod +x /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/*.py
```

#### Step 4: Copy Service Files

```bash
# rc.d service script
cp src/etc/rc.d/devicemonitor /etc/rc.d/
chmod +x /etc/rc.d/devicemonitor

# configd actions
cp src/opnsense/service/conf/actions.d/actions_devicemonitor.conf \
   /usr/local/opnsense/service/conf/actions.d/
```

#### Step 5: Initialize Database

```bash
# Create empty database
touch /var/db/devicemonitor/devices.db
chmod 644 /var/db/devicemonitor/devices.db

# Initialize schema (will be done on first run)
```

#### Step 6: Restart Services

```bash
# Restart configd
service configd restart

# Restart web GUI
/usr/local/etc/rc.restart_webgui
```

Wait 30 seconds for web GUI to restart.

#### Step 7: Start Daemon

```bash
service devicemonitor start
```

#### Step 8: Verify Installation

```bash
# Check files
ls -la /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/
ls -la /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/
ls -la /var/db/devicemonitor/

# Check daemon
service devicemonitor status
ps aux | grep devicemonitor

# Check GUI
# Open browser: https://your-opnsense-ip/
# Navigate to: Services > DeviceMonitor
```

---

## Post-Installation

### 1. Configure SMTP Server

**Required for email notifications**

Navigate to: **System → Settings → Notifications → SMTP**

**Example: Gmail**
```
SMTP Host: smtp.gmail.com
Port: 587
Secure: STARTTLS
From Email: your-email@gmail.com
Authentication: Username/Password
Username: your-email@gmail.com
Password: [app-specific password]
```

**Test the connection:**
```bash
# From OPNsense shell
echo "Test" | /usr/local/sbin/sendmail -v your@email.com
```

### 2. Configure Device Monitor

Navigate to: **Services → DeviceMonitor → Settings**

**Basic Configuration:**
```
☑ Enable Monitoring
Email To: admin@example.com
Email From: devicemonitor@opnsense.local
Scan Interval: 300 (seconds)
☐ Show Domain in hostname (optional)
```

Click **Save**.

### 3. Download OUI Database

Navigate to: **Services → DeviceMonitor → OUI Management**

**Manual Download:**
1. Click "Download OUI Database"
2. Wait for completion (toast notification)
3. Verify: File size ~5 MB at `/var/db/devicemonitor/oui.txt`

**Automatic Updates (Recommended):**
```
☑ Enable Auto-Update
Update Hour: 3 (3:00 AM daily)
```

Click **Save**.

### 4. Verify Daemon

```bash
# Check daemon status
service devicemonitor status

# Check log
tail -f /var/log/system.log | grep devicemonitor
```

**Expected log output:**
```
devicemonitor: OUI database loaded: 40123 vendors
devicemonitor: Monitoring interfaces: vlan0.10, vlan0.20
devicemonitor: Scan completed. Active: 15, New: 0
```

---

## Verification

### Check Installation Files

```bash
# 1. Check MVC structure
ls -R /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/
ls -R /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/
ls -R /usr/local/opnsense/mvc/app/views/OPNsense/DeviceMonitor/

# 2. Check scripts
ls -la /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/
# Expected:
# -rwxr-xr-x monitor_daemon.py
# -rwxr-xr-x scan_network.py
# -rwxr-xr-x download_oui.py

# 3. Check service files
ls -la /etc/rc.d/devicemonitor
ls -la /usr/local/opnsense/service/conf/actions.d/actions_devicemonitor.conf

# 4. Check data directory
ls -la /var/db/devicemonitor/
# Expected:
# -rw-r--r-- devices.db
# -rw-r--r-- oui.txt (after download)
```

### Check Daemon

```bash
# 1. Status
service devicemonitor status

# 2. PID file
cat /var/run/devicemonitor.pid

# 3. Process
ps aux | grep devicemonitor | grep -v grep

# 4. Log
grep devicemonitor /var/log/system.log | tail -10
```

### Check GUI

1. Open browser: `https://your-opnsense-ip/`
2. Login to OPNsense
3. Navigate to: **Services → DeviceMonitor**
4. You should see:
   - Dashboard tab
   - Devices tab
   - Settings tab
   - OUI Management tab

### Check Database

```bash
# Open database
sqlite3 /var/db/devicemonitor/devices.db

# Show schema
.schema

# Count devices
SELECT COUNT(*) FROM devices;

# Show recent devices
SELECT mac, ip, vendor FROM devices LIMIT 5;

# Exit
.quit
```

---

## First Run

### 1. Dashboard Overview

Navigate to: **Services → DeviceMonitor → Dashboard**

You should see:
- **Total Devices**: 0 (initially)
- **Online Now**: 0
- **New Today**: 0
- Daemon status: Running

### 2. Trigger Manual Scan

Click **"Run Manual Scan"** button.

Wait 10-15 seconds for completion.

**Toast notification:**
```
✓ Manual scan completed successfully
```

### 3. View Devices

Navigate to: **Services → DeviceMonitor → Devices**

You should now see a table with detected devices:
- MAC Address
- IP Address
- Hostname
- Vendor (if OUI database is downloaded)
- VLAN
- Status (Online/Offline)
- Last Seen

### 4. Test Email Notification

Navigate to: **Services → DeviceMonitor → Settings**

Click **"Test Email"** button.

**Expected:**
- Toast notification: "Test email sent successfully"
- Email received at configured address

**Email subject:** `OPNsense Device Monitor - Test Email`

---

## Troubleshooting

### Installation Issues

#### Issue: "Permission denied" during installation

**Solution:**
```bash
# Ensure you're root
whoami  # Should output: root

# If not root:
sudo -i

# Then retry installation
```

#### Issue: "File not found" errors

**Solution:**
```bash
# Verify archive integrity
ls -lh DeviceMonitor_plugin.zip

# Re-download if corrupted
wget https://github.com/.../DeviceMonitor_plugin.zip --no-check-certificate

# Extract with verbose output
unzip -v DeviceMonitor_plugin.zip
```

#### Issue: Web GUI doesn't show plugin

**Solution:**
```bash
# Restart configd
service configd restart

# Clear PHP cache
rm -rf /tmp/php_*

# Restart web GUI
/usr/local/etc/rc.restart_webgui

# Wait 30 seconds, then reload browser
# Press Ctrl+F5 to force refresh
```

### Daemon Issues

#### Issue: Daemon won't start

**Solution:**
```bash
# Check Python syntax
python3 -m py_compile /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/monitor_daemon.py

# Check permissions
ls -la /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/
# All .py files should be: -rwxr-xr-x

# Fix permissions if needed
chmod +x /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/*.py

# Try manual start
python3 /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/monitor_daemon.py

# Check error output
tail -50 /var/log/system.log | grep devicemonitor
```

#### Issue: Daemon starts but immediately stops

**Solution:**
```bash
# Check for existing PID file
ls -la /var/run/devicemonitor.pid

# Remove stale PID file
rm /var/run/devicemonitor.pid

# Restart daemon
service devicemonitor start
```

### Database Issues

#### Issue: Database file doesn't exist

**Solution:**
```bash
# Create directory
mkdir -p /var/db/devicemonitor
chmod 755 /var/db/devicemonitor

# Database will be created on first scan
service devicemonitor restart
```

#### Issue: Database is corrupted

**Solution:**
```bash
# Backup old database
mv /var/db/devicemonitor/devices.db \
   /var/db/devicemonitor/devices.db.backup

# Create new empty database
touch /var/db/devicemonitor/devices.db
chmod 644 /var/db/devicemonitor/devices.db

# Restart daemon (will initialize schema)
service devicemonitor restart
```

### Common Questions

**Q: Do I need to restart OPNsense after installation?**
A: No, just restart the web GUI and daemon.

**Q: Can I install on a production firewall?**
A: Yes, the plugin has minimal impact (< 1% CPU).

**Q: Will it work with VLANs?**
A: Yes, automatically detects and monitors all VLANs.

**Q: Does it work with static DHCP reservations?**
A: Yes, fully supports static DHCP entries.

**Q: Can I backup the database?**
A: Yes, just copy `/var/db/devicemonitor/devices.db`

---

## Uninstallation

### Using Makefile

```bash
cd DeviceMonitor_plugin
make uninstall
```

### Manual Uninstallation

```bash
# Stop daemon
service devicemonitor stop

# Remove files
rm -rf /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/
rm -rf /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/
rm -rf /usr/local/opnsense/mvc/app/views/OPNsense/DeviceMonitor/
rm -rf /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/
rm /etc/rc.d/devicemonitor
rm /usr/local/opnsense/service/conf/actions.d/actions_devicemonitor.conf

# Remove data (optional - includes database)
rm -rf /var/db/devicemonitor/

# Restart services
service configd restart
/usr/local/etc/rc.restart_webgui
```

---

## Next Steps

After successful installation:

1. ✅ Configure SMTP for email notifications
2. ✅ Download OUI database for vendor identification
3. ✅ Adjust scan interval based on your needs
4. ✅ Review detected devices
5. ✅ Set up automatic OUI updates

**Enjoy your new network monitoring capabilities!** 🎉

For further configuration details, see [Configuration Guide](CONFIGURATION.md).
