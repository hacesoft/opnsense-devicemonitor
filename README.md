# OPNsense Device Monitor

**English** · [Česky](README_CZ.md)

Device Monitor is an OPNsense plugin that tracks network devices using the built-in Hostwatch database and sends notifications about new devices.

## Features

- View detected devices by MAC and IP address, hostname, vendor, VLAN and last Hostwatch observation.
- Mark known devices, check them with a manual ping and export the filtered list to CSV. Optional firewall statistics supplement Hostwatch activity.
- Send email directly over SMTP. Existing local Sendmail/Postfix setups are supported. Send webhooks to ntfy.sh, Discord or a generic HTTP endpoint.
- View device counts and service status in the OPNsense Lobby widget, and manage the service in the web interface.

## Installation

Requires **OPNsense 26.1.5 or later**. Follow the [installation guide](doc/en/01_INSTALLATION.md).

## Documentation

- [Installation, upgrade and removal](doc/en/01_INSTALLATION.md)
- [Configuration and usage](doc/en/02_CONFIGURATION_AND_USAGE.md)
- [Troubleshooting](doc/en/03_TROUBLESHOOTING.md)
- [Administrator reference](doc/en/04_TECHNICAL_REFERENCE.md)
- [Version history](doc/en/CHANGELOG.md)

## Project

[Report an issue](https://github.com/hacesoft/opnsense-devicemonitor/issues) · [More Hacesoft projects](https://github.com/hacesoft?tab=repositories) · [hacesoft.cz](https://hacesoft.cz) · [BSD 2-Clause license](LICENSE)
