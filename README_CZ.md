# OPNsense Device Monitor

[English](README.md) · **Česky**

Device Monitor je plugin pro OPNsense, který sleduje síťová zařízení pomocí vestavěné databáze Hostwatch a posílá upozornění na nová zařízení.

## Funkce

- Seznam známých zařízení s MAC a IP adresou, výrobcem, názvem a časem první a poslední detekce.
- Načítání názvů z rezervací DHCP, ruční pojmenování zařízení a filtrování upozornění podle VLAN.
- E-mail přes místní Sendmail/Postfix nebo přímé SMTP. Webhooky pro ntfy.sh, Discord a obecné HTTP cíle.
- Widget v OPNsense Lobby s počtem zařízení a stavem služby. Ovládání služby ve webovém rozhraní.

## Instalace

Vyžaduje **OPNsense 26.1.5 nebo novější**. Postupuj podle [návodu k instalaci](doc/cz/01_INSTALACE.md).

## Dokumentace

- [Instalace, aktualizace a odinstalace](doc/cz/01_INSTALACE.md)
- [Nastavení a použití](doc/cz/02_NASTAVENI_A_POUZITI.md)
- [Řešení problémů](doc/cz/03_RESENI_PROBLEMU.md)
- [Technická dokumentace](doc/cz/04_TECHNICKA_DOKUMENTACE.md)
- [Historie verzí](doc/cz/HISTORIE_VERZI.md)

## Projekt

[Nahlásit problém](https://github.com/hacesoft/opnsense-devicemonitor/issues) · [Další projekty Hacesoft](https://github.com/hacesoft?tab=repositories) · [hacesoft.cz](https://hacesoft.cz) · [Licence BSD 2-Clause](LICENSE)
