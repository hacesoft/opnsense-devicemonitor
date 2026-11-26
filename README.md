# OPNsense Device Monitor

**English** · [Česky](README_CZ.md)

Device Monitor is an OPNsense plugin that tracks network devices using the built-in Hostwatch database and sends notifications about new devices.

## Features

- View known devices with MAC and IP addresses, vendor, hostname and first and last detection times.
- Use device names from DHCP reservations or set a name manually. Filter notifications by VLAN.
- Send email directly over SMTP. Existing local Sendmail/Postfix setups are supported. Send webhooks to ntfy.sh, Discord or a generic HTTP endpoint.
- View device counts and service status in the OPNsense Lobby widget, and manage the service in the web interface.

## Installation

Requires **OPNsense 26.1.5 or later**. Follow the [installation guide](doc/en/01_INSTALLATION.md).

## Documentation

- [Installation, upgrade and removal](doc/en/01_INSTALLATION.md)
- [Configuration and usage](doc/en/02_CONFIGURATION_AND_USAGE.md)
- [Troubleshooting](doc/en/03_TROUBLESHOOTING.md)
- [Technical reference](doc/en/04_TECHNICAL_REFERENCE.md)
- [OPNsense integration checks](doc/en/05_OPNSENSE_TESTS.md)
- [Version history](doc/en/CHANGELOG.md)

## Project

[Report an issue](https://github.com/hacesoft/opnsense-devicemonitor/issues) · [More Hacesoft projects](https://github.com/hacesoft?tab=repositories) · [hacesoft.cz](https://hacesoft.cz) · [BSD 2-Clause license](LICENSE)
