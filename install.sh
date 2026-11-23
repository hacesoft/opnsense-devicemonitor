#!/bin/sh

# Předpony: s = řetězec nebo cesta, i = číslo.
# Historie: 2.3.1 – instalace katalogů do standardní cesty OPNsense (#7).

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Device Monitor - Instalace"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================
# [1/9] KONTROLY
# ============================================

echo "[1/9] Provádím kontroly..."

[ "$(id -u)" != "0" ] && {
    echo "  ✗ CHYBA: Musíš být root!"
    exit 1
}
echo "  ✓ Root oprávnění OK"

sScriptDir=$(dirname "$(readlink -f "$0")")
cd "$sScriptDir" || exit 1

[ ! -d "src" ] && {
    echo "  ✗ CHYBA: src/ adresář nenalezen!"
    exit 1
}
echo "  ✓ Zdrojové soubory nalezeny"

sPluginVersion=$(python3 -c "import json; print(json.load(open('src/opnsense/mvc/app/models/OPNsense/DeviceMonitor/defaults.json'))['version'])" 2>/dev/null || echo "?")
echo "  ✓ Verze pluginu: Device Monitor v${sPluginVersion}"

sOpnsenseVersion=$(opnsense-version 2>/dev/null | awk '{print $2}')
if [ -n "$sOpnsenseVersion" ]; then
    iOpnsenseMajor=$(echo "$sOpnsenseVersion" | cut -d. -f1)
    iOpnsenseMinor=$(echo "$sOpnsenseVersion" | cut -d. -f2)
    sOpnsensePatch=$(echo "$sOpnsenseVersion" | cut -d. -f3)
    iOpnsensePatch=${sOpnsensePatch%%[!0-9]*}
    if [ "$iOpnsenseMajor" -lt 26 ] || \
       ( [ "$iOpnsenseMajor" -eq 26 ] && [ "$iOpnsenseMinor" -lt 1 ] ) || \
       ( [ "$iOpnsenseMajor" -eq 26 ] && [ "$iOpnsenseMinor" -eq 1 ] && [ "${iOpnsensePatch:-0}" -lt 5 ] ); then
        echo "  ✗ CHYBA: Vyžadována OPNsense >= 26.1.5, nalezena $sOpnsenseVersion"
        exit 1
    fi
    echo "  ✓ OPNsense $sOpnsenseVersion OK (minimum 26.1.5)"
else
    echo "  ⚠ Verzi OPNsense nelze zjistit, pokračuji..."
fi

if ! command -v msgfmt >/dev/null 2>&1; then
    echo "  → msgfmt nenalezen, instaluji gettext-tools..."
    pkg install -y gettext-tools
    [ $? -eq 0 ] && echo "  ✓ gettext-tools nainstalován" \
                 || echo "  ⚠ gettext-tools se nepodařilo nainstalovat - překlady nebudou fungovat"
else
    echo "  ✓ msgfmt dostupný"
fi

# ============================================
# [2/9] ODINSTALACE STARÉ VERZE
# ============================================

if [ -f "/etc/rc.d/devicemonitor" ] || \
   [ -d "/usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor" ]; then
    echo ""
    echo "[2/9] Detekována stará instalace, provádím aktualizaci..."
    if [ -f "$SCRIPT_DIR/uninstall.sh" ]; then
        sh "$SCRIPT_DIR/uninstall.sh" --silent
        echo "  ✓ Stará verze odstraněna (data zachována)"
    else
        echo "  ⚠ uninstall.sh nenalezen, pokračuji s přepisem..."
    fi
    sleep 1
else
    echo ""
    echo "[2/9] Nová instalace detekována"
fi

# ============================================
# [3/9] ADRESÁŘE
# ============================================

echo ""
echo "[3/9] Vytvářím adresářovou strukturu..."

