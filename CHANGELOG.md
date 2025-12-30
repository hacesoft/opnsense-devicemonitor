# Changelog

All notable changes to OPNsense Device Monitor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Web dashboard with charts (Chart.js integration)
- Slack/Discord/Telegram notifications
- Device grouping and tagging
- Historical statistics and trends
- REST API for external integrations
- Mobile app (iOS/Android)
- MAC address whitelist/blacklist
- Custom device names and notes
- Export to CSV/PDF
- Network mapping tools integration

---

## [1.0.0] - 2024-12-29

### Added - Initial Release

#### Core Features
- **Automatic Network Scanning**
  - Background daemon with configurable intervals (60-3600s)
  - ARP table scanning for devices with IP addresses
  - DHCP leases parsing (supports static reservations)
  - Layer 2 scanning (tcpdump) for devices without IP

- **Real-Time Status Detection**
  - pfctl state table analysis for accurate online/offline status
  - Sub-second detection speed (< 100ms for entire network)
  - Support for static DHCP reservations
  - Handles permanent ARP entries correctly

- **Vendor Identification**
  - IEEE OUI database integration (40,000+ manufacturers)
  - Automatic OUI database updates
  - Scheduled updates via cron (configurable hour)
  - Manual download option
  - In-memory caching for instant lookups

- **Multi-VLAN Support**
  - Automatic VLAN interface detection
  - VLAN tagging in device records
  - Support for tagged and untagged VLANs
  - Per-VLAN monitoring

- **Email Notifications**
  - HTML emails with inline CSS (universal client compatibility)
  - New device alerts with detailed information
  - Configurable sender and recipient addresses
  - Test email function
  - Special highlighting for devices without IP (yellow background)

- **Web GUI**
  - Dashboard with statistics (total, online, new today)
  - Interactive device table (Bootgrid)
    - Search across all fields
    - Sort by any column
    - Pagination (10/25/50/100 per page)
    - Delete individual devices
    - Clear entire database
  - Settings page
    - Enable/disable monitoring
    - Email configuration
    - Scan interval adjustment
    - Domain name display toggle
  - OUI Management page
    - Manual OUI database download
    - Auto-update configuration
    - Database status display
  - Daemon control buttons
    - Start/Stop/Restart daemon
    - Manual scan trigger
    - Real-time status display

- **Database Management**
  - SQLite3 for data persistence
  - Indexed queries for performance
  - Device history tracking
  - Last seen timestamps
  - Notification status tracking

#### Technical Features
- **Daemon Implementation**
  - Python 3.8+ daemon
  - PID file management
  - Graceful shutdown handling (SIGTERM)
  - Syslog integration
  - Configurable debug logging

- **Performance Optimizations**
  - In-memory OUI cache (instant lookups)
  - pfctl instead of ping (100x faster)
  - SQLite indexes for fast queries
  - Timeout management (non-blocking)
  - Minimal CPU usage (< 1% during scan, 0% idle)
  - Low memory footprint (~60 MB including cache)

- **Security Features**
  - SQL injection prevention (parameterized queries)
  - XSS prevention (HTML escaping)
  - Email header injection protection
  - PID file locking (prevents duplicate instances)

- **OPNsense Integration**
  - MVC framework compliance
  - configd actions for daemon control
  - rc.d service script
  - ACL permissions
  - Menu integration

#### Installation & Documentation
- Makefile for easy installation
- Shell script installer (`install.sh`)
- Manual installation instructions
- Uninstall support
- Comprehensive documentation
  - Installation guide
  - Configuration guide
  - Troubleshooting guide
  - API documentation (for developers)
  - Complete Czech documentation

#### Supported Protocols
- ARP (Address Resolution Protocol)
- DHCP (Dynamic Host Configuration Protocol)
- TCP/UDP (via pfctl state table)
- DNS (reverse lookups)
- ICMP (Layer 2 detection)

### Changed
- N/A (initial release)

### Deprecated
- N/A (initial release)

### Removed
- N/A (initial release)

### Fixed
- N/A (initial release)

### Security
- SQL injection prevention implemented from day one
- XSS prevention implemented from day one
- Secure email handling implemented from day one

---

## Version History

### Version Numbering

We use Semantic Versioning (MAJOR.MINOR.PATCH):
- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)

### Release Cycle

- **Major releases**: Annually (breaking changes allowed)
- **Minor releases**: Quarterly (new features)
- **Patch releases**: As needed (bug fixes)

### Support Policy

- **Current version (1.x)**: Full support (features + bug fixes)
- **Previous major version**: Security fixes only (6 months)
- **Older versions**: No support

---

## Migration Guides

### Migrating to v1.0.0

This is the initial release, no migration needed.

---

## Known Issues

### v1.0.0

**Minor Issues:**
- Dashboard statistics may take 1-2 seconds to load with 500+ devices
- Large OUI database (5 MB) download may timeout on slow connections
- Email notifications only support SMTP (no other methods yet)

**Workarounds:**
- For slow dashboard: Reduce device count or upgrade hardware
- For OUI timeout: Manually download from IEEE and copy to `/var/db/devicemonitor/oui.txt`
- For email: Configure SMTP server (Gmail, SendGrid, etc.)

**Planned Fixes:**
- Dashboard performance optimization (v1.1.0)
- OUI download retry mechanism (v1.0.1)
- Alternative notification methods (v1.2.0)

---

## Upgrade Instructions

### From Future Versions

When upgrading from older versions, see specific migration guides above.

### Backup Before Upgrade

Always backup your database before upgrading:

```bash
cp /var/db/devicemonitor/devices.db \
   /var/db/devicemonitor/devices.db.backup-$(date +%Y%m%d)
```

### Standard Upgrade Process

```bash
# 1. Download new version
wget https://github.com/.../DeviceMonitor_plugin-v1.x.x.zip

# 2. Stop daemon
service devicemonitor stop

# 3. Backup database
cp /var/db/devicemonitor/devices.db \
   /var/db/devicemonitor/devices.db.backup

# 4. Install new version
unzip DeviceMonitor_plugin-v1.x.x.zip
cd DeviceMonitor_plugin
make install

# 5. Restart services
make restart-web
service devicemonitor start

# 6. Verify
service devicemonitor status
tail -f /var/log/system.log | grep devicemonitor
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for information on contributing to this project.

---

## Links

- **Homepage**: https://github.com/hacesoft/opnsense-devicemonitor
- **Issues**: https://github.com/hacesoft/opnsense-devicemonitor/issues
- **Releases**: https://github.com/hacesoft/opnsense-devicemonitor/releases
- **Documentation**: https://github.com/hacesoft/opnsense-devicemonitor/tree/main/docs

---

[Unreleased]: https://github.com/hacesoft/opnsense-devicemonitor/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/hacesoft/opnsense-devicemonitor/releases/tag/v1.0.0
