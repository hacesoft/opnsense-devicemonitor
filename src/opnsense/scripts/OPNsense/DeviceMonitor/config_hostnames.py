"""Načítání názvů zařízení z konfiguračního stromu OPNsense.

Předpony: d = slovník, o = objekt XML, s = řetězec.
2.3.7 – kontrola typových předpon při sjednocení pluginu.
Historie: 2.3.1 – podpora rezervací Kea DHCPv4 (autor ptrsmk, PR #11).
"""


def _text(o_element, s_tag):
    """Vstup: XML prvek a název potomka. Výstup: text nebo None."""
    o_child = o_element.find(s_tag)
    if o_child is not None and o_child.text and o_child.text.strip():
        return o_child.text.strip()
    return None


def kea_reservation_names(o_root):
    """Vstup: kořen config.xml. Výstup: mapa MAC adres na názvy rezervací Kea."""
    d_names = {}
    for o_reservation in o_root.findall('./OPNsense/Kea/dhcp4/reservations/reservation'):
        s_mac = _text(o_reservation, 'hw_address')
        if not s_mac:
            continue
        s_name = _text(o_reservation, 'hostname') or _text(o_reservation, 'description')
        if s_name:
            d_names[s_mac.lower()] = s_name
    return d_names


def merge_names(d_isc, d_kea, d_dnsmasq):
    """Vstup: mapy ISC, Kea a Dnsmasq. Výstup: sloučená mapa v pořadí přednosti Dnsmasq, Kea, ISC."""
    d_merged = dict(d_isc)
    d_merged.update(d_kea)
    d_merged.update(d_dnsmasq)
    return d_merged
