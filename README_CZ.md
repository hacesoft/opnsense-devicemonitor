# OPNsense Device Monitor

[English](README.md) · **Česky**

Device Monitor je plugin pro OPNsense, který sleduje síťová zařízení pomocí vestavěné databáze Hostwatch a posílá upozornění na nová zařízení.

## Funkce

- Přehled nalezených zařízení s MAC a IP adresou, názvem, výrobcem, VLAN a časem posledního pozorování Hostwatch.
- Označení známých zařízení, ruční ping a export vyfiltrovaného seznamu do CSV. Aktivitu z Hostwatch lze doplnit údaji firewallu.
- E-mail přes přímé SMTP. Podporované zůstávají i stávající konfigurace místního Sendmailu/Postfixu. Webhooky pro ntfy.sh, Discord a obecné HTTP cíle.
- Widget v OPNsense Lobby s počtem zařízení a stavem služby. Ovládání služby ve webovém rozhraní.

## Instalace

Vyžaduje **OPNsense 26.1.5 nebo novější**. Postupuj podle [návodu k instalaci](doc/cz/01_INSTALACE.md).

## Dokumentace

- [Instalace, aktualizace a odinstalace](doc/cz/01_INSTALACE.md)
- [Nastavení a použití](doc/cz/02_NASTAVENI_A_POUZITI.md)
- [Řešení problémů](doc/cz/03_RESENI_PROBLEMU.md)
- [Informace pro správce](doc/cz/04_TECHNICKA_DOKUMENTACE.md)
- [Historie verzí](doc/cz/HISTORIE_VERZI.md)

## Projekt

[Nahlásit problém](https://github.com/hacesoft/opnsense-devicemonitor/issues) · [Další projekty Hacesoft](https://github.com/hacesoft?tab=repositories) · [hacesoft.cz](https://hacesoft.cz) · [Licence BSD 2-Clause](LICENSE)
