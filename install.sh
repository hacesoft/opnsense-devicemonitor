#!/bin/sh

# Předpony: s = řetězec nebo cesta, i = číslo.
# Historie:
# 2.3.1 – instalace katalogů do standardní cesty OPNsense (#7).
# 2.3.2 – anglický výpis, dvojjazyčné nadpisy a oprava cesty k odinstalátoru.

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Device Monitor - Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================
# [1/9] Kontrola před instalací / Pre-installation checks
# ============================================

echo "[1/9] Running pre-installation checks..."

[ "$(id -u)" != "0" ] && {
    echo "  ✗ ERROR: Run this installer as root."
    exit 1
}
echo "  ✓ Root privileges confirmed"

sScriptDir=$(dirname "$(readlink -f "$0")")
cd "$sScriptDir" || exit 1

[ ! -d "src" ] && {
    echo "  ✗ ERROR: Source directory src/ not found."
    exit 1
}
echo "  ✓ Source files found"

sPluginVersion=$(python3 -c "import json; print(json.load(open('src/opnsense/mvc/app/models/OPNsense/DeviceMonitor/defaults.json'))['version'])" 2>/dev/null || echo "?")
echo "  ✓ Plugin version: Device Monitor v${sPluginVersion}"

sOpnsenseVersion=$(opnsense-version 2>/dev/null | awk '{print $2}')
if [ -n "$sOpnsenseVersion" ]; then
    iOpnsenseMajor=$(echo "$sOpnsenseVersion" | cut -d. -f1)
    iOpnsenseMinor=$(echo "$sOpnsenseVersion" | cut -d. -f2)
    sOpnsensePatch=$(echo "$sOpnsenseVersion" | cut -d. -f3)
    iOpnsensePatch=${sOpnsensePatch%%[!0-9]*}
    if [ "$iOpnsenseMajor" -lt 26 ] || \
       ( [ "$iOpnsenseMajor" -eq 26 ] && [ "$iOpnsenseMinor" -lt 1 ] ) || \
       ( [ "$iOpnsenseMajor" -eq 26 ] && [ "$iOpnsenseMinor" -eq 1 ] && [ "${iOpnsensePatch:-0}" -lt 5 ] ); then
        echo "  ✗ ERROR: OPNsense 26.1.5 or later is required. Detected $sOpnsenseVersion"
        exit 1
    fi
    echo "  ✓ OPNsense $sOpnsenseVersion OK (minimum 26.1.5)"
else
    echo "  ⚠ Could not determine the OPNsense version. Continuing..."
fi

if ! command -v msgfmt >/dev/null 2>&1; then
    echo "  → msgfmt not found. Installing gettext-tools..."
    pkg install -y gettext-tools
    [ $? -eq 0 ] && echo "  ✓ gettext-tools installed" \
                 || echo "  ⚠ Could not install gettext-tools. Translations will be unavailable."
else
    echo "  ✓ msgfmt available"
fi

# ============================================
# [2/9] Kontrola stávající instalace / Existing installation check
# ============================================

if [ -f "/etc/rc.d/devicemonitor" ] || \
   [ -d "/usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor" ]; then
    echo ""
    echo "[2/9] Existing installation detected. Upgrading..."
    if [ -f "$sScriptDir/uninstall.sh" ]; then
        # Při aktualizaci odinstaluj staré soubory a zachovej data zařízení.
        if ! sh "$sScriptDir/uninstall.sh" --silent; then
            echo "  ✗ ERROR: Could not remove the previous version."
            exit 1
        fi
        echo "  ✓ Previous version removed. Device data preserved."
    else
        echo "  ⚠ uninstall.sh not found. Installing over the existing files..."
    fi
    sleep 1
else
    echo ""
    echo "[2/9] Fresh installation detected"
fi

# ============================================
# [3/9] Vytvoření adresářů / Creating directories
# ============================================

echo ""
echo "[3/9] Creating directories..."

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

echo "  ✓ Directories created"

# ============================================
# [4/9] Instalace spouštěcího skriptu a registrace služby / Installing startup script and registering service
# ============================================

echo ""
echo "[4/9] Installing startup script and registering service..."

if [ -f "src/etc/rc.d/devicemonitor" ]; then
    cp src/etc/rc.d/devicemonitor /usr/local/etc/rc.d/devicemonitor
    chmod +x /usr/local/etc/rc.d/devicemonitor
    ln -sf /usr/local/etc/rc.d/devicemonitor /etc/rc.d/devicemonitor
    echo "  ✓ Startup script installed (/usr/local/etc/rc.d/)"
else
    echo "  ⚠ WARNING: RC script not found."
fi

# Registruj službu v nabídce Diagnostics → Services přes plugins_services().
if [ -f "src/etc/inc/plugins.inc.d/devicemonitor.inc" ]; then
    cp src/etc/inc/plugins.inc.d/devicemonitor.inc \
       /usr/local/etc/inc/plugins.inc.d/
    chmod 644 /usr/local/etc/inc/plugins.inc.d/devicemonitor.inc
    echo "  ✓ Service registered under Diagnostics → Services"
else
    echo "  ⚠ WARNING: plugins.inc.d/devicemonitor.inc not found."
fi

# ============================================
# [5/9] Instalace widgetu / Installing widget
# ============================================

echo ""
echo "[5/9] Installing widget..."

