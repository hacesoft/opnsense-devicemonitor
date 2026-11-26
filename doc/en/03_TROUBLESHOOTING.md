# Troubleshooting

[Project overview](../../README.md) · [Česky](../cz/03_RESENI_PROBLEMU.md)

| Symptom | What to check |
|---------|---------------|
| Device Monitor is missing from **Services** | Check the installer result and reload the page. If an administrator can see the plugin but another user cannot, check the [account privileges](04_TECHNICAL_REFERENCE.md). |
| The device list is empty | Check that `devicemonitor` is running, monitoring is enabled and **Interfaces → Hostwatch** has records. Clear active filters and use the magnifying glass to request a refresh. |
| Firewall activity is unavailable | Check that **Recent firewall traffic** is enabled, the service is running and the account has access to **Firewall Sessions** diagnostics. Traffic within a VLAN can bypass the firewall. |
| A device answers ping but the activity is red | The activity status uses recent observations from Hostwatch and optionally the firewall. Manual ping requests a one-time reply. |
| Email does not arrive | Check whether email is enabled, the interface filter, the batching delays and the mail server settings. Use **Test Email** and check the recipient’s mailbox. |
| A webhook fails | Check the final URL, format, interface filter and HTTPS certificate. Use **Send Test** to verify the destination’s response. If ntfy displays raw JSON, select the **ntfy** format. |

Check service status in **System → Diagnostics → Services**. From a root shell you can also display the status and recent log entries:

```sh
configctl devicemonitor status
tail -n 50 /var/log/devicemonitor.log
```

If the log reports an invalid configuration file, restore the last working backup or save corrected settings in the web interface. If the database fails, preserve a copy of `/var/db/devicemonitor` first so device data, settings and pending notifications are available for recovery.

When [reporting an issue](https://github.com/hacesoft/opnsense-devicemonitor/issues), include the plugin and OPNsense versions, the symptom and relevant redacted log entries. Keep passwords, webhook URLs and the full configuration file private.
