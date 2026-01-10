# OPNsense Device Monitor Plugin - Makefile
# ==========================================

.PHONY: help install uninstall reinstall status start stop restart scan test-email clean backup

# Barvy pro výstup
RED    = \033[0;31m
GREEN  = \033[0;32m
YELLOW = \033[0;33m
BLUE   = \033[0;34m
NC     = \033[0m # No Color

# Cesty
PLUGIN_NAME = DeviceMonitor
DB_DIR = /var/db/devicemonitor
BACKUP_DIR = /root/devicemonitor_backup

help:
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)  OPNsense Device Monitor - Makefile$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "$(GREEN)Instalace:$(NC)"
	@echo "  make install      - Nainstaluje plugin"
	@echo "  make uninstall    - Odinstaluje plugin"
	@echo "  make reinstall    - Přeinstaluje plugin (uninstall + install)"
	@echo ""
	@echo "$(GREEN)Daemon:$(NC)"
	@echo "  make start        - Spustí daemon"
	@echo "  make stop         - Zastaví daemon"
	@echo "  make restart      - Restartuje daemon"
	@echo "  make status       - Zobrazí status daemona"
	@echo ""
	@echo "$(GREEN)Operace:$(NC)"
	@echo "  make scan         - Manuální sken sítě"
	@echo "  make test-email   - Test email formátů"
	@echo "  make logs         - Sleduj logy"
	@echo "  make db           - Zobraz databázi"
	@echo ""
	@echo "$(GREEN)Údržba:$(NC)"
	@echo "  make clean        - Vyčistí cache"
	@echo "  make backup       - Zálohuje databázi"
	@echo "  make restore      - Obnoví databázi"
	@echo ""

install:
	@echo "$(GREEN)Instaluji Device Monitor...$(NC)"
	@test -f install.sh || { echo "$(RED)CHYBA: install.sh nenalezen!$(NC)"; exit 1; }
	@chmod +x install.sh
	@./install.sh
	@echo "$(GREEN)✓ Instalace dokončena$(NC)"

	# Helper skripty pro configd
	install -m 0755 src/opnsense/scripts/OPNsense/DeviceMonitor/notify_email.php \
		$(DESTDIR)/usr/local/opnsense/scripts/OPNsense/DeviceMonitor/
	install -m 0755 src/opnsense/scripts/OPNsense/DeviceMonitor/notify_webhook.php \
		$(DESTDIR)/usr/local/opnsense/scripts/OPNsense/DeviceMonitor/

uninstall:
	@echo "$(YELLOW)Odinstalovávám Device Monitor...$(NC)"
	@test -f uninstall.sh || { echo "$(RED)CHYBA: uninstall.sh nenalezen!$(NC)"; exit 1; }
	@chmod +x uninstall.sh
	@./uninstall.sh
	@echo "$(YELLOW)✓ Odinstalace dokončena$(NC)"

reinstall: uninstall
	@echo "$(BLUE)Čekám 3 sekundy...$(NC)"
	@sleep 3
	@$(MAKE) install

start:
	@echo "$(GREEN)Spouštím daemon...$(NC)"
	@service devicemonitor start || echo "$(RED)Daemon se nepodařilo spustit$(NC)"
	@sleep 2
	@$(MAKE) status

stop:
	@echo "$(YELLOW)Zastavuji daemon...$(NC)"
	@service devicemonitor stop || echo "$(YELLOW)Daemon neběží$(NC)"
	@sleep 1
	@$(MAKE) status

restart:
	@echo "$(BLUE)Restartuji daemon...$(NC)"
	@service devicemonitor restart || { $(MAKE) stop; sleep 2; $(MAKE) start; }
	@sleep 2
	@$(MAKE) status

status:
	@echo "$(BLUE)Status daemona:$(NC)"
	@service devicemonitor status || echo "$(RED)Daemon neběží$(NC)"
	@if [ -f "/var/run/devicemonitor.pid" ]; then \
		echo "$(GREEN)PID: $$(cat /var/run/devicemonitor.pid)$(NC)"; \
	fi

scan:
	@echo "$(GREEN)Spouštím manuální sken...$(NC)"
	@/usr/local/bin/python3 /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/scan_network.py
	@echo "$(GREEN)✓ Sken dokončen$(NC)"

test-email:
	@echo "$(BLUE)Testování email formátů...$(NC)"
	@test -f test_email_formats.sh || { echo "$(RED)CHYBA: test_email_formats.sh nenalezen!$(NC)"; exit 1; }
	@chmod +x test_email_formats.sh
	@./test_email_formats.sh
	@echo "$(BLUE)✓ Zkontroluj emailovou schránku$(NC)"

logs:
	@echo "$(BLUE)Sledování logů (Ctrl+C pro ukončení):$(NC)"
	@tail -f /var/log/system.log | grep --color=always devicemonitor

db:
	@echo "$(BLUE)Obsah databáze:$(NC)"
	@if [ -f "$(DB_DIR)/devices.db" ]; then \
		echo "$(GREEN)Celkem zařízení:$(NC)"; \
		sqlite3 $(DB_DIR)/devices.db "SELECT COUNT(*) FROM devices;"; \
		echo ""; \
		echo "$(GREEN)Posledních 10 zařízení:$(NC)"; \
		sqlite3 $(DB_DIR)/devices.db "SELECT mac, ip, hostname, vlan, last_seen FROM devices ORDER BY last_seen DESC LIMIT 10;" | column -t -s '|'; \
	else \
		echo "$(RED)Databáze neexistuje$(NC)"; \
	fi

clean:
	@echo "$(YELLOW)Čistím cache...$(NC)"
	@rm -f /tmp/opnsense_menu_cache.xml
	@rm -f /tmp/opnsense_acl_cache.json
	@rm -rf /var/cache/opnsense/templates/*
	@echo "$(YELLOW)Restartuji služby...$(NC)"
	@service configd restart
	@configctl webgui restart
	@echo "$(GREEN)✓ Cache vyčištěna$(NC)"

backup:
	@echo "$(BLUE)Zálohuji databázi...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@if [ -f "$(DB_DIR)/devices.db" ]; then \
		cp $(DB_DIR)/devices.db $(BACKUP_DIR)/devices_$$(date +%Y%m%d_%H%M%S).db; \
		echo "$(GREEN)✓ Záloha uložena do $(BACKUP_DIR)$(NC)"; \
		ls -lh $(BACKUP_DIR)/devices_*.db | tail -1; \
	else \
		echo "$(RED)Databáze neexistuje$(NC)"; \
	fi

restore:
	@echo "$(BLUE)Dostupné zálohy:$(NC)"
	@ls -lh $(BACKUP_DIR)/devices_*.db 2>/dev/null || { echo "$(RED)Žádné zálohy nenalezeny$(NC)"; exit 1; }
	@echo ""
	@echo "$(YELLOW)Zadej jméno souboru k obnovení:$(NC)"
	@read -p "Soubor: " file; \
	if [ -f "$(BACKUP_DIR)/$$file" ]; then \
		cp $(BACKUP_DIR)/$$file $(DB_DIR)/devices.db; \
		chmod 644 $(DB_DIR)/devices.db; \
		echo "$(GREEN)✓ Databáze obnovena$(NC)"; \
	else \
		echo "$(RED)Soubor nenalezen!$(NC)"; \
	fi

# Developer cíle
dev-watch:
	@echo "$(BLUE)Sledování změn v souborech...$(NC)"
	@while true; do \
		inotifywait -r -e modify,create,delete src/ 2>/dev/null && \
		echo "$(YELLOW)Změna detekována, restartuji...$(NC)" && \
		$(MAKE) reinstall; \
	done

dev-debug:
	@echo "$(BLUE)Debug informace:$(NC)"
	@echo "$(GREEN)Config soubor:$(NC)"
	@cat /tmp/devicemonitor_config.json 2>/dev/null || echo "$(RED)Config neexistuje$(NC)"
	@echo ""
	@echo "$(GREEN)PID file:$(NC)"
	@cat /var/run/devicemonitor.pid 2>/dev/null || echo "$(RED)PID file neexistuje$(NC)"
	@echo ""
	@echo "$(GREEN)Daemon proces:$(NC)"
	@ps aux | grep monitor_daemon | grep -v grep || echo "$(RED)Daemon neběží$(NC)"

# Rychlé příkazy
i: install
u: uninstall
r: reinstall
st: status
sc: scan
l: logs
