{# Předpony: arr = pole, b = příznak, i = číslo, map = mapa, o = objekt, s = řetězec, set = množina, x = hodnota proměnlivého typu, $ = objekt jQuery.
   Historie: 2.4.14 – ochrana exportu CSV a ovládání podle oprávnění.
   2.4.10 – posuv tabulky a společný stav z Hostwatch a čítačů PF.
   2.4.9 – odpočet k pevnému termínu přehledu PF.
   2.4.8 – souhrny ze služby Device Monitor a odpočet v záhlaví.
   2.4.7 – součet přírůstků paketů do 15 minut od posledního provozu.
   2.4.6 – čítače paketů v běžné odpovědi seznamu zařízení.
   2.4.5 – rozlišení shodných, nižších a nedostupných čítačů PF.
   2.4.4 – přednost pro zdroj paketů a tiché zpracování chyb diagnostiky.
   2.4.3 – přírůstky bajtů a paketů mezi snímky PF.
   2.4.2 – záložní čtení statistik PF ze staršího rozhraní OPNsense.
   2.4.0 – nastavení viditelných sloupců a známá zařízení (#4).
   2.3.8 – záložní názvy zařízení z reverzního DNS OPNsense (#9).
   2.3.7 – sjednocení typových předpon proměnných.
   2.3.1 – názvy z konfigurace se zobrazují jako text.
   2.3.3 – stav Hostwatch a samostatný výsledek ručního pingu (#10).
   2.3.4 – zelený a červený text stavu Hostwatch.
   2.3.5 – časy v místním pásmu prohlížeče a chronologické řazení.
   2.3.6 – volitelné zobrazení přírůstků počítadel provozu PF. #}
<style>
    #dm-devices-table-scroll {
        box-sizing: border-box;
        width: 100%;
        min-width: 0;
        max-width: 100%;
        overflow-x: auto;
        contain: inline-size;
    }
    #btn-clear[hidden], #btn-scan-now[hidden], #grid-devices [hidden] { display: none !important; }
</style>
<div class="content-box" style="min-width:0;max-width:100%;">
    <div class="content-box-main" style="min-width:0;max-width:100%;">

        <!-- Header s verzí a statistikami -->
        <div style="padding:10px 10px 8px 10px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;border-bottom:1px solid #333;margin-bottom:12px;">
            <h1 style="margin:0;font-size:20px;">
                {{ lang._('Device Monitor') }}
                <small id="plugin-version" style="font-size:13px;color:#888;margin-left:5px;"></small>
                <span style="color:#555;margin:0 8px;">–</span>
                <span style="font-weight:normal;">{{ lang._('Devices') }}</span>
            </h1>
            <div style="display:flex;gap:20px;align-items:center;flex-wrap:wrap;">
                {% if dmFirewallTrafficEnabled %}
                <span style="font-size:13px;color:#888;">
                    {{ dmLabels['firewall_next_review']|e }}
                    <strong id="dm-pf-countdown" class="text-info">—</strong>
                </span>
                {% endif %}
                <span style="font-size:13px;color:#888;">
                    {{ lang._('Total Devices') }}:
                    <strong id="stat-total" style="color:#ccc;font-size:16px;margin-left:4px;">—</strong>
                </span>
                <span style="font-size:13px;color:#888;">
                    {{ dmLabels['seen_recently']|e }}:
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
                <option value="online">🟢 {{ dmLabels['seen_recently']|e }}</option>
                <option value="offline">⚫ {{ dmLabels['not_seen_recently']|e }}</option>
            </select>

            <select id="filter-known" class="form-control" style="width:auto;"
                    aria-label="{{ dmLabels['known_device']|e }}">
                <option value="">{{ dmLabels['all_devices']|e }}</option>
                <option value="known">{{ dmLabels['known_devices']|e }}</option>
                <option value="unmarked">{{ dmLabels['unmarked_devices']|e }}</option>
            </select>

            <div class="dropdown">
                <button type="button" class="btn btn-default dropdown-toggle" id="dm-column-toggle"
                        data-toggle="dropdown" aria-expanded="false" aria-haspopup="true">
                    <i class="fa fa-columns"></i> {{ dmLabels['columns']|e }} <span class="caret"></span>
                </button>
                <div id="dm-column-menu" class="dropdown-menu" aria-labelledby="dm-column-toggle"
                     style="padding:8px 12px;min-width:220px;">
                    <div id="dm-column-checklist"></div>
                    <button type="button" id="dm-reset-columns" class="btn btn-default btn-xs">
                        {{ dmLabels['reset_columns']|e }}
                    </button>
                </div>
            </div>

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

        {% if dmFirewallTrafficEnabled %}
            <div id="dm-firewall-traffic-unavailable" class="alert alert-warning" hidden>
                {{ dmLabels['firewall_traffic_unavailable']|e }}
            </div>
        {% endif %}

        <!-- Vodorovný posuv zůstává uvnitř přehledu. -->
        <div id="dm-devices-table-scroll" tabindex="0" role="region" aria-label="{{ lang._('Devices') }}">
            <table class="table table-condensed table-hover table-striped" id="grid-devices" data-can-manage="{% if dmCanManage %}1{% else %}0{% endif %}"
                   data-seen-recently="{{ dmLabels['seen_recently']|e }}"
                   data-not-seen-recently="{{ dmLabels['not_seen_recently']|e }}"
                   data-hostwatch-source="{{ dmLabels['hostwatch_source']|e }}"
                   data-firewall-source="{{ dmLabels['firewall_source']|e }}"
                   data-check-ping="{{ dmLabels['check_ping']|e }}"
                   data-ping-reply="{{ dmLabels['ping_reply']|e }}"
                   data-ping-no-reply="{{ dmLabels['ping_no_reply']|e }}"
                   data-mark-known="{{ dmLabels['mark_known']|e }}"
                   data-unmark-known="{{ dmLabels['unmark_known']|e }}"
                   data-known-save-error="{{ dmLabels['known_save_error']|e }}"
                   data-ping-failed="{{ dmLabels['ping_failed']|e }}"
                   data-firewall-traffic-detected="{{ dmLabels['firewall_traffic_detected']|e }}"
                   data-firewall-last-review="{{ dmLabels['firewall_last_review']|e }}"
                   data-firewall-inactive="{{ dmLabels['firewall_inactive']|e }}"
                   data-firewall-unchanged="{{ dmLabels['firewall_unchanged']|e }}"
                   data-firewall-lower="{{ dmLabels['firewall_lower']|e }}"
                   data-firewall-baseline="{{ dmLabels['firewall_baseline']|e }}"
                   data-firewall-no-states="{{ dmLabels['firewall_no_states']|e }}"
                   data-firewall-read-failed="{{ dmLabels['firewall_read_failed']|e }}"
                   data-firewall-sample="{{ dmLabels['firewall_sample']|e }}"
                   data-firewall-packets="{{ dmLabels['firewall_packets']|e }}"
                   style="margin-top:0;border-top:2px solid #444;">
                <thead>
                    <tr>
                        <th class="sortable" data-col="mac" data-column="mac" style="cursor:pointer;white-space:nowrap;">{{ lang._('MAC Address') }} <i class="fa fa-sort"></i></th>
                        <th class="sortable" data-col="ip" data-column="ip" style="cursor:pointer;white-space:nowrap;">{{ lang._('IP Address') }} <i class="fa fa-sort"></i></th>
                        <th class="sortable" data-col="hostname" data-column="hostname" style="cursor:pointer;white-space:nowrap;">{{ lang._('Hostname') }} <i class="fa fa-sort"></i></th>
                        <th class="sortable" data-col="vendor" data-column="vendor" style="cursor:pointer;white-space:nowrap;">{{ lang._('Vendor') }} <i class="fa fa-sort"></i></th>
                        <th class="sortable" data-col="vlan" data-column="vlan" style="cursor:pointer;white-space:nowrap;">{{ lang._('VLAN') }} <i class="fa fa-sort"></i></th>
                        <th class="sortable" data-col="status" data-column="status" style="cursor:pointer;white-space:nowrap;">{{ dmLabels['device_activity']|e }} <i class="fa fa-sort"></i></th>
                        <th class="sortable" data-col="last_seen" data-column="last_seen" style="cursor:pointer;white-space:nowrap;">{{ lang._('Last Seen') }} <i class="fa fa-sort"></i></th>
                        {% if dmFirewallTrafficEnabled %}
                            <th id="dm-firewall-traffic" data-column="firewall_traffic" style="white-space:nowrap;">{{ dmLabels['firewall_traffic']|e }}</th>
                        {% endif %}
                        <th data-column="manual_ping" style="white-space:nowrap;">{{ dmLabels['manual_ping']|e }}</th>
                        <th data-column="is_known" style="white-space:nowrap;">{{ dmLabels['known_device']|e }}</th>
                        <th data-column="actions" style="white-space:nowrap;">{{ lang._('Actions') }}</th>
                    </tr>
                </thead>
                <tbody></tbody>
            </table>
        </div>
    </div>
</div>


<script>
$(document).ready(function() {

    var oTranslations = {
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

    var arrAllRows = [], arrActiveVlans = [], sActiveStatus = '', oVlanNames = {};
    var sSortColumnActive = 'last_seen', sSortDirection = 'desc';
    // Výsledek pingu drž jen na otevřené stránce, samostatně pro každou dvojici MAC a IP.
    var mapPingResults = new Map();
    var setPendingPings = new Set();
    var sKnownFilter = '';
    var setKnownPending = new Set();
    var sColumnsStorageKey = 'dm_hidden_device_columns';
    var arrDeviceColumns = $('#grid-devices thead th[data-column]').map(function() {
        return $(this).attr('data-column');
    }).get();
    var setHiddenColumns = new Set();
    try {
        var arrStoredColumns = JSON.parse(localStorage.getItem(sColumnsStorageKey) || '[]');
        if (Array.isArray(arrStoredColumns)) {
            setHiddenColumns = new Set(arrStoredColumns.filter(sColumn => typeof sColumn === 'string'));
        }
    } catch(oError) {}
    if (arrDeviceColumns.every(sColumn => setHiddenColumns.has(sColumn))) {
        setHiddenColumns.delete(arrDeviceColumns[0]);
    }
    var mapDnsNames = new Map();
    var bDnsLookupPending = false;
    var bDnsLookupUnavailable = false;
    var oStatusLabels = $('#grid-devices').data();
    var bCanManage = oStatusLabels.canManage === 1;
    $('#btn-clear, #btn-scan-now').prop('hidden', !bCanManage);
    var bFirewallTrafficEnabled = $('#dm-firewall-traffic').length > 0;
    var bFirewallTrafficReadFailed = false;
    var oFirewallTraffic = {};
    var mapActivity = new Map();
    var iServerClockOffset = 0;
    var iNextActivityExpiry = 0;
    var iNextTrafficReview = 0;
    var iDevicesRequest = 0;
    var iActivityWindow = 15 * 60 * 1000;
    var oTrafficNumberFormat = new Intl.NumberFormat(undefined, {maximumFractionDigits: 1});

    // Obnov uložený VLAN filtr
    try { arrActiveVlans = JSON.parse(localStorage.getItem('dm_vlan_filter') || '[]'); } catch(oError) {}

    // Toast
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

    // Zobrazení nainstalované verze
    $.getJSON('/api/devicemonitor/config/getversion', function(oResponse) {
        $('#plugin-version').text('v'+(oResponse.version||'?'));
    });

    // VLAN multi-select dropdown
    function buildVlanDropdown(arrVlans) {
        var $list = $('#vlan-checklist').empty();
        if (!arrVlans.length) return;
        var bAllSelected = (arrActiveVlans.length === 0);

        $list.append($('<li>').append(
            $('<a>').attr('href','#').css({padding:'5px 14px',display:'flex',alignItems:'center',justifyContent:'space-between'}).append(
                $('<label>').css({margin:0,cursor:'pointer',display:'flex',alignItems:'center',gap:'6px'}).append(
                    $('<input type="checkbox" id="vlan-all">').prop('checked', bAllSelected),
                    $('<span>').css({'font-style':'italic'}).text(oTranslations.all_vlans)
                ),
                $('<a>').attr('href','#').addClass('vlan-select-none')
                    .css({fontSize:'11px',color:'#aaa',marginLeft:'12px',whiteSpace:'nowrap'})
                    .text('Select none')
                    .on('click', function(oEvent){
                        oEvent.preventDefault();
                        oEvent.stopPropagation();
                        // Reset = všechny odškrtnuté + All VLANs zaškrtnuté = žádný filtr
                        $('#vlan-checklist .vlan-cb').prop('checked', false);
                        $('#vlan-all').prop('checked', true);
                        arrActiveVlans = [];
                        try { localStorage.setItem('dm_vlan_filter', JSON.stringify([])); } catch(oStorageError) {}
                        updateVlanLabel();
                        applyFilters();
                    })
            )
        ));

        $list.append($('<li class="divider" style="margin:4px 0;">'));

        arrVlans.sort().forEach(function(sVlan) {
            var sVlanName = oVlanNames[sVlan];
            var sLabel = (sVlanName && sVlanName !== sVlan) ? (sVlan+' \u2013 '+sVlanName) : sVlan;
            var bSelected = bAllSelected || (arrActiveVlans.indexOf(sVlan) !== -1);
            $list.append($('<li>').append(
                $('<a>').attr('href','#').css({padding:'4px 14px',display:'block'}).append(
                    $('<input type="checkbox" class="vlan-cb">').val(sVlan).prop('checked', bSelected),
                    $('<span>').css('margin-left','8px').text(sLabel)
                )
            ));
        });
        updateVlanLabel();
    }

    // Dropdown nezavírat při kliknutí na checkbox
    $('#vlan-checklist').on('click', function(oEvent){ oEvent.stopPropagation(); });

    $(document).on('change','#vlan-all',function(){
        $('#vlan-checklist .vlan-cb').prop('checked',$(this).prop('checked'));
        persistVlans();
    });
    $(document).on('change','#vlan-checklist .vlan-cb',function(){
        var iTotal=$('#vlan-checklist .vlan-cb').length;
        var iChecked=$('#vlan-checklist .vlan-cb:checked').length;
        $('#vlan-all').prop('checked', iTotal===iChecked);
        persistVlans();
    });

    function persistVlans() {
        var arrSelectedVlans = [];
        var iTotal = $('#vlan-checklist .vlan-cb').length;
        $('#vlan-checklist .vlan-cb:checked').each(function(){ arrSelectedVlans.push($(this).val()); });

        if (arrSelectedVlans.length === iTotal || arrSelectedVlans.length === 0) {
            // Všechny zaškrtnuté NEBO žádná = žádný filtr
            arrActiveVlans = [];
            $('#vlan-all').prop('checked', true);
        } else {
            arrActiveVlans = arrSelectedVlans;
            $('#vlan-all').prop('checked', false);
        }
        try { localStorage.setItem('dm_vlan_filter', JSON.stringify(arrActiveVlans)); } catch(oError) {}
        updateVlanLabel();
        applyFilters();
    }

    function updateVlanLabel() {
        if (!arrActiveVlans.length) {
            $('#vlan-filter-label').text(oTranslations.all_vlans);
        } else if (arrActiveVlans.length===1) {
            var sVlanName=oVlanNames[arrActiveVlans[0]];
            $('#vlan-filter-label').text(arrActiveVlans[0]+(sVlanName?' \u2013 '+sVlanName:''));
        } else {
            $('#vlan-filter-label').text(arrActiveVlans.length+' VLANs');
        }
    }

    // Vstup: sekundy od unixové epochy. Výstup: datum a čas v místním pásmu prohlížeče.
    function formatLocalTime(iTimestamp) {
        if (!Number.isFinite(iTimestamp)) {
            return '';
        }
        var oTime = new Date(iTimestamp * 1000);
        var sDate = [oTime.getDate(), oTime.getMonth() + 1, oTime.getFullYear()]
            .map(iPart => String(iPart).padStart(2, '0')).join('.');
        var sTime = [oTime.getHours(), oTime.getMinutes(), oTime.getSeconds()]
            .map(iPart => String(iPart).padStart(2, '0')).join(':');
        return sDate + ' - ' + sTime;
    }

    // Vstup: řádek zařízení. Výstup: uložený název, záložní název z DNS nebo prázdný řetězec.
    function getDeviceHostname(oRow) {
        return oRow.hostname || mapDnsNames.get(oRow.ip) || '';
    }

    // Bez argumentů načte názvy pro dosud nevyřešené IP. Výsledky drží jen na otevřené stránce.
    async function resolveDeviceHostnames() {
        if (bDnsLookupUnavailable || bDnsLookupPending) {
            return;
        }
        var setAddresses = new Set();
        arrAllRows.forEach(function(oRow) {
            if (!oRow.hostname && oRow.ip && !mapDnsNames.has(oRow.ip)) {
                setAddresses.add(oRow.ip);
            }
        });
        if (setAddresses.size === 0) {
            return;
        }

        var arrAddresses = Array.from(setAddresses);
        var iBatchSize = 50;
        var bNamesFound = false;
        bDnsLookupPending = true;
        try {
            for (var iOffset = 0; iOffset < arrAddresses.length; iOffset += iBatchSize) {
                var arrBatch = arrAddresses.slice(iOffset, iOffset + iBatchSize);
                var oResponse = await $.ajax({
                    url: '/api/diagnostics/dns/reverse_lookup',
                    type: 'GET',
                    dataType: 'json',
                    traditional: false,
                    data: {address: arrBatch},
                    timeout: 5000
                });
                if (!oResponse || typeof oResponse !== 'object' || !arrBatch.some(sIp => Object.hasOwn(oResponse, sIp))) {
                    bDnsLookupUnavailable = true;
                    break;
                }
                arrBatch.forEach(function(sIp) {
                    var xValue = oResponse[sIp];
                    var sName = typeof xValue === 'string' ? xValue.trim().replace(/\.$/, '') : '';
                    // OPNsense vrací při nenalezení IP. Do tabulky a CSV patří pouze platný text názvu.
                    if (sName === sIp || !/^[a-z0-9_][a-z0-9_.-]*$/i.test(sName)) {
                        sName = '';
                    }
                    mapDnsNames.set(sIp, sName);
                    bNamesFound = bNamesFound || Boolean(sName);
                });
            }
        } catch (oError) {
            // Na starších verzích a účtech bez oprávnění se obejdeme bez této služby.
            bDnsLookupUnavailable = [200, 401, 403, 404].includes(oError?.status);
        } finally {
            bDnsLookupPending = false;
            // Překreslení tabulky by zrušilo právě otevřené pole pro ruční úpravu názvu.
            if (bNamesFound && !$('#grid-devices .hostname-display input').length) {
                applyFilters();
            }
        }
    }

    // Vstup: unixová časová značka a čas serveru v ms. Výstup: konec platnosti nedávného pozorování.
    function getActivityExpiry(iObservedAt, iNow) {
        var iObservedMs = Number(iObservedAt) * 1000;
        var iAge = iNow - iObservedMs;
        return iObservedMs > 0 && iAge >= 0 && iAge < iActivityWindow
            ? iObservedMs + iActivityWindow
            : 0;
    }

    // Bez vstupu. Přepočte společný stav, zdroje aktivity, souhrn a nejbližší změnu stavu.
    function updateDeviceActivity() {
        var iNow = Date.now() + iServerClockOffset;
        var iActiveCount = 0;
        iNextActivityExpiry = 0;
        mapActivity = new Map();
        arrAllRows.forEach(function(oRow) {
            var sKey = (oRow.mac || '') + '|' + (oRow.ip || '');
            var iHostwatchExpiry = getActivityExpiry(oRow.last_seen_at, iNow);
            var iFirewallExpiry = getActivityExpiry(oFirewallTraffic[sKey]?.seenAt, iNow);
            var bHostwatch = iHostwatchExpiry > 0 || (oRow.last_seen_at == null && oRow.status === 'online');
            var arrSources = [];
            if (bHostwatch) {
                arrSources.push(oStatusLabels.hostwatchSource);
            }
            if (iFirewallExpiry > 0) {
                arrSources.push(oStatusLabels.firewallSource);
            }
            [iHostwatchExpiry, iFirewallExpiry].forEach(function(iExpiry) {
                if (iExpiry > 0 && (iNextActivityExpiry === 0 || iExpiry < iNextActivityExpiry)) {
                    iNextActivityExpiry = iExpiry;
                }
            });
            var bActive = arrSources.length > 0;
            iActiveCount += Number(bActive);
            mapActivity.set(oRow, {status: bActive ? 'online' : 'offline', sources: arrSources});
        });
        $('#stat-total').text(arrAllRows.length);
        $('#stat-online').text(iActiveCount);
    }

    // Vstup: řádek zařízení. Výstup: zda odpovídá filtrům přehledu a exportu.
    function matchesDeviceFilters(oRow) {
        var bVlanMatches = !arrActiveVlans.length || arrActiveVlans.includes(oRow.vlan);
        var bStatusMatches = !sActiveStatus || mapActivity.get(oRow).status === sActiveStatus;
        var bKnownMatches = !sKnownFilter || (Number(oRow.is_known) === 1) === (sKnownFilter === 'known');
        return bVlanMatches && bStatusMatches && bKnownMatches;
    }

    // Bez vstupu promítne uloženou viditelnost do tabulky a zaškrtávacích polí.
    function applyColumnVisibility() {
        var iVisible = arrDeviceColumns.filter(sColumn => !setHiddenColumns.has(sColumn)).length;
        $('#grid-devices [data-column]').each(function() {
            var $cell = $(this);
            $cell.prop('hidden', setHiddenColumns.has($cell.attr('data-column')));
        });
        $('#dm-column-checklist input').each(function() {
            var $checkbox = $(this);
            var bVisible = !setHiddenColumns.has($checkbox.val());
            $checkbox.prop({checked: bVisible, disabled: bVisible && iVisible === 1});
        });
    }

    // Bez vstupu uloží výběr do prohlížeče a použije ho na aktuální tabulku.
    function saveColumnVisibility() {
        try {
            localStorage.setItem(sColumnsStorageKey, JSON.stringify(Array.from(setHiddenColumns)));
        } catch(oError) {}
        applyColumnVisibility();
    }

    // Filtrování
    function applyFilters() {
        updateDeviceActivity();
        if (!arrAllRows || !arrAllRows.length) { renderTable([]); return; }
        var arrFilteredRows = arrAllRows.filter(matchesDeviceFilters);
        // Řazení
        arrFilteredRows.sort(function(oLeft, oRight) {
            if (sSortColumnActive === 'last_seen') {
                var iLeft = oLeft.last_seen_at ?? -Infinity;
                var iRight = oRight.last_seen_at ?? -Infinity;
                var iComparison = iLeft === iRight ? 0 : (iLeft < iRight ? -1 : 1);
                return sSortDirection === 'asc' ? iComparison : -iComparison;
            }

            if (sSortColumnActive === 'status') {
                var iStatusOrder = mapActivity.get(oLeft).status.localeCompare(mapActivity.get(oRight).status);
                return sSortDirection === 'asc' ? iStatusOrder : -iStatusOrder;
            }

            var sLeftValue = sSortColumnActive === 'hostname' ? getDeviceHostname(oLeft) : (oLeft[sSortColumnActive] || '');
            var sRightValue = sSortColumnActive === 'hostname' ? getDeviceHostname(oRight) : (oRight[sSortColumnActive] || '');

            // Numerické řazení pro IP adresy
            if (sSortColumnActive === 'ip') {
                var arrLeftOctets = sLeftValue.split('.').map(Number);
                var arrRightOctets = sRightValue.split('.').map(Number);
                for (var iOctet = 0; iOctet < 4; iOctet++) {
                    if ((arrLeftOctets[iOctet]||0) !== (arrRightOctets[iOctet]||0)) {
                        var iOrder = (arrLeftOctets[iOctet]||0) < (arrRightOctets[iOctet]||0) ? -1 : 1;
                        return sSortDirection === 'asc' ? iOrder : -iOrder;
                    }
                }
                return 0;
            }

            // Numerické řazení pro MAC adresu (hex)
            if (sSortColumnActive === 'mac') {
                var sLeftMac = sLeftValue.replace(/:/g,'').toLowerCase();
                var sRightMac = sRightValue.replace(/:/g,'').toLowerCase();
                var iOrder = sLeftMac < sRightMac ? -1 : sLeftMac > sRightMac ? 1 : 0;
                return sSortDirection === 'asc' ? iOrder : -iOrder;
            }

            // Textové řazení pro ostatní
            sLeftValue = sLeftValue.toString().toLowerCase();
            sRightValue = sRightValue.toString().toLowerCase();
            if (sLeftValue === sRightValue) return 0;
            var iOrder = sLeftValue < sRightValue ? -1 : 1;
            return sSortDirection === 'asc' ? iOrder : -iOrder;
        });

        renderTable(arrFilteredRows);
        // Aktualizuj ikony šipek
        $('th.sortable .fa').removeClass('fa-sort-asc fa-sort-desc').addClass('fa-sort');
        $('th.sortable[data-col="'+sSortColumnActive+'"] .fa')
            .removeClass('fa-sort')
            .addClass(sSortDirection === 'asc' ? 'fa-sort-asc' : 'fa-sort-desc');
    }

    // Vstup: uložený snímek služby. Výstup: souhrny pro tabulku a termín přehledu PF.
    function updateFirewallTraffic(oSnapshot) {
        bFirewallTrafficReadFailed = oSnapshot?.available !== true;
        $('#dm-firewall-traffic-unavailable').prop('hidden', !bFirewallTrafficReadFailed);
        if (oSnapshot?.rows && Number.isInteger(oSnapshot.now)) {
            oFirewallTraffic = oSnapshot.rows;
            iNextTrafficReview = Number.isInteger(oSnapshot.nextReviewAt) ? oSnapshot.nextReviewAt * 1000 : 0;
            var oReview = oSnapshot.lastReview;
            var sReview = oReview
                ? formatLocalTime(oReview.at) + ' · ' + oStatusLabels.firewallLastReview.replace('%s', oReview.active)
                : '';
            $('#dm-pf-countdown').attr('title', sReview);
        }
    }

    // Bez vstupu. Aktualizuje serverový odpočet a překreslí řádky po vypršení jejich aktivity.
    function updateTrafficCountdown() {
        var iNow = Date.now() + iServerClockOffset;
        if (iNextActivityExpiry > 0 && iNextActivityExpiry <= iNow) {
            applyFilters();
            return;
        }
        var iRemaining = Math.max(0, Math.ceil((iNextTrafficReview - iNow) / 1000));
        var sRemaining = iNextTrafficReview > 0 && !bFirewallTrafficReadFailed
            ? Math.floor(iRemaining / 60) + ':' + String(iRemaining % 60).padStart(2, '0')
            : '—';
        $('#dm-pf-countdown').text(sRemaining);
    }

    // Vstup: historie zařízení a stav čtení PF. Výstup: stav provozu a součet zachycený službou.
    function renderPfTraffic(oTraffic) {
        var iNow = Date.now() + iServerClockOffset;
        var iSeenAt = (oTraffic?.seenAt ?? 0) * 1000;
        var bRecentTraffic = getActivityExpiry(oTraffic?.seenAt, iNow) > 0;
        var iStartedAt = (oTraffic?.startedAt ?? 0) * 1000;
        var bUnavailable = bFirewallTrafficReadFailed || !oTraffic || oTraffic.reading === 'firewallReadFailed';
        var bInactive = !bUnavailable && iNow - (iSeenAt || iStartedAt) >= iActivityWindow;
        var sStatus = '—';
        if (bRecentTraffic) {
            sStatus = oStatusLabels.firewallTrafficDetected;
        } else if (bInactive) {
            sStatus = oStatusLabels.firewallInactive;
        }
        var $cell = $('<td>').append($('<span>')
            .toggleClass('text-success', bRecentTraffic)
            .text(sStatus)
            .attr('title', iSeenAt > 0 ? formatLocalTime(iSeenAt / 1000) : ''));

        var sReading = bUnavailable ? oStatusLabels.firewallReadFailed : oStatusLabels[oTraffic.reading];
        var $reading = $('<div class="small dm-pf-traffic-delta">');
        if (bRecentTraffic) {
            var sTotal = oTrafficNumberFormat.format(oTraffic.totalPackets);
            $reading.text(oStatusLabels.firewallPackets.replace('%s', sTotal));
            var arrDetails = [sReading];
            if (!bUnavailable) {
                arrDetails.push(oStatusLabels.firewallSample + ' · ' + formatLocalTime(oTraffic.sampleAt));
            }
            $reading.attr('title', arrDetails.join('\n'));
        } else {
            $reading.text(sReading);
        }
        return $cell.append($reading);
    }

    // Vstup: společný stav a zdroje. Výstup: barevný stav s popisem potvrzujících zdrojů.
    function renderDeviceActivity(oActivity) {
        var bRecent = oActivity.status === 'online';
        var $cell = $('<td>').append($('<span>')
            .addClass(bRecent ? 'text-success' : 'text-danger')
            .text(bRecent ? oStatusLabels.seenRecently : oStatusLabels.notSeenRecently));
        if (bRecent) {
            $cell.append($('<div class="small">').text(oActivity.sources.join(' + ')));
        }
        return $cell;
    }

    // Vstup: řádky zařízení. Výstup: aktualizovaná tabulka v DOM.
    function renderTable(arrRows) {
        var $tbody = $('#grid-devices tbody').empty();
        arrRows.forEach(function(oRow) {
            var sMac = oRow.mac || '';
            var sIp = oRow.ip || '';
            var sHostname = getDeviceHostname(oRow);
            var sPingKey = sMac + '|' + sIp;

            var $hostname = $('<span class="hostname-display" title="Click to edit" style="cursor:pointer;border-bottom:1px dashed #666;">')
                .attr({'data-mac': sMac, 'data-stored-hostname': oRow.hostname || ''})
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
            if (oRow.vlan && oVlanNames[oRow.vlan]) {
                sVlanLabel += ' – ' + oVlanNames[oRow.vlan];
            }

            var $check = $('<button type="button" class="btn btn-xs btn-warning command-check" style="margin-right:2px;">')
                .attr({'data-row-mac': sMac, 'data-row-ip': sIp, title: oStatusLabels.checkPing,
                    'aria-label': oStatusLabels.checkPing})
                .prop('disabled', !bCanManage || !sIp || setPendingPings.has(sPingKey))
                .append($('<i>').addClass(setPendingPings.has(sPingKey) ? 'fa fa-spinner fa-spin' : 'fa fa-plug'));
            var $delete = $('<button class="btn btn-xs btn-danger command-delete"><i class="fa fa-trash"></i></button>')
                .attr('data-row-mac', sMac).prop('disabled', !bCanManage);

            var $row = $('<tr>').append(
                $('<td>').text(sMac),
                $ipCell,
                $('<td>').append($hostname),
                $('<td>').text(oRow.vendor || ''),
                $('<td>').text(sVlanLabel),
                renderDeviceActivity(mapActivity.get(oRow)),
                $('<td>').text(formatLocalTime(oRow.last_seen_at) || oRow.last_seen || '')
            );

            if (bFirewallTrafficEnabled) {
                $row.append(renderPfTraffic(oFirewallTraffic[sPingKey]));
            }

            var bKnown = Number(oRow.is_known) === 1;
            var sMarkLabel = bKnown ? oStatusLabels.unmarkKnown : oStatusLabels.markKnown;
            var $known = $('<button type="button" class="btn btn-xs dm-mark-known">')
                .addClass(bKnown ? 'btn-success' : 'btn-default')
                .attr({'data-mac': sMac, 'aria-pressed': String(bKnown), title: sMarkLabel, 'aria-label': sMarkLabel})
                .prop('disabled', !bCanManage || !sMac || setKnownPending.has(sMac))
                .append($('<i aria-hidden="true">').addClass(bKnown ? 'fa fa-star' : 'fa fa-star-o'));

            $row.append(
                $('<td>').text(mapPingResults.get(sPingKey) || '—'),
                $('<td>').append($known),
                $('<td>').append($check, $delete)
            );
            $row.children('td').each(function(iColumn) {
                $(this).attr('data-column', arrDeviceColumns[iColumn]);
            });
            $row.appendTo($tbody);
        });
        applyColumnVisibility();
        bindButtons();
        if (bFirewallTrafficEnabled) {
            updateTrafficCountdown();
        }
    }

    // Načtení dat
    function loadDevices() {
        var iRequest = ++iDevicesRequest;
        var oQuery = {rowCount: -1, current: 1, searchPhrase: ''};
        if (bFirewallTrafficEnabled) {
            oQuery.include_pf_packets = '1';
        }
        $.ajax({url:'/api/devicemonitor/devices/search',type:'POST',
            data: oQuery,
            error: handleReadError,
            success:function(oData){
                if (iRequest !== iDevicesRequest) {
                    return;
                }
                if (!Array.isArray(oData?.rows) || oData.error) {
                    handleReadError();
                    return;
                }
                arrAllRows = oData.rows;
                if (Number.isInteger(oData.server_time)) {
                    iServerClockOffset = (oData.server_time * 1000) - Date.now();
                }
                if (bFirewallTrafficEnabled) {
                    oFirewallTraffic = {};
                    updateFirewallTraffic(oData.pf_packets);
                }
                var oVlans={};
                arrAllRows.forEach(function(oResult){ if(oResult.vlan) oVlans[oResult.vlan]=1; });
                buildVlanDropdown(Object.keys(oVlans));
                applyFilters();
                resolveDeviceHostnames();
            }
        });

        // Bez vstupu. Při chybě obnov popisky PF a zachovej tabulku i zachycené pakety.
        function handleReadError() {
            if (iRequest === iDevicesRequest && bFirewallTrafficEnabled) {
                updateFirewallTraffic(null);
                applyFilters();
            }
        }
    }

    function bindButtons() {
        $('.command-delete').off('click').on('click',function(){
            var sMac=$(this).data('row-mac');
            if (!confirm(oTranslations.confirm_delete+' '+sMac+'?')) return;
            $.ajax({url:'/api/devicemonitor/devices/delete',type:'POST',data:{mac:sMac},
                success:function(oResult){
                    showToast(oResult.result==='deleted'?oTranslations.deleted:oTranslations.delete_error,
                              oResult.result==='deleted'?'success':'error');
                    loadDevices();
                }
            });
        });

        // Provede jeden ruční ping a uloží jeho výsledek pouze pro zobrazení.
        $('.command-check').off('click').on('click', function() {
            var $button = $(this);
            var sMac = $button.attr('data-row-mac');
            var sIp = $button.attr('data-row-ip');
            var sPingKey = sMac + '|' + sIp;
            if (!sIp || setPendingPings.has(sPingKey)) {
                return;
            }

            setPendingPings.add(sPingKey);
            $button.prop('disabled', true).find('i').attr('class', 'fa fa-spinner fa-spin');

            $.ajax({
                url: '/api/devicemonitor/devices/pingdevice',
                type: 'POST',
                data: {mac: sMac, ip: sIp},
                success: function(oResponse) {
                    if (oResponse.result === 'online' || oResponse.result === 'offline') {
                        var sResult = oResponse.result === 'online' ? oStatusLabels.pingReply : oStatusLabels.pingNoReply;
                        var sCheckedAt = formatLocalTime(oResponse.checked_at);
                        mapPingResults.set(sPingKey, sResult + ' · ' + sCheckedAt);
                    } else {
                        showToast(oStatusLabels.pingFailed, 'error');
                    }
                },
                error: function() {
                    showToast(oStatusLabels.pingFailed, 'error');
                },
                complete: function() {
                    setPendingPings.delete(sPingKey);
                    applyFilters();
                }
            });
        });
    }

    // Inline editace hostname
    $(document).on('click','.hostname-display',function(){
        if (!bCanManage) return;
        var $span=$(this);
        if ($span.find('input').length) return;
        var sMac=$span.data('mac');
        var sCurrentName=$span.attr('data-stored-hostname').trim();
        var $input=$('<input type="text" class="form-control input-sm">').val(sCurrentName).css({width:'150px',display:'inline-block'});
        $span.html($input);
        $input.focus().select();
        function save(){
            $.ajax({url:'/api/devicemonitor/devices/updatehostname',type:'POST',
                data:{mac:sMac,hostname:$input.val().trim()},
                success:function(oResult){
                    showToast(oResult.result==='saved'?oTranslations.hostname_saved:oTranslations.hostname_error,
                              oResult.result==='saved'?'success':'error');
                    loadDevices();
                }
            });
        }
        $input.on('keydown',function(oEvent){
            if(oEvent.key==='Enter') save();
            if(oEvent.key==='Escape') loadDevices();
        }).on('blur',function(){ setTimeout(save,150); });
    });

    // Řazení sloupců
    $(document).on('click', 'th.sortable', function() {
        var sSortColumn = $(this).data('col');
        if (sSortColumnActive === sSortColumn) {
            sSortDirection = sSortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            sSortColumnActive = sSortColumn;
            sSortDirection = 'asc';
        }
        applyFilters();
    });
    
    $(document).on('click', '.dm-mark-known', function() {
        var $button = $(this);
        var sMac = $button.attr('data-mac');
        if (setKnownPending.has(sMac)) return;

        var sKnown = $button.attr('aria-pressed') === 'true' ? '0' : '1';
        setKnownPending.add(sMac);
        $button.prop('disabled', true);
        $.ajax({
            url: '/api/devicemonitor/devices/setknown',
            type: 'POST',
            data: {mac: sMac, is_known: sKnown},
            success: function(oResult) {
                if (oResult.result !== 'saved') {
                    showToast(oStatusLabels.knownSaveError, 'error');
                    return;
                }
                arrAllRows.forEach(function(oRow) {
                    if (oRow.mac === sMac) {
                        oRow.is_known = Number(sKnown);
                    }
                });
            },
            error: function() {
                showToast(oStatusLabels.knownSaveError, 'error');
            },
            complete: function() {
                setKnownPending.delete(sMac);
                applyFilters();
            }
        });
    });

    $('#grid-devices thead th[data-column]').each(function() {
        var $header = $(this);
        $('#dm-column-checklist').append($('<label style="display:block;font-weight:normal;">')
            .append($('<input type="checkbox">').val($header.attr('data-column')),
                document.createTextNode(' ' + $header.text().trim())));
    });
    $('#dm-column-menu').on('click', function(oEvent) { oEvent.stopPropagation(); });
    $('#dm-column-checklist').on('change', 'input', function() {
        var $checkbox = $(this);
        if ($checkbox.prop('checked')) {
            setHiddenColumns.delete($checkbox.val());
        } else if (arrDeviceColumns.some(sColumn => sColumn !== $checkbox.val() && !setHiddenColumns.has(sColumn))) {
            setHiddenColumns.add($checkbox.val());
        }
        saveColumnVisibility();
    });
    $('#dm-reset-columns').on('click', function() {
        setHiddenColumns.clear();
        saveColumnVisibility();
    });
    applyColumnVisibility();

    // Toolbar
    $('#filter-known').on('change', function() {
        sKnownFilter = $(this).val();
        applyFilters();
    });
    $('#filter-status').on('change',function(){ sActiveStatus=$(this).val(); applyFilters(); });

    $('#btn-refresh').on('click',function(){ loadDevices(); });

    $('#btn-scan-now').on('click', function() {
        var $btn = $(this);
        $btn.prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i>');
        $.ajax({ url: '/api/devicemonitor/service/scan', type: 'POST',
            success: function() {
                setTimeout(function() {
                    loadDevices();
                    $btn.prop('disabled', false).html('<i class="fa fa-search"></i>');
                }, 3000);
            },
            error: function() {
                $btn.prop('disabled', false).html('<i class="fa fa-search"></i>');
            }
        });
    });

    // Vstup: text buňky. Výstup: CSV hodnota s ochranou proti vzorcům tabulkového procesoru.
    function escapeCsvCell(sValue) {
        var bFormula = /^[\s\u0000-\u001f]*[=+\-@＝＋－＠]/u.test(sValue) || /^[\t\r\n]/.test(sValue);
        if (bFormula) {
            sValue = "\t'" + sValue;
        }
        return bFormula || /[;"\r\n]/.test(sValue) ? '"' + sValue.replace(/"/g, '""') + '"' : sValue;
    }

    // Export CSV - respektuje aktuální filtr
    $('#btn-export').on('click', function() {
        // Vezmi aktuálně zobrazená data (po filtrování)
        var arrFilteredRows = arrAllRows.filter(matchesDeviceFilters);

        if (!arrFilteredRows.length) {
            showToast('No data to export', 'error');
            return;
        }

        // Hlavičky
        var arrColumns = ['mac', 'ip', 'hostname', 'vendor', 'vlan', 'status', 'last_seen'];
        var arrHeaders = ['MAC Address', 'IP Address', 'Hostname', 'Vendor', 'VLAN', 'Status', 'Last Seen'];

        var sCsv = arrHeaders.join(';') + '\n';
        arrFilteredRows.forEach(function(oDeviceRow) {
            var oActivity = mapActivity.get(oDeviceRow);
            var sLine = arrColumns.map(function(sColumn) {
                var sValue = sColumn === 'last_seen'
                    ? (formatLocalTime(oDeviceRow.last_seen_at) || oDeviceRow[sColumn] || '')
                    : (oDeviceRow[sColumn] || '').toString();
                if (sColumn === 'hostname') {
                    sValue = getDeviceHostname(oDeviceRow);
                } else if (sColumn === 'status') {
                    sValue = oActivity.status;
                }
                // VLAN přidej popis
                if (sColumn === 'vlan' && oDeviceRow.vlan && oVlanNames[oDeviceRow.vlan]) {
                    sValue = oDeviceRow.vlan + ' - ' + oVlanNames[oDeviceRow.vlan];
                }
                return escapeCsvCell(sValue);
            }).join(';');
            sCsv += sLine + '\n';
        });

        // Přidej BOM pro správné zobrazení v Excelu
        var sBom = '\uFEFF';
        var oBlob = new Blob([sBom + sCsv], { type: 'text/csv;charset=utf-8;' });
        var sUrl  = URL.createObjectURL(oBlob);

        // Vytvoř název souboru s datem + aktivním filtrem
        var sExportDate    = new Date().toISOString().slice(0,10);
        var sVlanSuffix = arrActiveVlans.length === 1 ? '_' + arrActiveVlans[0] : (arrActiveVlans.length > 1 ? '_multi' : '_all');
        var sFilename = 'device_monitor_' + sExportDate + sVlanSuffix + '.csv';

        var $downloadLink = $('<a>').attr({href: sUrl, download: sFilename}).css('display','none');
        $('body').append($downloadLink);
        $downloadLink[0].click();
        $downloadLink.remove();
        URL.revokeObjectURL(sUrl);

        showToast('Exported ' + arrFilteredRows.length + ' devices', 'success');
    });

    $('#btn-clear').on('click',function(){
        if (!confirm(oTranslations.confirm_clear)) return;
        $.ajax({url:'/api/devicemonitor/devices/clear',type:'POST',
            success:function(oResult){
                showToast(oResult.result==='cleared'?oTranslations.db_cleared:oTranslations.db_clear_error,
                          oResult.result==='cleared'?'success':'error');
                loadDevices();
            }
        });
    });

    // Init – nejprve načti interface popisky, pak zařízení
    $.ajax({url:'/api/devicemonitor/config/getinterfaces',type:'GET',
        success:function(oData){ oVlanNames=oData||{}; loadDevices(); },
        error:function(){ loadDevices(); }
    });
    setInterval(loadDevices, 30000);
    setInterval(updateTrafficCountdown, 1000);
});
</script>