# OPNsense Device Monitor Plugin - Makefile
# ==========================================

.PHONY: help install uninstall reinstall status start stop restart scan test-email clean backup

# Předpona s označuje řetězec. Názvy parametrů cest pro make zůstávají veřejné.
# Historie: 2.3.7 – sjednocení typových předpon proměnných.

# Barvy pro výstup
sRed    = \033[0;31m
sGreen  = \033[0;32m
sYellow = \033[0;33m
sBlue   = \033[0;34m
sResetColor     = \033[0m # No Color

# Cesty
PLUGIN_NAME = DeviceMonitor
DB_DIR = /var/db/devicemonitor
BACKUP_DIR = /root/devicemonitor_backup

help:
	@echo "$(sBlue)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(sResetColor)"
	@echo "$(sBlue)  OPNsense Device Monitor - Makefile$(sResetColor)"
	@echo "$(sBlue)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(sResetColor)"
	@echo ""
	@echo "$(sGreen)Instalace:$(sResetColor)"
	@echo "  make install      - Nainstaluje plugin"
	@echo "  make uninstall    - Odinstaluje plugin"
	@echo "  make reinstall    - Přeinstaluje plugin (uninstall + install)"
	@echo ""
	@echo "$(sGreen)Daemon:$(sResetColor)"
	@echo "  make start        - Spustí daemon"
	@echo "  make stop         - Zastaví daemon"
	@echo "  make restart      - Restartuje daemon"
	@echo "  make status       - Zobrazí status daemona"
	@echo ""
	@echo "$(sGreen)Operace:$(sResetColor)"
	@echo "  make scan         - Manuální sken sítě"
	@echo "  make test-email   - Test email formátů"
	@echo "  make logs         - Sleduj logy"
	@echo "  make db           - Zobraz databázi"
	@echo ""
	@echo "$(sGreen)Údržba:$(sResetColor)"
	@echo "  make clean        - Vyčistí cache"
	@echo "  make backup       - Zálohuje databázi"
	@echo "  make restore      - Obnoví databázi"
	@echo ""

install:
	@echo "$(sGreen)Instaluji Device Monitor...$(sResetColor)"
	@test -f install.sh || { echo "$(sRed)CHYBA: install.sh nenalezen!$(sResetColor)"; exit 1; }
	@chmod +x install.sh
	@./install.sh
	@echo "$(sGreen)✓ Instalace dokončena$(sResetColor)"

	# Helper skripty pro configd
	install -m 0755 src/opnsense/scripts/OPNsense/DeviceMonitor/notify_email.php \
		$(DESTDIR)/usr/local/opnsense/scripts/OPNsense/DeviceMonitor/
	install -m 0755 src/opnsense/scripts/OPNsense/DeviceMonitor/notify_webhook.php \
		$(DESTDIR)/usr/local/opnsense/scripts/OPNsense/DeviceMonitor/

uninstall:
	@echo "$(sYellow)Odinstalovávám Device Monitor...$(sResetColor)"
	@test -f uninstall.sh || { echo "$(sRed)CHYBA: uninstall.sh nenalezen!$(sResetColor)"; exit 1; }
	@chmod +x uninstall.sh
	@./uninstall.sh
	@echo "$(sYellow)✓ Odinstalace dokončena$(sResetColor)"

reinstall: uninstall
	@echo "$(sBlue)Čekám 3 sekundy...$(sResetColor)"
	@sleep 3
	@$(MAKE) install

start:
	@echo "$(sGreen)Spouštím daemon...$(sResetColor)"
	@service devicemonitor start || echo "$(sRed)Daemon se nepodařilo spustit$(sResetColor)"
	@sleep 2
	@$(MAKE) status

stop:
	@echo "$(sYellow)Zastavuji daemon...$(sResetColor)"
	@service devicemonitor stop || echo "$(sYellow)Daemon neběží$(sResetColor)"
	@sleep 1
	@$(MAKE) status

restart:
	@echo "$(sBlue)Restartuji daemon...$(sResetColor)"
	@service devicemonitor restart || { $(MAKE) stop; sleep 2; $(MAKE) start; }
	@sleep 2
	@$(MAKE) status

status:
	@echo "$(sBlue)Status daemona:$(sResetColor)"
	@service devicemonitor status || echo "$(sRed)Daemon neběží$(sResetColor)"
	@if [ -f "/var/run/devicemonitor.pid" ]; then \
		echo "$(sGreen)PID: $$(cat /var/run/devicemonitor.pid)$(sResetColor)"; \
	fi

scan:
	@echo "$(sGreen)Spouštím manuální sken...$(sResetColor)"
	@/usr/local/bin/python3 /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/scan_network.py
	@echo "$(sGreen)✓ Sken dokončen$(sResetColor)"

test-email:
	@echo "$(sBlue)Testování email formátů...$(sResetColor)"
	@test -f test_email_formats.sh || { echo "$(sRed)CHYBA: test_email_formats.sh nenalezen!$(sResetColor)"; exit 1; }
	@chmod +x test_email_formats.sh
	@./test_email_formats.sh
	@echo "$(sBlue)✓ Zkontroluj emailovou schránku$(sResetColor)"

logs:
	@echo "$(sBlue)Sledování logů (Ctrl+C pro ukončení):$(sResetColor)"
	@tail -f /var/log/system.log | grep --color=always devicemonitor

db:
	@echo "$(sBlue)Obsah databáze:$(sResetColor)"
	@if [ -f "$(DB_DIR)/devices.db" ]; then \
		echo "$(sGreen)Celkem zařízení:$(sResetColor)"; \
		sqlite3 $(DB_DIR)/devices.db "SELECT COUNT(*) FROM devices;"; \
		echo ""; \
		echo "$(sGreen)Posledních 10 zařízení:$(sResetColor)"; \
		sqlite3 $(DB_DIR)/devices.db "SELECT mac, ip, hostname, vlan, last_seen FROM devices ORDER BY last_seen DESC LIMIT 10;" | column -t -s '|'; \
	else \
		echo "$(sRed)Databáze neexistuje$(sResetColor)"; \
	fi

clean:
	@echo "$(sYellow)Čistím cache...$(sResetColor)"
	@rm -f /tmp/opnsense_menu_cache.xml
	@rm -f /tmp/opnsense_acl_cache.json
	@rm -rf /var/cache/opnsense/templates/*
	@echo "$(sYellow)Restartuji služby...$(sResetColor)"
	@service configd restart
	@configctl webgui restart
	@echo "$(sGreen)✓ Cache vyčištěna$(sResetColor)"

backup:
	@echo "$(sBlue)Zálohuji databázi...$(sResetColor)"
	@mkdir -p $(BACKUP_DIR)
	@if [ -f "$(DB_DIR)/devices.db" ]; then \
		cp $(DB_DIR)/devices.db $(BACKUP_DIR)/devices_$$(date +%Y%m%d_%H%M%S).db; \
		echo "$(sGreen)✓ Záloha uložena do $(BACKUP_DIR)$(sResetColor)"; \
		ls -lh $(BACKUP_DIR)/devices_*.db | tail -1; \
	else \
		echo "$(sRed)Databáze neexistuje$(sResetColor)"; \
	fi

restore:
	@echo "$(sBlue)Dostupné zálohy:$(sResetColor)"
	@ls -lh $(BACKUP_DIR)/devices_*.db 2>/dev/null || { echo "$(sRed)Žádné zálohy nenalezeny$(sResetColor)"; exit 1; }
	@echo ""
	@echo "$(sYellow)Zadej jméno souboru k obnovení:$(sResetColor)"
	@read -p "Soubor: " sFile; \
	if [ -f "$(BACKUP_DIR)/$$sFile" ]; then \
		cp $(BACKUP_DIR)/$$sFile $(DB_DIR)/devices.db; \
		chmod 644 $(DB_DIR)/devices.db; \
		echo "$(sGreen)✓ Databáze obnovena$(sResetColor)"; \
	else \
		echo "$(sRed)Soubor nenalezen!$(sResetColor)"; \
	fi

# Developer cíle
dev-watch:
	@echo "$(sBlue)Sledování změn v souborech...$(sResetColor)"
	@while true; do \
		inotifywait -r -e modify,create,delete src/ 2>/dev/null && \
		echo "$(sYellow)Změna detekována, restartuji...$(sResetColor)" && \
		$(MAKE) reinstall; \
	done

dev-debug:
	@echo "$(sBlue)Debug informace:$(sResetColor)"
	@echo "$(sGreen)Config soubor:$(sResetColor)"
	@cat /tmp/devicemonitor_config.json 2>/dev/null || echo "$(sRed)Config neexistuje$(sResetColor)"
	@echo ""
	@echo "$(sGreen)PID file:$(sResetColor)"
	@cat /var/run/devicemonitor.pid 2>/dev/null || echo "$(sRed)PID file neexistuje$(sResetColor)"
	@echo ""
	@echo "$(sGreen)Daemon proces:$(sResetColor)"
	@ps aux | grep monitor_daemon | grep -v grep || echo "$(sRed)Daemon neběží$(sResetColor)"

# Rychlé příkazy
i: install
u: uninstall
r: reinstall
st: status
sc: scan
l: logs
