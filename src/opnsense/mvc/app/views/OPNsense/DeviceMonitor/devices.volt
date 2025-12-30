<div class="content-box">
    <div class="content-box-main">
        <h1 style="padding-left: 10px;">{{ lang._('Device Monitor - Devices') }}</h1>
        
        <div style="margin-bottom: 15px;">
            <button id="btn-clear" class="btn btn-danger">
                <i class="fa fa-trash"></i> {{ lang._('Clear Database') }}
            </button>
        </div>
        
        <table id="grid-devices" class="table table-condensed table-hover table-striped">
            <thead>
                <tr>
                    <th data-column-id="mac" data-type="string" data-identifier="true" data-sortable="true">{{ lang._('MAC Address') }}</th>
                    <th data-column-id="ip" data-type="string" data-sortable="true">{{ lang._('IP Address') }}</th>
                    <th data-column-id="hostname" data-type="string" data-sortable="true">{{ lang._('Hostname') }}</th>
                    <th data-column-id="vendor" data-type="string" data-sortable="true">{{ lang._('Vendor') }}</th>
                    <th data-column-id="vlan" data-type="string" data-sortable="true">{{ lang._('VLAN') }}</th>
                    <th data-column-id="status" data-formatter="status" data-sortable="true">{{ lang._('Status') }}</th>
                    <th data-column-id="last_seen" data-type="string" data-sortable="true">{{ lang._('Last Seen')|e }}</th>
                    <th data-column-id="commands" data-formatter="commands" data-sortable="false">{{ lang._('Actions') }}</th>
                </tr>
            </thead>
            <tbody>
            </tbody>
        </table>
    </div>
</div>


<script>
$(document).ready(function() {
    var translations = {
        delete_device: '{{ lang._('Delete device') }}',
        clear_confirm: '{{ lang._('Really delete all devices from database?') }}',
        device_deleted: '{{ lang._('Device deleted') }}',
        error_deleting: '{{ lang._('Error deleting device') }}',
        database_cleared: '{{ lang._('Database cleared') }}',
        error_clearing: '{{ lang._('Error clearing database') }}'
    };
    
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
    
    var grid = $("#grid-devices").UIBootgrid({
        search: '/api/devicemonitor/devices/search',
        options: {
            sorting: true,
            multiSort: false,
            formatters: {
                status: function(column, row) {
                    if (row.status === 'online') {
                        return '<span style="color: #4CAF50; font-weight: bold;"><i class="fa fa-circle"></i> ONLINE</span>';
                    } else {
                        return '<span style="color: #999; font-weight: bold;"><i class="fa fa-circle-o"></i> OFFLINE</span>';
                    }
                },
                commands: function(column, row) {
                    return '<button class="btn btn-xs btn-danger command-delete" data-row-mac="' + row.mac + '">' +
                        '<i class="fa fa-trash"></i></button>';
                }
            }
        }
    }).on("loaded.rs.jquery.bootgrid", function() {
        // Bind delete button
        grid.find(".command-delete").off('click').on("click", function(e) {
            e.preventDefault();
            var mac = $(this).data("row-mac");
            
            if (!confirm(translations.delete_device + ' ' + mac + '?')) {
                return;
            }
            
            $.ajax({
                url: '/api/devicemonitor/devices/delete',
                type: 'POST',
                data: {mac: mac},
                success: function(response) {
                    if (response.result === 'deleted') {
                        showToast(translations.device_deleted, 'success');
                        grid.bootgrid('reload');
                    } else {
                        showToast(translations.error_deleting, 'error');
                    }
                },
                error: function() {
                    showToast(translations.error_deleting, 'error');
                }
            });
        });
    });
    
    $('#btn-clear').click(function() {
        //if (!confirm(translations.clear_confirm)) {
        //    return;
        //}
        
        $.ajax({
            url: '/api/devicemonitor/devices/clear',
            type: 'POST',
            success: function(response) {
                if (response.result === 'cleared') {
                    showToast(translations.database_cleared, 'success');
                    grid.bootgrid('reload');
                } else {
                    showToast(translations.error_clearing, 'error');
                }
            },
            error: function() {
                showToast(translations.error_clearing, 'error');
            }
        });
    });
});
</script>
