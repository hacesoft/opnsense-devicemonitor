# OPNsense Device Monitor

**[🇬🇧 English version](README.md)** | **[👨‍💻 Další projekty autora](https://github.com/hacesoft?tab=repositories)**

---

Plugin pro automatické sledování síťových zařízení v OPNsense firewallu. Detekuje nová zařízení pomocí ARP skenování a odesílá emailová upozornění.

---

## 📋 Obsah

- [Co plugin dělá](#co-plugin-dělá)
- [Funkce](#funkce)
- [Instalace](#instalace)
  - [Metoda 1: WinSCP + Ruční instalace](#metoda-1-winscp--ruční-instalace-doporučeno)
  - [Metoda 2: Přímá SSH instalace](#metoda-2-přímá-ssh-instalace)
- [Nastavení](#nastavení)
- [Použití](#použití)
- [Struktura pluginu](#struktura-pluginu)
- [Řešení problémů](#řešení-problémů)
- [Verzování](#verzování)
- [Odinstalace](#odinstalace)

---

## Co plugin dělá

Plugin automaticky sleduje síť a upozorňuje na:

- 🆕 **Nová zařízení** připojující se do sítě
- 🔄 **Změny IP adres** u existujících zařízení
- 📊 **Historie zařízení** s časovými údaji první/poslední detekce
- 🌐 **VLAN filtrování** - sledování jen vybraných síťových segmentů

---

## Funkce

✅ **Automatické ARP skenování** - detekce zařízení každých 5-30 minut  
✅ **Emailová upozornění** - okamžité notifikace o nových zařízeních a změnách IP  
✅ **VLAN filtrování** - sledování jen vybraných VLAN (např. LAN, VLAN20, VLAN50)  
✅ **Historie IP adres** - více IP adres na jednu MAC adresu  
✅ **Webový dashboard** - přehled statistik, ruční spuštění skenování  
✅ **Správa zařízení** - mazání jednotlivých zařízení nebo celé databáze  
✅ **Nastavitelné intervaly** - skenování každých 5, 10, 15 nebo 30 minut  
✅ **Test email tlačítko** - ověření SMTP konfigurace  

---

## Instalace

### Požadavky

- OPNsense 24.x nebo novější
- Funkční SMTP nastavení (System → Settings → Notifications)
- SSH přístup povolen (System → Settings → Administration → Secure Shell)
- Root heslo

---

### Metoda 1: WinSCP + Ruční instalace (Doporučeno)

Tato metoda je nejjednodušší pro uživatele, kteří nejsou zvyklí na příkazovou řádku.

#### Krok 1: Stáhni nejnovější verzi

Jdi na [**Releases**](/../../releases) /tree/main/releases a stáhni nejnovější archiv:

```
opnsense-devicemonitor31122025_1339.zip
```

**Název souboru:**
- `opnsense-devicemonitor` = název pluginu
- `31122025` = datum (DD.MM.RRRR)
- `1339` = čas (HH:MM)
- `.zip` = formát archivu

**Příklad:** `opnsense-devicemonitor31122025_1254.zip` = 31. prosince 2025 ve 13:39

**Poznámka:** Starší verze najdeš ve složce `/old/` v releases.

#### Krok 2: Povolit SSH na OPNsense

```
1. Přihlas se do webového rozhraní OPNsense
2. Jdi na: System → Settings → Administration
3. Zapni "Secure Shell"
4. Zaškrtni "Permit root user login"
5. Login Shell: /bin/csh (výchozí je OK)
6. Ulož
```

#### Krok 3: Nahraj soubor přes WinSCP

**Stáhni WinSCP:** https://winscp.net/

**Připoj se k OPNsense:**
```
Host:     tvoje.opnsense.ip.adresa
Port:     22
Uživatel: root
Heslo:    tvoje-root-heslo
```

**Postup nahrání:**
1. Ve WinSCP jdi do `/tmp/`
2. Přetáhni `opnsense-devicemonitor31122025_1254.zip` do okna

#### Krok 4: Instalace přes SSH

Použij PuTTY (Windows) nebo Terminál (Mac/Linux) pro připojení:

```bash
ssh root@tvoje.opnsense.ip
```

Pak spusť:

```bash
# Přejdi do složky s archivem
cd /tmp

# Rozbal archiv
unzip opnsense-devicemonitor31122025_1254.zip
cd opnsense-devicemonitor

# Spusť instalaci
sh install.sh
```

**Poznámka:** Restart OPNsense **NENÍ potřeba** - instalační script se o vše postará!

---

### Metoda 2: Přímá SSH instalace

Pro pokročilé uživatele znalé příkazové řádky:

```bash
# Připoj se přes SSH
ssh root@tvoje.opnsense.ip

# Stáhni nejnovější verzi (UPRAV URL!)
cd /tmp
fetch https://github.com/hacesoft/opnsense-devicemonitor/releases/download/v31122025_1254/opnsense-devicemonitor31122025_1254.zip

# Rozbal
unzip opnsense-devicemonitor31122025_1254.zip
cd opnsense-devicemonitor

# Instaluj
sh install.sh
```

**Pro starší verze:**

Pokud chceš nainstalovat starší verzi, uprav URL:

```bash
fetch https://github.com/hacesoft/opnsense-devicemonitor/releases/download/old/opnsense-devicemonitorDDMMRRRR_HHMM.zip
```

---

## Nastavení

Po instalaci jdi na: **Services → DeviceMonitor → Settings**

### Základní konfigurace

| Nastavení | Popis | Příklad |
|-----------|-------|---------|
| **Enable Device Monitor** | Zapnout/vypnout sledování | ✅ Zaškrtnuto |
| **Email (To)** | Tvůj email pro upozornění | `admin@example.com` |
| **Email (From)** | Email odesílatele | `opnsense@tvojadomena.cz` |
| **Scan Interval** | Jak často skenovat | `5 minutes` |
| **VLAN Filter** | Které VLAN sledovat | `LAN,VLAN20,VLAN50` |

### Příklady VLAN filtru

**Sledovat všechny sítě:**
```
LAN,VLAN11,VLAN20,VLAN30,VLAN50,VLAN70,VLAN80
```

**Sledovat jen LAN a hostovskou síť:**
```
LAN,VLAN50
```

**Sledovat jen jedno VLAN:**
```
VLAN20
```

**Důležité:** Názvy VLAN musí přesně odpovídat názvům rozhraní!

### Test konfigurace

1. Klikni na tlačítko **Test Email**
2. Zkontroluj schránku
3. Pokud email nedorazil:
   - Ověř SMTP nastavení: System → Settings → Notifications
   - Zkontroluj spam složku
   - Prohlédni logy: `grep devicemonitor /var/log/system.log`

---

## Použití

### Dashboard

**Umístění:** Services → DeviceMonitor → Dashboard

**Zobrazuje:**
- 📊 Total Devices - všechna kdy detekovaná zařízení
- 🆕 New Today - zařízení detekovaná dnes
- ⏰ Last Cron Run - časová značka posledního automatického skenování
- 🔄 Scan Now - tlačítko pro ruční skenování
- 📋 View All Devices - odkaz na seznam zařízení

### Seznam zařízení

**Umístění:** Services → DeviceMonitor → Devices

**Sloupce tabulky:**
- MAC adresa
- IP adresa
- Hostname (zjištěno přes reverse DNS)
- VLAN (síťový segment)
- First Seen (datum/čas první detekce)
- Last Seen (nejnovější detekce)
- Actions (ikona koše pro smazání)

**Operace:**
- ☑️ **Vybrat více** - checkbox vlevo
- 🗑️ **Delete Selected** - smazat vybraná zařízení
- 🗑️ **Individuální mazání** - ikona koše u každého zařízení

### Stránka nastavení

**Umístění:** Services → DeviceMonitor → Settings

**Akce:**
- 💾 **Save** - uložit konfiguraci
- ✉️ **Test Email** - ověřit funkčnost SMTP
- ⚠️ **Clear Database** - smazat VŠECHNY záznamy zařízení (vyžaduje potvrzení)

---

## Struktura pluginu

### Adresářová struktura

```
opnsense-devicemonitor/
├── install.sh                          # Instalační script
├── uninstall.sh                        # Odinstalační script
├── README.md                           # Dokumentace (CZ)
├── README_EN.md                        # Dokumentace (EN)
├── LICENSE                             # BSD 2-Clause licence
├── +MANIFEST                           # PKG metadata
├── +INSTALL                            # Post-install hook
├── +DEINSTALL                          # Post-uninstall hook
├── etc/
│   └── inc/
│       └── plugins.inc.d/
│           └── devicemonitor.inc       # Plugin hook
└── usr/
    └── local/
        └── opnsense/
            ├── mvc/app/
            │   ├── controllers/
            │   │   └── OPNsense/DeviceMonitor/
            │   │       ├── IndexController.php       # Hlavní controller
            │   │       ├── Api/
            │   │       │   ├── SettingsController.php   # API nastavení
            │   │       │   ├── DevicesController.php    # API zařízení
            │   │       │   └── ServiceController.php    # API služby
            │   │       └── forms/
            │   │           └── general.xml              # Formulář definice
            │   ├── models/
            │   │   └── OPNsense/DeviceMonitor/
            │   │       ├── DeviceMonitor.xml         # Model XML
            │   │       ├── DeviceMonitor.php         # Model PHP
            │   │       ├── Menu/
            │   │       │   └── Menu.xml              # Menu definice
            │   │       └── ACL/
            │   │           └── ACL.xml               # ACL definice
            │   └── views/
            │       └── OPNsense/DeviceMonitor/
            │           ├── index.volt                # Dashboard view
            │           ├── devices.volt              # Zařízení view
            │           └── settings.volt             # Nastavení view
            ├── scripts/devicemonitor/
            │   ├── scan.sh                           # ARP scanner script
            │   └── testemail.sh                      # Test email script
            └── service/conf/actions.d/
                └── actions_devicemonitor.conf        # Configd actions
```

### Databáze a logy

```
/var/db/known_devices.db                # SQLite databáze zařízení
/var/log/devicemonitor_cron.log         # Log cron běhů
```

### Formát databáze

**Soubor:** `/var/db/known_devices.db`

**Formát:** Hodnoty oddělené rourou (|)

```
MAC|IP|Hostname|PrvníDetekce|PosledníDetekce|Zdroj|Rozhraní|VLAN
```

**Příklad záznamu:**
```
aa:bb:cc:dd:ee:ff|192.168.1.100|PC-Honza|2025-11-30 10:15:23|2025-12-01 08:45:12|ARP|igc0|LAN
```

---

## Jak to funguje

### Technický přehled

1. **Cron Job**: OPNsense cron spouští scan script každých X minut (nastavený interval)
2. **ARP Scan**: Script spustí `arp -an` pro získání aktuálních zařízení
3. **VLAN Filtrování**: Zpracovávají se jen zařízení na povolených VLAN
4. **Kontrola databáze**: Porovnání aktuálních zařízení s uloženou databází
5. **Emailová upozornění**: Odeslání notifikace při:
   - Detekci nové MAC adresy
   - Existující MAC s jinou IP adresou
6. **Aktualizace databáze**: Záznam informací o zařízení do SQLite databáze
7. **Logování**: Zápis časové značky do `/var/log/devicemonitor_cron.log`

### Ruční příkazy

```bash
# Test emailové notifikace
configctl devicemonitor testemail

# Spuštění ručního skenování
configctl devicemonitor scan

# Zobrazení databáze
cat /var/db/known_devices.db

# Kontrola posledního cron spuštění
cat /var/log/devicemonitor_cron.log

# Zobrazení logů pluginu
grep devicemonitor /var/log/system.log | tail -20
```

---

## Řešení problémů

### Menu se nezobrazuje po instalaci

**Příznaky:** V menu Services není položka "DeviceMonitor"

**Řešení 1 - Vymazání cache:**
```bash
rm -f /tmp/opnsense_menu_cache.xml
rm -f /tmp/opnsense_acl_cache.json
configctl webgui restart
```

**Řešení 2 - Restart OPNsense:**
```bash
shutdown -r now
```

---

### Stránka Settings je prázdná

**Příznaky:** Na stránce Settings jsou jen tlačítka, chybí formulářová pole

**Diagnostika:**
```bash
# Zkontroluj zda existuje soubor forms
ls -la /usr/local/opnsense/mvc/app/controllers/OPNsense/DeviceMonitor/forms/general.xml
```

**Řešení:**
```bash
# Restart webgui
configctl webgui restart

# Pokud stále nefunguje, přeinstaluj plugin
cd /tmp/opnsense-devicemonitor
sh install.sh
```

---

### Emaily se neposílají

**Kontrola SMTP konfigurace:**
1. System → Settings → Notifications
2. Test pomocí vestavěného testu OPNsense: System → Settings → Notifications → Test
3. Pokud OPNsense test selže, nejprve oprav SMTP nastavení

**Kontrola konfigurace pluginu:**
1. Services → DeviceMonitor → Settings
2. Klikni "Test Email"
3. Zkontroluj že emailová adresa je správná

**Kontrola logů:**
```bash
# Zobrazení logů pluginu
grep devicemonitor /var/log/system.log

# Zobrazení SMTP logů
grep sendmail /var/log/maillog
```

---

### Zařízení se nedetekují

**Kontrola běhu skenování:**
```bash
# Zobraz čas posledního cron spuštění
cat /var/log/devicemonitor_cron.log

# Mělo by zobrazit nedávnou časovou značku: 2025-12-01 14:30:15
```

**Kontrola VLAN filtru:**
- Ujisti se že názvy VLAN přesně odpovídají rozhraním
- Rozlišují se velká/malá písmena: `VLAN20` ≠ `vlan20`
- Zkontroluj názvy rozhraní: Interfaces → Assignments

**Spuštění ručního skenování:**
```bash
# Mělo by vypsat detekce zařízení
configctl devicemonitor scan
```

---

### Instalační script selhává

**Chyba: "Command not found" nebo "not found" zprávy**

**Příčina:** Windows konce řádků (CRLF) v souborech scriptu

**Řešení:**
```bash
cd /tmp/opnsense-devicemonitor
sed -i '' 's/\r$//' install.sh
sed -i '' 's/\r$//' uninstall.sh
sh install.sh
```

---

## Verzování

### Jak jsou pojmenovány verze

**Formát archivu:**
```
opnsense-devicemonitorDDMMRRRR_HHMM.zip
```

Kde:
- `DD` = Den (01-31)
- `MM` = Měsíc (01-12)
- `RRRR` = Rok (4 číslice)
- `HH` = Hodina (00-23, 24hodinový formát)
- `MM` = Minuty (00-59)

**Příklady:**
- `opnsense-devicemonitor31122025_1254.zip` = 31. prosince 2025 ve 12:54
- `opnsense-devicemonitor15012026_0920.zip` = 15. ledna 2026 v 9:20

### Organizace verzí

**Aktuální verze:**
- Nejnovější vydání je vždy na hlavní stránce [Releases](../../releases)
- Kompletní archiv obsahuje celý plugin připravený k instalaci

**Staré verze:**
- Předchozí vydání přesunuta do složky `/old/`
- Dostupné pro rollback pokud je potřeba
- Pojmenovány stejným formátem časové značky

### Změny oproti předchozí verzi

**Verze 31122025_1254:**
- První veřejné vydání
- Kompletní PKG struktura
- Dokumentace v češtině a angličtině

---

## Odinstalace

### Odstranění pluginu

```bash
# Přejdi do instalační složky
cd /tmp/opnsense-devicemonitor

# Spusť odinstalační script
sh uninstall.sh
```

**Co se odstraní:**
- Všechny soubory pluginu z `/usr/local/opnsense/`
- Plugin hook z `/etc/inc/plugins.inc.d/`
- Cron joby
- Menu cache

**Co zůstane zachováno:**
- Databáze: `/var/db/known_devices.db`
- Logy: `/var/log/devicemonitor_cron.log`

### Úplné odstranění

Pro odstranění i databáze a logů:

```bash
rm -f /var/db/known_devices.db
rm -f /var/log/devicemonitor_cron.log
```

---

## Podpora

### Pomoc

- 🐛 **Hlášení chyb:** [GitHub Issues](../../issues/new)
- 💬 **Dotazy:** [GitHub Discussions](../../discussions)
- 📧 **Email:** hacesoft@mujmail.cz

---

## Licence

BSD 2-Clause License - viz soubor [LICENSE](LICENSE)

---

## Autor

**Hacesoft**

- 🌐 Web: [hacesoft.cz](https://hacesoft.cz)
- 📧 Email: hacesoft@mujmail.cz
- 💻 GitHub: [@hacesoft](https://github.com/hacesoft)
- 📦 **Všechny projekty:** [github.com/hacesoft?tab=repositories](https://github.com/hacesoft?tab=repositories)

---

**[⬆ Zpět nahoru](#opnsense-device-monitor)**
