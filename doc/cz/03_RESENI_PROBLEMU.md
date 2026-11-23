# Řešení problémů

[Přehled projektu](../../README_CZ.md) · [English](../en/03_TROUBLESHOOTING.md)

## Plugin se neobjevuje v Services

```bash
# Ověř že .inc soubor existuje (NE .php!)
ls /usr/local/etc/inc/plugins.inc.d/devicemonitor.inc

# Ověř že PHP může načíst funkci
php -r "require_once('/usr/local/etc/inc/plugins.inc.d/devicemonitor.inc'); var_dump(devicemonitor_services());"

# Znovu načti registry pluginů
/usr/local/etc/rc.configure_plugins
```

## Řízení daemona zobrazuje "Execute error"

```bash
# Zkontroluj že daemon_status.sh existuje a je spustitelný
ls -la /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/daemon_status.sh

# Otestuj ručně (musí vypsat "running" nebo "stopped", nikdy chybu)
sh /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/daemon_status.sh

# Zkontroluj že configd akce jsou načteny
configctl configd actions | grep devicemonitor
```

## Více zombie procesů daemona

```bash
# Zkontroluj kolik jich běží
ps aux | grep monitor_daemon | grep -v grep

# Zabij všechny instance
pkill -f monitor_daemon.py
rm -f /var/run/devicemonitor.pid

# Spusť čerstvou instanci
configctl devicemonitor start
```

Příčina: RC skriptu chyběl `procname`, takže `rc.d` nemohl detekovat běžící proces a spustil nový při každém volání. Opraveno ve v2.0 přidáním `procname="/usr/local/bin/python3"` do RC skriptu.

## Widget zobrazuje pomlčky, žádná data

```bash
# Ověř že stats endpoint funguje
curl -k -u "APIKEY:APISECRET" https://localhost/api/devicemonitor/devices/stats
# Mělo by vrátit: {"total": N, "online": N}

# Ověř že status endpoint funguje
curl -k -u "APIKEY:APISECRET" https://localhost/api/devicemonitor/service/status
# Mělo by vrátit: {"result": "running", ...}
```

Pokud endpointy vrací data ale widget stále zobrazuje pomlčky, vyčisti cache prohlížeče (Ctrl+Shift+R) a zkontroluj konzoli prohlížeče pro JavaScript chyby.

## Emailová upozornění nefungují

```bash
# Test z příkazové řádky
php /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/notify_email.php

# Zkontroluj logy
grep EMAIL /var/log/devicemonitor.log
```

## Daemon se nespustí

```bash
# Zkontroluj log pro chyby při startu
tail -30 /var/log/devicemonitor.log

# Spusť daemon ručně a sleduj chyby
/usr/local/bin/python3 /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/monitor_daemon.py

# Zkontroluj že defaults.json je čitelný
cat /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/defaults.json
```

## Poškozená databáze

```bash
cp /var/db/devicemonitor/devices.db /var/db/devicemonitor/devices.db.backup
rm /var/db/devicemonitor/devices.db
configctl devicemonitor restart
```
