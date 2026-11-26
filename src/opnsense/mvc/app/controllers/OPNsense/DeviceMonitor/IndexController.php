<?php

// Předpony: arr = pole, s = řetězec.
// Historie: 2.4.14 – ovládání podle práv a zobrazení uložených tajných údajů.
// 2.4.13 – překlady nápovědy ke všem nastavením.
// 2.4.12 – popisky režimů dávkování e-mailů.
// 2.4.11 – popisky časů dávkování e-mailů.
// 2.4.10 – popisky společného stavu a jeho zdrojů.
// 2.4.9 – popisky 15minutového přehledu provozu.
// 2.4.8 – popisek odpočtu k vypršení aktivity PF.
// 2.4.7 – popisky součtu paketů a období bez provozu.
// 2.4.5 – popisky výsledků porovnání čítačů PF.
// 2.4.3 – popisky přírůstků čítačů PF.
// 2.4.0 – popisky pro výběr sloupců a známá zařízení.
// 2.3.7 – sjednocení typových předpon proměnných.

// Historie: 2.3.3 – překlady voleb webhooku a stavů Hostwatch z katalogu pluginu.
// 2.3.6 – předání volby a popisků pasivních statistik PF do šablon.

namespace OPNsense\DeviceMonitor;

class IndexController extends \OPNsense\Base\IndexController
{
    /** Bez vstupu připraví přehled zařízení s popisky Hostwatch, ručního pingu a volitelných statistik PF. */
    public function devicesAction()
    {
        $this->setDeviceMonitorLabels([
            'device_activity' => 'Device activity',
            'hostwatch_source' => 'Hostwatch',
            'firewall_source' => 'Firewall (IP counters)',
            'seen_recently' => 'Seen in the last 15 minutes',
            'not_seen_recently' => 'Not seen in the last 15 minutes',
            'manual_ping' => 'Manual ping',
            'columns' => 'Columns',
            'reset_columns' => 'Show all columns',
            'all_devices' => 'All devices',
            'known_device' => 'Known device',
            'known_devices' => 'Known devices',
            'unmarked_devices' => 'Unmarked devices',
            'mark_known' => 'Mark as known',
            'unmark_known' => 'Remove known mark',
            'known_save_error' => 'Could not save the device mark',
            'check_ping' => 'Run manual ping',
            'ping_reply' => 'Ping reply',
            'ping_no_reply' => 'No ping reply',
            'ping_failed' => 'Ping failed',
            'firewall_traffic' => 'Recent firewall traffic',
            'firewall_traffic_detected' => 'Traffic observed',
            'firewall_next_review' => 'Next 15-minute traffic review in',
            'firewall_last_review' => 'Devices with traffic at last review: %s',
            'firewall_inactive' => 'No traffic observed in the last 15 minutes',
            'firewall_unchanged' => 'No change in counters',
            'firewall_lower' => 'Counter decreased',
            'firewall_baseline' => 'Waiting for another reading',
            'firewall_no_states' => 'No matching PF states',
            'firewall_read_failed' => 'Latest PF reading unavailable',
            'firewall_sample' => 'PF reading',
            'firewall_packets' => 'Observed packets: %s',
            'firewall_traffic_unavailable' => 'No current firewall statistics. Check the Device Monitor service and Firewall Sessions permissions.',
        ]);
        $arrConfig = DeviceMonitor::getConfig();
        $this->view->setVar('dmFirewallTrafficEnabled', (string)($arrConfig['firewall_traffic_enabled'] ?? '0') === '1');
        $oAcl = new \OPNsense\Core\ACL();
        $sUser = (string)$this->session->get('Username');
        $this->view->setVar('dmCanManage', $oAcl->isPageAccessible($sUser, '/ui/devicemonitor/index/settings')
            && !$oAcl->hasPrivilege($sUser, 'user-config-readonly'));
        $this->view->pick('OPNsense/DeviceMonitor/devices');
    }

