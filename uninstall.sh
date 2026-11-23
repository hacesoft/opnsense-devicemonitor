#!/bin/sh

# Předpona b označuje příznak 0/1.
# Historie:
# 2.3.1 – odstranění vlastních katalogů z adresáře locale.
# 2.3.2 – anglický výpis i při volání z instalátoru.

# Odinstalační skript Device Monitoru
# Podporuje tichý režim pro reinstalaci: ./uninstall.sh --silent

bSilentMode=0

# Kontrola parametru --silent
if [ "$1" = "--silent" ]; then
    bSilentMode=1
fi

if [ "$bSilentMode" -eq 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Device Monitor - Uninstallation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi

# Kontrola oprávnění uživatele root
[ "$(id -u)" != "0" ] && {
    echo "ERROR: Run this uninstaller as root."
    exit 1
}

# ============================================
# [1/6] Zastavení služby / Stopping the service
# ============================================

echo "[1/6] Stopping the daemon..."
# Zastav přes configd (ne service status který vrací exit 1)
pkill -f monitor_daemon.py 2>/dev/null || true
sleep 1
rm -f /var/run/devicemonitor.pid
echo "  ✓ Daemon stopped"


# ============================================
# [2/6] Vypnutí automatického spouštění / Disabling automatic startup
# ============================================

echo "[2/6] Disabling automatic startup..."
rm -f /etc/rc.conf.d/devicemonitor

if grep -q "devicemonitor_enable" /etc/rc.conf.local 2>/dev/null; then
    sed -i '' '/devicemonitor_enable/d' /etc/rc.conf.local
fi

echo "  ✓ Automatic startup disabled"

# ============================================
# [3/6] Odstranění souborů pluginu / Removing plugin files
# ============================================

echo "[3/6] Removing plugin files..."

# Spouštěcí skript služby a jeho odkaz
rm -f /usr/local/etc/rc.d/devicemonitor
rm -f /etc/rc.d/devicemonitor

# Pomocný skript pro zjištění stavu služby
rm -f /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/daemon_status.sh

# Registrace služby
rm -f /usr/local/etc/inc/plugins.inc.d/devicemonitor.inc

# Modely
rm -rf /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor

# Řadiče
rm -rf /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor

# Šablony
rm -rf /usr/local/opnsense/mvc/app/views/OPNsense/DeviceMonitor

# Provozní skripty
rm -rf /usr/local/opnsense/scripts/OPNsense/DeviceMonitor

# Akce configd
rm -f /usr/local/opnsense/service/conf/actions.d/actions_devicemonitor.conf

# Dočasná konfigurace
rm -f /tmp/devicemonitor_config.json

# Nový JS widget (OPNsense 26.x)
rm -f /usr/local/opnsense/www/js/widgets/DeviceMonitor.js
rm -f /usr/local/opnsense/www/js/widgets/Metadata/DeviceMonitor.xml

echo "  ✓ Plugin files removed"

# ============================================
# [4/6] Odstranění překladů / Removing translations
# ============================================

echo "[4/6] Removing translations..."
rm -f /usr/local/opnsense/mvc/app/languages/cs_CZ_devicemonitor.po
rm -f /usr/local/opnsense/mvc/app/languages/cs_CZ_devicemonitor.mo
rm -f /usr/local/opnsense/mvc/app/languages/en_US_devicemonitor.po
rm -f /usr/local/opnsense/mvc/app/languages/en_US_devicemonitor.mo
rm -f /usr/local/share/locale/cs_CZ/LC_MESSAGES/devicemonitor.mo
rm -f /usr/local/share/locale/en_US/LC_MESSAGES/devicemonitor.mo
echo "  ✓ Translations removed"

# ============================================
# [5/6] Databáze a nastavení / Database and settings
# ============================================

if [ "$bSilentMode" -eq 1 ]; then
    # Tichý režim (reinstalace) - NEMAZAT DATA!
    echo "[5/6] Preserving the database and settings for upgrade..."
    echo "  → /var/db/devicemonitor/devices.db"
else
    # Normální odinstalace - smazat vše
    echo "[5/6] Removing the database and settings..."

    if [ -d "/var/db/devicemonitor" ]; then
        rm -rf /var/db/devicemonitor
        echo "  ✓ Database directory removed"
    else
        echo "  → Database directory not found"
    fi
fi

# ============================================
# [6/6] Vyčištění mezipaměti / Clearing caches
# ============================================

echo "[6/6] Clearing caches..."

rm -f /tmp/opnsense_menu_cache.xml
rm -f /tmp/opnsense_acl_cache.json
rm -rf /var/cache/opnsense/templates/* 2>/dev/null || true

# ============================================
# Restart služeb při úplné odinstalaci / Restarting services after full removal
# ============================================

if [ "$bSilentMode" -eq 0 ]; then
    echo ""
    echo "Updating the menu and restarting services..."

    /usr/local/etc/rc.configure_plugins
    service configd restart
    sleep 2
    configctl webgui restart
    sleep 2
    service php-fpm restart

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✓ Uninstallation complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "The plugin has been removed from the web interface."
    echo "Reload the page with Ctrl+Shift+R to clear cached browser content."
    echo ""
fi

exit 0
