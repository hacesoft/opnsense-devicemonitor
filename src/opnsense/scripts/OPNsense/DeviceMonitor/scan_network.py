#!/usr/local/bin/python3

# Předpony: b = příznak, d = slovník, i = celé číslo, l = seznam, o = objekt, s = řetězec, set = množina, t = n-tice, x = proměnlivý typ.
# U konstant jsou tytéž předpony uvedené velkým písmenem.
# Historie: 2.4.16 – kontrola vstupních záznamů Hostwatch.
# 2.4.15 – samostatná trvalá fronta webhooků a postupné čtení Hostwatch.
# 2.4.11 – zařazení nových zařízení do trvalé e-mailové fronty.
# 2.3.7 – sjednocení typových předpon proměnných.

# Historie: 2.3.1 – načtení názvů z rezervací Kea DHCPv4 (PR #11).

import sqlite3
from runtime_config import read_runtime_config
from contextlib import closing
from datetime import datetime, timezone
import os
import json
import sys
import argparse
import ipaddress
import time
import re
import xml.etree.ElementTree as ET

from config_hostnames import kea_reservation_names, merge_names

# ================================================================
# KONFIGURACE - ZAPNI/VYPNI FUNKCE
# ================================================================
b_debug_logging = True  # ← Změň na False pro vypnutí logů

# ================================================================
# CESTY - VŠECHNO NA JEDNOM MÍSTĚ!
#
#          Ukazatel na konfigurační soubor s výchozími hodnotami
#
# ================================================================
S_DEFAULTS_FILE = '/usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/defaults.json'

def load_defaults():
    with open(S_DEFAULTS_FILE, 'r') as o_file:
        return json.load(o_file)

# Načti na startu
d_defaults = load_defaults()
D_PATHS = d_defaults['paths']

# Cesty (místo hardcoded)
S_HOSTWATCH_DB = D_PATHS['hostwatchDb']
S_CONFIG_FILE = D_PATHS['configFile']
S_DB_FILE = D_PATHS['dbFile']
D_DEFAULT_CONFIG = d_defaults['config']
# ================================================================


def log(s_message):
    """Standardní append logging (rychlé!)"""
    if not b_debug_logging:
        return
    
    s_timestamp = datetime.now().strftime('%d-%m-%Y %H:%M:%S')
    with open("/var/log/devicemonitor.log", "a") as o_file:
        o_file.write(f"{s_timestamp} - {s_message}\n")

