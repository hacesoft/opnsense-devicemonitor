# Řešení problémů

[Přehled projektu](../../README_CZ.md) · [English](../en/03_TROUBLESHOOTING.md)

| Problém | Co zkontrolovat |
|---------|-----------------|
| Plugin chybí v nabídce **Services** | Ověř výsledek instalace a obnov stránku. Jestli plugin vidí správce, ale jiný uživatel ne, ověř [oprávnění účtu](04_TECHNICKA_DOKUMENTACE.md). |
| Seznam zařízení je prázdný | Ověř, že služba `devicemonitor` běží, že je zapnuté sledování a že má **Interfaces → Hostwatch** vlastní záznamy. V seznamu pluginu odstraň aktivní filtry a zkus ruční načtení tlačítkem s lupou. |
| Aktivita z firewallu je nedostupná | Ověř zapnutí volby **Nedávný provoz přes firewall**, stav služby a oprávnění k diagnostice **Firewall Sessions**. Provoz uvnitř stejné VLAN může firewall obejít. |
| Ruční ping odpovídá, řádek je červený | Přehled aktivity závisí na časově omezených pozorováních Hostwatch a volitelně firewallu. Ruční ping je jednorázová kontrola odpovědi. |
| E-mail nepřichází | Ověř povolení e-mailu, filtr rozhraní, časy dávkování a nastavení poštovního serveru. Pomocí **Test Email** ověř doručení do schránky. |
| Webhook se nedoručí | Zkontroluj konečnou URL, formát, filtr rozhraní a certifikát HTTPS. Pomocí **Send Test** ověř odpověď cíle. Pokud ntfy zobrazuje surový JSON, nastav formát **ntfy**. |

Stav služby zkontroluješ v **System → Diagnostics → Services**. Z příkazové řádky lze jako root zobrazit stav a poslední řádky provozního logu:

```sh
configctl devicemonitor status
tail -n 50 /var/log/devicemonitor.log
```

Pokud log hlásí neplatný soubor nastavení, použij poslední funkční zálohu nebo ulož opravené nastavení ve webovém rozhraní. Při problému s databází nejdřív zachovej kopii adresáře `/var/db/devicemonitor`, aby zůstaly dostupné údaje o zařízeních, nastavení i čekající upozornění.

Při [hlášení problému](https://github.com/hacesoft/opnsense-devicemonitor/issues) přidej verze pluginu a OPNsense, popis projevu a relevantní anonymizované řádky z logu. Hesla, adresy webhooků a celý soubor konfigurace patří do soukromé správy.
