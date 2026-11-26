# Nastavení a použití

[Přehled projektu](../../README_CZ.md) · [English](../en/02_CONFIGURATION_AND_USAGE.md)

## Nastavení

Jdi na: **Services → DeviceMonitor → Settings**

Přepínač **Zobrazit nápovědu k nastavení** nad kartami zapíná popisky polí, očekávané hodnoty a vysvětlení tlačítek. Výchozí stav je vypnuto. Volba se projeví hned a prohlížeč si ji pamatuje pro danou adresu OPNsense. Tlačítko **Použít** uloží nastavení ze všech karet.

Při uložení plugin ověřuje typy voleb, rozsahy, SMTP server a seznam rozhraní. Chybnou změnu odmítne a dosavadní soubor nastavení zachová.

### Přístup ke správě a tajné údaje

V **System → Access → Users** nebo **Groups** nastav oprávnění **Services: Device Monitor (read only)** pro přehled a export, nebo **Services: Device Monitor (manage)** pro úpravy zařízení, nastavení, ruční ping, testy a ovládání služby. Po upgradu původní oprávnění poskytuje pouze přehled. Účet s úplným přístupem OPNsense má přístup ke správě.

Uložené SMTP heslo a URL webhooku se ve formuláři ani v odpovědi API nezobrazují. Prázdné pole uložený údaj zachová. Zadaná hodnota jej nahradí. Chceš-li údaj odstranit, použij příslušnou volbu pod polem. Pro odstranění URL nejdřív vypni webhook. Test webhooku může použít uloženou URL a aktuální formát.

Webhook přijímá pouze HTTP nebo HTTPS. HTTPS vyžaduje důvěryhodný certifikát a odpovídající název serveru. U vlastního ntfy nebo jiného interního cíle musí OPNsense důvěřovat jeho certifikační autoritě. HTTP neposkytuje šifrování. Přesměrování se nesledují, proto zadej přímo konečnou URL.

### Základní

| Nastavení | Popis |
|-----------|-------|
| Enable Device Monitor | Zapnout nebo vypnout automatické sledování přes Hostwatch |
| Interval načítání Hostwatch | Čas mezi načteními databáze Hostwatch (60–3600 sekund) |

### Nedávný provoz přes firewall

V **Nastavení → Ostatní nastavení** zaškrtni **Nedávný provoz přes firewall** a ulož změny. Volba je ve výchozím stavu vypnutá. Čítače paketů se načítají společně se seznamem zařízení. Účet potřebuje oprávnění k diagnostice Firewall Sessions. Pokud jsi zapnutý sloupec skryl, najdeš ho v nabídce **Sloupce**.

- **Co volba zachytí.** Služba Device Monitor čte čítače paketů PF přibližně každých 30 sekund i při zavřeném prohlížeči. Při zjištěném přírůstku se na 15 minut zeleně zobrazí **Zaznamenán provoz**. Po najetí myší uvidíš čas posledního přírůstku v místním čase prohlížeče. Po 15 minutách bez přírůstku se při dostupných datech zobrazí **Za posledních 15 minut nezaznamenán provoz**.
- **Čítače paketů.** Zobrazený počet sčítá zjištěné přírůstky a po 15 minutách bez přírůstku se vynuluje. Další přírůstek začne nový součet. První kladná hodnota slouží jako základ. Nulový, chybějící nebo shodný snímek zachová zobrazený součet. Nižší kladná hodnota změní základ a součet zachová také. Po 15 minutách bez kladného snímku se další kladná hodnota použije jako nový základ. Zavření nebo obnovení stránky součet zachová. Restart služby nebo vypnutí volby začne s novým počítáním. Odpočet v záhlaví ukazuje čas do dalšího společného 15minutového vyhodnocení služby. Přečte si stejný termín i po návratu na stránku. Po najetí myší se zobrazí čas posledního vyhodnocení a počet zařízení se zaznamenaným provozem. Každé zařízení má vlastní okno nečinnosti od posledního přírůstku.
- **Co může uniknout.** PF zachytí provoz, který uvidí ve své tabulce stavů. Provoz přepínaný přímo uvnitř jedné VLAN může firewall obejít a krátké spojení může mezi dvěma načteními zmizet. Konec jednoho spojení může zakrýt přírůstky v jiných spojeních téže IP. Device Monitor vynechá IP adresu sdílenou více zařízeními v seznamu. Počítadlo zahrnuje i pakety poslané na danou IP.
- **Tichá zařízení.** Plně funkční zařízení může zůstat připojené a déle než 15 minut nevyslat žádný paket. Pasivním sledováním v tu chvíli jeho dosažitelnost neověříš. Pokud odpovídá na ICMP, můžeš ho na vyžádání zkontrolovat přes **Ruční ping**. U zařízení s podporou telemetrie můžeš nastavit pravidelné hlášení ze samotného zařízení. Volba nezavádí automatický ping ani skenování. **Naposledy viděno** a upozornění vycházejí z Hostwatch.