def load_config():
    """Načte runtime konfiguraci"""
    
    if not os.path.exists(S_CONFIG_FILE):
        if b_debug_logging:
            log(f"Config file not found: {S_CONFIG_FILE}, using defaults")
        return {
            'enabled': D_DEFAULT_CONFIG['enabled'] == '1',
            'email_enabled': D_DEFAULT_CONFIG.get('email_enabled', '1') == '1',
            'email_to': D_DEFAULT_CONFIG.get('email_to', ''),
            'email_from': D_DEFAULT_CONFIG.get('email_from', 'devicemonitor@opnsense.local'),
            'webhook_enabled': D_DEFAULT_CONFIG.get('webhook_enabled', '0') == '1',
            'webhook_url': D_DEFAULT_CONFIG.get('webhook_url', ''),
            'scan_interval': int(D_DEFAULT_CONFIG.get('scan_interval', 300)),
            'email_vlans': D_DEFAULT_CONFIG.get('email_vlans', ''),
            'webhook_vlans': D_DEFAULT_CONFIG.get('webhook_vlans', ''),
            'apiEmailUrl': D_PATHS.get('apiEmailUrl', ''),
            'apiWebhookUrl': D_PATHS.get('apiWebhookUrl', '')
        }
    
    try:
        d_config = read_runtime_config(S_CONFIG_FILE, D_DEFAULT_CONFIG)

        return {
            'enabled': d_config.get('enabled', '0') == '1',
            'email_enabled': d_config.get('email_enabled', '1') == '1',
            'email_to': d_config.get('email_to', ''),
            'email_from': d_config.get('email_from', 'devicemonitor@opnsense.local'),
            'webhook_enabled': d_config.get('webhook_enabled', '0') == '1',
            'webhook_url': d_config.get('webhook_url', ''),
            'scan_interval': int(d_config.get('scan_interval', D_DEFAULT_CONFIG.get('scan_interval', 300))),
            'email_vlans': d_config.get('email_vlans', D_DEFAULT_CONFIG.get('email_vlans', '')),
            'webhook_vlans': d_config.get('webhook_vlans', D_DEFAULT_CONFIG.get('webhook_vlans', '')),
            'apiEmailUrl': D_PATHS.get('apiEmailUrl', ''),
            'apiWebhookUrl': D_PATHS.get('apiWebhookUrl', '')
        }
    except Exception as o_error:
        if b_debug_logging:
            log(f"Config load error: {o_error}")
        return {
            'enabled': False,
            'email_enabled': True,
            'email_to': '',
            'email_from': 'devicemonitor@opnsense.local',
            'webhook_enabled': False,
            'webhook_url': '',
            'scan_interval': 300,
            'email_vlans':  '',
            'webhook_vlans': '',
            'apiEmailUrl': D_PATHS.get('apiEmailUrl'),
            'apiWebhookUrl': D_PATHS.get('apiWebhookUrl')
        }

    
    

def init_db():
    """Inicializace databáze"""
    o_conn = sqlite3.connect(S_DB_FILE)
    o_schema_cursor = o_conn.cursor()
    o_schema_cursor.execute("BEGIN IMMEDIATE")
    
    o_schema_cursor.execute('''CREATE TABLE IF NOT EXISTS devices (
        mac TEXT PRIMARY KEY,
        ip TEXT,
        hostname TEXT,
        vendor TEXT,
        vlan TEXT,
        last_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
        notified INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 0,
        notification_pending INTEGER DEFAULT 0,
        email_queued_at INTEGER,
        webhook_queued_at INTEGER
    )''')
    
    # Přidej sloupce pokud neexistují (pro zpětnou kompatibilitu)   
    try:
        o_schema_cursor.execute('ALTER TABLE devices ADD COLUMN first_seen DATETIME DEFAULT CURRENT_TIMESTAMP')
    except:
        pass

    try:
        o_schema_cursor.execute('ALTER TABLE devices ADD COLUMN custom_hostname TEXT DEFAULT NULL')
    except:
        pass

    if not any(t_column[1] == 'email_queued_at' for t_column in o_schema_cursor.execute('PRAGMA table_info(devices)')):
        o_schema_cursor.execute('ALTER TABLE devices ADD COLUMN email_queued_at INTEGER')
    o_schema_cursor.execute('CREATE INDEX IF NOT EXISTS devices_email_queue ON devices (email_queued_at, mac) WHERE email_queued_at IS NOT NULL')
    if not any(t_column[1] == 'webhook_queued_at' for t_column in o_schema_cursor.execute('PRAGMA table_info(devices)')):
        o_schema_cursor.execute('ALTER TABLE devices ADD COLUMN webhook_queued_at INTEGER')
    o_schema_cursor.execute('CREATE INDEX IF NOT EXISTS devices_webhook_queue ON devices (webhook_queued_at, mac) WHERE webhook_queued_at IS NOT NULL')

    # Tombstones for manually deleted devices. Historical Hostwatch records
    # must not immediately recreate a device that the user removed.
    o_schema_cursor.execute('''CREATE TABLE IF NOT EXISTS deleted_devices (
        mac TEXT PRIMARY KEY,
        last_seen DATETIME,
        deleted_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )''')
    
    o_conn.commit()
    o_conn.close()


