#!/bin/sh

# Předpona b označuje příznak 0/1.
# Historie: 2.3.1 – odstranění vlastních katalogů z adresáře locale.

# Device Monitor - Uninstall Script
# Podporuje tichý režim pro reinstalaci: ./uninstall.sh --silent

bSilentMode=0

# Kontrola parametru --silent
if [ "$1" = "--silent" ]; then
    bSilentMode=1
fi

if [ "$bSilentMode" -eq 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Device Monitor - Odinstalace"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi

# Kontrola root
[ "$(id -u)" != "0" ] && {
    echo "CHYBA: Musíš být root!"
    exit 1
}

# ============================================
# 1. ZASTAVENÍ SLUŽEB
# ============================================

echo "[1/6] Zastavuji daemon..."
# Zastav přes configd (ne service status který vrací exit 1)
pkill -f monitor_daemon.py 2>/dev/null || true
sleep 1
rm -f /var/run/devicemonitor.pid
echo "  ✓ Daemon zastaven"


# ============================================
# 3. AUTOSTART
# ============================================

echo "[3/6] Vypínám autostart..."
rm -f /etc/rc.conf.d/devicemonitor

if grep -q "devicemonitor_enable" /etc/rc.conf.local 2>/dev/null; then
    sed -i '' '/devicemonitor_enable/d' /etc/rc.conf.local
fi

echo "  ✓ Autostart vypnut"

# ============================================
# 4. SOUBORY PLUGINU
# ============================================

echo "[4/6] Odstraňuji soubory pluginu..."

# RC script
rm -f /usr/local/etc/rc.d/devicemonitor
rm -f /etc/rc.d/devicemonitor

# Smazat také nový skript
rm -f /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/daemon_status.sh

# 
rm -f /usr/local/etc/inc/plugins.inc.d/devicemonitor.inc

# Models
rm -rf /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor

# Controllers
rm -rf /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor

# Views
rm -rf /usr/local/opnsense/mvc/app/views/OPNsense/DeviceMonitor

# Scripts
rm -rf /usr/local/opnsense/scripts/OPNsense/DeviceMonitor

# Configd actions
rm -f /usr/local/opnsense/service/conf/actions.d/actions_devicemonitor.conf

# Config files
rm -f /tmp/devicemonitor_config.json

# Nový JS widget (OPNsense 26.x)
rm -f /usr/local/opnsense/www/js/widgets/DeviceMonitor.js
rm -f /usr/local/opnsense/www/js/widgets/Metadata/DeviceMonitor.xml

echo "  ✓ Soubory pluginu odstraněny"

# ============================================
# 5. PŘEKLADY
# ============================================

echo "[5/6] Odstraňuji překlady..."
rm -f /usr/local/opnsense/mvc/app/languages/cs_CZ_devicemonitor.po
rm -f /usr/local/opnsense/mvc/app/languages/cs_CZ_devicemonitor.mo
rm -f /usr/local/opnsense/mvc/app/languages/en_US_devicemonitor.po
rm -f /usr/local/opnsense/mvc/app/languages/en_US_devicemonitor.mo
rm -f /usr/local/share/locale/cs_CZ/LC_MESSAGES/devicemonitor.mo
rm -f /usr/local/share/locale/en_US/LC_MESSAGES/devicemonitor.mo
echo "  ✓ Překlady odstraněny"

# ============================================
# 6. DATABÁZE A DATA
# ============================================

if [ "$bSilentMode" -eq 1 ]; then
    # Tichý režim (reinstalace) - NEMAZAT DATA!
    echo "[6/6] Ponechávám databázi (reinstalace)..."
    echo "  → /var/db/devicemonitor/devices.db"
else
    # Normální odinstalace - smazat vše
    echo "[6/6] Odstraňuji databázi ..."
    
    if [ -d "/var/db/devicemonitor" ]; then
        rm -rf /var/db/devicemonitor
        echo "  ✓ Databáze smazána"
    else
        echo "  → Databáze nenalezena"
    fi
fi

# ============================================
# VYČISTĚNÍ CACHE
# ============================================

if [ "$bSilentMode" -eq 0 ]; then
    echo ""
    echo "Čistím cache..."
fi

rm -f /tmp/opnsense_menu_cache.xml
rm -f /tmp/opnsense_acl_cache.json
rm -rf /var/cache/opnsense/templates/* 2>/dev/null || true

# ============================================
# RESTART SLUŽEB (pouze při normální odinstalaci)
# ============================================

if [ "$bSilentMode" -eq 0 ]; then
    echo ""
    echo "Aktualizuji menu a restartuji služby..."
    
    /usr/local/etc/rc.configure_plugins
    service configd restart
    sleep 2
    configctl webgui restart
    sleep 2
    service php-fpm restart
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✓ Odinstalace dokončena!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Plugin byl odstraněn z GUI."
    echo "Pro úplné vyčištění restartuj prohlížeč (Ctrl+Shift+R)."
    echo ""
fi

exit 0