# Nastavení a použití

[Přehled projektu](../../README_CZ.md) · [English](../en/02_CONFIGURATION_AND_USAGE.md)

## Nastavení

Jdi na: **Services → DeviceMonitor → Settings**

### Základní

| Nastavení | Popis |
|-----------|-------|
| Enable Device Monitor | Zapnout/vypnout skenování |
| Scan Interval | Jak často skenovat (5–30 minut) |

### E-mailová upozornění

- **Local Sendmail / Postfix** používá `/usr/local/sbin/sendmail` a vyžaduje funkční místní poštovní službu, například plugin `os-postfix`. Je to výchozí způsob odesílání.
- **Direct SMTP** se připojuje přímo k nastavenému SMTP serveru a používá standardní knihovnu Pythonu `smtplib`. Postfix ani Monit k odesílání nepotřebuje.

| Nastavení | Popis |
|-----------|-------|
| Enable Email | Zapnout emailová upozornění |
| Email (To) | Adresa příjemce |
| Email (From) | Adresa odesílatele |
| Email delivery method | Volba mezi Local Sendmail / Postfix a Direct SMTP |
| SMTP Server | Název nebo IP adresa SMTP serveru (jen Direct SMTP) |
| SMTP Port | Obvykle 587 pro STARTTLS nebo 465 pro SSL/TLS |
| Encryption | STARTTLS, SSL/TLS nebo None |
| SMTP Username | Volitelné uživatelské jméno pro přihlášení k SMTP |
| SMTP Password | Volitelné heslo pro přihlášení k SMTP |
| Test Email | Uloží aktuální nastavení a odešle testovací zprávu zvoleným způsobem |

Po aktualizaci se dál používá **Local Sendmail / Postfix**, dokud v nastavení nezvolíš **Direct SMTP**.

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

## Použití

### Widget na Lobby dashboardu

Po instalaci přidej widget **Device Monitor** na Lobby dashboard. Zobrazuje:
- Stav daemona (Running / Stopped)
- Celkový počet zařízení
- Počet online zařízení

### Seznam zařízení

**Services → DeviceMonitor → Devices**

Sloupce: MAC, Vendor, IP, Hostname, First Seen, Last Seen, Akce

Názvy zařízení mají toto pořadí přednosti: ručně zadaný název v Device Monitoru, Dnsmasq Host Overrides, rezervace Kea DHCPv4 a statická přiřazení ISC DHCP. V rezervaci Kea má název přednost před popisem. Rezervace se vyhledává podle MAC adresy.

Pravidelný sken používá čas posledního výskytu z Hostwatch. **Check online** provede samostatnou kontrolu dostupnosti. Její výsledek může přepsat následující sken.

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
