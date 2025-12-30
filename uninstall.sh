#!/bin/sh

# Device Monitor - Uninstall Script
# Podporuje tichý režim pro reinstalaci: ./uninstall.sh --silent

SILENT_MODE=0

# Kontrola parametru --silent
if [ "$1" = "--silent" ]; then
    SILENT_MODE=1
fi

if [ "$SILENT_MODE" -eq 0 ]; then
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
if service devicemonitor status > /dev/null 2>&1; then
    service devicemonitor stop 2>/dev/null || true
    echo "  ✓ Daemon zastaven"
else
    echo "  → Daemon neběží"
fi

# Smaž PID file
rm -f /var/run/devicemonitor.pid

# ============================================
# 2. ZASTAVENÍ CRONU
# ============================================

echo "[2/6] Zastavuji OUI cron..."
if [ -f "/etc/cron.d/devicemonitor_oui" ]; then
    rm -f /etc/cron.d/devicemonitor_oui
    echo "  ✓ OUI cron odstraněn"
else
    echo "  → OUI cron nenalezen"
fi

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
rm -f /etc/rc.d/devicemonitor

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
rm -f /tmp/devicemonitor_oui_config.json

echo "  ✓ Soubory pluginu odstraněny"

# ============================================
# 5. PŘEKLADY
# ============================================

echo "[5/6] Odstraňuji překlady..."

rm -f /usr/local/opnsense/mvc/app/languages/en_US/LC_MESSAGES/devicemonitor.*
rm -f /usr/local/opnsense/mvc/app/languages/cs_CZ/LC_MESSAGES/devicemonitor.*

# Pokud jsou složky prázdné, smaž je
if [ -d "/usr/local/opnsense/mvc/app/languages/en_US/LC_MESSAGES" ]; then
    if [ -z "$(ls -A /usr/local/opnsense/mvc/app/languages/en_US/LC_MESSAGES)" ]; then
        rmdir /usr/local/opnsense/mvc/app/languages/en_US/LC_MESSAGES 2>/dev/null || true
        rmdir /usr/local/opnsense/mvc/app/languages/en_US 2>/dev/null || true
    fi
fi

if [ -d "/usr/local/opnsense/mvc/app/languages/cs_CZ/LC_MESSAGES" ]; then
    if [ -z "$(ls -A /usr/local/opnsense/mvc/app/languages/cs_CZ/LC_MESSAGES)" ]; then
        rmdir /usr/local/opnsense/mvc/app/languages/cs_CZ/LC_MESSAGES 2>/dev/null || true
        rmdir /usr/local/opnsense/mvc/app/languages/cs_CZ 2>/dev/null || true
    fi
fi

echo "  ✓ Překlady odstraněny"

# ============================================
# 6. DATABÁZE A DATA
# ============================================

if [ "$SILENT_MODE" -eq 1 ]; then
    # Tichý režim (reinstalace) - NEMAZAT DATA!
    echo "[6/6] Ponechávám databázi a OUI (reinstalace)..."
    echo "  → /var/db/devicemonitor/devices.db"
    echo "  → /var/db/devicemonitor/oui.txt"
else
    # Normální odinstalace - smazat vše
    echo "[6/6] Odstraňuji databázi a OUI..."
    
    if [ -d "/var/db/devicemonitor" ]; then
        rm -rf /var/db/devicemonitor
        echo "  ✓ Databáze a OUI smazány"
    else
        echo "  → Databáze nenalezena"
    fi
fi

# ============================================
# VYČISTĚNÍ CACHE
# ============================================

if [ "$SILENT_MODE" -eq 0 ]; then
    echo ""
    echo "Čistím cache..."
fi

rm -f /tmp/opnsense_menu_cache.xml
rm -f /tmp/opnsense_acl_cache.json
rm -rf /var/cache/opnsense/templates/* 2>/dev/null || true

# ============================================
# RESTART SLUŽEB (pouze při normální odinstalaci)
# ============================================

if [ "$SILENT_MODE" -eq 0 ]; then
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