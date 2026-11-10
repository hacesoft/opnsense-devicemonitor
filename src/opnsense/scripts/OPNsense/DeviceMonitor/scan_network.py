#!/usr/local/bin/python3

import sqlite3
from datetime import datetime
import os
import json
import sys
import argparse
import subprocess
import re
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from config_hostnames import kea_reservation_names

# ================================================================
# KONFIGURACE - ZAPNI/VYPNI FUNKCE
# ================================================================
DEBUG_LOGGING = True  # ← Změň na False pro vypnutí logů

# ================================================================
# CESTY - VŠECHNO NA JEDNOM MÍSTĚ!
#
#          Ukazatel na konfigurační soubor s výchozími hodnotami
#
# ================================================================
defaultsFile = '/usr/local/opnsense/mvc/app/models/OPNsense/DeviceMonitor/defaults.json'

def load_defaults():
    with open(defaultsFile, 'r') as f:
        return json.load(f)

# Načti na startu
_defaults = load_defaults()
PATHS = _defaults['paths']

# Cesty (místo hardcoded)
HOSTWATCH_DB = PATHS['hostwatchDb']
CONFIG_FILE = PATHS['configFile']
DB_FILE = PATHS['dbFile']
DEFAULT_CONFIG = _defaults['config']
# ================================================================


def log(message):
    """Standardní append logging (rychlé!)"""
    if not DEBUG_LOGGING:
        return
    
    timestamp = datetime.now().strftime('%d-%m-%Y %H:%M:%S')
    with open("/var/log/devicemonitor.log", "a") as f:
        f.write(f"{timestamp} - {message}\n")

def load_config():
    """Načte runtime konfiguraci"""
    
    if not os.path.exists(CONFIG_FILE):
        if DEBUG_LOGGING:
            log(f"Config file not found: {CONFIG_FILE}, using defaults")
        return {
            'enabled': DEFAULT_CONFIG['enabled'] == '1',
            'email_enabled': DEFAULT_CONFIG.get('email_enabled', '1') == '1',
            'email_to': DEFAULT_CONFIG.get('email_to', ''),
            'email_from': DEFAULT_CONFIG.get('email_from', 'devicemonitor@opnsense.local'),
            'webhook_enabled': DEFAULT_CONFIG.get('webhook_enabled', '0') == '1',
            'webhook_url': DEFAULT_CONFIG.get('webhook_url', ''),
            'scan_interval': int(DEFAULT_CONFIG.get('scan_interval', 300)),
            'email_vlans': DEFAULT_CONFIG.get('email_vlans', ''),
            'webhook_vlans': DEFAULT_CONFIG.get('webhook_vlans', ''),
            'apiEmailUrl': PATHS.get('apiEmailUrl', ''),
            'apiWebhookUrl': PATHS.get('apiWebhookUrl', '')
        }
    
    try:
        with open(CONFIG_FILE, 'r') as f:
            config = json.load(f)
            
            return {
                'enabled': config.get('enabled', '0') == '1',
                'email_enabled': config.get('email_enabled', '1') == '1',
                'email_to': config.get('email_to', ''),
                'email_from': config.get('email_from', 'devicemonitor@opnsense.local'),
                'webhook_enabled': config.get('webhook_enabled', '0') == '1',
                'webhook_url': config.get('webhook_url', ''),
                'scan_interval': int(config.get('scan_interval', DEFAULT_CONFIG.get('scan_interval', 300))),
                'email_vlans': config.get('email_vlans', DEFAULT_CONFIG.get('email_vlans', '')),
                'webhook_vlans': config.get('webhook_vlans', DEFAULT_CONFIG.get('webhook_vlans', '')),
                'apiEmailUrl': PATHS.get('apiEmailUrl', ''),
                'apiWebhookUrl': PATHS.get('apiWebhookUrl', '')
            }
    except Exception as e:
        if DEBUG_LOGGING:
            log(f"Config load error: {e}")
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
            'apiEmailUrl': PATHS.get('apiEmailUrl'),
            'apiWebhookUrl': PATHS.get('apiWebhookUrl')
        }

    
    

def init_db():
    """Inicializace databáze"""
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    
    c.execute('''CREATE TABLE IF NOT EXISTS devices (
        mac TEXT PRIMARY KEY,
        ip TEXT,
        hostname TEXT,
        vendor TEXT,
        vlan TEXT,
        last_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
        notified INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 0,
        notification_pending INTEGER DEFAULT 0
    )''')
    
    # Přidej sloupce pokud neexistují (pro zpětnou kompatibilitu)   
    try:
        c.execute('ALTER TABLE devices ADD COLUMN first_seen DATETIME DEFAULT CURRENT_TIMESTAMP')
    except:
        pass

    try:
        c.execute('ALTER TABLE devices ADD COLUMN custom_hostname TEXT DEFAULT NULL')
    except:
        pass

    # Tombstones for manually deleted devices. Historical Hostwatch records
    # must not immediately recreate a device that the user removed.
    c.execute('''CREATE TABLE IF NOT EXISTS deleted_devices (
        mac TEXT PRIMARY KEY,
        last_seen DATETIME,
        deleted_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )''')
    
    conn.commit()
    conn.close()


