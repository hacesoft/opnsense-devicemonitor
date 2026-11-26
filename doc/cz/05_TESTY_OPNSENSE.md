# Integrační testy pro OPNsense

[English](../en/05_OPNSENSE_TESTS.md) · [Nastavení pluginu](02_NASTAVENI_A_POUZITI.md)

Cíl je zjistit, co už zajišťuje jádro OPNsense a která funkce Device Monitoru ho doplňuje. Testy vycházejí z [diskuse #5964](https://github.com/opnsense/plugins/issues/5964), [PR #11150](https://github.com/opnsense/core/pull/11150) (reverzní DNS) a [PR #11180](https://github.com/opnsense/core/pull/11180) (statistiky PF v Hostwatch).

## 1. Co je dostupné v nainstalované verzi

Na firewallu spusť přes SSH. Příkazy pouze čtou údaje.

```sh
opnsense-version
pkg info -e os-postfix && echo 'os-postfix: installed' || echo 'os-postfix: absent'
ls -l /var/db/hostwatch/hosts.db
sDiagnosticsApiDir=/usr/local/opnsense/mvc/app/controllers/OPNsense/Diagnostics/Api
grep -n 'function reverseLookupAction' "$sDiagnosticsApiDir/DnsController.php"
```

Nalezená metoda potvrzuje její přítomnost v souborech. Při testu ve webovém rozhraní pak ověř, že je dostupná i pro použitý účet. HTTP 403 značí odmítnutý přístup. Při 404 zkontroluj verzi a přítomnost metody. Kontrola `os-postfix` říká, zda je balíček nainstalovaný. Návod počítá i s čistým testovacím OPNsense, kde už chybí.

## 2. Hostwatch, názvy DNS a provoz PF

| Test | Postup | Očekávaný výsledek a význam |
|---|---|---|
| H1 · Zdroj zařízení | Vyber známé testovací zařízení. Porovnej jeho IP, MAC a poslední záznam v nativním **Interfaces → Hostwatch** a v **Services → Device Monitor → Devices**. Počkej na nastavený interval načítání pluginu. | Údaje odpovídají po přepočtu na stejné časové pásmo. |
| H2 · Reverzní DNS | Vyber zařízení se známým PTR záznamem, pro které plugin nemá ruční název ani název z DHCP či Dnsmasq. Otevři oba přehledy. V panelu **Síť** vývojářských nástrojů můžeš vyhledat `reverse_lookup`. | Oba přehledy ukážou jméno z PTR. Ručně zadaný název v pluginu má přednost. |
| H3 · Provoz přes firewall | Zapni **Nedávný provoz přes firewall** a otevři **Zařízení**. Po načtení první hodnoty spusť z vlastního testovacího zařízení běžný provoz přes firewall. Nech ho běžet přes další obnovení tabulky. V panelu **Síť** zkontroluj pole `pf_packets` v odpovědi běžného požadavku na seznam zařízení. | Při růstu čítače stoupne součet. Nulový, nižší nebo nedostupný snímek součet zachová. Po 15 minutách bez přírůstku se počítadlo vynuluje. Při dostupných datech se zobrazí stav bez zaznamenaného provozu. Zavři stránku Zařízení a ponech testovací provoz běžet přes další dva intervaly. Po otevření stránky ověř, že součet vzrostl a odpočet v záhlaví se pohybuje. |
| H5 · Aktivita a mobilní tabulka | Zkontroluj řádek se starým časem Hostwatch a čerstvým přírůstkem PF. Otevři přehled i na úzké obrazovce. | Stav je zelený a uvádí firewall jako zdroj. Po vypršení platnosti obou zdrojů je červený. Tabulka se posouvá vodorovně uvnitř přehledu. |
| H4 · Tiché zařízení | Použij vlastní zařízení, u kterého má Hostwatch starší záznam. Jednou proveď **Ruční ping**. | Zapiš oba výsledky. Odpověď na ping a starší záznam Hostwatch se mohou objevit současně. Provoz uvnitř jedné VLAN může obejít firewall. Tyto případy nelze brát jako spolehlivé určení výpadku. |

Test H3 používá běžný provoz z jednoho zvoleného zařízení a test H4 jeden ruční ping.

## 3. Direct SMTP bez Postfixu

1. Na testovacím firewallu ověř, že `os-postfix` chybí. Pokud je na ostrém firewallu nainstalovaný, ponech ho tam. Průkazný test proveď na testovacím firewallu bez něj.
2. V **Device Monitor → Settings → Email** vyber **Direct SMTP**. Zadej testovacího příjemce, povoleného odesílatele a údaje svého SMTP serveru. Port a šifrování nastav podle svého poskytovatele. Zapni e-mailová upozornění a klikni na **Test Email**.
3. Ověř, že zpráva přišla do schránky. V `/var/log/devicemonitor.log` zkontroluj výsledek. Samotná akceptace zprávy SMTP serverem nedokládá doručení.
4. Pro provozní test připoj k testovací VLAN vlastní zařízení, které v Device Monitoru ještě není. Zapni sledování a povol danou VLAN pro e-mail. Po načtení Hostwatch ověř skutečné upozornění na nové zařízení. Databázi kvůli testu nemaž.
5. Při upgradu zkontroluj, že uložené **Direct SMTP** nebo **Local Sendmail / Postfix** zůstalo vybrané. Čistá instalace má vybrané **Direct SMTP** a e-mail je vypnutý do nastavení.
6. Pro ověření dávkování použij dvě nová zařízení zachycená v různých načteních Hostwatch. Nastav čekání a maximum delší než odstup načtení. Ověř, že obě zařízení dorazí v jednom e-mailu.
7. V režimu bez maxima ponech čekání 15 s. V simulaci přidávej nové nálezy po 12 s déle než 45 s. Ověř, že dávka se odešle až po poslední 15sekundové pauze.

Výsledek považuj za potvrzený i pro ostré upozornění až po doručení obou zpráv na firewallu bez `os-postfix`.

### Nápověda v nastavení

Nad kartami zapni **Zobrazit nápovědu k nastavení**. Přepni mezi kartami a obnov stránku. Popisky mají zůstat zobrazené. Změň metodu e-mailu nebo režim dávkování a ověř, že popisy skrytých polí zmizí spolu s poli.

## 4. Co ověří Monit

Na testovacím firewallu nastav testovací SMTP a příjemce v **Services → Monit → Settings**. Založ kontrolu pro vlastní pomocný soubor, například `/tmp/device-monitor-monit-probe`. Zvol typ **File**, podmínku `does not exist` a akci **Alert**. Nech soubor nejdřív existovat, počkej na jeden cyklus kontroly, poté ho odstraň a po doručení upozornění znovu vytvoř. Sleduj událost a případné oznámení o návratu podle nastavení alertu. Po testu odeber testovací kontrolu a soubor. Podrobnosti jsou v [návodu k Monit](https://docs.opnsense.org/manual/monit.html).

Tento výsledek dokládá, že Monit umí poslat zprávu na základě konkrétní podmínky. Samostatně ověřuje smysl použití Monitu jako doručovací cesty. Před rozhodnutím o integraci ještě potřebujeme zjistit, zda lze z Hostwatch předat událost **nové zařízení** včetně IP, MAC a VLAN. Pokud by k tomu byl nutný vlastní převodník nebo periodická kontrola, je to samostatný návrh k diskusi s maintainerem.

## Záznam výsledků pro #5964

Zapiš verzi OPNsense a Device Monitoru, výsledky H1–H5, doručení obou SMTP zpráv, stav `os-postfix` a výsledek Monitu. U každého testu použij **prošel / neprošel / nedostupné** a přidej stručný důvod. Pro veřejný komentář stačí anonymizované údaje a časy. Uživatelské účty, hesla a celé výpisy konfigurace tam nekopíruj.

### Bezpečnostní kontroly

Ověř, že účet s oprávněním pouze pro čtení otevře přehled a export, ale nemůže uložit nastavení, spustit ping ani smazat databázi. U správce ověř zachování tajných údajů při uložení prázdných polí. Na testovacím webhooku vyzkoušej platný a nedůvěryhodný certifikát. Ověř, že druhý případ skončí chybou. Exportuj testovací text se začátkem podobným vzorci a zkontroluj, že tabulkový procesor jej zobrazí jako text.

### Provozní limity

Zkontroluj pravidlo rotace příkazem `newsyslog -n -v /var/log/devicemonitor.log`. Na testovacím firewallu překryj plánované a ruční načtení Hostwatch a ověř, že se záznamy webhooků doručí. Při nedostupném testovacím webhooku zkontroluj opakování a doručení po obnovení cíle.

### Kontrola vstupů

Zkus uložit interval mimo rozsah, text místo portu SMTP a nesprávný typ hodnoty přes testovací API. Nastavení musí zůstat původní. V testovací kopii dat Hostwatch ověř, že novější neplatný řádek nezakryje starší platný řádek téže MAC.
