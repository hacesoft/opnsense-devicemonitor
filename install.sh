#!/bin/sh

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Device Monitor - Instalace"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================
# KONTROLY
# ============================================

echo "[1/9] Provádím kontroly..."

# Kontrola root
[ "$(id -u)" != "0" ] && {
    echo "  ✗ CHYBA: Musíš být root!"
    exit 1
}
echo "  ✓ Root oprávnění OK"

# Zjisti adresář se skriptem
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cd "$SCRIPT_DIR" || exit 1

# Kontrola src adresáře
[ ! -d "src" ] && {
    echo "  ✗ CHYBA: src/ adresář nenalezen!"
    exit 1
}
echo "  ✓ Zdrojové soubory nalezeny"

# Kontrola msgfmt pro překlady
if ! command -v msgfmt >/dev/null 2>&1; then
    echo "  → msgfmt nenalezen, instaluji gettext-tools..."
    pkg install -y gettext-tools
    if [ $? -eq 0 ]; then
        echo "  ✓ gettext-tools nainstalován"
    else
        echo "  ⚠ VAROVÁNÍ: gettext-tools se nepodařilo nainstalovat"
        echo "  ⚠ Překlady nebudou fungovat!"
    fi
else
    echo "  ✓ msgfmt dostupný"
fi

# ============================================
# ODINSTALACE STARÉ VERZE (pokud existuje)
# ============================================

if [ -f "/etc/rc.d/devicemonitor" ] || [ -d "/usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor" ]; then
    echo ""
    echo "[2/9] Detekována stará instalace, provádím aktualizaci..."
    
    # Spusť uninstall v tichém režimu (nemazat DB a OUI)
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
# VYTVOŘENÍ ADRESÁŘŮ
# ============================================

echo ""
echo "[3/9] Vytvářím adresářovou strukturu..."

mkdir -p /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/Menu
mkdir -p /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/ACL
mkdir -p /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/Api
mkdir -p /usr/local/opnsense/mvc/app/views/OPNsense/DeviceMonitor
mkdir -p /usr/local/opnsense/scripts/OPNsense/DeviceMonitor
mkdir -p /usr/local/opnsense/service/conf/actions.d
mkdir -p /etc/rc.d
mkdir -p /var/db/devicemonitor
mkdir -p /usr/local/opnsense/mvc/app/languages/en_US/LC_MESSAGES
mkdir -p /usr/local/opnsense/mvc/app/languages/cs_CZ/LC_MESSAGES

# Nastav oprávnění
chmod 755 /var/db/devicemonitor

echo "  ✓ Adresáře vytvořeny"

# ============================================
# RC SCRIPT (DAEMON)
# ============================================

echo ""
echo "[4/9] Instaluji RC script..."

if [ -f "src/etc/rc.d/devicemonitor" ]; then
    cp src/etc/rc.d/devicemonitor /etc/rc.d/devicemonitor
    chmod +x /etc/rc.d/devicemonitor
    echo "  ✓ RC script nainstalován"
else
    echo "  ✗ VAROVÁNÍ: RC script nenalezen!"
fi

# ============================================
# PŘEKLADY (GETTEXT)
# ============================================

echo ""
echo "[5/9] Instaluji překlady..."

# Zkopíruj .po soubory
if [ -f "src/opnsense/mvc/app/languages/en_US/LC_MESSAGES/devicemonitor.po" ]; then
    echo "  → Kopíruji .po soubory..."
    
    cp src/opnsense/mvc/app/languages/en_US/LC_MESSAGES/devicemonitor.po \
       /usr/local/opnsense/mvc/app/languages/en_US/LC_MESSAGES/
    
    cp src/opnsense/mvc/app/languages/cs_CZ/LC_MESSAGES/devicemonitor.po \
       /usr/local/opnsense/mvc/app/languages/cs_CZ/LC_MESSAGES/
    
    # Zkompiluj .po → .mo
    if command -v msgfmt >/dev/null 2>&1; then
        echo "  → Kompiluji překlady (.po → .mo)..."
        
        msgfmt -o /usr/local/opnsense/mvc/app/languages/en_US/LC_MESSAGES/devicemonitor.mo \
                  /usr/local/opnsense/mvc/app/languages/en_US/LC_MESSAGES/devicemonitor.po
        
        msgfmt -o /usr/local/opnsense/mvc/app/languages/cs_CZ/LC_MESSAGES/devicemonitor.mo \
                  /usr/local/opnsense/mvc/app/languages/cs_CZ/LC_MESSAGES/devicemonitor.po
        
        if [ $? -eq 0 ]; then
            echo "  ✓ Překlady úspěšně nainstalovány (EN, CZ)"
        else
            echo "  ✗ CHYBA: Kompilace překladů selhala"
        fi
    else
        echo "  ⚠ msgfmt není dostupný - překlady nebudou fungovat"
    fi
else
    echo "  ⚠ Překladové soubory nenalezeny - plugin bude pouze v angličtině"
