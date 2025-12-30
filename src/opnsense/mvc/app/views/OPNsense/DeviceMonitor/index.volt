<div class="content-box">
    <div class="content-box-main">
        <h1 style="padding-left: 10px;">{{ lang._('Device Monitor - Dashboard') }}</h1>
        
        <!-- Status daemona -->
        <div class="row" style="margin-top: 20px;">
            <div class="col-md-12">
                <div class="panel panel-default">
                    <div class="panel-heading">
                        <h3 class="panel-title">{{ lang._('Daemon Status') }}</h3>
                    </div>
                    <div class="panel-body">
                        <p>
                            <strong>Daemon:</strong> 
                            <span id="daemon-status" class="label label-default">{{ lang._('Checking...') }}</span>
                        </p>
                        <button id="btn-start" class="btn btn-success" style="display:none;">
                            <i class="fa fa-play"></i> {{ lang._('Start') }}
                        </button>
                        <button id="btn-stop" class="btn btn-danger" style="display:none;">
                            <i class="fa fa-stop"></i> {{ lang._('Stop') }}
                        </button>
                        <button id="btn-restart" class="btn btn-warning" style="display:none;">
                            <i class="fa fa-refresh"></i> {{ lang._('Restart') }}
                        </button>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Statistiky -->
        <div class="row" style="margin-top: 20px;">
            <div class="col-md-6">
                <div class="panel panel-primary" style="border: 2px solid #328eb1;">
                    <div style="color: #fff; background-color: #328eb1; padding: 10px 15px;">
                        <h3 style="margin: 0; font-size: 16px;">{{ lang._('Total Devices') }}</h3>
                    </div>
                    <div class="panel-body" style="text-align: center;">
                        <h2 id="total-devices" style="font-size: 48px; margin: 20px 0;">0</h2>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="panel panel-primary" style="border: 2px solid #328eb1;">
                    <div style="color: #fff; background-color: #328eb1; padding: 10px 15px;">
                        <h3 style="margin: 0; font-size: 16px;">{{ lang._('Online') }}</h3>
                    </div>
                    <div class="panel-body" style="text-align: center;">
                        <h2 id="online-devices" style="font-size: 48px; margin: 20px 0;">0</h2>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Akce -->
        <div class="row" style="margin-top: 20px;">
            <div class="col-md-12">
                <button id="btn-scan" class="btn btn-primary btn-lg" style="background-color: #328eb1; border-color: #328eb1;">
                    <i class="fa fa-refresh"></i> {{ lang._('Manual Scan') }}
                </button>
                <a href="/ui/devicemonitor/index/devices" class="btn btn-default btn-lg">
                    <i class="fa fa-list"></i> {{ lang._('Devices') }}
                </a>
                <a href="/ui/devicemonitor/index/settings" class="btn btn-default btn-lg">
                    <i class="fa fa-cog"></i> {{ lang._('Settings') }}
                </a>
            </div>
        </div>
    </div>
</div>

