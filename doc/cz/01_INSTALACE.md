# Instalace, aktualizace a odinstalace

[Přehled projektu](../../README_CZ.md) · [English](../en/01_INSTALLATION.md)

## Instalace

Potřebuješ **OPNsense 26.1.5 nebo novější**, přístup k příkazové řádce a oprávnění root. ZIP můžeš na firewall nahrát přes SCP, SFTP nebo například WinSCP. SSH se povoluje v **System → Settings → Administration**.

Nahraj instalační ZIP do `/tmp` a spusť instalaci jako root. Název přizpůsob staženému souboru.

```sh
unzip /tmp/opnsense-devicemonitor-2.4.17.zip -d /tmp/devicemonitor-install
cd /tmp/devicemonitor-install/opnsense-devicemonitor
sh install.sh
```

V **System → Diagnostics → Services** ověř stav služby `devicemonitor`. Potom otevři **Services → Device Monitor → Settings** a pokračuj podle [návodu k nastavení](02_NASTAVENI_A_POUZITI.md).

## Aktualizace

Rozbal nový ZIP do prázdného adresáře a spusť jeho `install.sh` stejným postupem. Aktualizace zachová databázi včetně čekajících upozornění a uloženou konfiguraci v `/var/db/devicemonitor`. Po aktualizaci ověř verzi v záhlaví pluginu a stav služby.

Při přechodu z verze starší než 2.4.14 se dosavadní delegované oprávnění Device Monitor omezí na čtení. Správu můžeš delegovaným účtům povolit podle [přehledu oprávnění](04_TECHNICKA_DOKUMENTACE.md).

## Odinstalace

Z rozbaleného instalačního balíku spusť jako root:

```sh
sh uninstall.sh
```

**Úplná odinstalace smaže databázi zařízení, čekající upozornění a uloženou konfiguraci.** Pokud chceš data ponechat pro pozdější instalaci, použij `sh uninstall.sh --silent`.
