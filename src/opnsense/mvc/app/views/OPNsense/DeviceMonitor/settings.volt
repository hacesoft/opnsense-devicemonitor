<div class="content-box">
    <div class="content-box-main">
        <h1 style="padding-left: 10px;">{{ lang._('Device Monitor - Settings') }}</h1>
        
        <!-- Tabs -->
        <ul class="nav nav-tabs" role="tablist">
            <li role="presentation" class="active">
                <a href="#general" aria-controls="general" role="tab" data-toggle="tab">
                    <i class="fa fa-cog"></i> {{ lang._('General') }}
                </a>
            </li>
            <li role="presentation">
                <a href="#oui" aria-controls="oui" role="tab" data-toggle="tab">
                    <i class="fa fa-database"></i> {{ lang._('OUI Database') }}
                </a>
            </li>
        </ul>
        
        <!-- Tab Content -->
        <div class="tab-content" style="margin-top: 20px;">
            
            <!-- TAB 1: Obecné nastavení -->
            <div role="tabpanel" class="tab-pane active" id="general">
                <div class="alert alert-info">
                    <strong>Info:</strong> Zde můžeš nastavit emailové notifikace pro nová zařízení v síti.
                </div>
                
                <form>
                    <table class="table table-striped">
                        <tbody>
                            <tr>
                                <td style="width: 25%;"><strong>{{ lang._('Enable Monitoring') }}</strong></td>
                                <td>
                                    <input type="checkbox" id="enabled" />
                                    <small class="text-muted">{{ lang._('Enable automatic network monitoring') }}</small>
                                </td>
                            </tr>
                            <tr>
                                <td><strong>{{ lang._('Email Recipient') }}</strong></td>
                                <td>
                                    <input type="email" id="email_to" class="form-control" placeholder="admin@example.com" />
                                    <small class="text-muted">{{ lang._('Where to send notifications about new devices') }}</small>
                                </td>
                            </tr>
                            <tr>
                                <td><strong>{{ lang._('Email Sender') }}</strong></td>
                                <td>
                                    <input type="email" id="email_from" class="form-control" placeholder="devicemonitor@opnsense.local" value="devicemonitor@opnsense.local" />
                                    <small class="text-muted">{{ lang._('From which address to send notifications') }}</small>
                                </td>
                            </tr>
                            <tr>
                                <td><strong>{{ lang._('Scan Interval') }} (sekundy)</strong></td>
                                <td>
                                    <input type="number" id="scan_interval" class="form-control" value="300" min="60" max="3600" />
                                    <small class="text-muted">{{ lang._('Seconds between scans (60-3600)') }}</small>
                                </td>
                            </tr>
                            <tr>
                                <td><strong>{{ lang._('Hostname Display') }}</strong></td>
                                <td>
                                    <input type="checkbox" id="show_domain" />
                                    <small class="text-muted">{{ lang._('Show domain in hostname (e.g. device.localdomain)') }}</small>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                    
                    <div class="form-group">
                        <button type="button" id="btn-save" class="btn btn-primary">
                            <i class="fa fa-save"></i> {{ lang._('Save') }}
                        </button>
                        <button type="button" id="btn-test-email" class="btn btn-info" style="margin-left: 10px;">
                            <i class="fa fa-envelope"></i> {{ lang._('Test Email') }}
                        </button>
                    </div>
                </form>
                
                <hr>
                
                <div class="alert alert-warning">
                    <h4><i class="fa fa-exclamation-triangle"></i> {{ lang._('Important - SMTP Configuration') }}</h4>
                    <p>{{ lang._('Plugin uses <strong>sendmail (Postfix)</strong> to send emails') }}</p>
                    <p>{{ lang._('Must be configured in: <strong>System > Settings > Notifications > SMTP</strong>') }}</p>
                </div>
            </div>
            
            <!-- TAB 2: OUI Database -->
            <div role="tabpanel" class="tab-pane" id="oui">
                <div class="alert alert-info">
                    {{ lang._('OUI database contains ~30,000 network device manufacturers') }}<br>
                    {{ lang._('Used to identify vendor from MAC address (e.g. Apple, Samsung, Intel)') }}
                </div>
                
                <!-- Status databáze -->
                <div class="panel panel-default">
                    <div class="panel-heading">
                        <h3 class="panel-title">{{ lang._('Database Status') }}</h3>
                    </div>
                    <div class="panel-body">
                        <table class="table table-condensed">
                            <tr>
                                <td style="width: 25%;"><strong>{{ lang._('Status') }}:</strong></td>
                                <td><span id="db-status" class="label label-default">{{ lang._('Checking...') }}</span></td>
                            </tr>
                            <tr>
                                <td><strong>{{ lang._('File') }}:</strong></td>
                                <td><code id="db-file">/var/db/devicemonitor/oui.txt</code></td>
                            </tr>
                            <tr>
                                <td><strong>{{ lang._('Size') }}:</strong></td>
                                <td><span id="db-size">-</span></td>
                            </tr>
                            <tr>
                                <td><strong>{{ lang._('Vendor Count') }}:</strong></td>
                                <td><span id="db-count">-</span></td>
                            </tr>
                            <tr>
                                <td><strong>{{ lang._('Last Update') }}:</strong></td>
                                <td><span id="db-updated">-</span></td>
                            </tr>
                        </table>
                        
                        <button id="btn-download-now" class="btn btn-primary">
                            <i class="fa fa-download"></i> {{ lang._('Download Now') }}
                        </button>
                        <button id="btn-delete-db" class="btn btn-danger">
                            <i class="fa fa-trash"></i> {{ lang._('Delete Database') }}
                        </button>
                    </div>
                </div>
                
                <!-- Konfigurace URL -->
                <div class="panel panel-default">
                    <div class="panel-heading">
                        <h3 class="panel-title">{{ lang._('OUI Data Sources') }}</h3>
                    </div>
                    <div class="panel-body">
                        <p class="text-muted">
                            {{ lang._('Enter list of URLs to download OUI database from') }}.<br>
                            {{ lang._('Attempts will be made in order from top to bottom') }}.
                        </p>
                        
                        <div class="form-group">
                            <label>{{ lang._('URL sources (one per line)') }}:</label>
                            <textarea id="oui-urls" class="form-control" rows="5" style="font-family: monospace; min-width: 300px; max-width: 80%;"></textarea>
                            <small class="text-muted">
                                <strong>{{ lang._('Official IEEE sources:') }}</strong><br>
                                http://standards-oui.ieee.org/oui/oui.txt<br>
                                http://standards-oui.ieee.org/oui.txt<br>
                                http://standards.ieee.org/develop/regauth/oui/oui.txt
                            </small>
                        </div>
                    </div>
                </div>
                
                <!-- Automatické aktualizace -->
                <div class="panel panel-default">
                    <div class="panel-heading">
                        <h3 class="panel-title">{{ lang._('Automatic Updates') }}</h3>
                    </div>
                    <div class="panel-body">
                        <div class="form-group">
                            <label>
                                <input type="checkbox" id="auto-update-enabled" />
                                {{ lang._('Enable automatic updates') }}
                            </label>
                            <small class="text-muted">{{ lang._('Daily download of new database version') }}</small>
                        </div>
                        
                        <div class="form-group" id="auto-update-settings" style="display: none;">
                            <label>{{ lang._('Update Time') }}:</label>
                            <div class="row">
                                <div class="col-sm-3">
                                    <select id="update-hour" class="form-control">
                                        <option value="0">00:00</option>
                                        <option value="1">01:00</option>
                                        <option value="2">02:00</option>
                                        <option value="3" selected>03:00</option>
                                        <option value="4">04:00</option>
                                        <option value="5">05:00</option>
                                        <option value="6">06:00</option>
                                        <option value="7">07:00</option>
                                        <option value="8">08:00</option>
                                        <option value="9">09:00</option>
                                        <option value="10">10:00</option>
                                        <option value="11">11:00</option>
                                        <option value="12">12:00</option>
                                        <option value="13">13:00</option>
                                        <option value="14">14:00</option>
                                        <option value="15">15:00</option>
                                        <option value="16">16:00</option>
                                        <option value="17">17:00</option>
                                        <option value="18">18:00</option>
                                        <option value="19">19:00</option>
                                        <option value="20">20:00</option>
                                        <option value="21">21:00</option>
                                        <option value="22">22:00</option>
                                        <option value="23">23:00</option>
                                    </select>
                                </div>
                                <div class="col-sm-9">
                                    <small class="text-muted">
                                        {{ lang._('Recommended: 03:00 (at night, low load)') }}
                                    </small>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Uložit OUI -->
                <div class="form-group">
                    <button id="btn-save-oui" class="btn btn-primary btn-lg">
                        <i class="fa fa-save"></i> {{ lang._('Save OUI Settings') }}
                    </button>
                </div>
            </div>
            
        </div>
    </div>