def normalize_hostwatch_time(s_value, o_now):
    """Vrátí čas v UTC včetně ověření formátu a rozumného časového rozsahu."""
    if not isinstance(s_value, str) or not 19 <= len(s_value) <= 40 or s_value[10] not in {'T', ' '}:
        return None
    try:
        o_value = datetime.fromisoformat(s_value)
        o_value = o_value.replace(tzinfo=timezone.utc) if o_value.tzinfo is None else o_value.astimezone(timezone.utc)
        if (o_value - o_now).total_seconds() > 60:
            return None
        return min(o_value, o_now).strftime('%Y-%m-%d %H:%M:%S')
    except (ValueError, OverflowError):
        return None


def normalize_hostwatch_row(o_row, o_now):
    """Ověří identifikátory a čas. Nepoužitelný záznam se přeskočí."""
    x_mac = o_row['ether_address']
    x_ip = o_row['ip_address']
    if not isinstance(x_mac, str) or not isinstance(x_ip, str) or len(x_mac) > 32 or len(x_ip) > 32:
        return None
    s_mac = x_mac.strip().lower()
    if not re.fullmatch(r'(?:[0-9a-f]{2}:){5}[0-9a-f]{2}', s_mac) or s_mac in {'00:00:00:00:00:00', 'ff:ff:ff:ff:ff:ff'}:
        return None
    try:
        o_ip = ipaddress.IPv4Address(x_ip.strip())
    except ipaddress.AddressValueError:
        return None
    if o_ip.is_unspecified or o_ip.is_multicast or o_ip.is_link_local or int(o_ip) == 0xffffffff:
        return None

    s_last_seen = normalize_hostwatch_time(o_row['last_seen'], o_now)
    if s_last_seen is None:
        return None
    s_first_seen = normalize_hostwatch_time(o_row['first_seen'], o_now) or s_last_seen
    x_interface = o_row['interface_name']
    s_interface = x_interface.strip() if isinstance(x_interface, str) and len(x_interface) <= 64 else ''
    s_interface = s_interface if re.fullmatch(r'[a-zA-Z0-9_.:-]+', s_interface) else ''
    x_vendor = o_row['organization_name']
    s_vendor = re.sub(r'[\x00-\x1f\x7f]', ' ', x_vendor[:40]).strip() if isinstance(x_vendor, str) else ''
    return {
        'mac': s_mac, 'ip': str(o_ip), 'hostname': '', 'vendor': s_vendor or 'Unknown',
        'vlan': map_interface_to_vlan(s_interface), 'first_seen': min(s_first_seen, s_last_seen),
        'last_seen': s_last_seen,
    }


def get_hostwatch_devices():
    """Načte zařízení přímo z OPNsense hostwatch databáze"""
    d_hostwatch_devices = {}

    if not os.path.exists(S_HOSTWATCH_DB):
        log("CHYBA: hostwatch databáze neexistuje: " + S_HOSTWATCH_DB)
        return []

    try:
        with closing(sqlite3.connect(f'file:{S_HOSTWATCH_DB}?mode=ro', uri=True)) as o_conn:
            o_conn.row_factory = sqlite3.Row
            o_cursor = o_conn.cursor()

            o_cursor.execute('''
                SELECT
                    interface_name,
                    ip_address,
                    ether_address,
                    first_seen,
                    last_seen,
                    organization_name
                FROM v_hosts
                WHERE protocol = 'inet'
                  AND ether_address NOT IN ('ff:ff:ff:ff:ff:ff', '00:00:00:00:00:00')
                  AND ip_address NOT LIKE '169.254.%'
                ORDER BY last_seen DESC
            ''')

            # Porovnávej normalizované časy, i pokud se zápisy liší časovým pásmem.
            i_skipped_duplicates = 0
            i_skipped_invalid = 0
            i_read_rows = 0
            o_now = datetime.now(timezone.utc)
            for o_hostwatch_row in o_cursor:
                i_read_rows += 1
                d_device = normalize_hostwatch_row(o_hostwatch_row, o_now)
                if d_device is None:
                    i_skipped_invalid += 1
                    continue
                s_device_mac = d_device['mac']
                d_previous = d_hostwatch_devices.get(s_device_mac)
                if d_previous is not None:
                    i_skipped_duplicates += 1
                    if d_previous['last_seen'] >= d_device['last_seen']:
                        continue
                d_hostwatch_devices[s_device_mac] = d_device

            log(
                f"Hostwatch DB: načteno {i_read_rows} záznamů, "
                f"{len(d_hostwatch_devices)} unikátních MAC, "
                f"přeskočeno {i_skipped_duplicates} duplicit a {i_skipped_invalid} neplatných záznamů"
            )

    except Exception as o_error:
        log(f"Chyba čtení hostwatch DB: {o_error}")
        return []

    return list(d_hostwatch_devices.values())


