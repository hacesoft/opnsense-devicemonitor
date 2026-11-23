{# Předpony v upraveném kódu: arr = pole, o = objekt, s = řetězec, $ = objekt jQuery.
   Historie: 2.3.1 – názvy z konfigurace se zobrazují jako text. #}
<div class="content-box">
    <div class="content-box-main">

        <!-- Header s verzí a statistikami -->
        <div style="padding:10px 10px 8px 10px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;border-bottom:1px solid #333;margin-bottom:12px;">
            <h1 style="margin:0;font-size:20px;">
                {{ lang._('Device Monitor') }}
                <small id="plugin-version" style="font-size:13px;color:#888;margin-left:5px;"></small>
                <span style="color:#555;margin:0 8px;">–</span>
                <span style="font-weight:normal;">{{ lang._('Devices') }}</span>
            </h1>
            <div style="display:flex;gap:20px;align-items:center;">
                <span style="font-size:13px;color:#888;">
                    {{ lang._('Total Devices') }}:
                    <strong id="stat-total" style="color:#ccc;font-size:16px;margin-left:4px;">—</strong>
                </span>
                <span style="font-size:13px;color:#888;">
                    {{ lang._('Online') }}:
                    <strong id="stat-online" style="color:#4CAF50;font-size:16px;margin-left:4px;">—</strong>
                </span>
            </div>
        </div>

        <!-- Toolbar -->
        <div style="padding:0 4px 12px 4px;display:flex;gap:8px;align-items:center;flex-wrap:wrap;">

            <!-- Multi-select VLAN dropdown -->
            <div class="dropdown" id="vlan-filter-wrapper" style="display:inline-block;">
                <button type="button" class="btn btn-default dropdown-toggle"
                        id="vlan-dropdown-toggle" data-toggle="dropdown"
                        style="min-width:160px;text-align:left;">
                    <span id="vlan-filter-label">{{ lang._('All VLANs') }}</span>
                    <span class="caret" style="float:right;margin-top:7px;"></span>
                </button>
                <ul class="dropdown-menu" id="vlan-checklist"
                    style="min-width:240px;padding:4px 0;max-height:300px;overflow-y:auto;">
                </ul>
            </div>

            <!-- Status filtr -->
            <select id="filter-status" class="form-control" style="width:auto;min-width:130px;">
                <option value="">{{ lang._('All statuses') }}</option>
                <option value="online">🟢 Online</option>
                <option value="offline">⚫ Offline</option>
            </select>

            <button id="btn-refresh" class="btn btn-default" title="{{ lang._('Refresh') }}">
                <i class="fa fa-refresh"></i>
            </button>

            <button id="btn-scan-now" class="btn btn-default" title="{{ lang._('Run scan now') }}">
                <i class="fa fa-search"></i>
            </button>

            <button id="btn-export" class="btn btn-default" title="{{ lang._('Export to CSV') }}">
                <i class="fa fa-download"></i>
            </button>

            <div style="flex-grow:1;"></div>

            <button id="btn-clear" class="btn btn-danger">
                <i class="fa fa-trash"></i> {{ lang._('Clear Database') }}
            </button>
        </div>

        <!-- Tabulka -->
        <table class="table table-condensed table-hover table-striped" id="grid-devices" style="margin-top:0;border-top:2px solid #444;">
            <thead>
                <tr>
                    <th class="sortable" data-col="mac" style="cursor:pointer;white-space:nowrap;">{{ lang._('MAC Address') }} <i class="fa fa-sort"></i></th>
                    <th class="sortable" data-col="ip" style="cursor:pointer;white-space:nowrap;">{{ lang._('IP Address') }} <i class="fa fa-sort"></i></th>
                    <th class="sortable" data-col="hostname" style="cursor:pointer;white-space:nowrap;">{{ lang._('Hostname') }} <i class="fa fa-sort"></i></th>
                    <th class="sortable" data-col="vendor" style="cursor:pointer;white-space:nowrap;">{{ lang._('Vendor') }} <i class="fa fa-sort"></i></th>
                    <th class="sortable" data-col="vlan" style="cursor:pointer;white-space:nowrap;">{{ lang._('VLAN') }} <i class="fa fa-sort"></i></th>
                    <th class="sortable" data-col="status" style="cursor:pointer;white-space:nowrap;">{{ lang._('Status') }} <i class="fa fa-sort"></i></th>
                    <th class="sortable" data-col="last_seen" style="cursor:pointer;white-space:nowrap;">{{ lang._('Last Seen') }} <i class="fa fa-sort"></i></th>
                    <th style="white-space:nowrap;">{{ lang._('Actions') }}</th>
                </tr>
            </thead>
            <tbody></tbody>
        </table>
    </div>
</div>


<script>
$(document).ready(function() {

    var translations = {
        deleted:        '{{ lang._('Device deleted') }}',
        delete_error:   '{{ lang._('Error deleting device') }}',
        db_cleared:     '{{ lang._('Database cleared') }}',
        db_clear_error: '{{ lang._('Error clearing database') }}',
        hostname_saved: '{{ lang._('Hostname saved') }}',
        hostname_error: '{{ lang._('Error saving hostname') }}',
        confirm_delete: '{{ lang._('Delete device') }}',
        confirm_clear:  '{{ lang._('Really delete all devices from database?') }}',
        all_vlans:      '{{ lang._('All VLANs') }}'
    };

    var allRows = [], activeVlans = [], activeStatus = '', vlanNames = {};
    var sortCol = 'last_seen', sortDir = 'desc';

    // Obnov uložený VLAN filtr
    try { activeVlans = JSON.parse(localStorage.getItem('dm_vlan_filter') || '[]'); } catch(e) {}

    // Toast
    function showToast(msg, type) {
        var bg = type==='success'?'#4CAF50':(type==='error'?'#f44336':'#2196F3');
        var ic = type==='success'?'fa-check-circle':(type==='error'?'fa-exclamation-circle':'fa-info-circle');
        var $t = $('<div>').css({position:'fixed',top:'20px',right:'20px','background-color':bg,color:'white',
            padding:'15px 20px','border-radius':'4px','box-shadow':'0 4px 8px rgba(0,0,0,.3)',
            'z-index':9999,'min-width':'280px',display:'none'})
            .html('<i class="fa '+ic+'"></i> '+msg);
        $('body').append($t); $t.fadeIn(300);
        setTimeout(function(){ $t.fadeOut(300,function(){ $t.remove(); }); },3000);
    }

    // Verze + statistiky
    $.getJSON('/api/devicemonitor/config/getversion', function(d) {
        $('#plugin-version').text('v'+(d.version||'?'));
    });

    function loadStats() {
        $.ajax({url:'/api/devicemonitor/devices/stats',type:'GET',success:function(d){
            $('#stat-total').text(d.total||0);
            $('#stat-online').text(d.online||0);
        }});
    }

    // VLAN multi-select dropdown
    function buildVlanDropdown(vlans) {
        var $list = $('#vlan-checklist').empty();
        if (!vlans.length) return;
        var allSel = (activeVlans.length === 0);

        $list.append($('<li>').append(
            $('<a>').attr('href','#').css({padding:'5px 14px',display:'flex',alignItems:'center',justifyContent:'space-between'}).append(
                $('<label>').css({margin:0,cursor:'pointer',display:'flex',alignItems:'center',gap:'6px'}).append(
                    $('<input type="checkbox" id="vlan-all">').prop('checked', allSel),
                    $('<span>').css({'font-style':'italic'}).text(translations.all_vlans)
                ),
                $('<a>').attr('href','#').addClass('vlan-select-none')
                    .css({fontSize:'11px',color:'#aaa',marginLeft:'12px',whiteSpace:'nowrap'})
                    .text('Select none')
                    .on('click', function(e){
                        e.preventDefault();
                        e.stopPropagation();
                        // Reset = všechny odškrtnuté + All VLANs zaškrtnuté = žádný filtr
                        $('#vlan-checklist .vlan-cb').prop('checked', false);
                        $('#vlan-all').prop('checked', true);
                        activeVlans = [];
                        try { localStorage.setItem('dm_vlan_filter', JSON.stringify([])); } catch(e2) {}
                        updateVlanLabel();
                        applyFilters();
                    })
            )
        ));

        $list.append($('<li class="divider" style="margin:4px 0;">'));

        vlans.sort().forEach(function(v) {
            var n = vlanNames[v];
            var label = (n && n !== v) ? (v+' \u2013 '+n) : v;
            var chk = allSel || (activeVlans.indexOf(v) !== -1);
            $list.append($('<li>').append(
                $('<a>').attr('href','#').css({padding:'4px 14px',display:'block'}).append(
                    $('<input type="checkbox" class="vlan-cb">').val(v).prop('checked', chk),
                    $('<span>').css('margin-left','8px').text(label)
                )
            ));
        });
        updateVlanLabel();
    }

    // Dropdown nezavírat při kliknutí na checkbox
    $('#vlan-checklist').on('click', function(e){ e.stopPropagation(); });

    $(document).on('change','#vlan-all',function(){
        $('#vlan-checklist .vlan-cb').prop('checked',$(this).prop('checked'));
        persistVlans();
    });
    $(document).on('change','#vlan-checklist .vlan-cb',function(){
        var total=$('#vlan-checklist .vlan-cb').length;
        var checked=$('#vlan-checklist .vlan-cb:checked').length;
        $('#vlan-all').prop('checked', total===checked);
        persistVlans();
    });

    function persistVlans() {
        var sel = [];
        var total = $('#vlan-checklist .vlan-cb').length;
        $('#vlan-checklist .vlan-cb:checked').each(function(){ sel.push($(this).val()); });

        if (sel.length === total || sel.length === 0) {
            // Všechny zaškrtnuté NEBO žádná = žádný filtr
            activeVlans = [];
            $('#vlan-all').prop('checked', true);
        } else {
            activeVlans = sel;
            $('#vlan-all').prop('checked', false);
        }
        try { localStorage.setItem('dm_vlan_filter', JSON.stringify(activeVlans)); } catch(e) {}
        updateVlanLabel();
        applyFilters();
    }

    function updateVlanLabel() {
        if (!activeVlans.length) {
            $('#vlan-filter-label').text(translations.all_vlans);
        } else if (activeVlans.length===1) {
            var n=vlanNames[activeVlans[0]];
            $('#vlan-filter-label').text(activeVlans[0]+(n?' \u2013 '+n:''));
        } else {
            $('#vlan-filter-label').text(activeVlans.length+' VLANs');
        }
    }

    // Filtrování
    function applyFilters() {
        if (!allRows || !allRows.length) return;
        var filtered = allRows.filter(function(r){
            var vo = !activeVlans.length || activeVlans.indexOf(r.vlan) !== -1;
            var so = !activeStatus || r.status === activeStatus;
            return vo && so;
        });
        // Řazení
        filtered.sort(function(a, b) {
            var va = a[sortCol] || '';
            var vb = b[sortCol] || '';

            // Numerické řazení pro IP adresy
            if (sortCol === 'ip') {
                var ia = va.split('.').map(Number);
                var ib = vb.split('.').map(Number);
                for (var i = 0; i < 4; i++) {
                    if ((ia[i]||0) !== (ib[i]||0)) {
                        var cmp = (ia[i]||0) < (ib[i]||0) ? -1 : 1;
                        return sortDir === 'asc' ? cmp : -cmp;
                    }
                }
                return 0;
            }

            // Numerické řazení pro MAC adresu (hex)
            if (sortCol === 'mac') {
                var ma = va.replace(/:/g,'').toLowerCase();
                var mb = vb.replace(/:/g,'').toLowerCase();
                var cmp = ma < mb ? -1 : ma > mb ? 1 : 0;
                return sortDir === 'asc' ? cmp : -cmp;
            }

            // Textové řazení pro ostatní
            va = va.toString().toLowerCase();
            vb = vb.toString().toLowerCase();
            if (va === vb) return 0;
            var cmp = va < vb ? -1 : 1;
            return sortDir === 'asc' ? cmp : -cmp;
        });

        renderTable(filtered);
        // Aktualizuj ikony šipek
        $('th.sortable .fa').removeClass('fa-sort-asc fa-sort-desc').addClass('fa-sort');
        $('th.sortable[data-col="'+sortCol+'"] .fa')
            .removeClass('fa-sort')
            .addClass(sortDir === 'asc' ? 'fa-sort-asc' : 'fa-sort-desc');
    }

    // Vstup: řádky zařízení. Výstup: aktualizovaná tabulka v DOM.
    function renderTable(arrRows) {
        var $tbody = $('#grid-devices tbody').empty();
        arrRows.forEach(function(oRow) {
            var sMac = oRow.mac || '';
            var sIp = oRow.ip || '';
            var sHostname = oRow.hostname || '';
            var sStatusHtml = oRow.status === 'online'
                ? '<span style="color:#4CAF50;font-weight:bold;white-space:nowrap;"><i class="fa fa-circle"></i> ONLINE</span>'
                : '<span style="color:#666;font-weight:bold;white-space:nowrap;"><i class="fa fa-circle-o"></i> OFFLINE</span>';

            var $hostname = $('<span class="hostname-display" title="Click to edit" style="cursor:pointer;border-bottom:1px dashed #666;">')
                .attr('data-mac', sMac)
                .text(sHostname);
            if (!sHostname) {
                $hostname.append($('<em style="color:#555;">').text('—'));
            }

            var $ipCell = $('<td>').text(sIp);
            if (/^\d{1,3}(\.\d{1,3}){3}$/.test(sIp)) {
                $ipCell.empty().append($('<a target="_blank" rel="noopener noreferrer" style="color:#5bc0de;">')
                    .attr('href', 'http://' + sIp)
                    .text(sIp));
            }

            var sVlanLabel = oRow.vlan || '';
            if (oRow.vlan && vlanNames[oRow.vlan]) {
                sVlanLabel += ' – ' + vlanNames[oRow.vlan];
            }

            var $check = $('<button class="btn btn-xs btn-warning command-check" title="Check online" style="margin-right:2px;"><i class="fa fa-plug"></i></button>')
                .attr({'data-row-mac': sMac, 'data-row-ip': sIp});
            var $delete = $('<button class="btn btn-xs btn-danger command-delete"><i class="fa fa-trash"></i></button>')
                .attr('data-row-mac', sMac);

            $('<tr>').append(
                $('<td>').text(sMac),
                $ipCell,
                $('<td>').append($hostname),
                $('<td>').text(oRow.vendor || ''),
                $('<td>').text(sVlanLabel),
                $('<td>').html(sStatusHtml),
                $('<td>').text(oRow.last_seen || ''),
                $('<td>').append($check, $delete)
            ).appendTo($tbody);
        });
        bindButtons();
    }

    // Načtení dat
    function loadDevices() {
        $.ajax({url:'/api/devicemonitor/devices/search',type:'POST',
            data:{rowCount:-1,current:1,searchPhrase:''},
            success:function(data){
                allRows = data.rows||[];
                var vlans={};
                allRows.forEach(function(r){ if(r.vlan) vlans[r.vlan]=1; });
                buildVlanDropdown(Object.keys(vlans));
                applyFilters();
            }
        });
    }

    function bindButtons() {
        $('.command-delete').off('click').on('click',function(){
            var mac=$(this).data('row-mac');
            if (!confirm(translations.confirm_delete+' '+mac+'?')) return;
            $.ajax({url:'/api/devicemonitor/devices/delete',type:'POST',data:{mac:mac},
                success:function(r){
                    showToast(r.result==='deleted'?translations.deleted:translations.delete_error,
                              r.result==='deleted'?'success':'error');
                    loadDevices(); loadStats();
                }
            });
        });

        $('.command-check').off('click').on('click', function() {
            var mac = $(this).data('row-mac');
            var ip  = $(this).data('row-ip');
            var $btn = $(this);

            if (!ip) {
                showToast('No IP address for this device', 'error');
                return;
            }

            $btn.prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i>');

            $.ajax({
                url: '/api/devicemonitor/devices/pingdevice',
                type: 'POST',
                data: { mac: mac, ip: ip },
                success: function(r) {
                    $btn.prop('disabled', false).html('<i class="fa fa-plug"></i>');
                    if (r.result === 'online') {
                        showToast(ip + ' ONLINE', 'success');
                    } else if (r.result === 'offline') {
                        showToast(ip + ' OFFLINE', 'error');
                    }
                    loadDevices();
                },
                error: function() {
                    $btn.prop('disabled', false).html('<i class="fa fa-plug"></i>');
                    showToast('Ping failed', 'error');
                }
            });
        });
    }

    // Inline editace hostname
    $(document).on('click','.hostname-display',function(){
        var $span=$(this);
        if ($span.find('input').length) return;
        var mac=$span.data('mac');
        var sCurrentName=$span.children('em').length ? '' : $span.text().trim();
        var $inp=$('<input type="text" class="form-control input-sm">').val(sCurrentName).css({width:'150px',display:'inline-block'});
        $span.html($inp);
        $inp.focus().select();
        function save(){
            $.ajax({url:'/api/devicemonitor/devices/updatehostname',type:'POST',
                data:{mac:mac,hostname:$inp.val().trim()},
                success:function(r){
                    showToast(r.result==='saved'?translations.hostname_saved:translations.hostname_error,
                              r.result==='saved'?'success':'error');
                    loadDevices();
                }
            });
        }
        $inp.on('keydown',function(e){
            if(e.key==='Enter') save();
            if(e.key==='Escape') loadDevices();
        }).on('blur',function(){ setTimeout(save,150); });
    });

    // Řazení sloupců
    $(document).on('click', 'th.sortable', function() {
        var col = $(this).data('col');
        if (sortCol === col) {
            sortDir = sortDir === 'asc' ? 'desc' : 'asc';
        } else {
            sortCol = col;
            sortDir = 'asc';
        }
        applyFilters();
    });
    
    // Toolbar
    $('#filter-status').on('change',function(){ activeStatus=$(this).val(); applyFilters(); });

    $('#btn-refresh').on('click',function(){ loadDevices(); loadStats(); });

    $('#btn-scan-now').on('click', function() {
        var $btn = $(this);
        $btn.prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i>');
        $.ajax({ url: '/api/devicemonitor/service/scan', type: 'POST',
            success: function() {
                setTimeout(function() {
                    loadDevices(); loadStats();
                    $btn.prop('disabled', false).html('<i class="fa fa-search"></i>');
                }, 3000);
            },
            error: function() {
                $btn.prop('disabled', false).html('<i class="fa fa-search"></i>');
            }
        });
    });

    // Export CSV - respektuje aktuální filtr
    $('#btn-export').on('click', function() {
        // Vezmi aktuálně zobrazená data (po filtrování)
        var filtered = allRows.filter(function(r) {
            var vo = !activeVlans.length || activeVlans.indexOf(r.vlan) !== -1;
            var so = !activeStatus || r.status === activeStatus;
            return vo && so;
        });

        if (!filtered.length) {
            showToast('No data to export', 'error');
            return;
        }

        // Hlavičky
        var cols = ['mac', 'ip', 'hostname', 'vendor', 'vlan', 'status', 'last_seen'];
        var headers = ['MAC Address', 'IP Address', 'Hostname', 'Vendor', 'VLAN', 'Status', 'Last Seen'];

        var csv = headers.join(';') + '\n';
        filtered.forEach(function(row) {
            var line = cols.map(function(c) {
                var val = (row[c] || '').toString();
                // VLAN přidej popis
                if (c === 'vlan' && row.vlan && vlanNames[row.vlan]) {
                    val = row.vlan + ' - ' + vlanNames[row.vlan];
                }
                // Escapuj středník a uvozovky
                val = val.replace(/"/g, '""');
                if (val.indexOf(';') !== -1 || val.indexOf('"') !== -1) {
                    val = '"' + val + '"';
                }
                return val;
            }).join(';');
            csv += line + '\n';
        });

        // Přidej BOM pro správné zobrazení v Excelu
        var bom = '\uFEFF';
        var blob = new Blob([bom + csv], { type: 'text/csv;charset=utf-8;' });
        var url  = URL.createObjectURL(blob);

        // Vytvoř název souboru s datem + aktivním filtrem
        var date    = new Date().toISOString().slice(0,10);
        var vlanPart = activeVlans.length === 1 ? '_' + activeVlans[0] : (activeVlans.length > 1 ? '_multi' : '_all');
        var filename = 'device_monitor_' + date + vlanPart + '.csv';

        var $a = $('<a>').attr({href: url, download: filename}).css('display','none');
        $('body').append($a);
        $a[0].click();
        $a.remove();
        URL.revokeObjectURL(url);

        showToast('Exported ' + filtered.length + ' devices', 'success');
    });

    $('#btn-clear').on('click',function(){
        if (!confirm(translations.confirm_clear)) return;
        $.ajax({url:'/api/devicemonitor/devices/clear',type:'POST',
            success:function(r){
                showToast(r.result==='cleared'?translations.db_cleared:translations.db_clear_error,
                          r.result==='cleared'?'success':'error');
                loadDevices(); loadStats();
            }
        });
    });

    // Init – nejprve načti interface popisky, pak zařízení
    $.ajax({url:'/api/devicemonitor/config/getinterfaces',type:'GET',
        success:function(data){ vlanNames=data||{}; loadDevices(); },
        error:function(){ loadDevices(); }
    });
    loadStats();
    setInterval(function(){ loadDevices(); loadStats(); },30000);
});
</script>