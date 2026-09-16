# OPNsense Device Monitor

**[🇬🇧 English version](README.md)** | **[👨‍💻 Další projekty autora](https://github.com/hacesoft?tab=repositories)**

---

Plugin pro automatické sledování síťových zařízení v OPNsense firewallu. Detekuje nová zařízení pomocí nativní OPNsense hostwatch databáze a odesílá emailová nebo webhook upozornění.

---

## 📋 Obsah

- [Co plugin dělá](#co-plugin-dělá)
- [Historie verzí](#historie-verzí)
- [Funkce](#funkce)
- [Požadavky](#požadavky)
- [Instalace](#instalace)
- [Nastavení](#nastavení)
- [Použití](#použití)
- [Struktura pluginu](#struktura-pluginu)
- [Jak daemon funguje](#jak-daemon-funguje)
- [Řešení problémů](#řešení-problémů)
- [Odinstalace](#odinstalace)

---

## Co plugin dělá

Plugin automaticky sleduje síť a upozorňuje na:

- 🆕 **Nová zařízení** připojující se do sítě
- 📊 **Historii zařízení** s časovými údaji první/poslední detekce
- 📧 **Emailová upozornění** s profesionálním HTML designem
- 🔔 **Webhook upozornění** (ntfy.sh, Discord, vlastní)
- 🖥️ **Dashboard widget** na stránce Lobby v OPNsense

---

## Historie verzí

### v2.3 (srpen 2026) — Přímé SMTP a vylepšení upozornění

- Do nastavení Device Monitoru přibyla volba **způsobu odesílání e-mailu**.
- **Local Sendmail / Postfix** zůstává výchozí metodou a zachovává chování stávajících instalací.
- Přidáno vestavěné **Direct SMTP** pomocí standardní Python knihovny `smtplib`; není potřeba instalovat další Python balíček.
- Direct SMTP podporuje **STARTTLS**, **SSL/TLS** i nešifrované SMTP.
- Do UI přibylo nastavení SMTP serveru, portu, uživatelského jména a hesla.
- **Test Email** nyní používá právě zvolený způsob odesílání.
- Existující konfigurace se při aktualizaci automaticky doplní o nové výchozí položky, takže není nutný reset konfigurace.
- SMTP heslo se nepředává na příkazové řádce procesu, ale načítá se z chráněné konfigurace Device Monitoru.
- Konfigurační soubor obsahující SMTP údaje se ukládá s omezenými přístupovými právy.
- Součástí jsou i opravy z v2.2: výběr nejnovějšího Hostwatch záznamu pro každou MAC, zabránění návratu ručně smazaných zařízení z historických záznamů, oprava filtrování VLAN upozornění a zachování skutečného Hostwatch `last_seen` při rychlé aktualizaci stavu.

v2.1 (duben 2026) — Podpora Dnsmasq hostname
Co se změnilo a proč
1. Načítání hostname z Dnsmasq — `get_dnsmasq_descriptions()`
Uživatelé OPNsense, kteří migrovali ze zastaralého ISC DHCPv4 na Dnsmasq DNS & DHCP (doporučená náhrada od OPNsense 25.7+), měli v Device Monitoru prázdné hostname. Předchozí kód četl hostname pouze z `config.xml → dhcpd` (statická mapování ISC DHCP).
Nová funkce čte hostname z části config.xml určené pro Dnsmasq Host Overrides. Správná XML struktura Dnsmasq záznamu vypadá takto:
```xml
<hosts uuid="...">
  <host>MojeZarizeni</host>              ← pole hostname
  <hwaddr>aa:bb:cc:dd:ee:ff</hwaddr>     ← MAC adresa (pozor: hwaddr, NE hw)
  <ip>192.168.1.100</ip>
  <descr>Popis zařízení</descr>
</hosts>
```
> ⚠️ Pole MAC adresy se jmenuje `<hwaddr>` — nikoliv `<hw>` jak by se dalo očekávat. Potvrzeno přímou inspekcí živého `config.xml`.
2. Vypnuté ISC DHCP interfacy jsou přeskočeny
Pokud je ISC DHCP interface vypnutý (checkbox odškrtnutý v UI), OPNsense nenastaví žádný element `<enable>` uvnitř konfiguračního bloku daného interface. Aktualizovaná funkce `get_dhcp_descriptions()` přeskočí každý ISC interface, kterému chybí tag `<enable>`, a zabrání tak tomu, aby se zastaralá data z vypnutých interfaců zobrazovala jako hostname.
3. Priorita zdrojů hostname
Překlad hostname nyní sleduje jasný prioritní řetězec:
```
1. custom_hostname  (nastaveno ručně v UI Device Monitoru — nejvyšší priorita)
2. Dnsmasq          (Host Overrides s vazbou MAC → hostname)
3. ISC DHCP         (statická mapování, preferováno pole hostname před descr)
```
Dnsmasq přepíše ISC data pro stejnou MAC adresu pomocí `dict.update()`:
```python
dhcp_descriptions = get_dhcp_descriptions()        # ISC DHCP (jen zapnuté interfacy)
dnsmasq_descriptions = get_dnsmasq_descriptions()  # Dnsmasq Host Overrides
dhcp_descriptions.update(dnsmasq_descriptions)     # Dnsmasq vyhraje při konfliktu
```
4. Preference pole hostname v ISC DHCP
Dříve čtenář ISC DHCP používal pouze `<descr>` (pole poznámky/popisu). Nyní preferuje `<hostname>` a na `<descr>` se vrací pouze tehdy, když `<hostname>` chybí nebo je prázdné. To odpovídá tomu, jak se hostname skutečně zobrazují v DNS a tabulkách DHCP lease.


### v2.0 (duben 2026) — Kompletní přepracování

Tato verze je kompletní má těsnějsi integraci s OPNsense 26.x. Mnoho komponent, které byly dříve vytvořeny na míru, je nyní nahrazeno nativními mechanismy OPNsense.

#### Co se změnilo a proč

**1. Registrace služby — `plugins.inc.d/devicemonitor.inc`**

V předchozích verzích byl daemon pro OPNsense zcela neviditelný. Neobjevoval se v *System → Diagnostics → Services*, takže nebylo možné ho spustit/zastavit/restartovat z GUI.

Opravou je nový soubor `src/etc/inc/plugins.inc.d/devicemonitor.inc`, který registruje službu pomocí nativního mechanismu OPNsense `plugins_services()`.

```php
function devicemonitor_services()
{
    $services = [];
    $services[] = [
        'description' => gettext('Device Monitor - network device tracking'),
        'configd' => [
            'restart' => ['devicemonitor restart'],
            'start'   => ['devicemonitor start'],
            'stop'    => ['devicemonitor stop'],
        ],
        'name'    => 'devicemonitor',
        'pidfile' => '/var/run/devicemonitor.pid',
    ];
    return $services;
}
```

**2. Kontrola stavu daemona — `daemon_status.sh`**

Předchozí přístup používal `service devicemonitor status` v configd akci `[status]`. Na FreeBSD tento příkaz vrací exit kód 1 i tehdy, když služba normálně běží (vrací 1 = "není spravováno rc.d tradičním způsobem"). Protože configd typ `script_output` považuje jakýkoliv nenulový exit za chybu, každá kontrola stavu skončila `Execute error`.

Opravou je dedikovaný shell skript, který přímo kontroluje pidfile:

```sh
#!/bin/sh
PIDFILE="/var/run/devicemonitor.pid"
if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "running"
        exit 0
    fi
    rm -f "$PIDFILE"   # vyčistí stale pidfile
fi
echo "stopped"
exit 0
```

**3. `actions_devicemonitor.conf` — `|| true` u start/stop/restart**

Bez `|| true`, pokud daemon již běžel a configd se pokusil ho znovu spustit, `service devicemonitor start` vrátil nenulový exit kód (daemon already running), který configd interpretoval jako chybu a zobrazil `Error (1)`. Přidání `|| true` zajistí, že configd vždy vidí úspěch.

Akce `[status]` nyní volá `daemon_status.sh` místo `service devicemonitor status`.

**4. `rc.d/devicemonitor` — přidán `procname`, opravena výchozí hodnota**

Dvě opravy:
- Výchozí hodnota změněna z `"YES"` na `"NO"` — FreeBSD konvence: skript sám musí být výchozí disabled; aktivaci řídí `/etc/rc.conf.d/devicemonitor`
- Přidán `procname="/usr/local/bin/python3"` — bez tohoto `rc.d` nemůže najít běžící proces, a každý `start` vytvořil nový zombie proces.

**5. `service.xml` — oprava názvu tagu, přidán `<pidfile>`, opraveny `<commands>`**

Tři chyby v jednom souboru:
- `<n>DeviceMonitor</n>` → `<name>DeviceMonitor</name>` — OPNsense tag `<n>` nerozpoznal
- Přidán `<pidfile>/var/run/devicemonitor.pid</pidfile>` — nutný pro zobrazení zelené/červené tečky stavu
- `<commands>` změněno ze shell příkazů (`service devicemonitor start`) na názvy configd akcí (`devicemonitor start`)

**6. `ServiceController.php` — start/stop/restart přes `configdRun()`**

Dříve PHP API controller volal `exec('service devicemonitor start')` přímo. Tím obchází privilege model OPNsense. Veškeré řízení služby nyní prochází přes `$backend->configdRun('devicemonitor start')`.

**7. Dashboard widget — oprava odpojeného DOM elementu**

Metoda `onWidgetTick()` widgetu aktualizovala `this.$container.find('.dm-total')`. Widget framework OPNsense však kopíruje markup do DOMu místo vložení původního jQuery objektu, takže `this.$container` ukazoval na odpojený element — `.find()` fungovalo tiše, ale změny nebyly na obrazovce nikdy vidět.

Opraveno přidáním unikátního `id` každému elementu a výběrem přímo z dokumentu:

```javascript
// Dříve (rozbité — aktualizuje odpojený element)
this.$container.find('.dm-total').text(stats.total);

// Po opravě (správně — vybírá z živého DOM)
$('#dm-total').text(stats.total);
```

Také opraveno: widget volal `/api/devicemonitor/service/status` pro počty zařízení (který vrací stav daemona, nikoliv statistiky). Nyní správně volá `/api/devicemonitor/devices/stats`.

**8. `install.sh` — kompletní přepis**

Klíčové změny:
- Čištění zombie procesů před spuštěním daemona (`pkill -f monitor_daemon.py`)
- Daemon spouštěn přes `configctl devicemonitor start` místo `service devicemonitor start`
- Daemon ověřen přes pidfile + `kill -0` místo `service devicemonitor status`
- Odstraněno rozbité `service php-fpm restart` a `configctl webgui restart`
- Přidán krok instalace `plugins.inc.d/devicemonitor.inc`
- Opraveno číslování kroků (bylo `[6/11]` následováno `[6/10]`)

**9. `uninstall.sh` — opraveno zastavení daemona**

Dříve používal `service devicemonitor status`, který vrátil exit 1, čímž zastavení selhalo. Nyní používá `pkill -f monitor_daemon.py`, které vždy funguje bez ohledu na stav pidfile.

Také odstraněno rozbité `configctl webgui restart` a `service php-fpm restart` — tyto příkazy buď nejsou dostupné nebo jsou zbytečné na OPNsense 26.x.

---

### v1.x (leden 2026)

- **Oprava kompatibility s OPNsense 26.x:** Odstraněna volání `$this->sessionClose()` z controllerů. Tato funkce byla odstraněna v OPNsense 26.0 a způsobovala crash při zavolání. Přidána automatická detekce verze pro zachování zpětné kompatibility s 25.x.

---

## Funkce

### 🎯 Základní funkce

✅ **Detekce zařízení** přes OPNsense hostwatch SQLite databázi (`/var/db/hostwatch/hosts.db`)
✅ **Emailová upozornění** — profesionální HTML emaily s inline CSS
✅ **Webhook upozornění** — ntfy.sh, Discord, vlastní HTTP POST endpointy
✅ **Historie zařízení** — časy první/poslední detekce
✅ **Vendor lookup** — výrobce z MAC adresy (IEEE OUI databáze)

### 🖥️ Webové rozhraní

✅ **Dashboard widget** — zobrazuje celkový/online počet zařízení a stav daemona na stránce Lobby
✅ **Seznam zařízení** — prohledávatelná, řaditelná tabulka s akcemi mazání
✅ **Stránka nastavení** — vše na jednom místě s testovacími tlačítky
✅ **Řízení služby** — viditelné v *System → Diagnostics → Services* s tlačítky start/stop/restart

### 📊 Technické

✅ **SQLite databáze** — rychlé ukládání, není potřeba externí databáze
✅ **Daemon na pozadí** — Python proces spravovaný FreeBSD rc.d
✅ **Integrace configd** — všechny akce služby procházejí přes OPNsense configd
✅ **Logování** — `/var/log/devicemonitor.log`

---

## Požadavky

- **OPNsense 26.1.5 nebo novější**
- **SSH přístup** (System → Settings → Administration → Secure Shell)
- **Root účet** nebo admin s přístupem do CLI

> ⚠️ Verze starší než 26.1.5 nejsou podporovány. Plugin používá API a mechanismy zavedené ve verzi 26.x.

---

## Instalace

### Metoda 1: WinSCP + SSH (doporučeno)

**Krok 1:** Stáhni nejnovější ZIP z [Release](../../tree/main/release).

**Krok 2:** Povol SSH na OPNsense:
```
System → Settings → Administration → Secure Shell → Enable
```

**Krok 3:** Nahraj přes WinSCP do `/tmp/` na OPNsense.

**Krok 4:** Připoj se přes SSH a nainstaluj:
```bash
cd /tmp
unzip opnsense-devicemonitor*.zip
cd opnsense-devicemonitor
sh install.sh
```

Restart není potřeba. Instalační skript se postará o vše.

---

### Metoda 2: Přímá SSH instalace

```bash
ssh root@tvoje.opnsense.ip
cd /tmp
fetch https://github.com/hacesoft/opnsense-devicemonitor/releases/latest/download/opnsense-devicemonitor.zip
unzip opnsense-devicemonitor.zip
cd opnsense-devicemonitor
sh install.sh
```

---

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

---

## Nastavení

Jdi na: **Services → DeviceMonitor → Settings**

### Základní

| Nastavení | Popis |
|-----------|-------|
| Enable Device Monitor | Zapnout/vypnout skenování |
| Scan Interval | Jak často skenovat (5–30 minut) |

### Emailová upozornění

Vyžaduje funkční SMTP: **System → Settings → Notifications → E-Mail**

| Nastavení | Popis |
|-----------|-------|
| Enable Email | Zapnout emailová upozornění |
| Email (To) | Adresa příjemce |
| Email (From) | Adresa odesílatele |
| Test Email | Odeslat testovací zprávu |

### Webhook upozornění

| Nastavení | Popis |
|-----------|-------|
| Enable Webhook | Zapnout webhook upozornění |
| Webhook URL | Cílová URL |
| Test Webhook | Odeslat testovací payload |

**Podporované typy webhooků:**

- **ntfy.sh** — `https://ntfy.sh/tvojeSecretTema`
- **Discord** — `https://discord.com/api/webhooks/...`
- **Generic** — jakýkoliv HTTP POST endpoint přijímající JSON

---

## Použití

### Widget na Lobby dashboardu

Po instalaci přidej widget **Device Monitor** na Lobby dashboard. Zobrazuje:
- Stav daemona (Running / Stopped)
- Celkový počet zařízení
- Počet online zařízení

### Seznam zařízení

**Services → DeviceMonitor → Devices**

Sloupce: MAC, Vendor, IP, Hostname, First Seen, Last Seen, Akce

### Řízení služby

**System → Diagnostics → Services → devicemonitor**

Spusť, zastav, restartuj daemon přímo z GUI. Zelená/červená tečka odráží skutečný stav procesu přes pidfile.

### Logy

```bash
# Sledování v reálném čase
tail -f /var/log/devicemonitor.log

# Filtrování podle typu
grep EMAIL /var/log/devicemonitor.log
grep WEBHOOK /var/log/devicemonitor.log
grep SCAN /var/log/devicemonitor.log
```

---

## Struktura pluginu

```
src/
├── etc/
│   ├── rc.d/
│   │   └── devicemonitor              # FreeBSD rc.d servisní skript
│   └── inc/
│       └── plugins.inc.d/
│           └── devicemonitor.inc      # Registrace služby pro Diagnostics → Services
├── opnsense/
│   ├── mvc/app/
│   │   ├── controllers/OPNsense/DeviceMonitor/
│   │   │   ├── IndexController.php
│   │   │   └── Api/
│   │   │       ├── ConfigController.php
│   │   │       ├── DevicesController.php
│   │   │       └── ServiceController.php
│   │   ├── models/OPNsense/DeviceMonitor/
│   │   │   ├── DeviceMonitor.php
│   │   │   ├── DeviceMonitor.xml
│   │   │   ├── defaults.json
│   │   │   ├── Metadata/
│   │   │   │   └── service.xml        # MVC service metadata
│   │   │   ├── Menu/Menu.xml
│   │   │   └── ACL/ACL.xml
│   │   └── views/OPNsense/DeviceMonitor/
│   │       ├── devices.volt
│   │       ├── settings.volt
│   │       └── service_widget.volt
│   ├── scripts/OPNsense/DeviceMonitor/
│   │   ├── monitor_daemon.py          # Hlavní daemon
│   │   ├── scan_network.py            # Skenovací skript
│   │   ├── daemon_status.sh           # Spolehlivá kontrola stavu přes pidfile
│   │   ├── NotificationHandler.php
│   │   ├── notify_email.php
│   │   └── notify_webhook.php
│   ├── service/conf/actions.d/
│   │   └── actions_devicemonitor.conf # Definice configd akcí
│   └── www/js/widgets/
│       ├── DeviceMonitor.js           # Lobby dashboard widget
│       └── Metadata/
│           └── DeviceMonitor.xml      # Metadata a endpointy widgetu
```

### Runtime soubory

```
/var/run/devicemonitor.pid             # PID daemona
/var/log/devicemonitor.log             # Log soubor
/var/db/devicemonitor/
├── devices.db                         # SQLite databáze zařízení
└── config.json                        # Runtime konfigurace
/etc/rc.conf.d/devicemonitor           # Příznak autostartu
```

### API endpointy

| Metoda | Endpoint | Popis |
|--------|----------|-------|
| GET | `/api/devicemonitor/devices/stats` | Celkový a online počet zařízení |
| GET | `/api/devicemonitor/service/status` | Stav daemona (running/stopped) |
| POST | `/api/devicemonitor/service/start` | Spustit daemon |
| POST | `/api/devicemonitor/service/stop` | Zastavit daemon |
| POST | `/api/devicemonitor/service/restart` | Restartovat daemon |
| POST | `/api/devicemonitor/service/scan` | Spustit ruční skenování |
| GET | `/api/devicemonitor/config/get` | Načíst konfiguraci |
| POST | `/api/devicemonitor/config/set` | Uložit konfiguraci |
| POST | `/api/devicemonitor/config/testemail` | Odeslat testovací email |
| POST | `/api/devicemonitor/config/testwebhook` | Odeslat testovací webhook |

---

## Jak daemon funguje

```
monitor_daemon.py (proces na pozadí)
    │
    ├── čte /var/db/devicemonitor/config.json   (scan interval, příznak enabled)
    ├── čte /var/db/hostwatch/hosts.db           (nativní detekce OPNsense)
    ├── zapisuje /var/db/devicemonitor/devices.db (known devices, fronta notifikací)
    └── zapisuje /var/log/devicemonitor.log

configd (konfigurační daemon OPNsense)
    │
    ├── devicemonitor start   → service devicemonitor start || true
    ├── devicemonitor stop    → service devicemonitor stop || true
    ├── devicemonitor restart → service devicemonitor restart || true
    └── devicemonitor status  → daemon_status.sh (kontrola pidfile, vždy exit 0)

rc.d/devicemonitor
    │
    ├── používá /usr/sbin/daemon -f -p /var/run/devicemonitor.pid python3 monitor_daemon.py
    ├── procname="/usr/local/bin/python3"   (potřebné aby stop našel proces)
    └── výchozí: devicemonitor_enable="NO"  (aktivováno přes /etc/rc.conf.d/devicemonitor)
```

---

## Řešení problémů

### Plugin se neobjevuje v Services

```bash
# Ověř že .inc soubor existuje (NE .php!)
ls /usr/local/etc/inc/plugins.inc.d/devicemonitor.inc

# Ověř že PHP může načíst funkci
php -r "require_once('/usr/local/etc/inc/plugins.inc.d/devicemonitor.inc'); var_dump(devicemonitor_services());"

# Znovu načti registry pluginů
/usr/local/etc/rc.configure_plugins
```

### Řízení daemona zobrazuje "Execute error"

```bash
# Zkontroluj že daemon_status.sh existuje a je spustitelný
ls -la /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/daemon_status.sh

# Otestuj ručně (musí vypsat "running" nebo "stopped", nikdy chybu)
sh /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/daemon_status.sh

# Zkontroluj že configd akce jsou načteny
configctl configd actions | grep devicemonitor
```

### Více zombie procesů daemona

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

### Widget zobrazuje pomlčky, žádná data

```bash
# Ověř že stats endpoint funguje
curl -k -u "APIKEY:APISECRET" https://localhost/api/devicemonitor/devices/stats
# Mělo by vrátit: {"total": N, "online": N}

# Ověř že status endpoint funguje
curl -k -u "APIKEY:APISECRET" https://localhost/api/devicemonitor/service/status
# Mělo by vrátit: {"result": "running", ...}
```

Pokud endpointy vrací data ale widget stále zobrazuje pomlčky, vyčisti cache prohlížeče (Ctrl+Shift+R) a zkontroluj konzoli prohlížeče pro JavaScript chyby.

### Emailová upozornění nefungují

```bash
# Test z příkazové řádky
php /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/notify_email.php

# Zkontroluj logy
grep EMAIL /var/log/devicemonitor.log
```

### Daemon se nespustí

```bash
# Zkontroluj log pro chyby při startu
tail -30 /var/log/devicemonitor.log

# Spusť daemon ručně a sleduj chyby
/usr/local/bin/python3 /usr/local/opnsense/scripts/OPNsense/DeviceMonitor/monitor_daemon.py

# Zkontroluj že defaults.json je čitelný
cat /usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/defaults.json
```

### Poškozená databáze

```bash
cp /var/db/devicemonitor/devices.db /var/db/devicemonitor/devices.db.backup
rm /var/db/devicemonitor/devices.db
configctl devicemonitor restart
```

---

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

---

## Podpora

**GitHub Issues:** https://github.com/hacesoft/opnsense-devicemonitor/issues

**Autor:**
- GitHub: [@hacesoft](https://github.com/hacesoft)
- Web: [hacesoft.cz](https://hacesoft.cz)

---

## Licence

MIT License — viz [LICENSE](LICENSE)