def map_interface_to_vlan(s_interface):
    """Převede interface_name (vlan0.11) na čitelný název (VLAN11)"""
    if not s_interface:
        return 'Unknown'
    
    # vlan0.11 → VLAN11
    o_match = re.search(r'vlan\d+\.(\d+)', s_interface, re.I)
    if o_match:
        return 'VLAN' + o_match.group(1)
    
    # igc0, igc1 → interface název
    return s_interface.upper()


def get_dhcp_descriptions():
    """Načte popisky zařízení z DHCP statických přiřazení (/conf/config.xml)"""
    d_descriptions = {}
    try:
        o_config_tree = ET.parse('/conf/config.xml')
        o_config_root = o_config_tree.getroot()
        o_dhcpd = o_config_root.find('dhcpd')
        if o_dhcpd is None:
            return d_descriptions

        for o_dhcp_interface in o_dhcpd:
            # Přeskočit vypnuté ISC DHCP interfacy
            o_enable = o_dhcp_interface.find('enable')
            if o_enable is None:
                continue
            for o_static_mapping in o_dhcp_interface.findall('staticmap'):
                o_mac = o_static_mapping.find('mac')
                o_hostname_el = o_static_mapping.find('hostname')
                o_description = o_static_mapping.find('descr')
                if o_mac is not None and o_mac.text:
                    s_device_mac = o_mac.text.lower().strip()
                    # Preferuj hostname, fallback na descr
                    if o_hostname_el is not None and o_hostname_el.text:
                        d_descriptions[s_device_mac] = o_hostname_el.text.strip()
                    elif o_description is not None and o_description.text:
                        d_descriptions[s_device_mac] = o_description.text.strip()

        log(f"DHCP popisky: {len(d_descriptions)} záznamů")
    except Exception as o_error:
        log(f"Chyba čtení config.xml: {o_error}")
    return d_descriptions

def get_dnsmasq_descriptions():
    """Načte popisky zařízení z Dnsmasq Host Overrides (/conf/config.xml)"""
    d_descriptions = {}
    try:
        o_config_tree = ET.parse('/conf/config.xml')
        o_config_root = o_config_tree.getroot()
        o_dnsmasq = o_config_root.find('dnsmasq')
        if o_dnsmasq is None:
            return d_descriptions

        for o_host in o_dnsmasq.findall('hosts'):
            o_hwaddr = o_host.find('hwaddr')
            o_hostname = o_host.find('host')
            o_description = o_host.find('descr')
            if o_hwaddr is not None and o_hwaddr.text:
                s_device_mac = o_hwaddr.text.lower().strip()
                # Preferuj host (hostname), fallback na descr
                if o_hostname is not None and o_hostname.text:
                    d_descriptions[s_device_mac] = o_hostname.text.strip()
                elif o_description is not None and o_description.text:
                    d_descriptions[s_device_mac] = o_description.text.strip()

        log(f"Dnsmasq popisky: {len(d_descriptions)} záznamů")
    except Exception as o_error:
        log(f"Chyba čtení Dnsmasq config.xml: {o_error}")
    return d_descriptions

