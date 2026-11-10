import os
import sys
import unittest
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.join(
    os.path.dirname(__file__), '..', 'src', 'opnsense', 'scripts',
    'OPNsense', 'DeviceMonitor'))

from config_hostnames import kea_reservation_names  # noqa: E402


def parse(xml):
    return ET.fromstring(xml)


class KeaReservationNames(unittest.TestCase):
    def test_hostname_is_used(self):
        root = parse("""<opnsense><OPNsense><Kea><dhcp4><reservations>
          <reservation uuid="1"><hw_address>AA:BB:CC:00:11:22</hw_address>
          <hostname>nas</hostname><description>Storage</description></reservation>
        </reservations></dhcp4></Kea></OPNsense></opnsense>""")
        self.assertEqual(kea_reservation_names(root), {'aa:bb:cc:00:11:22': 'nas'})

    def test_falls_back_to_description(self):
        root = parse("""<opnsense><OPNsense><Kea><dhcp4><reservations>
          <reservation><hw_address>aa:bb:cc:00:11:22</hw_address>
          <hostname></hostname><description>Printer</description></reservation>
        </reservations></dhcp4></Kea></OPNsense></opnsense>""")
        self.assertEqual(kea_reservation_names(root), {'aa:bb:cc:00:11:22': 'Printer'})

    def test_skips_entries_without_mac_or_name(self):
        root = parse("""<opnsense><OPNsense><Kea><dhcp4><reservations>
          <reservation><hostname>x</hostname></reservation>
          <reservation><hw_address>aa:bb:cc:00:11:22</hw_address></reservation>
        </reservations></dhcp4></Kea></OPNsense></opnsense>""")
        self.assertEqual(kea_reservation_names(root), {})

    def test_no_kea_section(self):
        self.assertEqual(kea_reservation_names(parse('<opnsense/>')), {})


if __name__ == '__main__':
    unittest.main()
