# OPNsense Device Monitor Plugin

<div align="center">

![OPNsense](https://img.shields.io/badge/OPNsense-24.x-orange?style=flat-square&logo=opnsense)
![Python](https://img.shields.io/badge/Python-3.8+-blue?style=flat-square&logo=python)
![License](https://img.shields.io/badge/License-BSD--2--Clause-green?style=flat-square)
![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen?style=flat-square)

**Automatic network device monitoring with real-time detection, vendor identification, and email notifications**

[Features](#features) • [Installation](#installation) • [Documentation](#documentation) • [Screenshots](#screenshots) • [Contributing](#contributing)

</div>

---

## 📖 Overview

**OPNsense Device Monitor** is a powerful plugin that automatically detects and monitors all devices connected to your network. It provides real-time visibility into your network infrastructure, identifies device manufacturers, tracks online/offline status, and alerts you about new devices via email notifications.

### Why Device Monitor?

- 🔒 **Security**: Instantly detect unauthorized devices on your network
- 📊 **Inventory Management**: Maintain an automated asset database
- 🔍 **Vendor Identification**: Identify 40,000+ manufacturers via IEEE OUI database
- 🌐 **Multi-VLAN Support**: Monitor across all VLANs simultaneously
- ⚡ **Performance**: < 1% CPU usage, minimal system impact
- 📧 **Notifications**: HTML email alerts for new devices
- 🎯 **Accurate**: pfctl-based detection for precise online/offline status

---

## ✨ Features

### Core Capabilities

- **Automatic Network Scanning**
  - Background daemon with configurable intervals (60-3600s)
  - ARP table, DHCP leases, and Layer 2 scanning
  - Multi-VLAN support with automatic interface detection
  
- **Real-Time Status Detection**
  - pfctl state table analysis for accurate online/offline status
  - Works with static DHCP reservations
  - Sub-second detection speed (< 100ms)

- **Vendor Identification**
  - IEEE OUI database with 40,000+ manufacturers
  - Automatic updates via scheduled cron jobs
  - In-memory caching for instant lookups

- **Email Notifications**
  - HTML emails with inline CSS (compatible with all clients)
  - Detailed device information: MAC, IP, hostname, vendor, VLAN
  - Configurable sender and recipient
  - Test email function

- **Web GUI**
  - Dashboard with statistics (total, online, new today)
  - Interactive device table with search, sort, and pagination
  - Settings management
  - Daemon control (start/stop/restart)
  - Manual scan trigger

- **Database Management**
  - SQLite3 for persistence
  - Device history tracking
  - Last seen timestamps
  - Indexed queries for performance

### Advanced Features

- **Layer 2 Device Detection**: Finds devices without IP addresses
- **DNS Hostname Resolution**: Automatic reverse DNS lookups
- **VLAN Detection**: Identifies devices by VLAN membership
- **Graceful Daemon Handling**: Proper PID management and signal handling
- **Debug Logging**: Integrated with OPNsense syslog

---

## 🚀 Quick Start

### Prerequisites

- OPNsense 24.x or newer
- Python 3.8+ (included in OPNsense)
- Configured SMTP server (for email notifications)
- ~10 MB free disk space

### Installation

```bash
# Download the plugin
wget https://github.com/yourusername/opnsense-devicemonitor/releases/latest/download/DeviceMonitor_plugin.zip

# Extract
unzip DeviceMonitor_plugin.zip
cd DeviceMonitor_plugin

# Install using Makefile
make install

# Start the daemon
make start

# Check status
make status
```

**Alternative**: Manual installation via `install.sh` script

### Basic Configuration

1. **Configure SMTP** (System → Settings → Notifications → SMTP)
   ```
   SMTP Server: smtp.gmail.com
   Port: 587
   Encryption: STARTTLS
   ```

2. **Configure Device Monitor** (Services → DeviceMonitor → Settings)
   ```
   ☑ Enable monitoring
   Email To: admin@example.com
   Scan Interval: 300 seconds
   ```

3. **Download OUI Database** (Services → DeviceMonitor → OUI Management)
   ```
   Click "Download OUI Database"
   Enable Auto-Update (optional)
   ```

4. **View Devices** (Services → DeviceMonitor → Devices)

---

## 📸 Screenshots

### Dashboard
<p align="center">
  <img src="docs/images/dashboard.png" alt="Dashboard" width="700">
</p>

*Dashboard showing total devices, online status, and new devices*

### Device List
<p align="center">
  <img src="docs/images/devices.png" alt="Device List" width="700">
</p>

*Interactive table with MAC, IP, hostname, vendor, VLAN, and status*

### Email Notification
<p align="center">
  <img src="docs/images/email.png" alt="Email Notification" width="600">
</p>

*HTML email notification for new devices*

---

## 📚 Documentation

### English
- [Installation Guide](docs/INSTALLATION.md) - Detailed installation instructions
- [Configuration Guide](docs/CONFIGURATION.md) - Complete configuration reference
- [API Documentation](docs/API.md) - REST API endpoints
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Development Guide](docs/DEVELOPMENT.md) - Contributing and development setup

### Czech (Česky)
- [Kompletní dokumentace (CZ)](docs/DOKUMENTACE_CZ.md) - Úplná dokumentace v češtině
- [README (CZ)](README_CZ.md) - Český README

---

## 🛠️ Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Backend** | Python 3.8+ | Daemon and scanning logic |
| **Frontend** | PHP 8.1+ (OPNsense MVC) | Web GUI |
| **Database** | SQLite3 | Device persistence |
| **Detection** | pfctl, ARP, tcpdump | Network scanning |
| **Notifications** | SMTP (sendmail) | Email alerts |
| **Vendor DB** | IEEE OUI | Manufacturer identification |

### Detection Algorithm

```
┌─────────────────────────────────────────────────────────────┐
│                    Detection Pipeline                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  1. Discovery (ALL devices)                                  │
│     ├─ ARP Table Scan         → Devices with IP             │
│     ├─ DHCP Leases            → Static + Dynamic            │
│     └─ Layer 2 Scan (tcpdump) → Devices without IP          │
│                                                               │
│  2. Activity Check (ONLINE/OFFLINE)                          │
│     └─ pfctl -ss              → Active connections          │
│                                                               │
│  3. Enrichment                                               │
│     ├─ OUI Lookup             → Vendor name                 │
│     ├─ DNS Reverse Lookup     → Hostname                    │
│     └─ Interface Parsing      → VLAN ID                     │
│                                                               │
│  4. Persistence & Notification                               │
│     ├─ SQLite Update          → Database                    │
│     └─ Email Send             → New devices only            │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Performance

| Metric | Value |
|--------|-------|
| **CPU Usage** | < 1% (during scan), 0% (idle) |
| **Memory Usage** | ~60 MB (including OUI cache) |
| **Scan Time** | 10-15 seconds (full network) |
| **Detection Speed** | < 100 ms (pfctl query) |
| **Database Size** | ~1 MB (100 devices) |
| **Network Impact** | Minimal (< 0.01 Mbps) |

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### Development Setup

```bash
# Clone repository
git clone https://github.com/yourusername/opnsense-devicemonitor.git
cd opnsense-devicemonitor

# Install development dependencies
make dev-install

# Run tests
make test

# Build plugin
make build
```

### Reporting Issues

Found a bug? Have a feature request? Please open an issue on GitHub:
- [Report Bug](https://github.com/yourusername/opnsense-devicemonitor/issues/new?template=bug_report.md)
- [Request Feature](https://github.com/yourusername/opnsense-devicemonitor/issues/new?template=feature_request.md)

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed version history.

### Latest Release (v1.0.0)

- ✨ Initial public release
- 🎯 pfctl-based detection for accurate online/offline status
- 📊 Multi-VLAN support
- 📧 HTML email notifications
- 🏷️ IEEE OUI vendor identification
- 🌐 Complete web GUI

---

## 🔒 Security

### Security Considerations

- **SQL Injection Prevention**: Parameterized queries throughout
- **XSS Prevention**: HTML escaping in all GUI outputs
- **Email Header Injection**: Strict validation of email addresses
- **PID File Locking**: Prevents duplicate daemon instances
- **Privilege Separation**: Daemon runs as root (required for pfctl/tcpdump)

### Reporting Security Issues

Please report security vulnerabilities privately to: security@example.com

**Do not open public GitHub issues for security vulnerabilities.**

---

## 📜 License

This project is licensed under the **BSD 2-Clause License** - see [LICENSE](LICENSE) file for details.

```
Copyright (c) 2024, Hacesoft
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the conditions in LICENSE are met.
```

---

## 🙏 Acknowledgments

- **OPNsense Team** - For the excellent firewall platform
- **IEEE** - For maintaining the OUI database
- **Contributors** - Everyone who has contributed code, bug reports, or suggestions

---

## 📞 Support

### Community Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/yourusername/opnsense-devicemonitor/issues)
- **OPNsense Forum**: [Discuss on forum](https://forum.opnsense.org/)
- **Documentation**: [Complete docs](docs/)

### Commercial Support

For commercial support, training, or custom development:
- Email: support@example.com
- Website: https://example.com

---

## 🗺️ Roadmap

### Planned Features

- [ ] Web dashboard with charts (Chart.js)
- [ ] Slack/Discord/Telegram notifications
- [ ] Device grouping and tagging
- [ ] Historical statistics and trends
- [ ] REST API for external integrations
- [ ] Mobile app (iOS/Android)
- [ ] MAC address whitelist/blacklist
- [ ] Custom device names and notes
- [ ] Export to CSV/PDF
- [ ] Integration with network mapping tools

---

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yourusername/opnsense-devicemonitor&type=Date)](https://star-history.com/#yourusername/opnsense-devicemonitor&Date)

---

<div align="center">

**Made with ❤️ by [Hacesoft](https://github.com/hacesoft)**

[⬆ Back to Top](#opnsense-device-monitor-plugin)

</div>