    /** Bez vstupu připraví formulář nastavení s lokalizovanými popisky a nápovědou. */
    public function settingsAction()
    {
        $this->setDeviceMonitorLabels([
            'secret_saved' => 'Saved on OPNsense',
            'clear_smtp_password' => 'Remove saved SMTP password',
            'clear_webhook_url' => 'Remove saved webhook URL',
            'webhook_url_needed' => 'Enter a webhook URL first.',
            'settings_help_toggle' => 'Show setting help',
            'settings_help_apply' => 'Apply saves the settings from all tabs.',
            'settings_help_email_enabled' => 'Send email when Device Monitor discovers new devices on the selected interfaces. Email is off on a fresh installation.',
            'settings_help_email_to' => 'Enter one email address to receive device alerts and test messages.',
            'settings_help_email_from' => 'Enter one sender address permitted by your mail server.',
            'settings_help_email_method' => 'Direct SMTP connects to your mail server. Local Sendmail / Postfix uses the configured mailer on OPNsense.',
            'settings_help_email_batch_mode' => 'With a maximum, a long series can produce several summaries. Without a maximum, a continuous series can keep delaying the email.',
            'settings_help_email_batch_wait' => 'Each new discovery restarts the wait. Enter 0–3600 seconds. Default: 15. A value of 0 sends the group from one Hostwatch refresh immediately.',
            'settings_help_email_batch_max' => 'Enter 1–3600 seconds from the first discovery. Default: 45. The maximum must be at least as long as the wait.',
            'settings_help_smtp_host' => 'Enter the SMTP hostname or IP address, for example smtp.example.com.',
            'settings_help_smtp_port' => 'Use the port required by your provider. Common ports are 587 for STARTTLS and 465 for SSL/TLS.',
            'settings_help_smtp_encryption' => 'Match the server settings. STARTTLS upgrades an existing connection, SSL/TLS encrypts from the start, and None leaves it unencrypted.',
            'settings_help_smtp_username' => 'Enter the login required by your SMTP provider. Leave it blank if the server accepts mail without authentication.',
            'settings_help_smtp_password' => 'Enter a new SMTP or app password to replace the saved password. Leave the field blank to keep the saved password.',
            'settings_help_email_test' => 'Saves the current settings and sends one test email immediately, without waiting for a batch.',
            'settings_help_interfaces' => 'Select which interfaces can trigger this notification. An empty selection includes all interfaces.',
            'settings_help_webhook_enabled' => 'Send a webhook when Device Monitor discovers new devices on the selected interfaces. Webhooks are off on a fresh installation.',
            'settings_help_webhook_type' => 'Automatic chooses a format from the URL. For ntfy on a custom server, select ntfy explicitly. Use Generic JSON for your own JSON endpoint.',
            'settings_help_webhook_url' => 'Enter the full HTTP or HTTPS URL, including the ntfy topic when applicable. HTTPS requires a trusted certificate. Leave blank to keep the saved URL.',
            'settings_help_webhook_test' => 'Sends a test using the entered URL or the saved URL, and the current format. The test does not save settings.',
            'settings_help_monitoring' => 'Periodically reads new devices from the Hostwatch database. Enable this for automatic discovery and notifications.',
            'settings_help_hostwatch_refresh' => 'Enter 60–3600 seconds between Hostwatch refreshes. Default: 300. This interval affects when the plugin first sees a new device.',
            'settings_help_firewall_traffic' => 'Read existing firewall counters to supplement Hostwatch activity. Off by default. Traffic within a single network segment can bypass the firewall.',
            'settings_help_about' => 'Find the user guides in the project repository. The required OPNsense version is shown below.',
            'email_batch_mode' => 'Email batching mode',
            'email_batch_bounded' => 'Wait for a pause, with a maximum',
            'email_batch_quiet' => 'Wait for a pause, without a maximum',
            'email_batch_wait' => 'Wait after the last discovery (seconds)',
            'email_batch_max' => 'Maximum wait from the first discovery (seconds)',
            'webhook_type' => 'Webhook type',
            'automatic' => 'Automatic',
            'generic_json' => 'Generic JSON',
            'hostwatch_refresh' => 'Hostwatch Refresh Interval',
            'firewall_traffic' => 'Recent firewall traffic',
        ]);
        $this->view->pick('OPNsense/DeviceMonitor/settings');
    }

    /** Přijme anglické klíče a předá šabloně přeložené popisky. */
    private function setDeviceMonitorLabels(array $arrLabels): void
    {
        bindtextdomain('devicemonitor', '/usr/local/share/locale');
        bind_textdomain_codeset('devicemonitor', 'UTF-8');
        $this->view->setVar('dmLabels', array_map(
            static fn (string $sMessage): string => dgettext('devicemonitor', $sMessage),
            $arrLabels
        ));
    }
}