mkdir -p /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/Metadata
mkdir -p /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/Menu
mkdir -p /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/ACL
mkdir -p /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/Api
mkdir -p /usr/local/opnsense/mvc/app/views/OPNsense/DeviceMonitor
mkdir -p /usr/local/opnsense/scripts/OPNsense/DeviceMonitor
mkdir -p /usr/local/opnsense/service/conf/actions.d
mkdir -p /usr/local/opnsense/www/js/widgets/Metadata
mkdir -p /usr/local/etc/inc/plugins.inc.d
mkdir -p /usr/local/etc/rc.d
mkdir -p /etc/rc.d
mkdir -p /var/db/devicemonitor
chmod 755 /var/db/devicemonitor

echo "  ✓ Adresáře vytvořeny"

# ============================================
# [4/9] RC SCRIPT + REGISTRACE SLUŽBY
# ============================================

echo ""
echo "[4/9] Instaluji RC script a registraci služby..."

if [ -f "src/etc/rc.d/devicemonitor" ]; then
    cp src/etc/rc.d/devicemonitor /usr/local/etc/rc.d/devicemonitor
    chmod +x /usr/local/etc/rc.d/devicemonitor
    ln -sf /usr/local/etc/rc.d/devicemonitor /etc/rc.d/devicemonitor
    echo "  ✓ RC script nainstalován (/usr/local/etc/rc.d/)"
else
    echo "  ✗ VAROVÁNÍ: RC script nenalezen!"
fi

# Registrace v Diagnostics → Services (plugins_services() mechanismus)
if [ -f "src/etc/inc/plugins.inc.d/devicemonitor.inc" ]; then
    cp src/etc/inc/plugins.inc.d/devicemonitor.inc \
       /usr/local/etc/inc/plugins.inc.d/
    chmod 644 /usr/local/etc/inc/plugins.inc.d/devicemonitor.inc
    echo "  ✓ Registrace služby v Diagnostics → Services"
else
    echo "  ✗ VAROVÁNÍ: plugins.inc.d/devicemonitor.inc nenalezen!"
fi

# ============================================
# [5/9] WIDGET
# ============================================

echo ""
echo "[5/9] Instaluji widget..."

if [ -f "src/opnsense/www/js/widgets/DeviceMonitor.js" ]; then
    cp src/opnsense/www/js/widgets/DeviceMonitor.js \
       /usr/local/opnsense/www/js/widgets/
    chmod 644 /usr/local/opnsense/www/js/widgets/DeviceMonitor.js
    echo "  ✓ Widget JS nainstalován"
else
    echo "  ✗ VAROVÁNÍ: DeviceMonitor.js nenalezen!"
fi

if [ -f "src/opnsense/www/js/widgets/Metadata/DeviceMonitor.xml" ]; then
    cp src/opnsense/www/js/widgets/Metadata/DeviceMonitor.xml \
       /usr/local/opnsense/www/js/widgets/Metadata/
    chmod 644 /usr/local/opnsense/www/js/widgets/Metadata/DeviceMonitor.xml
    echo "  ✓ Widget metadata nainstalována"
else
    echo "  ✗ VAROVÁNÍ: DeviceMonitor.xml nenalezen!"
fi

if [ -f "src/opnsense/mvc/app/models/OPNsense/DeviceMonitor/Metadata/service.xml" ]; then
    cp src/opnsense/mvc/app/models/OPNsense/DeviceMonitor/Metadata/service.xml \
       /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/Metadata/
    chmod 644 /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/Metadata/service.xml
    echo "  ✓ Service metadata nainstalována"
else
    echo "  ✗ VAROVÁNÍ: service.xml nenalezen!"
fi

# ============================================
# [6/9] PŘEKLADY
# ============================================

echo ""
echo "[6/9] Instaluji překlady..."

if command -v msgfmt >/dev/null 2>&1; then
    for sLocale in cs_CZ en_US; do
        sSourceCatalog="src/opnsense/mvc/app/languages/${sLocale}_devicemonitor.po"
        sLocaleDir="/usr/local/share/locale/$sLocale/LC_MESSAGES"
        if mkdir -p "$sLocaleDir" && msgfmt --check -o "$sLocaleDir/devicemonitor.mo" "$sSourceCatalog"; then
            echo "  ✓ Překlad $sLocale zkompilován"
        else
            echo "  ✗ CHYBA: Kompilace $sLocale selhala"
        fi
    done