def get_hostwatch_devices():
    """Načte zařízení přímo z OPNsense hostwatch databáze"""
    devices = []
    
    if not os.path.exists(HOSTWATCH_DB):
        log("CHYBA: hostwatch databáze neexistuje: " + HOSTWATCH_DB)
        return devices
    
    try:
        conn = sqlite3.connect(f'file:{HOSTWATCH_DB}?mode=ro', uri=True)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        cursor.execute('''
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
        
        rows = cursor.fetchall()
        conn.close()
        
        # The query is sorted newest-first. Keep only the first row for each
        # MAC so historical Hostwatch records cannot overwrite current data.
        seen_macs = set()
        skipped_duplicates = 0

        for row in rows:
            mac = (row['ether_address'] or '').lower().strip()
            if not mac:
                continue
            if mac in seen_macs:
                skipped_duplicates += 1
                continue
            seen_macs.add(mac)

            # Mapuj interface_name na VLAN popis
            iface = row['interface_name'] or ''
            vlan = map_interface_to_vlan(iface)
            
            vendor = row['organization_name'] or 'Unknown'
            if len(vendor) > 40:
                vendor = vendor[:37] + '...'
            
            devices.append({
                'mac': mac,
                'ip': row['ip_address'] or '',
                'hostname': '',
                'vendor': vendor,
                'vlan': vlan,
                'first_seen': row['first_seen'] or '',
                'last_seen': row['last_seen'] or '',
            })
        
        log(
            f"Hostwatch DB: načteno {len(rows)} záznamů, "
            f"{len(devices)} unikátních MAC, přeskočeno {skipped_duplicates} historických duplicit"
        )
        
    except Exception as e:
        log(f"Chyba čtení hostwatch DB: {e}")
    
    return devices


def map_interface_to_vlan(interface_name):
    """Převede interface_name (vlan0.11) na čitelný název (VLAN11)"""
    if not interface_name:
        return 'Unknown'
    
    # vlan0.11 → VLAN11
    match = re.search(r'vlan\d+\.(\d+)', interface_name, re.I)
    if match:
        return 'VLAN' + match.group(1)
    
    # igc0, igc1 → interface název
    return interface_name.upper()


def get_dhcp_descriptions():
    """Načte popisky zařízení z DHCP statických přiřazení (/conf/config.xml)"""
    descriptions = {}
    try:
        tree = ET.parse('/conf/config.xml')
        root = tree.getroot()
        dhcpd = root.find('dhcpd')
        if dhcpd is None:
            return descriptions

        for iface in dhcpd:
            # Přeskočit vypnuté ISC DHCP interfacy
            enable_el = iface.find('enable')
            if enable_el is None:
                continue
            for staticmap in iface.findall('staticmap'):
                mac_el = staticmap.find('mac')
                hostname_el = staticmap.find('hostname')
                descr_el = staticmap.find('descr')
                if mac_el is not None and mac_el.text:
                    mac = mac_el.text.lower().strip()
                    # Preferuj hostname, fallback na descr
                    if hostname_el is not None and hostname_el.text:
                        descriptions[mac] = hostname_el.text.strip()
                    elif descr_el is not None and descr_el.text:
                        descriptions[mac] = descr_el.text.strip()

        log(f"DHCP popisky: {len(descriptions)} záznamů")
    except Exception as e:
        log(f"Chyba čtení config.xml: {e}")
    return descriptions

def get_dnsmasq_descriptions():
    """Načte popisky zařízení z Dnsmasq Host Overrides (/conf/config.xml)"""
    descriptions = {}
    try:
        tree = ET.parse('/conf/config.xml')
        root = tree.getroot()
        dnsmasq = root.find('dnsmasq')
        if dnsmasq is None:
            return descriptions

        for host in dnsmasq.findall('hosts'):
            hw_el = host.find('hwaddr')
            host_el = host.find('host')
            descr_el = host.find('descr')
            if hw_el is not None and hw_el.text:
                mac = hw_el.text.lower().strip()
                # Preferuj host (hostname), fallback na descr
                if host_el is not None and host_el.text:
                    descriptions[mac] = host_el.text.strip()
                elif descr_el is not None and descr_el.text:
                    descriptions[mac] = descr_el.text.strip()

        log(f"Dnsmasq popisky: {len(descriptions)} záznamů")
    except Exception as e:
        log(f"Chyba čtení Dnsmasq config.xml: {e}")
    return descriptions

def get_kea_descriptions():
    """Load hostnames from Kea DHCPv4 reservations (/conf/config.xml)"""
    try:
        names = kea_reservation_names(ET.parse('/conf/config.xml').getroot())
        log(f"Kea reservations: {len(names)} entries")
        return names
    except Exception as e:
        log(f"Error reading Kea reservations: {e}")
        return {}

def is_recently_seen(last_seen_str, minutes=15):
    """True pokud bylo zařízení viděno v posledních N minutách (porovnání v UTC)"""
    if not last_seen_str:
        return False
    try:
        last_seen = datetime.strptime(last_seen_str, '%Y-%m-%d %H:%M:%S')
        now_utc = datetime.utcnow()
        return (now_utc - last_seen).total_seconds() < minutes * 60
    except:
        return False
    

def send_email_via_php_api(new_devices):
    """Označ zařízení v DB pro odeslání emailu"""
    if not new_devices:
        return
    
    try:
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()

        # Pending must represent exactly this delivery channel's filtered set.
        cursor.execute("UPDATE devices SET notification_pending = 0")
        
        # Označ zařízení pro notifikaci
        for device in new_devices:
            cursor.execute("""
                UPDATE devices 
                SET notification_pending = 1 
                WHERE mac = ?
            """, (device['mac'],))
        
        conn.commit()
        # log(f"[EMAIL] Marked {len(new_devices)} devices for notification")
        
        # Zavolej PHP BEZ parametrů
        result = subprocess.run(
            ['/usr/local/sbin/configctl', 'devicemonitor', 'sendEmailNotification'],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        # log(f"[EMAIL] configctl returned: {result.returncode}")
        # if result.stdout:
        #     log(f"[EMAIL] stdout: {result.stdout[:200]}")
        if result.stderr:
            log(f"[EMAIL] stderr: {result.stderr[:200]}")
            
    except Exception as e:
        log(f"[EMAIL] Error: {e}")


def send_webhook_via_php_api(new_devices):
    """Označ zařízení v DB pro odeslání webhooku"""
    if not new_devices:
        return
    
    try:
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()

        # Pending must represent exactly this delivery channel's filtered set.
        cursor.execute("UPDATE devices SET notification_pending = 0")
        
        # Označ zařízení pro notifikaci
        for device in new_devices:
            cursor.execute("""
                UPDATE devices 
                SET notification_pending = 1 
                WHERE mac = ?
            """, (device['mac'],))
        
        conn.commit()
        # log(f"[WEBHOOK] Marked {len(new_devices)} devices for notification")
        
        # Zavolej PHP BEZ parametrů
        result = subprocess.run(
            ['/usr/local/sbin/configctl', 'devicemonitor', 'sendWebhookNotification'],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        # log(f"[WEBHOOK] configctl returned: {result.returncode}")
        # if result.stdout:
        #     log(f"[WEBHOOK] stdout: {result.stdout[:200]}")
        if result.stderr:
            log(f"[WEBHOOK] stderr: {result.stderr[:200]}")
            
    except Exception as e:
        log(f"[WEBHOOK] Error: {e}")
    

# ================================================================
# HLAVNÍ FUNKCE - REFAKTOROVANÉ
# ================================================================

def update_status_only():
    """Rychlá aktualizace online/offline statusu z hostwatch DB"""
    log("Quick status update (hostwatch DB)")
    init_db()

    devices = get_hostwatch_devices()
    if not devices:
        log("Žádná data z hostwatch DB")
        print("ERROR: No hostwatch data")
        return 1

    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("UPDATE devices SET is_active = 0")
    for d in devices:
        if is_recently_seen(d.get('last_seen', '')):
            cursor.execute(
                "UPDATE devices SET is_active = 1, last_seen = ? WHERE mac = ?",
                (d.get('last_seen', ''), d['mac'])
            )

    conn.commit()
    online = conn.execute("SELECT COUNT(*) FROM devices WHERE is_active = 1").fetchone()[0]
    total = conn.execute("SELECT COUNT(*) FROM devices").fetchone()[0]
    conn.close()

    log(f"Status: {online}/{total} online")
    print(f"OK: {online}/{total} online")
    return 0


def full_scan():
    """Kompletní scan z OPNsense hostwatch DB + DHCP popisky"""
    log("Spouštím full scan (hostwatch DB)...")
    config = load_config()
    init_db()

    # 1. Data z hostwatch
    devices = get_hostwatch_devices()
    if not devices:
        log("CHYBA: Žádná data z hostwatch DB")
        return 1

    # 2. DHCP popisky (ISC + Dnsmasq, Dnsmasq má přednost)
    dhcp_descriptions = get_dhcp_descriptions()
    dhcp_descriptions.update(get_kea_descriptions())  # Kea overrides ISC for the same MAC
    dnsmasq_descriptions = get_dnsmasq_descriptions()
    dhcp_descriptions.update(dnsmasq_descriptions)  # Dnsmasq přepíše ISC pokud existuje stejné MAC

    # 3. Aktualizace vlastní DB
    new_devices = []
    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    conn = sqlite3.connect(DB_FILE)
    conn.execute('UPDATE devices SET is_active = 0, notification_pending = 0')

    for device in devices:
        mac = device['mac']
        if not mac:
            continue

        # Obohacení o DHCP popis
        if mac in dhcp_descriptions:
            device['hostname'] = dhcp_descriptions[mac]

        is_active = 1 if is_recently_seen(device.get('last_seen', '')) else 0
        last_seen = device.get('last_seen') or now
        first_seen = device.get('first_seen') or now

        # If the user manually deleted this device, ignore the same historical
        # Hostwatch record. A genuinely newer last_seen means the device has
        # returned to the network, so remove the tombstone and add it again.
        deleted_row = conn.execute(
            'SELECT last_seen FROM deleted_devices WHERE mac = ?', (mac,)
        ).fetchone()
        if deleted_row:
            deleted_last_seen = deleted_row[0] or ''
            if deleted_last_seen and last_seen <= deleted_last_seen:
                continue
            conn.execute('DELETE FROM deleted_devices WHERE mac = ?', (mac,))

        row = conn.execute(
            'SELECT mac, custom_hostname FROM devices WHERE mac = ?', (mac,)
        ).fetchone()

        if row:
            hostname = row[1] if row[1] else device['hostname']
            conn.execute('''
                UPDATE devices
                SET ip = ?, hostname = ?, vendor = ?, vlan = ?,
                    last_seen = ?, is_active = ?
                WHERE mac = ?
            ''', (device['ip'], hostname, device['vendor'],
                  device['vlan'], last_seen, is_active, mac))
        else:
            conn.execute('''
                INSERT INTO devices
                    (mac, ip, hostname, vendor, vlan, first_seen, last_seen,
                     is_active, notification_pending)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0)
            ''', (mac, device['ip'], device['hostname'], device['vendor'],
                  device['vlan'], first_seen, last_seen, is_active))
            device['first_seen'] = first_seen
            new_devices.append(device)

    conn.commit()
    online = conn.execute(
        "SELECT COUNT(*) FROM devices WHERE is_active = 1"
    ).fetchone()[0]
    total = conn.execute("SELECT COUNT(*) FROM devices").fetchone()[0]
    conn.close()

    # 4. Notifikace (s filtrováním podle VLAN)
    log(f"Nová zařízení: {len(new_devices)}, Online: {online}/{total}")
    if new_devices and config['enabled']:
        email_vlans   = set(v.strip() for v in config.get('email_vlans',  '').split(',') if v.strip())
        webhook_vlans = set(v.strip() for v in config.get('webhook_vlans', '').split(',') if v.strip())
        email_devs    = [d for d in new_devices if not email_vlans   or d.get('vlan','') in email_vlans]
        webhook_devs  = [d for d in new_devices if not webhook_vlans or d.get('vlan','') in webhook_vlans]
        if email_devs and config.get('email_enabled') and config.get('email_to'):
            send_email_via_php_api(email_devs)
        if webhook_devs and config.get('webhook_enabled') and config.get('webhook_url'):
            send_webhook_via_php_api(webhook_devs)

    # Do not leave stale pending flags between scans/channels.
    with sqlite3.connect(DB_FILE) as cleanup_conn:
        cleanup_conn.execute('UPDATE devices SET notification_pending = 0')

    return 0


def main():
    """Hlavní entry point s parsováním argumentů"""
    
    # Parsuj argumenty
    parser = argparse.ArgumentParser(
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
    
    parser.add_argument(
        '--update-only',
        action='store_true',
        help='Quick mode: only update online/offline status via hostwatch DB'
    )
    
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Enable verbose output'
    )
    
    args = parser.parse_args()
    
    # Verbose mode
    global DEBUG_LOGGING
    if args.verbose:
        DEBUG_LOGGING = True
    
    try:
        # Rozhodnutí podle režimu
        if args.update_only:
            return update_status_only()
        else:
            return full_scan()
            
    except KeyboardInterrupt:
        log("Scan interrupted by user")
        print("\nInterrupted")
        return 1
    except Exception as e:
        log(f"Fatal error: {e}")
        print(f"ERROR: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())