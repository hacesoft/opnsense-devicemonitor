# Historie verzí

[Přehled projektu](../../README_CZ.md) · [English](../en/CHANGELOG.md)

## v2.4.16

- Validace záznamů Hostwatch, požadavků API a uložené konfigurace před použitím.

## v2.4.15

- Omezit paměť při čtení PF a odesílání upozornění, oddělit trvalé fronty e-mailu a webhooku a instalovat rotaci provozního logu.

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
- Doplněny integrační testy pro Hostwatch, PF, Direct SMTP a Monit.

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

- Přidán volitelný sloupec **Nedávný provoz přes firewall**, který využívá statistiky PF z OPNsense PR #11180.
- Český a anglický návod popisují zapnutí volby, požadavky na verzi OPNsense a omezení pasivního sledování.

## v2.3.5

- Údaje Last Seen a ruční ping používají stejný formát a místní časové pásmo prohlížeče. Last Seen se řadí chronologicky a v exportu CSV je také v místním čase.

## v2.3.4

- Text stavu Hostwatch je zelený u zařízení zaznamenaných za posledních 15 minut a červený u ostatních.

## v2.3.3

- Formát webhooku lze zvolit nezávisle na URL. Podporován je i ntfy na vlastní doméně (#8).
- Stav podle Hostwatch se zobrazuje odděleně od výsledku ručního pingu s časem kontroly. Ruční ping automatický stav nemění (#10).

## v2.3.2

- Instalace i odinstalace vypisují hlášky anglicky. Komentáře ve zdrojích jsou česky a nadpisy sekcí jsou dvojjazyčné.
- Instalátor při aktualizaci správně najde přiložený odinstalátor. Pokud odinstalátor vrátí chybu, aktualizace se zastaví.

## v2.3.1

- Opravený přímý odkaz na dříve zveřejněný instalační ZIP v dokumentaci (#6).
- Instalace překladových katalogů do standardních adresářů OPNsense a lokalizace validačních hlášek nastavení (#5, #7).
- Načítání názvů a popisů z rezervací Kea DHCPv4 na základě příspěvku od ptrsmk (PR #11).
- Zobrazení názvů zařízení prostým textem v tabulce.

## v2.3 (srpen 2026) — Přímé SMTP a vylepšení upozornění

- Do nastavení Device Monitoru přibyla volba **způsobu odesílání e-mailu**.
- **Local Sendmail / Postfix** zůstává výchozí metodou a zachovává chování stávajících instalací.
- Přidáno vestavěné **Direct SMTP** pomocí standardní Python knihovny `smtplib`; není potřeba instalovat další Python balíček.
- Direct SMTP podporuje **STARTTLS**, **SSL/TLS** i nešifrované SMTP.
- Do UI přibylo nastavení SMTP serveru, portu, uživatelského jména a hesla.
- **Test Email** nyní používá právě zvolený způsob odesílání.
- Existující konfigurace se při aktualizaci automaticky doplní o nové výchozí položky, takže není nutný reset konfigurace.
- SMTP heslo se nepředává na příkazové řádce procesu, ale načítá se z chráněné konfigurace Device Monitoru.
- Konfigurační soubor obsahující SMTP údaje se ukládá s omezenými přístupovými právy.
- Součástí jsou i opravy z v2.2: výběr nejnovějšího Hostwatch záznamu pro každou MAC, zabránění návratu ručně smazaných zařízení z historických záznamů, oprava filtrování VLAN upozornění a zachování skutečného Hostwatch `last_seen` při rychlé aktualizaci stavu.

## v2.1 (duben 2026) — Podpora Dnsmasq hostname

1. Načítání hostname z Dnsmasq — `get_dnsmasq_descriptions()`
Uživatelé OPNsense, kteří migrovali ze zastaralého ISC DHCPv4 na Dnsmasq DNS & DHCP (doporučená náhrada od OPNsense 25.7+), měli v Device Monitoru prázdné hostname. Předchozí kód četl hostname pouze z `config.xml → dhcpd` (statická mapování ISC DHCP).
Nová funkce čte hostname z části config.xml určené pro Dnsmasq Host Overrides. Správná XML struktura Dnsmasq záznamu vypadá takto:
```xml
<hosts uuid="...">
  <host>MojeZarizeni</host>              ← pole hostname
  <hwaddr>aa:bb:cc:dd:ee:ff</hwaddr>     ← MAC adresa (pozor: hwaddr, NE hw)
  <ip>192.168.1.100</ip>
  <descr>Popis zařízení</descr>
</hosts>
```
> ⚠️ Pole MAC adresy se jmenuje `<hwaddr>` — nikoliv `<hw>` jak by se dalo očekávat. Potvrzeno přímou inspekcí živého `config.xml`.
2. Vypnuté ISC DHCP interfacy jsou přeskočeny
Pokud je ISC DHCP interface vypnutý (checkbox odškrtnutý v UI), OPNsense nenastaví žádný element `<enable>` uvnitř konfiguračního bloku daného interface. Aktualizovaná funkce `get_dhcp_descriptions()` přeskočí každý ISC interface, kterému chybí tag `<enable>`, a zabrání tak tomu, aby se zastaralá data z vypnutých interfaců zobrazovala jako hostname.
3. Priorita zdrojů hostname
Překlad hostname nyní sleduje jasný prioritní řetězec:
```
1. custom_hostname  (nastaveno ručně v UI Device Monitoru — nejvyšší priorita)
2. Dnsmasq          (Host Overrides s vazbou MAC → hostname)
3. ISC DHCP         (statická mapování, preferováno pole hostname před descr)
```
Dnsmasq přepíše ISC data pro stejnou MAC adresu pomocí `dict.update()`:
```python
dhcp_descriptions = get_dhcp_descriptions()        # ISC DHCP (jen zapnuté interfacy)
dnsmasq_descriptions = get_dnsmasq_descriptions()  # Dnsmasq Host Overrides
dhcp_descriptions.update(dnsmasq_descriptions)     # Dnsmasq vyhraje při konfliktu
```
4. Preference pole hostname v ISC DHCP
Dříve čtenář ISC DHCP používal pouze `<descr>` (pole poznámky/popisu). Nyní preferuje `<hostname>` a na `<descr>` se vrací pouze tehdy, když `<hostname>` chybí nebo je prázdné. To odpovídá tomu, jak se hostname skutečně zobrazují v DNS a tabulkách DHCP lease.


## v2.0 (duben 2026) — Kompletní přepracování

Tato verze je kompletní má těsnějsi integraci s OPNsense 26.x. Mnoho komponent, které byly dříve vytvořeny na míru, je nyní nahrazeno nativními mechanismy OPNsense.

### Co se změnilo a proč

**1. Registrace služby — `plugins.inc.d/devicemonitor.inc`**

V předchozích verzích byl daemon pro OPNsense zcela neviditelný. Neobjevoval se v *System → Diagnostics → Services*, takže nebylo možné ho spustit/zastavit/restartovat z GUI.

Opravou je nový soubor `src/etc/inc/plugins.inc.d/devicemonitor.inc`, který registruje službu pomocí nativního mechanismu OPNsense `plugins_services()`.

```php
function devicemonitor_services()
{
    $services = [];
    $services[] = [
        'description' => gettext('Device Monitor - network device tracking'),
        'configd' => [
            'restart' => ['devicemonitor restart'],
            'start'   => ['devicemonitor start'],
            'stop'    => ['devicemonitor stop'],
        ],
        'name'    => 'devicemonitor',
        'pidfile' => '/var/run/devicemonitor.pid',
    ];
    return $services;
}
```

**2. Kontrola stavu daemona — `daemon_status.sh`**

Předchozí přístup používal `service devicemonitor status` v configd akci `[status]`. Na FreeBSD tento příkaz vrací exit kód 1 i tehdy, když služba normálně běží (vrací 1 = "není spravováno rc.d tradičním způsobem"). Protože configd typ `script_output` považuje jakýkoliv nenulový exit za chybu, každá kontrola stavu skončila `Execute error`.

Opravou je dedikovaný shell skript, který přímo kontroluje pidfile:

```sh
#!/bin/sh
PIDFILE="/var/run/devicemonitor.pid"
if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "running"
        exit 0
    fi
    rm -f "$PIDFILE"   # vyčistí stale pidfile
fi
echo "stopped"
exit 0
```

**3. `actions_devicemonitor.conf` — `|| true` u start/stop/restart**

Bez `|| true`, pokud daemon již běžel a configd se pokusil ho znovu spustit, `service devicemonitor start` vrátil nenulový exit kód (daemon already running), který configd interpretoval jako chybu a zobrazil `Error (1)`. Přidání `|| true` zajistí, že configd vždy vidí úspěch.

Akce `[status]` nyní volá `daemon_status.sh` místo `service devicemonitor status`.

**4. `rc.d/devicemonitor` — přidán `procname`, opravena výchozí hodnota**

Dvě opravy:
- Výchozí hodnota změněna z `"YES"` na `"NO"` — FreeBSD konvence: skript sám musí být výchozí disabled; aktivaci řídí `/etc/rc.conf.d/devicemonitor`
- Přidán `procname="/usr/local/bin/python3"` — bez tohoto `rc.d` nemůže najít běžící proces, a každý `start` vytvořil nový zombie proces.

**5. `service.xml` — oprava názvu tagu, přidán `<pidfile>`, opraveny `<commands>`**

Tři chyby v jednom souboru:
- `<n>DeviceMonitor</n>` → `<name>DeviceMonitor</name>` — OPNsense tag `<n>` nerozpoznal
- Přidán `<pidfile>/var/run/devicemonitor.pid</pidfile>` — nutný pro zobrazení zelené/červené tečky stavu
- `<commands>` změněno ze shell příkazů (`service devicemonitor start`) na názvy configd akcí (`devicemonitor start`)

**6. `ServiceController.php` — start/stop/restart přes `configdRun()`**

Dříve PHP API controller volal `exec('service devicemonitor start')` přímo. Tím obchází privilege model OPNsense. Veškeré řízení služby nyní prochází přes `$backend->configdRun('devicemonitor start')`.

**7. Dashboard widget — oprava odpojeného DOM elementu**

Metoda `onWidgetTick()` widgetu aktualizovala `this.$container.find('.dm-total')`. Widget framework OPNsense však kopíruje markup do DOMu místo vložení původního jQuery objektu, takže `this.$container` ukazoval na odpojený element — `.find()` fungovalo tiše, ale změny nebyly na obrazovce nikdy vidět.

Opraveno přidáním unikátního `id` každému elementu a výběrem přímo z dokumentu:

```javascript
// Dříve (rozbité — aktualizuje odpojený element)
this.$container.find('.dm-total').text(stats.total);

// Po opravě (správně — vybírá z živého DOM)
$('#dm-total').text(stats.total);
```

Také opraveno: widget volal `/api/devicemonitor/service/status` pro počty zařízení (který vrací stav daemona, nikoliv statistiky). Nyní správně volá `/api/devicemonitor/devices/stats`.

**8. `install.sh` — kompletní přepis**

Klíčové změny:
- Čištění zombie procesů před spuštěním daemona (`pkill -f monitor_daemon.py`)
- Daemon spouštěn přes `configctl devicemonitor start` místo `service devicemonitor start`
- Daemon ověřen přes pidfile + `kill -0` místo `service devicemonitor status`
- Odstraněno rozbité `service php-fpm restart` a `configctl webgui restart`
- Přidán krok instalace `plugins.inc.d/devicemonitor.inc`
- Opraveno číslování kroků (bylo `[6/11]` následováno `[6/10]`)

**9. `uninstall.sh` — opraveno zastavení daemona**

Dříve používal `service devicemonitor status`, který vrátil exit 1, čímž zastavení selhalo. Nyní používá `pkill -f monitor_daemon.py`, které vždy funguje bez ohledu na stav pidfile.

Také odstraněno rozbité `configctl webgui restart` a `service php-fpm restart` — tyto příkazy buď nejsou dostupné nebo jsou zbytečné na OPNsense 26.x.

---

## v1.x (leden 2026)

- **Oprava kompatibility s OPNsense 26.x:** Odstraněna volání `$this->sessionClose()` z controllerů. Tato funkce byla odstraněna v OPNsense 26.0 a způsobovala crash při zavolání. Přidána automatická detekce verze pro zachování zpětné kompatibility s 25.x.
