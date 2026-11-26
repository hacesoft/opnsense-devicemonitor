{# Předpony: arr = pole, b = příznak, fn = funkce, i = číslo, o = objekt, s = řetězec, $ = objekt jQuery.
   Historie: 2.4.14 – úprava tajných údajů bez jejich načtení do prohlížeče.
   2.4.13 – společný přepínač nápovědy a popisy polí.
   2.4.12 – volba režimu dávkování e-mailů.
   2.4.11 – nastavení časů dávkování e-mailů.
   2.4.1 – Direct SMTP je výchozí volba v nové instalaci.
   2.3.7 – sjednocení typových předpon proměnných.
   2.3.3 – volba formátu webhooku (#8) a pojmenování intervalu Hostwatch (#10).
   2.3.6 – volba pasivních statistik PF. #}
<style>
    #dm-settings [data-dm-help][hidden] { display: none !important; }
    #dm-settings .dm-setting-note { margin: 4px 0 8px; max-width: 600px; }
</style>
<div class="content-box" id="dm-settings"
     data-secret-saved="{{ dmLabels['secret_saved']|e }}"
     data-webhook-url-needed="{{ dmLabels['webhook_url_needed']|e }}">
    <div class="content-box-main">

        <h1 style="padding-left:10px;">
            {{ lang._('Device Monitor') }}
            <small id="settings-version" style="font-size:13px;color:#888;margin-left:5px;"></small>
            <span style="color:#555;margin:0 8px;">–</span>
            <span style="font-weight:normal;font-size:18px;">{{ lang._('Settings') }}</span>
        </h1>

        <div style="padding:0 10px;">
            <label for="dm-settings-help">
                <input type="checkbox" role="switch" id="dm-settings-help" />
                {{ dmLabels['settings_help_toggle']|e }}
            </label>
        </div>

        <ul class="nav nav-tabs" role="tablist" style="margin:10px 0 0 0;">
            <li role="presentation" class="active">
                <a href="#tab-email" role="tab" data-toggle="tab">
                    <i class="fa fa-envelope-o"></i> {{ lang._('Email Notifications') }}
                </a>
            </li>
            <li role="presentation">
                <a href="#tab-webhook" role="tab" data-toggle="tab">
                    <i class="fa fa-bell-o"></i> {{ lang._('Webhook Notifications') }}
                </a>
            </li>
            <li role="presentation">
                <a href="#tab-other" role="tab" data-toggle="tab">
                    <i class="fa fa-cog"></i> {{ lang._('Other Settings') }}
                </a>
            </li>
            <li role="presentation">
                <a href="#tab-about" role="tab" data-toggle="tab">
                    <i class="fa fa-info-circle"></i> {{ lang._('About') }}
                </a>
            </li>
        </ul>

        <div class="tab-content" style="padding:15px 0;">

            <!-- TAB 1: Email -->
            <div role="tabpanel" class="tab-pane active" id="tab-email">
                <table class="table table-striped">
                    <tbody>
                        <tr>
                            <td style="width:30%;vertical-align:top;">
                                <label>
                                    <input type="checkbox" id="email_enabled" />
                                    <strong>{{ lang._('Enable Email') }}</strong>
                                </label>
                                <div class="small text-muted dm-setting-note" id="dm-help-email_enabled" data-dm-help-for="email_enabled" data-dm-help hidden>{{ dmLabels['settings_help_email_enabled']|e }}</div>
                            </td>
                            <td>
                                <div id="email_config">
                                    <label for="email_to">{{ lang._('Email Recipient') }}:</label>
                                    <input type="email" id="email_to" class="form-control" placeholder="admin@example.com" style="max-width:400px;" />
                                    <div class="small text-muted dm-setting-note" id="dm-help-email_to" data-dm-help-for="email_to" data-dm-help hidden>{{ dmLabels['settings_help_email_to']|e }}</div>
                                    <br><br>

                                    <label for="email_from">{{ lang._('Email Sender') }}:</label>
                                    <input type="email" id="email_from" class="form-control" placeholder="devicemonitor@opnsense.local" style="max-width:400px;" />
                                    <div class="small text-muted dm-setting-note" id="dm-help-email_from" data-dm-help-for="email_from" data-dm-help hidden>{{ dmLabels['settings_help_email_from']|e }}</div>
                                    <br><br>

                                    <label for="email_method">{{ lang._('Email delivery method') }}:</label>
                                    <select id="email_method" class="form-control" style="max-width:400px;">
                                        <option value="smtp">{{ lang._('Direct SMTP (built into Device Monitor)') }}</option>
                                        <option value="sendmail">{{ lang._('Local Sendmail / Postfix') }}</option>
                                    </select>
                                    <div class="small text-muted dm-setting-note" id="dm-help-email_method" data-dm-help-for="email_method" data-dm-help hidden>{{ dmLabels['settings_help_email_method']|e }}</div>

                                    <div style="margin-top:14px;max-width:600px;">
                                        <label for="email_batch_mode">{{ dmLabels['email_batch_mode']|e }}</label>
                                        <select id="email_batch_mode" class="form-control" style="max-width:400px;margin-bottom:12px;">
                                            <option value="bounded">{{ dmLabels['email_batch_bounded']|e }}</option>
                                            <option value="quiet">{{ dmLabels['email_batch_quiet']|e }}</option>
                                        </select>
                                        <div class="small text-muted dm-setting-note" id="dm-help-email_batch_mode" data-dm-help-for="email_batch_mode" data-dm-help hidden>{{ dmLabels['settings_help_email_batch_mode']|e }}</div>
                                        <div style="display:flex;flex-wrap:wrap;gap:12px;">
                                            <div>
                                                <label for="email_batch_wait">{{ dmLabels['email_batch_wait']|e }}</label>
                                                <input type="number" id="email_batch_wait" class="form-control" min="0" max="3600" step="1" style="width:120px;" />
                                                <div class="small text-muted dm-setting-note" id="dm-help-email_batch_wait" data-dm-help-for="email_batch_wait" data-dm-help hidden>{{ dmLabels['settings_help_email_batch_wait']|e }}</div>
                                            </div>
                                            <div id="email_batch_max_field">
                                                <label for="email_batch_max">{{ dmLabels['email_batch_max']|e }}</label>
                                                <input type="number" id="email_batch_max" class="form-control" min="1" max="3600" step="1" style="width:120px;" />
                                                <div class="small text-muted dm-setting-note" id="dm-help-email_batch_max" data-dm-help-for="email_batch_max" data-dm-help hidden>{{ dmLabels['settings_help_email_batch_max']|e }}</div>
                                            </div>
                                        </div>
                                    </div>

                                    <div id="email_smtp_config" style="margin-top:14px;max-width:600px;display:none;">
                                        <label for="smtp_host">{{ lang._('SMTP Server') }}:</label>
                                        <input type="text" id="smtp_host" class="form-control" placeholder="smtp.example.com" style="max-width:400px;" />
                                        <div class="small text-muted dm-setting-note" id="dm-help-smtp_host" data-dm-help-for="smtp_host" data-dm-help hidden>{{ dmLabels['settings_help_smtp_host']|e }}</div>
                                        <br>

                                        <div style="display:flex;gap:15px;align-items:flex-end;flex-wrap:wrap;">
                                            <div>
                                                <label for="smtp_port">{{ lang._('SMTP Port') }}:</label>
                                                <input type="number" id="smtp_port" class="form-control" value="587" min="1" max="65535" style="width:120px;" />
                                                <div class="small text-muted dm-setting-note" id="dm-help-smtp_port" data-dm-help-for="smtp_port" data-dm-help hidden>{{ dmLabels['settings_help_smtp_port']|e }}</div>
                                            </div>
                                            <div>
                                                <label for="smtp_encryption">{{ lang._('Encryption') }}:</label>
                                                <select id="smtp_encryption" class="form-control" style="width:180px;">
                                                    <option value="starttls">STARTTLS</option>
                                                    <option value="ssl">SSL/TLS</option>
                                                    <option value="none">{{ lang._('None') }}</option>
                                                </select>
                                                <div class="small text-muted dm-setting-note" id="dm-help-smtp_encryption" data-dm-help-for="smtp_encryption" data-dm-help hidden>{{ dmLabels['settings_help_smtp_encryption']|e }}</div>
                                            </div>
                                        </div>
                                        <br>

                                        <label for="smtp_username">{{ lang._('SMTP Username') }}:</label>
                                        <input type="text" id="smtp_username" class="form-control" autocomplete="username" style="max-width:400px;" />
                                        <div class="small text-muted dm-setting-note" id="dm-help-smtp_username" data-dm-help-for="smtp_username" data-dm-help hidden>{{ dmLabels['settings_help_smtp_username']|e }}</div>
                                        <br><br>

                                        <label for="smtp_password">{{ lang._('SMTP Password') }}:</label>
                                        <input type="password" id="smtp_password" class="form-control" autocomplete="new-password" style="max-width:400px;" />
                                        <div class="small text-muted dm-setting-note" id="dm-help-smtp_password" data-dm-help-for="smtp_password" data-dm-help hidden>{{ dmLabels['settings_help_smtp_password']|e }}</div>
                                    <label id="dm-clear_smtp_password-option" class="small" hidden>
                                        <input type="checkbox" id="clear_smtp_password" /> {{ dmLabels['clear_smtp_password']|e }}
                                    </label>
                                    </div>

                                    <button type="button" id="btn-test-email" class="btn btn-default btn-sm" style="margin-top:14px;">
                                        🧪 {{ lang._('Test Email') }}
                                    </button>
                                    <div class="small text-muted dm-setting-note" id="dm-help-btn-test-email" data-dm-help-for="btn-test-email" data-dm-help hidden>{{ dmLabels['settings_help_email_test']|e }}</div>
                                </div>
                            </td>
                        </tr>
                        <tr>
                            <td style="vertical-align:top;padding-top:16px;">
                                <strong>{{ lang._('Notify for interfaces') }}</strong>
                            </td>
                            <td>
                                <div style="margin-top:6px;border:1px solid #444;border-radius:4px;padding:8px;max-width:350px;max-height:180px;overflow-y:auto;" id="email-vlan-list" role="group" aria-label="{{ lang._('Notify for interfaces') }}"></div>
                                <div class="small text-muted dm-setting-note" id="dm-help-email-vlan-list" data-dm-help-for="email-vlan-list" data-dm-help hidden>{{ dmLabels['settings_help_interfaces']|e }}</div>
                            </td>
                        </tr>
                    </tbody>
                </table>
                <div style="padding:10px 0 0 0;">
                    <button type="button" class="btn btn-primary btn-apply" id="btn-apply-email">
                        <i class="fa fa-check"></i> {{ lang._('Apply') }}
                    </button>
                    <div class="small text-muted dm-setting-note" id="dm-help-btn-apply-email" data-dm-help-for="btn-apply-email" data-dm-help hidden>{{ dmLabels['settings_help_apply']|e }}</div>
                </div>
            </div>

            <!-- TAB 2: Webhook -->
            <div role="tabpanel" class="tab-pane" id="tab-webhook">
                <table class="table table-striped">
                    <tbody>
                        <tr>
                            <td style="width:30%;vertical-align:top;">
                                <label>
                                    <input type="checkbox" id="webhook_enabled" />
                                    <strong>{{ lang._('Enable Webhook') }}</strong>
                                </label>
                                <div class="small text-muted dm-setting-note" id="dm-help-webhook_enabled" data-dm-help-for="webhook_enabled" data-dm-help hidden>{{ dmLabels['settings_help_webhook_enabled']|e }}</div>
                            </td>
                            <td>
                                <div id="webhook_config">
                                    <label for="webhook_type">{{ dmLabels['webhook_type']|e }}</label>
                                    <select id="webhook_type" class="form-control" style="max-width:500px;margin-bottom:10px;">
                                        <option value="auto">{{ dmLabels['automatic']|e }}</option>
                                        <option value="ntfy">ntfy</option>
                                        <option value="discord">Discord</option>
                                        <option value="generic">{{ dmLabels['generic_json']|e }}</option>
                                    </select>
                                    <div class="small text-muted dm-setting-note" id="dm-help-webhook_type" data-dm-help-for="webhook_type" data-dm-help hidden>{{ dmLabels['settings_help_webhook_type']|e }}</div>
                                    <label for="webhook_url">{{ lang._('Webhook URL') }}:</label>
                                    <input type="text" id="webhook_url" class="form-control" placeholder="https://ntfy.sh/your_topic" style="max-width:500px;" />
                                    <div class="small text-muted dm-setting-note" id="dm-help-webhook_url" data-dm-help-for="webhook_url" data-dm-help hidden>{{ dmLabels['settings_help_webhook_url']|e }}</div>
                                    <label id="dm-clear_webhook_url-option" class="small" hidden>
                                        <input type="checkbox" id="clear_webhook_url" /> {{ dmLabels['clear_webhook_url']|e }}
                                    </label>
                                    <br>
                                    <button type="button" id="test_webhook" class="btn btn-default btn-sm">
                                        🧪 {{ lang._('Send Test') }}
                                    </button>
                                    <span id="webhook_test_result" style="margin-left:10px;font-weight:bold;"></span>
                                    <div class="small text-muted dm-setting-note" id="dm-help-test_webhook" data-dm-help-for="test_webhook" data-dm-help hidden>{{ dmLabels['settings_help_webhook_test']|e }}</div>
                                </div>
                            </td>
                        </tr>
                        <tr>
                            <td style="vertical-align:top;padding-top:16px;">
                                <strong>{{ lang._('Notify for interfaces') }}</strong>
                            </td>
                            <td>
                                <div style="margin-top:6px;border:1px solid #444;border-radius:4px;padding:8px;max-width:350px;max-height:180px;overflow-y:auto;" id="webhook-vlan-list" role="group" aria-label="{{ lang._('Notify for interfaces') }}"></div>
                                <div class="small text-muted dm-setting-note" id="dm-help-webhook-vlan-list" data-dm-help-for="webhook-vlan-list" data-dm-help hidden>{{ dmLabels['settings_help_interfaces']|e }}</div>
                            </td>
                        </tr>
                    </tbody>
                </table>
                <div style="padding:10px 0 0 0;">
                    <button type="button" class="btn btn-primary btn-apply" id="btn-apply-webhook">
                        <i class="fa fa-check"></i> {{ lang._('Apply') }}
                    </button>
                    <div class="small text-muted dm-setting-note" id="dm-help-btn-apply-webhook" data-dm-help-for="btn-apply-webhook" data-dm-help hidden>{{ dmLabels['settings_help_apply']|e }}</div>
                </div>
            </div>

            <!-- TAB 3: Other Settings -->
            <div role="tabpanel" class="tab-pane" id="tab-other">
                <table class="table table-striped">
                    <tbody>
                        <tr>
                            <td style="width:30%;"><label for="enabled">{{ lang._('Enable Monitoring') }}</label></td>
                            <td>
                                <input type="checkbox" id="enabled" />
                                <div class="small text-muted dm-setting-note" id="dm-help-enabled" data-dm-help-for="enabled" data-dm-help hidden>{{ dmLabels['settings_help_monitoring']|e }}</div>
                            </td>
                        </tr>
                        <tr>
                            <td><label for="scan_interval">{{ dmLabels['hostwatch_refresh']|e }}</label></td>
                            <td>
                                <div style="display:flex;align-items:center;gap:10px;">
                                    <input type="number" id="scan_interval" class="form-control" value="300" min="60" max="3600" style="max-width:120px;" />
                                    <span class="text-muted">{{ lang._('seconds') }}</span>
                                </div>
                                <div class="small text-muted dm-setting-note" id="dm-help-scan_interval" data-dm-help-for="scan_interval" data-dm-help hidden>{{ dmLabels['settings_help_hostwatch_refresh']|e }}</div>
                            </td>
                        </tr>
                        <tr>
                            <td><label for="firewall_traffic_enabled">{{ dmLabels['firewall_traffic']|e }}</label></td>
                            <td>
                                <input type="checkbox" id="firewall_traffic_enabled" />
                                <div class="small text-muted dm-setting-note" id="dm-help-firewall_traffic_enabled" data-dm-help-for="firewall_traffic_enabled" data-dm-help hidden>{{ dmLabels['settings_help_firewall_traffic']|e }}</div>
                            </td>
                        </tr>
                    </tbody>
                </table>
                <div style="padding:10px 0 0 0;">
                    <button type="button" class="btn btn-primary btn-apply" id="btn-apply-other">
                        <i class="fa fa-check"></i> {{ lang._('Apply') }}
                    </button>
                    <div class="small text-muted dm-setting-note" id="dm-help-btn-apply-other" data-dm-help-for="btn-apply-other" data-dm-help hidden>{{ dmLabels['settings_help_apply']|e }}</div>
                </div>
            </div>

            <!-- TAB 4: About -->
            <div role="tabpanel" class="tab-pane" id="tab-about">
                <div style="max-width:600px;padding:10px 0;">
                    <h3 style="margin-top:0;">{{ lang._('Device Monitor') }} <span id="about-version" style="color:#888;font-size:16px;"></span></h3>
                    <p class="text-muted">{{ lang._('OPNsense plugin for monitoring network devices using the native hostwatch database.') }}</p>
                    <div class="small text-muted dm-setting-note" data-dm-help hidden>{{ dmLabels['settings_help_about']|e }}</div>
                    <table class="table table-condensed" style="margin-top:20px;">
                        <tr>
                            <td style="width:40%;color:#888;">{{ lang._('Author') }}</td>
                            <td>Hacesoft</td>
                        </tr>
                        <tr>
                            <td style="color:#888;">{{ lang._('GitHub Repository') }}</td>
                            <td><a href="https://github.com/hacesoft/opnsense-devicemonitor" target="_blank">github.com/hacesoft/opnsense-devicemonitor</a></td>
                        </tr>
                        <tr>
                            <td style="color:#888;">{{ lang._('License') }}</td>
                            <td>MIT</td>
                        </tr>
                        <tr>
                            <td style="color:#888;">{{ lang._('Requires OPNsense') }}</td>
                            <td>&ge; 26.1.5</td>
                        </tr>
                    </table>
                </div>
            </div>

        </div>
    </div>
</div>

<script>
$().ready(function() {
    var oTranslations = {
        config_saved:  '{{ lang._('Configuration saved') }}',
        config_error:  '{{ lang._('Error saving configuration') }}',
        test_sent:     '{{ lang._('Test email sent to') }}',
        test_failed:   '{{ lang._('Failed to send email') }}',
        saving:        '{{ lang._('Saving...') }}'
    };

    var oVlanNames = {};
    var bSavedWebhook = false;
    var sSecretSavedLabel = $('#dm-settings').attr('data-secret-saved');

    function showToast(sMessage, sToastType) {
        var sBackgroundColor = sToastType==='success'?'#4CAF50':(sToastType==='error'?'#f44336':'#2196F3');
        var sIconClass = sToastType==='success'?'fa-check-circle':(sToastType==='error'?'fa-exclamation-circle':'fa-info-circle');
        var $toast = $('<div>').css({position:'fixed',top:'20px',right:'20px','background-color':sBackgroundColor,color:'white',
            padding:'15px 20px','border-radius':'4px','box-shadow':'0 4px 8px rgba(0,0,0,.3)',
            'z-index':9999,'min-width':'280px',display:'none'})
            .append($('<i>').addClass('fa ' + sIconClass), document.createTextNode(' ' + sMessage));
        $('body').append($toast); $toast.fadeIn(300);
        setTimeout(function(){ $toast.fadeOut(300,function(){ $toast.remove(); }); },3000);
    }

    // Version
    $.getJSON('/api/devicemonitor/config/getversion', function(oConfig) {
        var sVlan = 'v'+(oConfig.version||'?');
        $('#settings-version').text(sVlan);
        $('#about-version').text(sVlan);
    });

    // Build VLAN checklist in a container
    function buildVlanCheckList(sContainerId, sSelectedVlans) {
        var $container = $('#'+sContainerId).empty();
        var arrVlans = Object.keys(oVlanNames).sort();
        if (!arrVlans.length) {
            $container.html('<em style="color:#888;font-size:12px;">{{ lang._('No interfaces found') }}</em>');
            return;
        }
        var arrSelectedVlans = sSelectedVlans ? sSelectedVlans.split(',').map(function(sVlan){return sVlan.trim();}).filter(Boolean) : [];
        arrVlans.forEach(function(sVlan) {
            var sVlanName = oVlanNames[sVlan];
            var sLabel = (sVlanName && sVlanName !== sVlan) ? sVlan+' \u2013 '+sVlanName : sVlan;
            var bSelected = (arrSelectedVlans.length === 0) || (arrSelectedVlans.indexOf(sVlan) !== -1);
            $container.append($('<label>').css({display:'block',margin:'3px 0',fontWeight:'normal',cursor:'pointer'}).append(
                $('<input type="checkbox" class="notif-vlan-cb">').val(sVlan).prop('checked',bSelected),
                $('<span>').css('margin-left','8px').text(sLabel)
            ));
        });
    }

    function getSelectedVlans(sContainerId) {
        var arrSelectedVlans=[], iTotal=$('#'+sContainerId+' .notif-vlan-cb').length;
        $('#'+sContainerId+' .notif-vlan-cb:checked').each(function(){ arrSelectedVlans.push($(this).val()); });
        return (arrSelectedVlans.length===iTotal) ? '' : arrSelectedVlans.join(',');
    }

    function loadConfig() {
        $.ajax({ url:'/api/devicemonitor/config/get', type:'GET', success:function(oConfig) {
            $('#enabled').prop('checked', oConfig.enabled==='1');
            $('#scan_interval').val(oConfig.scan_interval||300);
            $('#firewall_traffic_enabled').prop('checked', String(oConfig.firewall_traffic_enabled) === '1');
            $('#email_enabled').prop('checked', oConfig.email_enabled==='1');
            $('#email_to').val(oConfig.email_to||'');
            $('#email_from').val(oConfig.email_from||'devicemonitor@opnsense.local');
            $('#email_method').val(oConfig.email_method||'smtp');
            $('#email_batch_mode').val(oConfig.email_batch_mode === 'quiet' ? 'quiet' : 'bounded');
            toggleEmailBatchMode();
            $('#email_batch_wait').val(oConfig.email_batch_wait ?? 15);
            $('#email_batch_max').val(oConfig.email_batch_max ?? 45);
            $('#smtp_host').val(oConfig.smtp_host||'');
            $('#smtp_port').val(oConfig.smtp_port||587);
            $('#smtp_encryption').val(oConfig.smtp_encryption||'starttls');
            $('#smtp_username').val(oConfig.smtp_username||'');
            $('#smtp_password').val('').attr('placeholder', oConfig.smtp_password_set ? sSecretSavedLabel : '');
            $('#clear_smtp_password').prop('checked', false);
            $('#dm-clear_smtp_password-option').prop('hidden', !oConfig.smtp_password_set);
            $('#webhook_enabled').prop('checked', oConfig.webhook_enabled==='1');
            bSavedWebhook = oConfig.webhook_url_set === true;
            $('#webhook_url').val('').attr('placeholder', bSavedWebhook ? sSecretSavedLabel : 'https://ntfy.sh/your_topic');
            $('#clear_webhook_url').prop('checked', false);
            $('#dm-clear_webhook_url-option').prop('hidden', !bSavedWebhook);
            $('#webhook_type').val(oConfig.webhook_type || 'auto');
            buildVlanCheckList('email-vlan-list',   oConfig.email_vlans   || '');
            buildVlanCheckList('webhook-vlan-list', oConfig.webhook_vlans || '');
            toggleEmailConfig();
            toggleEmailMethod();
            toggleWebhookConfig();
        }});
    }

    function toggleEmailConfig() {
        $('#email_enabled').prop('checked') ? $('#email_config').slideDown() : $('#email_config').slideUp();
    }
    function toggleEmailMethod() {
        $('#email_smtp_config').toggle($('#email_method').val() !== 'sendmail');
    }
    function toggleWebhookConfig() {
        $('#webhook_enabled').prop('checked') ? $('#webhook_config').slideDown() : $('#webhook_config').slideUp();
    }
    // Bez vstupu. Zobrazí maximum jen v režimu, ve kterém se uplatňuje.
    function toggleEmailBatchMode() {
        $('#email_batch_max_field').prop('hidden', $('#email_batch_mode').val() === 'quiet');
    }
    $('#email_enabled').change(toggleEmailConfig);
    $('#email_batch_mode').change(toggleEmailBatchMode);
    $('#email_method').change(toggleEmailMethod);
    $('#webhook_enabled').change(toggleWebhookConfig);

    var sHelpStorageKey = 'devicemonitor.settings.help';
    var $helpSwitch = $('#dm-settings-help');

    // Vstup: stav přepínače. Výstup: viditelné popisy a jejich vazby na ovládací prvky.
    function setSettingHelp(bShow) {
        $('#dm-settings [data-dm-help]').each(function() {
            var $note = $(this).prop('hidden', !bShow);
            var sControlId = $note.attr('data-dm-help-for');
            if (sControlId) {
                var $control = $('#' + sControlId);
                if (bShow) {
                    $control.attr('aria-describedby', this.id);
                } else {
                    $control.removeAttr('aria-describedby');
                }
            }
        });
    }

    try {
        $helpSwitch.prop('checked', localStorage.getItem(sHelpStorageKey) === '1');
    } catch (oError) {}
    setSettingHelp($helpSwitch.prop('checked'));
    $helpSwitch.on('change', function() {
        var bShow = this.checked;
        setSettingHelp(bShow);
        try {
            localStorage.setItem(sHelpStorageKey, bShow ? '1' : '0');
        } catch (oError) {}
    });

    function collectConfigData() {
        var oConfig = {
            enabled:          $('#enabled').is(':checked')?'1':'0',
            email_enabled:    $('#email_enabled').is(':checked')?'1':'0',
            email_to:         $('#email_to').val(),
            email_from:       $('#email_from').val(),
            email_method:     $('#email_method').val(),
            email_batch_mode: $('#email_batch_mode').val(),
            email_batch_wait: $('#email_batch_wait').val(),
            email_batch_max:  $('#email_batch_max').val(),
            smtp_host:        $('#smtp_host').val(),
            smtp_port:        $('#smtp_port').val(),
            smtp_encryption:  $('#smtp_encryption').val(),
            smtp_username:    $('#smtp_username').val(),
            email_vlans:      getSelectedVlans('email-vlan-list'),
            webhook_enabled:  $('#webhook_enabled').is(':checked')?'1':'0',
            webhook_type:     $('#webhook_type').val(),
            webhook_vlans:    getSelectedVlans('webhook-vlan-list'),
            scan_interval:    $('#scan_interval').val(),
            firewall_traffic_enabled: $('#firewall_traffic_enabled').is(':checked') ? '1' : '0'
        };
        var sPassword = $('#smtp_password').val();
        var sWebhookUrl = $('#webhook_url').val().trim();
        if (sPassword !== '' || $('#clear_smtp_password').is(':checked')) {
            oConfig.smtp_password = $('#clear_smtp_password').is(':checked') ? '' : sPassword;
        }
        if (sWebhookUrl !== '' || $('#clear_webhook_url').is(':checked')) {
            oConfig.webhook_url = $('#clear_webhook_url').is(':checked') ? '' : sWebhookUrl;
        }
        return oConfig;
    }

    function saveConfig($btn, fnSuccess) {
        var sOriginalHtml = $btn.html();
        $btn.prop('disabled',true).html('<i class="fa fa-spinner fa-spin"></i> '+oTranslations.saving);
        $.ajax({ url:'/api/devicemonitor/config/set', type:'POST', data:collectConfigData(), success:function(oResult) {
            $btn.prop('disabled',false).html(sOriginalHtml);
            if (oResult.result==='saved') {
                loadConfig();
                if (typeof fnSuccess === 'function') {
                    fnSuccess();
                } else {
                    showToast(oTranslations.config_saved,'success');
                }
            } else {
                showToast(oResult.message||oTranslations.config_error,'error');
            }
        }, error:function() {
            $btn.prop('disabled',false).html(sOriginalHtml);
            showToast(oTranslations.config_error,'error');
        }});
    }

    $('.btn-apply').click(function(){ saveConfig($(this)); });

    $('#btn-test-email').click(function() {
        var sEmail=$('#email_to').val();
        if (!sEmail) { showToast('{{ lang._('Please enter recipient email first') }}','error'); return; }
        var $testButton=$(this), sOriginalHtml=$testButton.html();

        // Save the current form first so the test always uses the selected
        // transport and the values currently visible in the UI.
        saveConfig($testButton, function() {
            $testButton.prop('disabled',true).html('<i class="fa fa-spinner fa-spin"></i>');
            $.ajax({ url:'/api/devicemonitor/config/testemail', type:'POST', success:function(oResult) {
                $testButton.prop('disabled',false).html(sOriginalHtml);
                var sTransport = oResult.transport ? ' ('+oResult.transport+')' : '';
                showToast(oResult.result==='sent'?oTranslations.test_sent+' '+sEmail+sTransport:(oResult.message||oTranslations.test_failed),
                          oResult.result==='sent'?'success':'error');
            }, error:function() {
                $testButton.prop('disabled',false).html(sOriginalHtml);
                showToast(oTranslations.test_failed,'error');
            }});
        });
    });

    // Otestuje aktuální URL a formát z formuláře bez uložení nastavení.
    $('#test_webhook').click(function() {
        var sUrl = $('#webhook_url').val().trim();
        var $result = $('#webhook_test_result');
        if (!sUrl && (!bSavedWebhook || $('#clear_webhook_url').is(':checked'))) {
            $result.css('color', 'red').text($('#dm-settings').attr('data-webhook-url-needed'));
            return;
        }
        $result.css('color', 'blue').text('⏳ {{ lang._('Sending...') }}');
        $.ajax({
            url: '/api/devicemonitor/config/testWebhook',
            type: 'POST',
            data: {webhook_url: sUrl, webhook_type: $('#webhook_type').val()},
            success: function(oResponse) {
                if (oResponse.result === 'ok') {
                    $result.css('color', 'green').text('✅ {{ lang._('Test sent!') }}');
                } else {
                    $result.css('color', 'red').text('❌ ' + (oResponse.message || '{{ lang._('Failed') }}'));
                }
            },
            error: function() {
                $result.css('color', 'red').text('❌ {{ lang._('Failed') }}');
            }
        });
    });

    // Load interfaces then config
    $.ajax({ url:'/api/devicemonitor/config/getinterfaces', type:'GET',
        success:function(oInterfaces){ oVlanNames=oInterfaces||{}; loadConfig(); },
        error:function(){ loadConfig(); }
    });
});
</script>
