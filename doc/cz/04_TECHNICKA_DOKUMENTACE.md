# Technická dokumentace

[Přehled projektu](../../README_CZ.md) · [English](../en/04_TECHNICAL_REFERENCE.md)

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
│   │   ├── smtp_send.py               # Direct SMTP
│   │   ├── config_hostnames.py        # Rezervace Kea DHCPv4
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

### Volitelný přehled provozu PF

Služba Device Monitor čte při zapnuté volbě `firewall_traffic_enabled` přibližně každých 30 sekund existující stavy PF pomocí akce configd `filter diag top`. Samostatné vlákno udržuje v paměti základ pro čítač, součet přírůstků a čas posledního přírůstku pro jednoznačné dvojice MAC a IP v databázi. Souhrn zapisuje atomicky do `/var/run/devicemonitor-pf.json`. Běžný požadavek na seznam zařízení s `include_pf_packets` ověří oprávnění Firewall Sessions a připojí jen souhrny vrácených řádků. Stránka počítá odpočet z času serveru. Při zastavení sběru označí snímek starší než 75 sekund jako nedostupný.

Přehled počítá společný stav z času `last_seen_at` (Hostwatch) a `seenAt` (poslední přírůstek čítače PF). Obě časové značky porovnává se serverovým časem z odpovědi seznamu. Stejný stav používá tabulka, filtr, řazení, souhrn a export seznamu.

Snímek obsahuje také příští termín společného 15minutového vyhodnocení a výsledek posledního vyhodnocení, pokud byl při něm snímek dostupný. Termín určuje služba nezávisle na otevřených stránkách a přírůstcích v jednotlivých řádcích.

### API endpointy

| Metoda | Endpoint | Popis |
|--------|----------|-------|
| GET | `/api/devicemonitor/devices/stats` | Celkový počet a počet zařízení zaznamenaných v Hostwatch za posledních 15 minut (pole API má název `online`) |
| GET | `/api/devicemonitor/service/status` | Stav daemona (running/stopped) |
| POST | `/api/devicemonitor/service/start` | Spustit daemon |
| POST | `/api/devicemonitor/service/stop` | Zastavit daemon |
| POST | `/api/devicemonitor/service/restart` | Restartovat daemon |
| POST | `/api/devicemonitor/service/scan` | Spustit ruční skenování |
| GET | `/api/devicemonitor/config/get` | Načíst konfiguraci |
| POST | `/api/devicemonitor/config/set` | Uložit konfiguraci |
| POST | `/api/devicemonitor/config/testemail` | Odeslat testovací email |
| POST | `/api/devicemonitor/config/testwebhook` | Odeslat testovací webhook |

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

### E-mailová fronta

Při uložení nového zařízení se ve stejné transakci zapíše `email_queued_at`, pokud je e-mail povolen a zařízení odpovídá filtru VLAN. Daemon čeká na pauzu po posledním nálezu. Při zapnutém maximu odešle dávku nejpozději v termínu od prvního nálezu. Po úspěšném předání transportu vymaže jen odeslané položky. Fronta přežije restart a po chybě se další pokus provede přibližně za minutu. Pokud SMTP zprávu přijme a proces skončí ještě před potvrzením v databázi, může po restartu přijít znovu. Vypnutí e-mailových upozornění vyprázdní dosud neodeslanou frontu.

### Nápověda v nastavení

Přepínač nápovědy upravuje viditelnost popisků a vazby `aria-describedby`. Stav se ukládá do `localStorage` pro daný prohlížeč a adresu OPNsense.

### Bezpečnostní hranice

Přehled a správa mají samostatná ACL. Akce s vedlejšími účinky vyžadují POST a kontrolují oprávnění pro zápis. Ruční ping musí odpovídat uložené dvojici MAC a IP. API konfigurace pro tajné údaje vrací pouze informaci, zda jsou uloženy. Soubor konfigurace se nahrazuje atomicky s oprávněním 0600. CSV před podezřelé začátky buněk přidává tabulátor a apostrof a uzavírá obsah do uvozovek. Při strojovém importu může být ochranná předpona součástí hodnoty.

### Fronta webhooků a provozní limity

Webhook se zařadí do vlastního sloupce `webhook_queued_at` ve stejné transakci jako nově uložené zařízení. Ruční nebo plánované načtení Hostwatch nepřepisuje existující frontu. Služba doručuje webhooky po skupinách z jednoho načtení. Oba kanály mají samostatné zámky, dávky nejvýš 100 zařízení a po chybě pokus opakují přibližně za minutu. Vypnutí kanálu odstraní jeho čekající položky. V obou kanálech může vzdálená služba přijmout zprávu těsně před výpadkem procesu. Pak může při opakování přijít znovu.

Výstup PF se při čtení omezuje na 16 MiB a 20 sekund. Při překročení je nový snímek označený jako nedostupný. Limit se vztahuje na načtený výstup, rozbalený JSON může zabrat více paměti. Hostwatch se čte po řádcích, služba uchovává nejnovější záznam pro každou MAC.

Instalátor přidává pravidlo `/usr/local/etc/newsyslog.conf.d/devicemonitor.conf`. Aktivní log má práva 0600. Jakmile dosáhne přibližně 1 MiB, při dalším spuštění `newsyslog` se otočí. Systém uchovává až pět komprimovaných kopií.

### Kontrola vstupních dat

Nález Hostwatch musí obsahovat platnou MAC, IPv4 a čas posledního pozorování. Neplatné záznamy a časy vzdálené více než minutu do budoucnosti se přeskočí. Při výběru posledního záznamu se porovnávají normalizované časy v UTC. Formálně platná MAC nebo IP sama neověřuje identitu zařízení.

Konfigurace má limit 64 KiB a vyžaduje objekt JSON. Poškozený nebo typově neplatný soubor uspí automatické načítání a doručování, čekající notifikace zůstávají v databázi. Ručně spuštěné načtení může i v takovém případě aktualizovat inventář podle platných dat Hostwatch. API odmítá neplatné změny před atomickým zápisem.