else
    echo "  ⚠ msgfmt není dostupný – překlady nebudou fungovat"
fi

# ============================================
# [7/9] MVC (Models, Controllers, Views)
# ============================================

echo ""
echo "[7/9] Kopíruji MVC soubory..."

cp src/opnsense/mvc/app/models/OPNsense/DeviceMonitor/DeviceMonitor.xml \
   /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/
cp src/opnsense/mvc/app/models/OPNsense/DeviceMonitor/DeviceMonitor.php \
   /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/
cp src/opnsense/mvc/app/models/OPNsense/DeviceMonitor/Menu/Menu.xml \
   /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/Menu/
cp src/opnsense/mvc/app/models/OPNsense/DeviceMonitor/ACL/ACL.xml \
   /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/ACL/
cp src/opnsense/mvc/app/models/OPNsense/DeviceMonitor/defaults.json \
   /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/
echo "  ✓ Models nainstalovány"

cp src/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/IndexController.php \
   /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/
cp src/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/Api/*.php \
   /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/Api/
echo "  ✓ Controllers nainstalovány"

cp src/opnsense/mvc/app/views/OPNsense/DeviceMonitor/*.volt \
   /usr/local/opnsense/mvc/app/views/OPNsense/DeviceMonitor/
echo "  ✓ Views nainstalovány"

# ============================================
# [8/9] SKRIPTY A KONFIGURACE
# ============================================

echo ""
echo "[8/9] Instaluji skripty a konfiguraci..."

cp src/opnsense/scripts/OPNsense/DeviceMonitor/*.py \
   /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/
chmod +x /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/*.py
echo "  ✓ Python skripty nainstalovány"

cp src/opnsense/scripts/OPNsense/DeviceMonitor/*.sh \
   /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/
chmod +x /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/*.sh
echo "  ✓ Shell skripty nainstalovány"

cp src/opnsense/scripts/OPNsense/DeviceMonitor/*.php \
   /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/
chmod +x /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/*.php
echo "  ✓ PHP skripty nainstalovány"

cp src/opnsense/service/conf/actions.d/actions_devicemonitor.conf \
   /usr/local/opnsense/service/conf/actions.d/
echo "  ✓ Configd actions nainstalovány"

echo 'devicemonitor_enable="YES"' > /etc/rc.conf.d/devicemonitor
chmod 644 /etc/rc.conf.d/devicemonitor
echo "  ✓ Autostart nastaven"

[ -f "/var/db/known_devices.db" ] && rm -f /var/db/known_devices.db

# ============================================
# [9/9] FINALIZACE A SPUŠTĚNÍ
# ============================================

echo ""
echo "[9/9] Finalizuji instalaci..."

echo "  → Čistím cache..."
rm -f /tmp/opnsense_menu_cache.xml
rm -f /tmp/opnsense_acl_cache.json
rm -rf /var/cache/opnsense/templates/* 2>/dev/null || true

echo "  → Aktualizuji menu a pluginy..."
/usr/local/etc/rc.configure_plugins

echo "  → Restartuji configd..."
service configd restart
sleep 3

echo "  → Spouštím daemon..."
pkill -f monitor_daemon.py 2>/dev/null
sleep 1
rm -f /var/run/devicemonitor.pid
configctl devicemonitor start
sleep 2

iDaemonPid=$(cat /var/run/devicemonitor.pid 2>/dev/null)
if [ -n "$iDaemonPid" ] && kill -0 "$iDaemonPid" 2>/dev/null; then
    echo "  ✓ Daemon běží (PID: $iDaemonPid)"
else
    echo "  ⚠ VAROVÁNÍ: Daemon se nepodařilo spustit"
    echo "  → Spusť ručně: configctl devicemonitor start"
    echo "  → Log: tail -f /var/log/devicemonitor.log"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Device Monitor v${sPluginVersion} úspěšně nainstalován!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exit 0