### E-mailová upozornění

#### Dávkování e-mailů

V kartě **Email Notifications** nastav **Režim dávkování e-mailů** a **Čekání od posledního nálezu** (výchozí hodnota 15 s).

- **Čekat na pauzu, s maximem** je výchozí režim. Nálezy obnovují čekání, dokud neuplyne maximum od prvního nálezu (výchozí hodnota 45 s).
- **Čekat na pauzu, bez maxima** odešle dávku, jakmile po posledním nálezu uplyne celé nastavené čekání. Každý nový nález jej spouští znovu, takže nepřetržitý příliv nálezů může odeslání dál odkládat. Pro odeslání 45 s po posledním nálezu nastav čekání na 45 s.

Čekání může být 0–3600 s. Při 0 s se zařízení z jednoho načtení odešlou společně hned. V režimu s maximem musí být maximum od 1 do 3600 s a alespoň stejně dlouhé jako čekání. Čas běží od načtení nálezu do Device Monitoru. Pro sloučení nálezů z více načtení nastav čekání delší než interval načítání Hostwatch. V režimu s maximem musí přes interval dosáhnout i maximum. Testovací e-mail se posílá okamžitě. Webhook včetně ntfy má vlastní způsob odesílání.

- **Local Sendmail / Postfix** používá `/usr/local/sbin/sendmail` a vyžaduje funkční místní poštovní službu, například plugin `os-postfix`. Tuto volbu použij, pokud už na firewallu používáš místní poštovní službu.
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
| Notify for interfaces | Rozhraní pro e-mailová upozornění. Prázdný výběr zahrnuje všechna rozhraní. |
| Test Email | Uloží aktuální nastavení a odešle testovací zprávu zvoleným způsobem |

Nová instalace má vybranou metodu **Direct SMTP** a e-mailová upozornění jsou vypnutá, dokud je nenastavíš a nezapneš. Aktualizace zachová uložené nastavení včetně místního odesílání. Pro přechod vyplň údaje SMTP serveru a doručení ověř tlačítkem **Test Email**.

Čekající e-maily i webhooky se ukládají do samostatných front. Po neúspěšném odeslání služba pokus zopakuje přibližně za minutu. Jedna zpráva obsahuje nejvýše 100 zařízení, větší dávky se rozdělí. Formát ntfy dál vypíše nejvýše pět položek dané zprávy a uvede počet zbývajících.

### Webhook upozornění

| Nastavení | Popis |
|-----------|-------|
| Enable Webhook | Zapnout webhook upozornění |
| Typ webhooku | Automaticky, ntfy, Discord nebo obecný JSON |
| Webhook URL | Cílová URL. U ntfy je součástí URL i název tématu. |
| Notify for interfaces | Rozhraní pro webhook. Prázdný výběr zahrnuje všechna rozhraní. |
| Test Webhook | Vyzkouší URL a formát právě zadané ve formuláři |

#### ntfy na Androidu

V poli **Typ webhooku** vyber **ntfy** a zadej celou URL tématu, například `https://push.example.com/moje-tema`. V **aplikaci ntfy pro Android** se přihlas k odběru stejného tématu na stejném serveru. Ulož nastavení tlačítkem **Apply** a tlačítkem **Send Test** ověř doručení. Pro ostrá upozornění zapni **Enable Webhook**. Pokud používáš filtr VLAN, musí zahrnovat VLAN daného zařízení.

Device Monitor odesílá HTTP `POST` na URL tématu. Tělo zprávy je prostý text v UTF-8. Titulek, štítky a prioritu posílá v samostatných HTTP hlavičkách, aby aplikace pro Android zobrazila titulek zvlášť a zachovala odřádkování i seznam v textu.

