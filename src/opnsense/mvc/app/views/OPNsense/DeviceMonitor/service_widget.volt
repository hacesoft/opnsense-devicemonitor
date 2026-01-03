<div id="devicemonitor_service_widget">
    <table class="table table-striped table-condensed">
        <tbody>
            <tr>
                <td>Status:</td>
                <td id="devicemonitor_status">...</td>
            </tr>
        </tbody>
    </table>
</div>

<script>
    function update_devicemonitor_status() {
        ajaxGet('/api/devicemonitor/service/status', {}, function(data, status) {
            if (status == 'success') {
                $('#devicemonitor_status').html(data.status);
            }
        });
    }
    
    $(document).ready(function() {
        update_devicemonitor_status();
        setInterval(update_devicemonitor_status, 5000);
    });
</script>