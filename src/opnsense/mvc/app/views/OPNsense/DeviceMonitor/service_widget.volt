{# Předpony: b = příznak, o = objekt, s = řetězec.
   Historie: 2.3.7 – sjednocení typových předpon proměnných.
   2.3.3 – popisek počtu zařízení zaznamenaných v Hostwatch (#10). #}
<div id="devicemonitor_widget">
    <table class="table table-striped table-condensed">
        <tbody>
            <tr>
                <td style="color:#aaa;">Status</td>
                <td><span id="dm_widget_status" class="label label-default">...</span></td>
            </tr>
            <tr>
                <td style="color:#aaa;">Total</td>
                <td><strong id="dm_widget_total">—</strong></td>
            </tr>
            <tr>
                <td style="color:#aaa;"> {{ lang._('Seen in the last 15 minutes') }}</td>
                <td><strong id="dm_widget_online" style="color:#4CAF50;">—</strong></td>
            </tr>
        </tbody>
    </table>
</div>

<script>
function update_devicemonitor_widget() {
    ajaxGet('/api/devicemonitor/service/status', {}, function(oResponse, sStatus) {
        if (sStatus === 'success') {
            var bRunning = oResponse.result === 'running';
            $('#dm_widget_status')
                .removeClass('label-default label-success label-danger')
                .addClass(bRunning ? 'label-success' : 'label-danger')
                .text(bRunning ? 'Running (PID: '+oResponse.pid+')' : 'Stopped');
        }
    });
    ajaxGet('/api/devicemonitor/devices/stats', {}, function(oResponse, sStatus) {
        if (sStatus === 'success') {
            $('#dm_widget_total').text(oResponse.total || 0);
            $('#dm_widget_online').text(oResponse.online || 0);
        }
    });
}

$(document).ready(function() {
    update_devicemonitor_widget();
    setInterval(update_devicemonitor_widget, 10000);
});
</script>