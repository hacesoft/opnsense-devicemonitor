"""Pure helpers for reading device names out of an OPNsense config.xml tree.

No module-level side effects, so they can be unit tested without a router.
"""


def _text(el, tag):
    child = el.find(tag)
    if child is not None and child.text and child.text.strip():
        return child.text.strip()
    return None


def kea_reservation_names(root):
    """Map lowercase MAC -> hostname (fallback: description) from Kea DHCPv4
    reservations (OPNsense/Kea/dhcp4/reservations/reservation)."""
    names = {}
    for res in root.findall('./OPNsense/Kea/dhcp4/reservations/reservation'):
        mac = _text(res, 'hw_address')
        if not mac:
            continue
        name = _text(res, 'hostname') or _text(res, 'description')
        if name:
            names[mac.lower()] = name
    return names