</div>

<script>
$().ready(function() {
//$(document).ready(function() {
    // === PŘEKLADY - PŘIDEJ TOTO NA ZAČÁTEK ===
    var translations = {
        // General tab
        config_saved: '{{ lang._('Configuration saved') }}',
        config_error: '{{ lang._('Error saving configuration') }}',
        test_sent: '{{ lang._('Test email sent to') }}',
        test_failed: '{{ lang._('Failed to send email') }}',
        // OUI tab
        checking: '{{ lang._('Checking...') }}',
        installed: '{{ lang._('Installed') }}',
        not_installed: '{{ lang._('Not Installed') }}',
        downloading: '{{ lang._('Downloading...') }}',
        download_now: '{{ lang._('Download Now') }}',
        oui_downloaded: '{{ lang._('OUI database downloaded successfully') }}',
        download_failed: '{{ lang._('Download failed') }}',
        delete_confirm: '{{ lang._('Really delete OUI database?') }}\\n\\n{{ lang._('Vendor lookup will stop working until you download it again') }}',
        database_deleted: '{{ lang._('Database deleted') }}',
        error_deleting: '{{ lang._('Error deleting database') }}',
        saving: '{{ lang._('Saving...') }}',
        save_oui: '{{ lang._('Save OUI Settings') }}',
        oui_saved: '{{ lang._('OUI settings saved') }}',
        enter_url: '{{ lang._('Enter at least one URL') }}'
    };
    // === KONEC PŘEKLADŮ ===

    // Toast notifikace
    function showToast(message, type) {
        var bgColor = type === 'success' ? '#4CAF50' : (type === 'error' ? '#f44336' : '#2196F3');
        var icon = type === 'success' ? 'fa-check-circle' : (type === 'error' ? 'fa-exclamation-circle' : 'fa-info-circle');
        
        var toast = $('<div>')
            .css({
                'position': 'fixed',
                'top': '20px',
                'right': '20px',
                'background-color': bgColor,
                'color': 'white',
                'padding': '15px 20px',
                'border-radius': '4px',
                'box-shadow': '0 4px 8px rgba(0,0,0,0.3)',
                'z-index': 9999,
                'min-width': '300px',
                'display': 'none'
            })
            .html('<i class="fa ' + icon + '"></i> ' + message);
        
        $('body').append(toast);
        toast.fadeIn(300);
        
        setTimeout(function() {
            toast.fadeOut(300, function() { $(this).remove(); });
        }, 3000);
    }
    
    // ========================================
    // TAB 1: Obecné nastavení
    // ========================================
    
    function loadConfig() {
        $.ajax({
            url: '/api/devicemonitor/config/get',
            type: 'GET',
            success: function(data) {
                if (data.email_to) {
                    $('#email_to').val(data.email_to);
                }
                if (data.email_from) {
                    $('#email_from').val(data.email_from);
                }
                if (data.enabled == '1') {
                    $('#enabled').prop('checked', true);
                }
                if (data.scan_interval) {
                    $('#scan_interval').val(data.scan_interval);
                }
                if (data.show_domain == '1') {
                    $('#show_domain').prop('checked', true);
                }
            }
        });
    }
    
    loadConfig();
    
    $('#btn-save').click(function() {
        var $btn = $(this);
        var originalHtml = $btn.html();
        $btn.prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> Ukládám...');
        
        var config = {
            enabled: $('#enabled').is(':checked') ? '1' : '0',
            email_to: $('#email_to').val(),
            email_from: $('#email_from').val(),
            scan_interval: $('#scan_interval').val(),
            show_domain: $('#show_domain').is(':checked') ? '1' : '0',
        };
        
        $.ajax({
            url: '/api/devicemonitor/config/set',
            type: 'POST',
            data: config,
            success: function(response) {
                $btn.prop('disabled', false).html(originalHtml);
                
                if (response.result === 'saved') {
                    showToast(translations.config_saved, 'success');
                } else {
                    showToast(response.message || translations.config_error, 'error');
                }
            },
            error: function() {
                $btn.prop('disabled', false).html(originalHtml);
                //showToast('Chyba při ukládání konfigurace', 'error');
                showToast(translations.configSave_error, 'error');
            }
        });
    });
    
    $('#btn-test-email').click(function() {
        var email = $('#email_to').val();
        
        if (!email) {
            showToast('Nejprve vyplň a ulož emailovou adresu příjemce', 'error');
            return;
        }
        
        var $btn = $(this);
        var originalHtml = $btn.html();
        $btn.prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> Odesílám...');
        
        $.ajax({
            url: '/api/devicemonitor/config/testemail',
            type: 'POST',
            success: function(response) {
                $btn.prop('disabled', false).html(originalHtml);
                
                if (response.result === 'sent') {
                    showToast(translations.test_sent + ' ' + email, 'success');
                } else {
                    showToast(response.message || translations.test_failed, 'error');
                }
            },
            error: function() {
                $btn.prop('disabled', false).html(originalHtml);
                //showToast('Chyba při odesílání emailu', 'error');
                showToast(translations.stansmition_failed, 'error');
            }
        });
    });
    
    // ========================================
    // TAB 2: OUI Database
    // ========================================
    
    function loadDbStatus() {
        $.ajax({
            url: '/api/devicemonitor/oui/status',
            type: 'GET',
            success: function(data) {
                //Zobrazeni statusu hlasky
                 if (data.exists) {
                    $('#db-status').removeClass().addClass('label label-success').text('Installed');
                    $('#db-size').text(data.size);
                    $('#db-count').text(data.count);
                    $('#db-updated').text(data.updated);
                } else {
                    $('#db-status').removeClass().addClass('label label-warning').text('Not installed');
                    $('#db-size').text('-');
                    $('#db-count').text('-');
                    $('#db-updated').text('-');
                }
            }
        });
    }
    
    function loadOuiConfig() {
        $.ajax({
            url: '/api/devicemonitor/oui/getconfig',
            type: 'GET',
            success: function(data) {
                if (data.urls && data.urls.length > 0) {
                    $('#oui-urls').val(data.urls.join('\n'));
                } else {
                    $('#oui-urls').val(
                        'http://standards-oui.ieee.org/oui/oui.txt\n' +
                        'http://standards-oui.ieee.org/oui.txt\n' +
                        'http://standards.ieee.org/develop/regauth/oui/oui.txt'
                    );
                }
                
                // OPRAVENO: Přidán else pro vypnutí
                if (data.auto_update_enabled == '1') {
                    $('#auto-update-enabled').prop('checked', true);
                    $('#auto-update-settings').show();
                } else {
                    $('#auto-update-enabled').prop('checked', false);
                    $('#auto-update-settings').hide();
                }
                
                if (data.update_hour) {
                    $('#update-hour').val(data.update_hour);
                }
            }
        });
    }
    
    // Načti při zobrazení OUI tabu
    $('a[href="#oui"]').on('shown.bs.tab', function() {
        loadDbStatus();
        loadOuiConfig();
    });
    
    $('#auto-update-enabled').change(function() {
        if ($(this).is(':checked')) {
            $('#auto-update-settings').slideDown();
        } else {
            $('#auto-update-settings').slideUp();
        }
    });
    
    //Tlačítko download now
    $('#btn-download-now').click(function() {
       // if (!confirm(translations.delete_confirm)) {
       //         return;
       //     }


        var $btn = $(this);
        $btn.prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> ' + translations.downloading);
        
        // Nastav status na "Downloading..."
        $('#db-status').removeClass().addClass('label label-info').html('<i class="fa fa-spinner fa-spin"></i> Downloading...');
        
        $.ajax({
            url: '/api/devicemonitor/oui/download',
            type: 'POST',
            timeout: 120000,
            success: function(data) {
                if (data.result === 'success') {
                    showToast(translations.oui_downloaded + ' (' + data.size + ')', 'success');
                    
                    // Zobraz log pokud chceš vidět detaily
                    if (data.log) {
                        console.log('Download log:', data.log);
                    }
                    
                    loadDbStatus();  // Refresh status
                } else {
                    // Chyba - zobraz hlavní hlášku
                    showToast(data.message || translations.download_failed, 'error');
                    
                    // Zobraz detailní log v konzoli
                    if (data.log) {
                        console.error('Download failed. Log:', data.log);
                    }
                    
                    // Zobraz poslední chybu jako toast
                    if (data.error) {
                        setTimeout(function() {
                            showToast('Last error: ' + data.error, 'error');
                        }, 2000);
                    }
                    
                    // Nastav status na červenou
                    $('#db-status').removeClass().addClass('label label-danger').text(translations.download_failed);
                }
                
                $btn.prop('disabled', false).html('<i class="fa fa-download"></i> ' + translations.download_now);
            },
            error: function(xhr, status, error) {
                var errorMsg = 'Download failed';
                
                if (status === 'timeout') {
                    errorMsg = 'Timeout - download took too long (>2 minutes)';
                } else if (xhr.status === 0) {
                    errorMsg = 'Network error - check connection';
                } else if (xhr.status === 404) {
                    errorMsg = 'API not found (404)';
                } else if (xhr.status === 500) {
                    errorMsg = 'Server error (500) - check logs';
                }
                
                showToast(errorMsg, 'error');
                $('#db-status').removeClass().addClass('label label-danger').text('Error');
                
                $btn.prop('disabled', false).html('<i class="fa fa-download"></i> ' + translations.download_now);
            }
        });
    });
    
    //Tlačítko delete database
    $('#btn-delete-db').click(function() {
        //if (!confirm(translations.delete_confirm)) {
        //    return;
        //}
        
        $.ajax({
            url: '/api/devicemonitor/oui/delete',
            type: 'POST',
            success: function(data) {
                if (data.result === 'success') {
                    showToast(translations.oui_downloaded, 'success');
                    loadDbStatus();
                } else {
                    showToast(translations.download_failed, 'error');
                }
            }
        });
    });
    
    // Uložit OUI nastavení
    $('#btn-save-oui').click(function() {
        var $btn = $(this);
        $btn.prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> ' + translations.saving);
        
        var urls = $('#oui-urls').val().split('\n')
            .map(function(url) { return url.trim(); })
            .filter(function(url) { return url.length > 0; });
        
        if (urls.length === 0) {
            showToast(translations.enter_url, 'error');
            $btn.prop('disabled', false).html('<i class="fa fa-save"></i> ' + translations.save_oui);
            return;
        }
        
        var config = {
            urls: urls,
            auto_update_enabled: $('#auto-update-enabled').is(':checked') ? '1' : '0',
            update_hour: $('#update-hour').val()
        };
        
        $.ajax({
            url: '/api/devicemonitor/oui/setconfig',
            type: 'POST',
            data: JSON.stringify(config),
            contentType: 'application/json',
            success: function(data) {
            if (data.result === 'saved') {
                showToast('OUI nastavení uloženo', 'success');
                // Pokud byl zapnut auto-update, upozorni
                //if ($('#auto-update-enabled').is(':checked')) {
                if (config.auto_update_enabled === '1') {
                    showToast('Automatická aktualizace nastavena na ' + $('#update-hour').val() + ':00', 'info');
                }
            } else {
                showToast(data.message || 'Chyba při ukládání nastavení', 'error');
            }
            $btn.prop('disabled', false).html('<i class="fa fa-save"></i> Save OUI Settings');
        },
            error: function() {
                showToast(translations.oui_saved_error, 'error');
                $btn.prop('disabled', false).html('<i class="fa fa-save"></i> ' + translations.save_oui);
            }
        });
    });
});
</script>