if [ -f "src/opnsense/www/js/widgets/DeviceMonitor.js" ]; then
    cp src/opnsense/www/js/widgets/DeviceMonitor.js \
       /usr/local/opnsense/www/js/widgets/
    chmod 644 /usr/local/opnsense/www/js/widgets/DeviceMonitor.js
    echo "  ✓ Widget JavaScript installed"
else
    echo "  ⚠ WARNING: DeviceMonitor.js not found."
fi

if [ -f "src/opnsense/www/js/widgets/Metadata/DeviceMonitor.xml" ]; then
    cp src/opnsense/www/js/widgets/Metadata/DeviceMonitor.xml \
       /usr/local/opnsense/www/js/widgets/Metadata/
    chmod 644 /usr/local/opnsense/www/js/widgets/Metadata/DeviceMonitor.xml
    echo "  ✓ Widget metadata installed"
else
    echo "  ⚠ WARNING: DeviceMonitor.xml not found."
fi

if [ -f "src/opnsense/mvc/app/models/OPNsense/DeviceMonitor/Metadata/service.xml" ]; then
    cp src/opnsense/mvc/app/models/OPNsense/DeviceMonitor/Metadata/service.xml \
       /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/Metadata/
    chmod 644 /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/Metadata/service.xml
    echo "  ✓ Service metadata installed"
else
    echo "  ⚠ WARNING: service.xml not found."
fi

# ============================================
# [6/9] Instalace překladů / Installing translations
# ============================================

echo ""
echo "[6/9] Installing translations..."

# Zkompiluj oba jazykové katalogy pro rozhraní pluginu.
if command -v msgfmt >/dev/null 2>&1; then
    for sLocale in cs_CZ en_US; do
        sSourceCatalog="src/opnsense/mvc/app/languages/${sLocale}_devicemonitor.po"
        sLocaleDir="/usr/local/share/locale/$sLocale/LC_MESSAGES"
        if mkdir -p "$sLocaleDir" && msgfmt --check -o "$sLocaleDir/devicemonitor.mo" "$sSourceCatalog"; then
            echo "  ✓ Translation catalog compiled ($sLocale)"
        else
            echo "  ✗ ERROR: Could not compile the $sLocale translation catalog."
        fi
    done
else
    echo "  ⚠ msgfmt unavailable. Skipping translation compilation."
fi

# ============================================
# [7/9] Instalace modelů, řadičů a šablon / Installing MVC files
# ============================================

echo ""
echo "[7/9] Installing MVC files..."

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
echo "  ✓ Models installed"

cp src/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/IndexController.php \
   /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/
cp src/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/Api/*.php \
   /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/Api/
echo "  ✓ Controllers installed"

cp src/opnsense/mvc/app/views/OPNsense/DeviceMonitor/*.volt \
   /usr/local/opnsense/mvc/app/views/OPNsense/DeviceMonitor/
echo "  ✓ Views installed"

# ============================================
# [8/9] Instalace skriptů a konfigurace / Installing scripts and configuration
# ============================================

echo ""
echo "[8/9] Installing scripts and configuration..."

cp src/opnsense/scripts/OPNsense/DeviceMonitor/*.py \
   /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/
chmod +x /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/*.py
echo "  ✓ Python scripts installed"

cp src/opnsense/scripts/OPNsense/DeviceMonitor/*.sh \
   /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/
chmod +x /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/*.sh
echo "  ✓ Shell scripts installed"

cp src/opnsense/scripts/OPNsense/DeviceMonitor/*.php \
   /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/
chmod +x /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/*.php
echo "  ✓ PHP scripts installed"

cp src/opnsense/service/conf/actions.d/actions_devicemonitor.conf \
   /usr/local/opnsense/service/conf/actions.d/
echo "  ✓ configd actions installed"

echo 'devicemonitor_enable="YES"' > /etc/rc.conf.d/devicemonitor
chmod 644 /etc/rc.conf.d/devicemonitor
echo "  ✓ Automatic startup enabled"

[ -f "/var/db/known_devices.db" ] && rm -f /var/db/known_devices.db

# ============================================
# [9/9] Dokončení instalace a spuštění služby / Finalizing installation and starting service
# ============================================

echo ""
echo "[9/9] Finalizing installation..."

echo "  → Clearing caches..."
rm -f /tmp/opnsense_menu_cache.xml
rm -f /tmp/opnsense_acl_cache.json
rm -rf /var/cache/opnsense/templates/* 2>/dev/null || true

echo "  → Updating the menu and plugin registration..."
/usr/local/etc/rc.configure_plugins

echo "  → Restarting configd..."
service configd restart
sleep 3

echo "  → Starting the daemon..."
pkill -f monitor_daemon.py 2>/dev/null
sleep 1
rm -f /var/run/devicemonitor.pid
configctl devicemonitor start
sleep 2

iDaemonPid=$(cat /var/run/devicemonitor.pid 2>/dev/null)
if [ -n "$iDaemonPid" ] && kill -0 "$iDaemonPid" 2>/dev/null; then
    echo "  ✓ Daemon running (PID: $iDaemonPid)"
else
    echo "  ⚠ WARNING: The daemon failed to start."
    echo "  → Start manually: configctl devicemonitor start"
    echo "  → Log: tail -f /var/log/devicemonitor.log"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Device Monitor v${sPluginVersion} installed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exit 0