<script>
$().ready(function() {
    // === PŘEKLADY - PŘIDEJ TOTO NA ZAČÁTEK ===
    var translations = {
        running: '{{ lang._('Running') }}',
        stopped: '{{ lang._('Stopped') }}',
        pid: '{{ lang._('PID') }}',
        daemon_started: '{{ lang._('Daemon started successfully') }}',
        daemon_failed_start: '{{ lang._('Failed to start daemon') }}',
        daemon_stopped: '{{ lang._('Daemon stopped successfully') }}',
        daemon_failed_stop: '{{ lang._('Failed to stop daemon') }}',
        daemon_restarted: '{{ lang._('Daemon restarted successfully') }}',
        daemon_failed_restart: '{{ lang._('Failed to restart daemon') }}',
        restarting: '{{ lang._('Daemon restarted successfully') }}',
        scan_completed: '{{ lang._('Scan completed') }}',
        scan_failed: '{{ lang._('Scan completed') }}',
        scanning: '{{ lang._('Manual Scan') }}'
    };
    // === KONEC PŘEKLADŮ ===
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
    
    function loadStats() {
        $.ajax({
            url: '/api/devicemonitor/devices/stats',            // ← Volá API endpoint
            type: 'GET',
            success: function(data) {
                $('#total-devices').text(data.total || 0);      // ← Použije data.total
                $('#online-devices').text(data.online || 0);    // ← Použije data.online
            }
        });
    }
    
    function checkDaemonStatus() {
        $.ajax({
            url: '/api/devicemonitor/service/status',
            type: 'GET',
            success: function(data) {
                if (data.result === 'running') {
                    $('#daemon-status').removeClass().addClass('label label-success').text(translations.running + ' (PID: ' + data.pid + ')');
                    $('#btn-start').hide();
                    $('#btn-stop, #btn-restart').show();
                } else {
                    $('#daemon-status').removeClass().addClass('label label-danger').text(translations.stopped);
                    $('#btn-start').show();
                    $('#btn-stop, #btn-restart').hide();
                }
            }
        });
    }

    function updateOnlineStatus() {
        $.ajax({
            url: '/api/devicemonitor/devices/updatestatus',
            type: 'POST',
            success: function(data) {
                if (data.result === 'ok') {
                    // Aktualizuj jen online počet
                    $('#online-devices').text(data.online || 0);
                }
            }
        });
    }
    
    // Načti při startu
    updateOnlineStatus();       
    loadStats();
    checkDaemonStatus();
    
    // Refresh každých 60s
    setInterval(function() {
        updateOnlineStatus();  // Rychlá aktualizace (pfctl)
        loadStats();           // Celkové statistiky
    }, 60000);
    // Refresh každých 10s
    setInterval(checkDaemonStatus, 10000);
    
    // Manuální sken
    $('#btn-scan').click(function() {
        var $btn = $(this);
        $btn.prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> Skenuji...');
        
        $.ajax({
            url: '/api/devicemonitor/service/scan',
            type: 'POST',
            success: function(data) {
                showToast(translations.scan_completed, 'success');
                //showToast('Sken dokončen', 'success');
                setTimeout(function() {
                    loadStats();
                    $btn.prop('disabled', false).html('<i class="fa fa-refresh"></i> Manuální sken');
                }, 2000);
            },
            error: function() {
                showToast(translations.scan_error, 'error');
                $btn.prop('disabled', false).html('<i class="fa fa-refresh"></i> Manuální sken');
            }
        });
    });
    
    // Start daemon
    $('#btn-start').click(function() {
        var $btn = $(this);
        $btn.prop('disabled', true);
        
        $.ajax({
            url: '/api/devicemonitor/service/start',
            type: 'POST',
            success: function(data) {
                if (data.result === 'started' || data.result === 'already_running') {
                    showToast(translations.daemon_started, 'success');
                } else {
                    showToast(translations.daemon_failed_start, 'error');
                }
                $btn.prop('disabled', false);
                checkDaemonStatus();
            }
        });
    });
    
    // Stop daemon
    $('#btn-stop').click(function() {
        var $btn = $(this);
        $btn.prop('disabled', true);
        
        $.ajax({
            url: '/api/devicemonitor/service/stop',
            type: 'POST',
            success: function(data) {
                if (data.result === 'stopped') {
                    showToast(translations.daemon_stopped, 'success');
                } else {
                    showToast(translations.daemon_failed_stop, 'error');
                }
                $btn.prop('disabled', false);
                checkDaemonStatus();
            }
        });
    });
    
    // Restart daemon
    $('#btn-restart').click(function() {
        var $btn = $(this);
        $btn.prop('disabled', true);
        
        showToast('Restartuji daemon...', 'info');
        
        $.ajax({
            url: '/api/devicemonitor/service/restart',
            type: 'POST',
            success: function(data) {
                if (data.result === 'started') {
                    showToast(translations.daemon_restarted, 'success');
                } else {
                    showToast(translations.daemon_failed_restart, 'error');
                }
                $btn.prop('disabled', false);
                checkDaemonStatus();
            }
        });
    });
});
</script>