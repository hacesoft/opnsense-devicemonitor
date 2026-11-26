# Informace pro správce

[Přehled projektu](../../README_CZ.md) · [English](../en/04_TECHNICAL_REFERENCE.md)

## Oprávnění

V OPNsense otevři **System → Access → Users** nebo **Groups**.

| Oprávnění | Co umožňuje |
|-----------|-------------|
| **Services: Device Monitor (read only)** | Přehled zařízení, export CSV a stav služby. |
| **Services: Device Monitor (manage)** | Navíc úpravy zařízení, ruční ping, nastavení, zkušební upozornění a ovládání služby. |
| **Firewall Sessions** | Přístup k volitelným údajům o provozu přes firewall. |

Účet s úplným přístupem OPNsense může plugin spravovat. Při upgradu z verze starší než 2.4.14 poskytuje původní delegované oprávnění Device Monitor pouze čtení.

## Data a logy

| Cesta | Obsah |
|-------|-------|
| `/var/db/devicemonitor/devices.db` | Seznam zařízení, ruční názvy, označení známé MAC a čekající upozornění. |
| `/var/db/devicemonitor/config.json` | Nastavení včetně uložených přihlašovacích údajů. Soubor má práva `0600`. |
| `/var/log/devicemonitor.log` | Provozní log. Při dosažení přibližně 1 MiB ho systém při dalším běhu rotace otočí a uchová až pět komprimovaných kopií. |

Pro zálohu konfigurace a inventáře uchovej celý adresář `/var/db/devicemonitor` v chráněném umístění. Poškozená konfigurace pozastaví automatické načítání a doručování. Čekající upozornění zůstanou v databázi. Pokud cíl zprávu přijal těsně před výpadkem služby, opakovaný pokus ji může doručit znovu.

## Základní API

Použij účet nebo API klíč s příslušným oprávněním. API nastavení vrací pouze informaci o tom, zda je SMTP heslo či adresa webhooku uložená.

| Metoda | Cesta pod `/api/devicemonitor/` | Výsledek |
|--------|--------------------------------|----------|
| GET | `devices/stats` | Celkový počet zařízení a počet aktivních podle Hostwatch. |
| GET | `service/status` | Stav služby. |
| GET | `config/get` | Nastavení bez uloženého hesla a URL webhooku. |
| POST | `config/set` | Uložení ověřených nastavení. |
| POST | `config/testemail`, `config/testWebhook` | Test doručení. |
