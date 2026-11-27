# Installation, upgrade and removal

[Project overview](../../README.md) · [Česky](../cz/01_INSTALACE.md)

## Install

You need **OPNsense 26.1.5 or later**, shell access and root privileges. Transfer the ZIP to the firewall using SCP, SFTP or a client such as WinSCP. SSH can be enabled under **System → Settings → Administration**.

Upload the installation ZIP to `/tmp` and run the installer as root. Adjust the filename to match your download.

```sh
unzip /tmp/opnsense-devicemonitor-2.4.17.zip -d /tmp/devicemonitor-install
cd /tmp/devicemonitor-install/opnsense-devicemonitor
sh install.sh
```

Under **System → Diagnostics → Services**, check that `devicemonitor` is running. Then open **Services → Device Monitor → Settings** and follow the [configuration guide](02_CONFIGURATION_AND_USAGE.md).

## Upgrade

Extract the new ZIP into an empty directory and run its `install.sh` as above. An upgrade preserves the database, including pending notifications, and the saved configuration under `/var/db/devicemonitor`. Verify the version in the plugin header and check the service status after upgrading.

When upgrading from a release older than 2.4.14, the existing delegated Device Monitor privilege becomes read-only. Use the [privilege reference](04_TECHNICAL_REFERENCE.md) to grant delegated management access.

## Uninstall

From the extracted installation package, run as root:

```sh
sh uninstall.sh
```

**A full uninstall deletes the device database, pending notifications and saved configuration.** To retain the data for a later installation, run `sh uninstall.sh --silent`.
