# Instalace, aktualizace a odinstalace

[Přehled projektu](../../README_CZ.md) · [English](../en/01_INSTALLATION.md)

## Požadavky

- **OPNsense 26.1.5 nebo novější**
- **SSH přístup** (System → Settings → Administration → Secure Shell)
- **Root účet** nebo admin s přístupem do CLI

> ⚠️ Verze starší než 26.1.5 nejsou podporovány. Plugin používá API a mechanismy zavedené ve verzi 26.x.

## Instalace

### Instalace z Windows přes WinSCP a SSH

1. Stáhni instalační ZIP Device Monitor 2.3.1.
2. Pokud SSH ještě nepoužíváš, povol ho v **System → Settings → Administration → Secure Shell**.
3. Nahraj ZIP přes WinSCP do `/tmp/` na OPNsense.
4. Připoj se přes SSH, přepni se na účet s oprávněním root a spusť:

```sh
cd /tmp
unzip opnsense-devicemonitor-2.3.1.zip
cd opnsense-devicemonitor
sh install.sh
```

### Stažení verze 2.3 přímo přes SSH

Odkaz v příkazu níže vede na dříve zveřejněnou verzi 2.3. Pro verzi 2.3.1 použij ZIP z předchozího postupu. Na OPNsense spusť jako root:

```sh
cd /tmp
fetch https://raw.githubusercontent.com/hacesoft/opnsense-devicemonitor/main/release/opnsense-devicemonitor28082026_1812.zip
unzip opnsense-devicemonitor28082026_1812.zip
cd opnsense-devicemonitor
sh install.sh
```

V **System → Diagnostics → Services** ověř, že služba `devicemonitor` běží. OPNsense kvůli instalaci nemusíš restartovat.

### Aktualizace stávající instalace

Spusť `install.sh` z novějšího balíku. Při nalezení stávající instalace skript používá tichou odinstalaci, která zachová databázi zařízení. Potom můžeš pokračovat podle [návodu k nastavení](02_NASTAVENI_A_POUZITI.md).

### Co dělá install.sh

1. Zkontroluje verzi OPNsense (minimum 26.1.5)
2. Spustí `uninstall.sh --silent` pokud je detekována stará instalace (zachová databázi)
3. Vytvoří všechny potřebné adresáře
4. Zkopíruje RC skript a zaregistruje službu v `plugins.inc.d`
5. Nainstaluje dashboard widget
6. Zkompiluje překladové soubory
7. Zkopíruje MVC controllery, modely, views
8. Zkopíruje Python, shell a PHP skripty
9. Zkopíruje configd akce
10. Zabije zombie procesy daemona, spustí čerstvou instanci přes `configctl devicemonitor start`

## Odinstalace

### Metoda 1: uninstall.sh (doporučeno)

```bash
cd /cesta/k/opnsense-devicemonitor
sh uninstall.sh
```

Odstraní všechny soubory, zastaví daemon, vypne autostart a vyčistí cache. Databáze `/var/db/devicemonitor/devices.db` je smazána.

### Metoda 2: Tichá odinstalace (zachová databázi)

```bash
sh uninstall.sh --silent
```

Používá interně `install.sh` při upgrade. Odstraní všechny soubory, ale zachová databázi.

### Metoda 3: Ruční

```bash
pkill -f monitor_daemon.py
rm -f /var/run/devicemonitor.pid
rm -f /etc/rc.conf.d/devicemonitor
rm -f /usr/local/etc/rc.d/devicemonitor
rm -f /etc/rc.d/devicemonitor
rm -f /usr/local/etc/inc/plugins.inc.d/devicemonitor.inc
rm -rf /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor
rm -rf /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor
rm -rf /usr/local/opnsense/mvc/app/views/OPNsense/DeviceMonitor
rm -rf /usr/local/opnsense/scripts/OPNsense/DeviceMonitor
rm -f /usr/local/opnsense/service/conf/actions.d/actions_devicemonitor.conf
rm -f /usr/local/opnsense/www/js/widgets/DeviceMonitor.js
rm -f /usr/local/opnsense/www/js/widgets/Metadata/DeviceMonitor.xml
rm -rf /var/db/devicemonitor        # POZOR: smaže databázi zařízení
rm -f /var/log/devicemonitor.log
/usr/local/etc/rc.configure_plugins
service configd restart
```
