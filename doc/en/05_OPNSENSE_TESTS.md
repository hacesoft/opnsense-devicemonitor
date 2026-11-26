# OPNsense integration checks

[Česky](../cz/05_TESTY_OPNSENSE.md) · [Plugin configuration](02_CONFIGURATION_AND_USAGE.md)

These checks compare the native OPNsense features with what Device Monitor adds. See [proposal #5964](https://github.com/opnsense/plugins/issues/5964), [PR #11150](https://github.com/opnsense/core/pull/11150) for DNS and [PR #11180](https://github.com/opnsense/core/pull/11180) for Hostwatch PF statistics.

## 1. Installed capabilities

Run these read-only commands on OPNsense over SSH.

```sh
opnsense-version
pkg info -e os-postfix && echo 'os-postfix: installed' || echo 'os-postfix: absent'
ls -l /var/db/hostwatch/hosts.db
sDiagnosticsApiDir=/usr/local/opnsense/mvc/app/controllers/OPNsense/Diagnostics/Api
grep -n 'function reverseLookupAction' "$sDiagnosticsApiDir/DnsController.php"
```

A method in the installed source establishes its presence. Use the browser tests below to check the current account can use it. HTTP 403 means access is denied. With 404, check the firmware and the method above.

## 2. Hostwatch, DNS and PF

| Check | Steps | Expected result |
|---|---|---|
| H1 · Hostwatch data | Compare the IP, MAC and last-seen timestamp of a test device in **Interfaces → Hostwatch** and **Services → Device Monitor → Devices**. Allow one configured plugin refresh interval. | The records agree after accounting for time zones. |
| H2 · Reverse DNS | Use a device with a known PTR record and no saved or configured name in Device Monitor. Open both device lists and look for `reverse_lookup` in the browser Network tab. | Both show the PTR name. A manual name in Device Monitor takes precedence. |
| H3 · Firewall traffic | Enable **Recent firewall traffic** and open Devices. After the first reading, generate normal routed traffic on your test device through another table refresh. Check `pf_packets` in the device-list response in the Network tab. | The count increases as PF reports increases. Zero, lower or unavailable readings preserve the count. After 15 minutes without an increase the count resets. When readings are available, the status reports no observed traffic. Close the Devices page and leave the test traffic running through two more intervals. Reopen the page and verify that the total increased and the header countdown moves. |
| H5 · Activity and mobile table | Check a row with an old Hostwatch timestamp and a recent PF increase. Open the page on a narrow screen. | The row is green with firewall as the source. After both sources expire, the row turns red. The table scrolls horizontally inside the page. |
| H4 · Quiet device | Use your own device with an older Hostwatch observation and run one manual ping. | Record both results. A ping reply can coexist with an older Hostwatch observation. Traffic switched within one VLAN can also bypass PF. Neither observation alone establishes an outage. |

## 3. Direct SMTP without Postfix

1. Use a test firewall without `os-postfix`. Leave an existing production installation in place.
2. Select **Direct SMTP** in Device Monitor’s **Email** settings. Configure a test recipient, allowed sender and SMTP server using your provider's port and encryption. Enable email and run **Test Email**.
3. Verify the message in the recipient's mailbox and check `/var/log/devicemonitor.log`. Acceptance by an SMTP server and delivery to the mailbox are separate observations.
4. For a real alert, connect one of your devices that is new to Device Monitor on the test VLAN. Enable monitoring and include that VLAN for email. Wait for a Hostwatch refresh and verify the new-device email.
5. On upgrade, verify the saved delivery method remains selected. A fresh install selects **Direct SMTP** and starts with email alerts disabled.
6. To verify batching, use two new devices discovered on different Hostwatch refreshes. Set the wait and maximum longer than the refresh gap. Verify that one email lists both devices.
7. In quiet mode, keep the 15-second wait. Simulate discoveries 12 seconds apart for more than 45 seconds. Verify that the batch is sent after a full 15-second pause.

### Settings help

Turn on **Show setting help** above the tabs. Switch tabs and reload. The field explanations should remain visible. Change the email delivery method or batching mode and verify that explanations for hidden fields disappear with the fields.

## 4. Monit

On a test firewall, configure SMTP and a test recipient in **Services → Monit → Settings**. Create a **File** check for a disposable file such as `/tmp/device-monitor-monit-probe`, with the condition `does not exist` and action **Alert**. Start with the file present. Wait for a check cycle, remove it, verify the alert, then recreate it and observe the recovery event according to the alert settings. Remove the test check and file afterwards. See the [Monit manual](https://docs.opnsense.org/manual/monit.html).

This establishes whether Monit can deliver an alert for a known condition. A Hostwatch integration still needs an event carrying the new device’s IP, MAC and VLAN. Record whether that would require glue code or polling before proposing it to the maintainers.

## Results for #5964

Record both installed versions, the results of H1–H5, the two SMTP delivery results, `os-postfix` presence and the Monit result. Mark each check **pass / fail / unavailable**, with a short reason. Share redacted evidence in the public discussion.

### Security checks

Verify that a read-only account can open and export the list. Check that it cannot save settings, run a ping, or clear the database. As a manager, verify that saving blank secret fields retains the saved values. Use a test webhook with a trusted and then an untrusted certificate and check that the second attempt fails. Export a test value with a formula-like prefix and confirm that the spreadsheet treats it as text.

### Operational limits

Check the rotation rule using `newsyslog -n -v /var/log/devicemonitor.log`. On a test firewall, overlap scheduled and manual Hostwatch refreshes and verify webhook delivery. With the test webhook unavailable, check that the service retries and succeeds after the destination is restored.

### Input validation

Try saving a refresh interval out of range, text as the SMTP port, and an invalid input type through the test API. Verify that settings remain unchanged. In a copy of the Hostwatch database, verify that a newer malformed row cannot hide a valid older row for the same MAC.