def get_kea_descriptions():
    """Bez vstupu načte config.xml a vrátí mapu MAC adres na názvy rezervací Kea."""
    try:
        o_root = ET.parse('/conf/config.xml').getroot()
        d_names = kea_reservation_names(o_root)
        log(f"Kea reservations: {len(d_names)} entries")
        return d_names
    except (OSError, ET.ParseError) as o_error:
        log(f"Error reading Kea reservations: {o_error}")
        return {}


def is_recently_seen(s_last_seen_input, i_minutes=15):
    """True pokud bylo zařízení viděno v posledních N minutách (porovnání v UTC)"""
    if not s_last_seen_input:
        return False
    try:
        o_last_seen = datetime.strptime(s_last_seen_input, '%Y-%m-%d %H:%M:%S')
        o_now_utc = datetime.utcnow()
        return 0 <= (o_now_utc - o_last_seen).total_seconds() < i_minutes * 60
    except:
        return False
    

def update_status_only():
    """Rychlá aktualizace online/offline statusu z hostwatch DB"""
    log("Quick status update (hostwatch DB)")
    init_db()

    l_hostwatch_devices = get_hostwatch_devices()
    if not l_hostwatch_devices:
        log("Žádná data z hostwatch DB")
        print("ERROR: No hostwatch data")
        return 1

    o_conn = sqlite3.connect(S_DB_FILE)
    o_cursor = o_conn.cursor()
    o_cursor.execute("UPDATE devices SET is_active = 0")
    for d_seen_device in l_hostwatch_devices:
        if is_recently_seen(d_seen_device.get('last_seen', '')):
            o_cursor.execute(
                "UPDATE devices SET is_active = 1, last_seen = ? WHERE mac = ?",
                (d_seen_device.get('last_seen', ''), d_seen_device['mac'])
            )

    o_conn.commit()
    i_online_count = o_conn.execute("SELECT COUNT(*) FROM devices WHERE is_active = 1").fetchone()[0]
    i_device_count = o_conn.execute("SELECT COUNT(*) FROM devices").fetchone()[0]
    o_conn.close()

    log(f"Status: {i_online_count}/{i_device_count} online")
    print(f"OK: {i_online_count}/{i_device_count} online")
    return 0


