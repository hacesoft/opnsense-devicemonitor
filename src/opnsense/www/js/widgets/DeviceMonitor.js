// Předpony: b = příznak, o = objekt, s = řetězec.
// 2.3.7 – sjednocení typových předpon proměnných.
// Historie: 2.3.3 – popisek počtu zařízení zaznamenaných v Hostwatch (#10).
export default class DeviceMonitor extends BaseWidget {
    constructor(oConfig) {
        super(oConfig);
        this.tickTimeout = 15;
    }

    // Bez vstupu vrátí HTML widgetu se stavem služby a počty zařízení.
    getMarkup() {
        const oTranslations = this.translations;
        // Unikátní ID – tak widget framework vždy najde správný DOM uzel
        return $(`
            <table id="dm-widget-table" class="table table-condensed" style="margin-bottom:0;">
                <tbody>
                    <tr>
                        <td>${oTranslations.status || 'Status'}</td>
                        <td id="dm-status"><span class="text-muted">...</span></td>
                    </tr>
                    <tr>
                        <td>${oTranslations.total || 'Total Devices'}</td>
                        <td><strong id="dm-total">-</strong></td>
                    </tr>
                    <tr>
                        <td>${oTranslations.online || 'Seen in the last 15 minutes'}</td>
                        <td><strong id="dm-online" style="color:#4CAF50;font-weight:bold;">-</strong></td>
                    </tr>
                </tbody>
            </table>
        `);
    }

    async onWidgetTick() {
        try {
            const oStats = await this.ajaxCall('/api/devicemonitor/devices/stats');
            if (oStats) {
                // Hledej přímo v dokumentu – ne přes this.$container
                $('#dm-total').text(oStats.total ?? '-');
                $('#dm-online').text(oStats.online ?? '-');
            }
        } catch(oError) {
            console.error("Chyba při načítání stats:", oError);
        }

        try {
            const oStatus = await this.ajaxCall('/api/devicemonitor/service/status');
            if (oStatus && oStatus.result) {
                const bRunning    = oStatus.result === 'running';
                const sLabelClass = bRunning ? 'label-success' : 'label-danger';
                const sStatusText  = bRunning
                    ? (this.translations.running  || 'Running')
                    : (this.translations.stopped  || 'Stopped');
                $('#dm-status').html(`<span class="label ${sLabelClass}">${sStatusText}</span>`);
            }
        } catch(oError) {
            console.error("Chyba při načítání statusu:", oError);
        }
    }
}