| Zpráva | Co Device Monitor odesílá |
|--------|---------------------------|
| Test | Titulek `🧪 OPNsense Test`, text `Device Monitor webhook is working! ✅`, štítky `test,opnsense`, priorita 3 |
| Nová zařízení | Titulek `🔔 OPNsense: N new device(s)`, celkový počet a nejvýše pět položek s MAC adresou, výrobcem a IP adresou. Při více než pěti zařízeních zpráva uvede i počet zbývajících. Štítky jsou `opnsense,network`, priorita 3 pro nejvýše tři zařízení a 4 pro čtyři a více. |

Pokud aplikace zobrazí JSON s položkou `"event":"test"` nebo `"event":"new_devices"`, ověř, že je **Typ webhooku** nastavený na **ntfy**. Volba **Automaticky** dál vybírá formát podle URL a u vlastní domény může zvolit **obecný JSON**.

Správné zobrazení formátovaných zpráv potvrdil správce projektu v **aplikaci ntfy pro Android**. Verzi aplikace při ověření nezaznamenal. Samostatný test s lokálním HTTP přijímačem ověřil u testovací i provozní zprávy textové tělo a hlavičky ntfy.

- **ntfy.sh** — `https://ntfy.sh/tvojeSecretTema`
- **Discord** — `https://discord.com/api/webhooks/...`
- **Generic** — jakýkoliv HTTP POST endpoint přijímající JSON

## Použití

### Widget na Lobby dashboardu

Po instalaci přidej widget **Device Monitor** na Lobby dashboard. Zobrazuje:
- Stav daemona (Running / Stopped)
- Celkový počet zařízení
- Počet zařízení, která Hostwatch zaznamenal za posledních 15 minut

### Seznam zařízení

**Services → DeviceMonitor → Devices**

V tabulce najdeš **Aktivita zařízení**, **Naposledy viděno**, **Ruční ping** a volitelně **Nedávný provoz přes firewall**.

Názvy zařízení mají toto pořadí přednosti: ručně zadaný název v Device Monitoru, Dnsmasq Host Overrides, rezervace Kea DHCPv4 a statická přiřazení ISC DHCP. V rezervaci Kea má název přednost před popisem. Rezervace se vyhledává podle MAC adresy.

Pokud žádný z těchto zdrojů název nedodá, stránka **Zařízení** dohledá záznam PTR podle IP přes rozhraní OPNsense pro reverzní DNS. Stejné rozhraní používá stránka Hostwatch od OPNsense 26.7.9. Dotaz vyřizuje firewall, takže jeho resolver musí mít přístup k příslušné reverzní DNS zóně. Výsledek se ukáže v tabulce i v exportu CSV. Drží se po dobu otevření stránky a neukládá se jako ruční název. Po změně DNS obnov celou stránku. Pokud rozhraní není dostupné nebo název nenajde, údaj zůstane prázdný.

**Aktivita zařízení** je zelená, pokud za posledních 15 minut zaznamenal zařízení Hostwatch nebo přibyly pakety v čítači firewallu. Pod stavem jsou uvedeny zdroje, které aktivitu zaznamenaly. Při vypnutém nebo nedostupném sběru se stav vyhodnotí z dostupných údajů. Když žádný zdroj neukazuje nedávnou aktivitu, stav je červený. Stejný stav používají filtr, souhrn nad tabulkou i export CSV. Na mobilu posuň širokou tabulku vodorovně uvnitř přehledu. **Naposledy viděno** ukazuje čas z Hostwatch. Tlačítko **Spustit ruční ping** ověří aktuální IP na vyžádání. Výsledek a čas jsou ve sloupci **Ruční ping** a zůstávají viditelné při průběžném obnovování tabulky, dokud je stránka otevřená.

### Známá zařízení a viditelné sloupce

Klikni na hvězdičku ve sloupci **Známé zařízení**, pokud zařízení poznáváš. Dalším kliknutím označení zrušíš. Značka je uložená v databázi podle MAC adresy, takže ji uvidíš i v jiném prohlížeči. Smazáním zařízení ze seznamu se smaže i jeho označení. Přehled můžeš omezit filtrem **Všechna zařízení / Známá zařízení / Neoznačená zařízení** a kombinovat ho s filtrem VLAN nebo aktivity zařízení. Označení platí bez ohledu na způsob přidělení IP adresy.

V nabídce **Sloupce** vyber, které údaje chceš vidět. Výběr se uloží v aktuálním prohlížeči pro danou adresu OPNsense a zůstane i po obnovení stránky. Tlačítko **Zobrazit všechny sloupce** obnoví plný přehled. CSV má dosavadní sloupce a používá stejné filtry zařízení jako tabulka.

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