fi

# ============================================
# MODELS
# ============================================

echo ""
echo "[6/9] Kopíruji Models..."

cp src/opnsense/mvc/app/models/OPNsense/DeviceMonitor/DeviceMonitor.xml \
   /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/

cp src/opnsense/mvc/app/models/OPNsense/DeviceMonitor/DeviceMonitor.php \
   /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/

cp src/opnsense/mvc/app/models/OPNsense/DeviceMonitor/Menu/Menu.xml \
   /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/Menu/

cp src/opnsense/mvc/app/models/OPNsense/DeviceMonitor/ACL/ACL.xml \
   /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/ACL/

cp src/opnsense/mvc/app/models/OPNsense/DeviceMonitor/defaults.json \
   /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/defaults.json

echo "  ✓ Models nainstalovány"

# ============================================
# CONTROLLERS
# ============================================

echo ""
echo "[7/9] Kopíruji Controllers..."

cp src/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/IndexController.php \
   /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/

cp src/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/Api/*.php \
   /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/Api/

echo "  ✓ Controllers nainstalovány"

# ============================================
# VIEWS
# ============================================

echo ""
echo "[8/9] Kopíruji Views..."

cp src/opnsense/mvc/app/views/OPNsense/DeviceMonitor/*.volt \
   /usr/local/opnsense/mvc/app/views/OPNsense/DeviceMonitor/

echo "  ✓ Views nainstalovány"

# ============================================
# SCRIPTS A KONFIGURACE
# ============================================

echo ""
echo "[9/9] Finalizuji instalaci..."

# Python scripts
echo "  → Python skripty..."
cp src/opnsense/scripts/OPNsense/DeviceMonitor/*.py \
   /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/

chmod +x /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/*.py


cp src/opnsense/scripts/OPNsense/DeviceMonitor/*.php \
   /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/

chmod +x /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/*.php

# Configd actions
echo "  → Configd actions..."
cp src/opnsense/service/conf/actions.d/actions_devicemonitor.conf \
   /usr/local/opnsense/service/conf/actions.d/

# Autostart
echo "  → Zapínám autostart..."
echo 'devicemonitor_enable="YES"' > /etc/rc.conf.d/devicemonitor
chmod 644 /etc/rc.conf.d/devicemonitor

# Smaž starou databázi (pokud existuje)
if [ -f "/var/db/known_devices.db" ]; then
    echo "  → Odstraňuji starou databázi..."
    rm -f /var/db/known_devices.db
fi

# Vyčisti cache
echo "  → Čistím cache..."
rm -f /tmp/opnsense_menu_cache.xml
rm -f /tmp/opnsense_acl_cache.json
rm -rf /var/cache/opnsense/templates/* 2>/dev/null || true

# Aktualizuj menu
echo "  → Aktualizuji menu..."
/usr/local/etc/rc.configure_plugins

# Restart služeb
echo "  → Restartuji služby..."
service configd restart
sleep 2

configctl webgui restart
sleep 2

service php-fpm restart
sleep 2

echo "  ✓ Instalace dokončena"

# ============================================
# SPUŠTĚNÍ DAEMONA
# ============================================

echo ""
echo "Spouštím daemon..."

# Počkej chvíli než se všechno inicializuje
sleep 2

# Spusť daemon
if service devicemonitor start; then
    echo "  ✓ Daemon úspěšně spuštěn"
    
    # Ověř že běží
    sleep 1
    if service devicemonitor status > /dev/null 2>&1; then
        PID=$(cat /var/run/devicemonitor.pid 2>/dev/null)
        if [ -n "$PID" ]; then
            echo "  ✓ Daemon běží (PID: $PID)"
        fi
    else
        echo "  ⚠ Daemon byl spuštěn, ale ještě se inicializuje..."
        echo "🔧 Ovládání daemona:"
        echo "   service devicemonitor start"
        echo "   service devicemonitor stop"
        echo "   service devicemonitor status"
        echo "   service devicemonitor restart"
        echo ""
    fi
else
    echo "  ⚠ VAROVÁNÍ: Daemon se nepodařilo spustit"
    echo "  → Spusť ručně: service devicemonitor start"
    echo "  → Nebo zkontroluj log: tail -f /var/log/system.log | grep devicemonitor"
fi

# ============================================
# FINÁLNÍ ZPRÁVA
# ============================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Device Monitor úspěšně nainstalován!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 Přístup:"
echo "   GUI: Services > Device Monitor"
echo ""
echo "⚙️  Doporučené kroky:"
echo "   1. Nakonfiguruj SMTP: System > Settings > Notifications > SMTP"
echo "   2. Nastav email: Services > Device Monitor > Settings"
echo "   3. Stáhni OUI databázi: Settings > OUI Database > Stáhnout nyní"
echo ""
echo "🌍 Jazyky:"
echo "   System > Settings > Administration > Language"
echo "   - English (výchozí)"
echo "   - Čeština"
echo ""

exit 0