def full_scan():
    """Bez vstupu synchronizuje zařízení z Hostwatch s databází a vrátí stav 0/1."""
    log("Spouštím full scan (hostwatch DB)...")
    d_config = load_config()
    init_db()

    # 1. Data z hostwatch
    l_devices = get_hostwatch_devices()
    if not l_devices:
        log("CHYBA: Žádná data z hostwatch DB")
        return 1

    # Dnsmasq má přednost před Kea a Kea před ISC.
    d_dhcp_names = merge_names(
        get_dhcp_descriptions(), get_kea_descriptions(), get_dnsmasq_descriptions()
    )

    # 3. Aktualizace vlastní DB
    i_new_devices = 0
    set_email_vlans = {s_vlan.strip() for s_vlan in d_config['email_vlans'].split(',') if s_vlan.strip()}
    set_webhook_vlans = {s_vlan.strip() for s_vlan in d_config['webhook_vlans'].split(',') if s_vlan.strip()}
    b_queue_webhook = d_config['enabled'] and d_config['webhook_enabled'] and bool(d_config['webhook_url'])
    b_queue_email = d_config['enabled'] and d_config['email_enabled'] and bool(d_config['email_to'])
    s_now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    o_connection = sqlite3.connect(S_DB_FILE)
    o_connection.execute('UPDATE devices SET is_active = 0')

    i_queued_at = time.time_ns() // 1_000_000
    for d_device in l_devices:
        s_mac = d_device['mac']
        if not s_mac:
            continue

        # Obohacení o DHCP popis
        if s_mac in d_dhcp_names:
            d_device['hostname'] = d_dhcp_names[s_mac]

        i_active = 1 if is_recently_seen(d_device.get('last_seen', '')) else 0
        s_last_seen = d_device.get('last_seen') or s_now
        s_first_seen = d_device.get('first_seen') or s_now

        # If the user manually deleted this device, ignore the same historical
        # Hostwatch record. A genuinely newer last_seen means the device has
        # returned to the network, so remove the tombstone and add it again.
        t_deleted_row = o_connection.execute(
            'SELECT last_seen FROM deleted_devices WHERE mac = ?', (s_mac,)
        ).fetchone()
        if t_deleted_row:
            s_deleted_last_seen = t_deleted_row[0] or ''
            if s_deleted_last_seen and s_last_seen <= s_deleted_last_seen:
                continue
            o_connection.execute('DELETE FROM deleted_devices WHERE mac = ?', (s_mac,))

        t_row = o_connection.execute(
            'SELECT mac, custom_hostname FROM devices WHERE mac = ?', (s_mac,)
        ).fetchone()

        if t_row:
            s_hostname = t_row[1] if t_row[1] else d_device['hostname']
            o_connection.execute('''
                UPDATE devices
                SET ip = ?, hostname = ?, vendor = ?, vlan = ?,
                    last_seen = ?, is_active = ?
                WHERE mac = ?
            ''', (d_device['ip'], s_hostname, d_device['vendor'],
                  d_device['vlan'], s_last_seen, i_active, s_mac))
        else:
            b_email_vlan = not set_email_vlans or d_device['vlan'] in set_email_vlans
            b_webhook_vlan = not set_webhook_vlans or d_device['vlan'] in set_webhook_vlans
            o_connection.execute('''
                INSERT INTO devices
                    (mac, ip, hostname, vendor, vlan, first_seen, last_seen,
                     is_active, notification_pending, email_queued_at, webhook_queued_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?)
            ''', (s_mac, d_device['ip'], d_device['hostname'], d_device['vendor'],
                  d_device['vlan'], s_first_seen, s_last_seen, i_active,
                  i_queued_at if b_queue_email and b_email_vlan else None,
                  i_queued_at if b_queue_webhook and b_webhook_vlan else None))
            i_new_devices += 1

    o_connection.commit()
    i_online = o_connection.execute(
        "SELECT COUNT(*) FROM devices WHERE is_active = 1"
    ).fetchone()[0]
    i_total = o_connection.execute("SELECT COUNT(*) FROM devices").fetchone()[0]
    o_connection.close()

    log(f"Nová zařízení: {i_new_devices}, Online: {i_online}/{i_total}")
    return 0


def main():
    """Hlavní entry point s parsováním argumentů"""
    
    # Parsuj argumenty
    o_parser = argparse.ArgumentParser(
        description='OPNsense Device Monitor - Network Scanner',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s                    # Full scan (default)
  %(prog)s --update-only      # Quick status update (hostwatch DB)
  %(prog)s --verbose          # Full scan with verbose output
  %(prog)s --help             # Show this help
        '''
    )
    
    o_parser.add_argument(
        '--update-only',
        action='store_true',
        help='Quick mode: only update online/offline status via hostwatch DB'
    )
    
    o_parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Enable verbose output'
    )
    
    o_args = o_parser.parse_args()
    
    # Verbose mode
    global b_debug_logging
    if o_args.verbose:
        b_debug_logging = True
    
    try:
        # Rozhodnutí podle režimu
        if o_args.update_only:
            return update_status_only()
        else:
            return full_scan()
            
    except KeyboardInterrupt:
        log("Scan interrupted by user")
        print("\nInterrupted")
        return 1
    except Exception as o_error:
        log(f"Fatal error: {o_error}")
        print(f"ERROR: {o_error}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())