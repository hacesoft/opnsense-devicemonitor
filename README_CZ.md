# OPNsense Device Monitor Plugin

<div align="center">

![OPNsense](https://img.shields.io/badge/OPNsense-24.x-orange?style=flat-square&logo=opnsense)
![Python](https://img.shields.io/badge/Python-3.8+-blue?style=flat-square&logo=python)
![License](https://img.shields.io/badge/License-BSD--2--Clause-green?style=flat-square)
![Verze](https://img.shields.io/badge/Verze-1.0.0-brightgreen?style=flat-square)

**Automatické monitorování síťových zařízení s detekcí v reálném čase, identifikací výrobců a emailovými notifikacemi**

[Funkce](#funkce) • [Instalace](#instalace) • [Dokumentace](DOKUMENTACE_CZ.md) • [Změny](CHANGELOG,md)

[🇬🇧 English](README.md) | 🇨🇿 Čeština

</div>

---

## 📖 Přehled

**OPNsense Device Monitor** je pokročilý plugin, který automaticky detekuje a monitoruje všechna zařízení připojená k vaší síti. Poskytuje přehled v reálném čase o síťové infrastruktuře, identifikuje výrobce zařízení, sleduje online/offline stav a upozorňuje vás na nová zařízení prostřednictvím emailových notifikací.

### Proč Device Monitor?

- 🔒 **Bezpečnost**: Okamžitá detekce neautorizovaných zařízení v síti
- 📊 **Správa inventáře**: Automatická databáze IT majetku
- 🔍 **Identifikace výrobců**: Rozpozná 40,000+ výrobců přes IEEE OUI databázi
- 🌐 **Podpora multi-VLAN**: Monitoruje všechny VLANy současně
- ⚡ **Výkon**: < 1% CPU, minimální dopad na systém
- 📧 **Notifikace**: HTML emailové upozornění na nová zařízení
- 🎯 **Přesnost**: pfctl-based detekce pro přesný online/offline stav

---

## ✨ Funkce

### Základní vlastnosti

- **Automatické síťové skenování**
  - Daemon běží na pozadí s konfigurovatelným intervalem (60-3600s)
  - ARP tabulka, DHCP leases a Layer 2 skenování
  - Podpora multi-VLAN s automatickou detekcí rozhraní
  
- **Detekce stavu v reálném čase**
  - Analýza pfctl state table pro přesný online/offline stav
  - Funguje se statickými DHCP rezervacemi
  - Rychlost detekce pod sekundu (< 100ms)

- **Identifikace výrobců**
  - IEEE OUI databáze s 40,000+ výrobci
  - Automatické aktualizace přes naplánované cron joby
  - In-memory cache pro okamžité vyhledávání

- **Emailové notifikace**
  - HTML emaily s inline CSS (kompatibilní se všemi klienty)
  - Detailní informace o zařízení: MAC, IP, hostname, vendor, VLAN
  - Konfigurovatelný odesílatel a příjemce
  - Funkce test emailu

- **Webové GUI**
  - Dashboard se statistikami (celkem, online, nová dnes)
  - Interaktivní tabulka zařízení s vyhledáváním, řazením a stránkováním
  - Správa nastavení
  - Ovládání daemona (start/stop/restart)
  - Manuální spuštění scanu

- **Správa databáze**
  - SQLite3 pro perzistenci
  - Sledování historie zařízení
  - Timestampy poslední aktivity
  - Indexované dotazy pro výkon

---

## 🚀 Rychlý start

### Požadavky

- OPNsense 24.x nebo novější
- Python 3.8+ (součást OPNsense)
- Nakonfigurovaný SMTP server (pro emailové notifikace)
- ~10 MB volného diskového prostoru

### Instalace

```bash
# Stažení pluginu
wget https://github.com/yourusername/opnsense-devicemonitor/releases/latest/download/DeviceMonitor_plugin.zip

# Rozbalení
unzip DeviceMonitor_plugin.zip
cd DeviceMonitor_plugin

# Instalace pomocí Makefile
make install

# Spuštění daemona
make start

# Kontrola stavu
make status
```

**Alternativa**: Manuální instalace přes `install.sh` script

### Základní konfigurace

1. **Konfigurace SMTP** (System → Settings → Notifications → SMTP)
   ```
   SMTP Server: smtp.gmail.com
   Port: 587
   Šifrování: STARTTLS
   ```

2. **Konfigurace Device Monitor** (Services → DeviceMonitor → Settings)
   ```
   ☑ Zapnout monitoring
   Email To: admin@example.com
   Interval skenování: 300 sekund
   ```

3. **Stažení OUI databáze** (Services → DeviceMonitor → OUI Management)
   ```
   Klikni "Download OUI Database"
   Zapni Auto-Update (volitelné)
   ```

4. **Zobrazení zařízení** (Services → DeviceMonitor → Devices)

---

## 📚 Dokumentace

### Kompletní dokumentace (česky)
- [📖 Kompletní dokumentace](docs/DOKUMENTACE_CZ.md) - Úplná dokumentace v češtině
- [📦 Instalační návod](docs/INSTALACE_CZ.md) - Detailní instalační instrukce
- [⚙️ Návod ke konfiguraci](docs/KONFIGURACE_CZ.md) - Kompletní reference konfigurace
- [🔧 Řešení problémů](docs/TROUBLESHOOTING_CZ.md) - Časté problémy a řešení

### English Documentation
- [Installation Guide](docs/INSTALLATION.md)
- [Configuration Guide](docs/CONFIGURATION.md)
- [API Documentation](docs/API.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

---

## 🛠️ Technologie

| Komponenta | Technologie | Účel |
|-----------|------------|------|
| **Backend** | Python 3.8+ | Daemon a logika skenování |
| **Frontend** | PHP 8.1+ (OPNsense MVC) | Webové GUI |
| **Databáze** | SQLite3 | Perzistence zařízení |
| **Detekce** | pfctl, ARP, tcpdump | Síťové skenování |
| **Notifikace** | SMTP (sendmail) | Emailové upozornění |
| **Vendor DB** | IEEE OUI | Identifikace výrobců |

---

## 📊 Výkon

| Metrika | Hodnota |
|---------|---------|
| **Využití CPU** | < 1% (během scanu), 0% (idle) |
| **Využití paměti** | ~60 MB (včetně OUI cache) |
| **Čas scanu** | 10-15 sekund (celá síť) |
| **Rychlost detekce** | < 100 ms (pfctl dotaz) |
| **Velikost databáze** | ~1 MB (100 zařízení) |
| **Síťový dopad** | Minimální (< 0.01 Mbps) |

---

## 🤝 Přispívání

Vítáme příspěvky! Prosím přečtěte si [CONTRIBUTING.md](CONTRIBUTING.md) pro detaily.

### Vývojové prostředí

```bash
# Klonování repozitáře
git clone https://github.com/yourusername/opnsense-devicemonitor.git
cd opnsense-devicemonitor

# Instalace vývojových závislostí
make dev-install

# Spuštění testů
make test

# Build pluginu
make build
```

---

## 📝 Changelog

Viz [CHANGELOG.md](CHANGELOG.md) pro detailní historii verzí.

### Nejnovější vydání (v1.0.0)

- ✨ První veřejné vydání
- 🎯 pfctl-based detekce pro přesný online/offline stav
- 📊 Podpora multi-VLAN
- 📧 HTML emailové notifikace
- 🏷️ IEEE OUI identifikace výrobců
- 🌐 Kompletní webové GUI

---

## 📜 Licence

Tento projekt je licencován pod **BSD 2-Clause License** - viz soubor [LICENSE](LICENSE) pro detaily.

---

## 🙏 Poděkování

- **OPNsense Tým** - Za vynikající firewallovou platformu
- **IEEE** - Za údržbu OUI databáze
- **Přispěvatelé** - Všem, kdo přispěli kódem, hlášeními chyb nebo návrhy

---

## 📞 Podpora

### Komunitní podpora

- **GitHub Issues**: [Nahlásit chybu nebo požádat o funkci](https://github.com/yourusername/opnsense-devicemonitor/issues)
- **OPNsense Fórum**: [Diskutovat na fóru](https://forum.opnsense.org/)
- **Dokumentace**: [Kompletní dokumentace](docs/)

---

## 🗺️ Plánované funkce

- [ ] Webový dashboard s grafy (Chart.js)
- [ ] Slack/Discord/Telegram notifikace
- [ ] Seskupování a tagování zařízení
- [ ] Historické statistiky a trendy
- [ ] REST API pro externí integrace
- [ ] Mobilní aplikace (iOS/Android)
- [ ] Whitelist/blacklist MAC adres
- [ ] Vlastní názvy a poznámky k zařízením
- [ ] Export do CSV/PDF
- [ ] Integrace s nástroji pro mapování sítě

---

<div align="center">

**Vytvořeno s ❤️ od [Hacesoft](https://github.com/hacesoft)**

[⬆ Zpět nahoru](#opnsense-device-monitor-plugin)

</div>
