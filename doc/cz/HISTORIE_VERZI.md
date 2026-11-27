# Historie verzí

[Přehled projektu](../../README_CZ.md) · [English](../en/CHANGELOG.md)

## v2.4.17

- Widget na nástěnce počítá nedávnou aktivitu z Hostwatch i z čítačů firewallu, pokud jsou zapnuté a účet má příslušné oprávnění.

## v2.4.16

- Validace záznamů Hostwatch, požadavků API a uložené konfigurace před použitím.
- Zpřehledněný uživatelský návod a informace pro správce.

## v2.4.15

- Omezená spotřeba paměti při čtení PF a odesílání upozornění, oddělené fronty e-mailu a webhooku a rotace provozního logu.

## v2.4.14

- Oddělení přehledu od správy, ochrana uloženého SMTP hesla a URL webhooku, kontrola TLS webhooků, ochrana exportu CSV a kontrola metod API.

## v2.4.13

- Přepínač nápovědy ke všem nastavením s popisy polí a očekávaných hodnot. Volba se pamatuje v prohlížeči.

## v2.4.12

- Volitelný režim dávkování e-mailů, který čeká pouze na pauzu po posledním nálezu.

## v2.4.11

- Seskupení nových nálezů do souhrnných e-mailů s nastavitelným čekáním 15 s a výchozím maximem 45 s.

## v2.4.10

- Široká tabulka se na mobilu posouvá uvnitř přehledu. Stav aktivity používá Hostwatch i čítače firewallu a uvádí zdroj.

## v2.4.9

- Odpočet v záhlaví sleduje pevné 15minutové vyhodnocení služby. Po návratu na stránku pokračuje podle času serveru.

## v2.4.8

- Služba čte čítače PF i při zavřeném prohlížeči. Záhlaví ukazuje odpočet k nejbližšímu vypršení aktivity zobrazených zařízení.

## v2.4.7

- Průběžný součet paketů se zachová při nulovém nebo nedostupném snímku i při poklesu čítače PF. Po 15 minutách bez přírůstku se počítadlo vynuluje.

## v2.4.6

- Čítače paketů PF se načítají se seznamem zařízení jednou akcí configd s mezipamětí. Odebrány oba samostatné požadavky na diagnostická rozhraní a čítač bajtů.

## v2.4.5

- Přehled rozlišuje nezměněné, nižší a nedostupné čítače PF a po najetí myší ukáže naměřené hodnoty.

## v2.4.4

- Přednost pro PF Sessions s čítači paketů a zpracování nedostupné diagnostiky přímo v přehledu bez chybového dialogu OPNsense.

## v2.4.3

- Zobrazení změn čítačů bajtů a dostupných čítačů paketů mezi snímky PF.

## v2.4.2

- Nedávný provoz přes firewall funguje i přes starší diagnostické rozhraní PF, například na OPNsense 26.7.10.

## v2.4.1

- Pro nové instalace je výchozí vestavěné Direct SMTP. Aktualizace zachovává uložené nastavení pošty.

## v2.4.0

- Přidáno trvalé označení známých zařízení a filtr podle označení (#4).
- Přidán výběr viditelných sloupců s uložením v prohlížeči.

## v2.3.9

- Doplněn formát zpráv ntfy, ověření v aplikaci pro Android a postup při zobrazení surového JSON.

## v2.3.8

- Obnoveno dohledávání názvů zařízení přes reverzní DNS pomocí rozhraní OPNsense ([#9](https://github.com/hacesoft/opnsense-devicemonitor/issues/9)).

## v2.3.7

- Sjednocena maďarská notace proměnných v celém pluginu včetně webového rozhraní, daemona, upozornění a instalačních skriptů.

## v2.3.6

- Přidán volitelný sloupec **Nedávný provoz přes firewall**, který využívá statistiky PF v OPNsense.
- Český a anglický návod popisují zapnutí volby, požadavky na verzi OPNsense a omezení pasivního sledování.

## v2.3.5

- Údaje Last Seen a ruční ping používají stejný formát a místní časové pásmo prohlížeče. Last Seen se řadí chronologicky a v exportu CSV je také v místním čase.

## v2.3.4

- Text stavu Hostwatch je zelený u zařízení zaznamenaných za posledních 15 minut a červený u ostatních.

## v2.3.3

- Formát webhooku lze zvolit nezávisle na URL. Podporován je i ntfy na vlastní doméně (#8).
- Stav podle Hostwatch se zobrazuje odděleně od výsledku ručního pingu s časem kontroly. Ruční ping automatický stav nemění (#10).

## v2.3.2

- Zprávy instalátoru a odinstalátoru jsou v angličtině.
- Instalátor při aktualizaci správně najde přiložený odinstalátor. Pokud odinstalátor vrátí chybu, aktualizace se zastaví.

## v2.3.1

- Opravený přímý odkaz na dříve zveřejněný instalační ZIP v dokumentaci (#6).
- Instalace překladových katalogů do standardních adresářů OPNsense a lokalizace validačních hlášek nastavení (#5, #7).
- Načítání názvů a popisů z rezervací Kea DHCPv4 na základě příspěvku od ptrsmk (PR #11).
- Zobrazení názvů zařízení prostým textem v tabulce.

## v2.3

- Přidáno přímé SMTP, volba způsobu odesílání a zkušební e-mail podle zvolené metody.
- Zpřesněno filtrování upozornění podle VLAN a zpracování nových a ručně smazaných zařízení.

## v2.1

- Doplněny názvy zařízení z Dnsmasq Host Overrides a upravena přednost zdrojů názvů.

## v2.0

- Přidána integrace služby do OPNsense 26.x a přepracováno ovládání služby, instalace a widget.

## v1.x

- Opravy kompatibility s OPNsense 26.x.
