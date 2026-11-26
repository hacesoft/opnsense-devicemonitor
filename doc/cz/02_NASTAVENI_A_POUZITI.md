# Nastavení a použití

[Přehled projektu](../../README_CZ.md) · [English](../en/02_CONFIGURATION_AND_USAGE.md)

## První spuštění

1. Otevři **Services → Device Monitor → Settings**.
2. V kartě **Ostatní nastavení (Other Settings)** zapni **Zapnout monitoring (Enable Monitoring)**. Plugin pak pravidelně čte databázi Hostwatch. Výchozí interval je **300 sekund**, povolený rozsah je **60–3600 sekund**.
3. Podle potřeby nastav e-mail nebo webhook. Upozornění jsou po čisté instalaci vypnutá.
4. Klikni na **Použít (Apply)** a otevři **Device Monitor → Devices**. Pokud potřebuješ stáhnout nové údaje z Hostwatch hned, použij tlačítko s lupou v seznamu zařízení.

Přepínač **Zobrazit nápovědu k nastavení** nad kartami vysvětlí jednotlivá pole. Prohlížeč si volbu pamatuje. Tlačítko **Použít** ukládá nastavení ze všech karet.

## Přehled zařízení

| Údaj | Co znamená |
|-------|------------|
| **Aktivita zařízení** | Zelená znamená, že za posledních 15 minut zařízení zaznamenal Hostwatch nebo přibyly pakety v čítači firewallu. Pod stavem vidíš zdroj. Červená znamená, že žádný dostupný zdroj neukazuje nedávnou aktivitu. Tiché zařízení může být stále připojené. |
| **Poslední výskyt** | Čas posledního pozorování z Hostwatch v místním čase prohlížeče. U řádku se zelenou aktivitou z firewallu může zůstat starší. |
| **Ruční ping** | Jednorázově ověří odpověď na ICMP. Výsledek zůstane viditelný, dokud je stránka otevřená. |
| **Známé zařízení** | Hvězdička uložená pro danou MAC. Použij ji k označení vlastních zařízení. MAC adresa sama nepotvrzuje identitu zařízení. |

Podle VLAN, aktivity a označení známých zařízení můžeš seznam filtrovat. **Sloupce** nastavují viditelné údaje pro aktuální prohlížeč. Export CSV používá aktuální filtry a vlastní sadu sloupců. Na mobilu můžeš posouvat širokou tabulku vodorovně.

Název zařízení můžeš upravit přímo v seznamu. Ruční název má přednost před údaji Dnsmasq, Kea DHCPv4 a ISC DHCP. Když název chybí, plugin se pokusí použít reverzní DNS.

Widget **Device Monitor** v OPNsense Lobby ukazuje stav služby, celkový počet zařízení a počet zařízení zaznamenaných v Hostwatch za posledních 15 minut.

### Nedávný provoz přes firewall

Volbu najdeš v **Ostatní nastavení**. Ve výchozím stavu je vypnutá. Služba při zapnutí přibližně každých 30 sekund pasivně čte existující čítače firewallu. Účet potřebuje oprávnění k diagnostice **Firewall Sessions**.

Čítač se sčítá i po zavření prohlížeče. Po 15 minutách bez přírůstku se součet daného zařízení vynuluje. Odpočet nad tabulkou ukazuje čas do společného vyhodnocení služby. Vlastní patnáctiminutové okno každého zařízení běží od jeho posledního přírůstku.

Provoz přepínaný uvnitř stejné VLAN může firewall obejít. Zařízení, které nevysílá žádný provoz, může přesto fungovat a odpovídat na ruční ping. Čítače firewallu zahrnují i pakety poslané na danou IP adresu.

## E-mailová upozornění

V kartě **Email notifikace (Email Notifications)** zapni e-mail a vyplň adresu příjemce a povolenou adresu odesílatele. Zvol způsob doručení:

- **Direct SMTP** se připojí k tvému poštovnímu serveru. Zadej server, port a šifrování podle poskytovatele. Přihlašovací údaje vyplň, pokud je server vyžaduje.
- **Local Sendmail / Postfix** využije místní poštovní službu nakonfigurovanou v OPNsense.

**Test Email** uloží aktuální nastavení a ihned odešle testovací zprávu. Uložené heslo zůstává skryté. Prázdné pole ho zachová, nové ho přepíše a zaškrtávací volba pod polem ho odstraní.

### Souhrnné e-maily

| Režim | Kdy se odešle zpráva |
|-------|----------------------|
| **Čekat na pauzu, s maximem** (výchozí) | Každý nový nález obnoví čekání. Výchozí čekání je **15 s**, nejdelší prodleva od prvního nálezu **45 s**. |
| **Čekat na pauzu, bez maxima** | Zpráva odejde po nastavené pauze od posledního nálezu. Při nepřetržité sérii nálezů se odeslání může dál odkládat. |

Čekání **0 s** pošle skupinu z jednoho načtení ihned. Časy se počítají od chvíle, kdy Device Monitor načte nález z Hostwatch. Pro spojení dvou načtení vzdálených 300 s nastav například čekání 310 s a v režimu s maximem limit 650 s.

## Webhooky a ntfy

V kartě **Webhook notifikace (Webhook Notifications)** zapni webhook a zadej cílovou URL. Vyber **ntfy**, **Discord**, **Obecný JSON** nebo **Automaticky**. Pro ntfy na vlastním serveru nastav typ **ntfy** výslovně.

V aplikaci **ntfy pro Android** se přihlas k tématu uvedenému v URL, například `https://push.example.com/moje-tema`. **Odeslat test (Send Test)** použije aktuální formát a zadanou nebo uloženou URL. Nastavení ulož tlačítkem **Použít**.

Zadej konečnou URL. Webhook nepřechází na přesměrovanou adresu. U HTTPS musí OPNsense důvěřovat certifikátu serveru. Uložená URL se spravuje stejně jako SMTP heslo. Před jejím odstraněním vypni webhook.

### Rozhraní a doručování

E-mail i webhook mají vlastní filtr **Notifikovat pro rozhraní (Notify for interfaces)**. Prázdný výběr zahrnuje všechna rozhraní. Každá zpráva pokrývá nejvýše **100 zařízení**. Větší skupina se rozdělí. ntfy vypíše prvních pět položek zprávy a počet zbývajících.

Čekající upozornění přežijí restart služby. Po chybě se je služba pokusí doručit znovu přibližně za minutu. Vypnutí příslušného kanálu vyprázdní jeho čekající frontu.

## Oprávnění a pomoc

Pro delegování přístupu použij [přehled oprávnění pro správce](04_TECHNICKA_DOKUMENTACE.md). Pokud se seznam neplní nebo zprávy nepřicházejí, pokračuj [řešením problémů](03_RESENI_PROBLEMU.md).
