#!/usr/local/bin/python3

import sqlite3
import subprocess
import re
from datetime import datetime
import os
import json
import sys
import argparse

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
CONFIG_FILE = PATHS['configFile']
DB_FILE = PATHS['dbFile']
OUI_FILE = PATHS['ouiFile']
DEFAULT_CONFIG = _defaults['config']
# ================================================================

# Cache pro OUI lookup
oui_cache = {}

def log(message):
    """Logování do souboru /var/log/devicemonitor.log"""
    if DEBUG_LOGGING:
        with open("/var/log/devicemonitor.log", "a") as f:
            f.write(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - {message}\n")


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
            'show_domain': DEFAULT_CONFIG.get('show_domain', '0') == '1'
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
                'scan_interval': int(config.get('scan_interval', 300)),
                'show_domain': config.get('show_domain', '0') == '1'
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
            'show_domain': False
        }

def load_oui_database():
    """Načtení OUI databáze do paměti"""
    global oui_cache
    
    if oui_cache:
        return
    
    if not os.path.exists(OUI_FILE):
        log("OUI database not found, vendor lookup disabled")
        return
    
    try:
        with open(OUI_FILE, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                if '(base 16)' in line or '(hex)' in line:
                    parts = line.split('(hex)')
                    if len(parts) >= 2:
                        oui = parts[0].strip().upper().replace('-', '').replace(':', '')
                        vendor = parts[-1].strip()
                        if oui and vendor:
                            oui_cache[oui] = vendor
        
        log(f"OUI database loaded: {len(oui_cache)} vendors")
    except Exception as e:
        log(f"Error loading OUI database: {e}")

def send_webhook(new_devices, config):
    """
    Webhook notifikace - posílá JSON data na URL
    Podporuje:
    - ntfy.sh (notifikace na mobil)
    - Discord
    - Generic webhooks (jakékoli URL)
    """
    import requests

    webhook_url = config.get('webhook_url')
    webhook_enabled = config.get('webhook_enabled', False)

    if not webhook_enabled or not webhook_url or not new_devices:
        log(f"[WEBHOOK] SKIPPED! enabled={webhook_enabled}, url={'yes' if webhook_url else 'NO'}, devices={len(new_devices) if new_devices else 0}")
        return False

    log(f"[WEBHOOK] Preparing request to {webhook_url}...")

    try:
        count = len(new_devices)
        devices_list = []
        for dev in new_devices:
            devices_list.append({
                'mac': dev['mac'],
                'ip': dev.get('ip', 'No IP'),
                'hostname': dev.get('hostname', 'Unknown'),
                'vendor': dev.get('vendor', 'Unknown'),
                'vlan': dev.get('vlan', ''),
                'first_seen': dev.get('first_seen', '')
            })

        # === NTFY.SH formát ===
        if 'ntfy' in webhook_url.lower():
            message_text = f'{count} new device(s) detected:\n\n'
            message_text += '\n'.join([
                f"• {d['mac']} - {d['vendor']} ({d.get('ip', 'No IP')})"
                for d in devices_list[:5]
            ])
            if count > 5:
                message_text += f'\n\n... and {count - 5} more'

            headers = {
                'Title': f'OPNsense: {count} new device(s)',
                'Tags': 'opnsense,network,security',
                'Priority': '4' if count > 3 else '3'
            }

            response = requests.post(
                webhook_url,
                data=message_text,
                headers=headers,
                timeout=10
            )

            log(f"[WEBHOOK] Response: HTTP {response.status_code}")
            if response.ok:
                log(f"Webhook SUCCESS: HTTP {response.status_code}")
                return True
            else:
                log(f"Webhook FAILED: HTTP {response.status_code}")
                return False

        # === DISCORD formát ===
        elif 'discord' in webhook_url.lower():
            embed_fields = []
            for dev in devices_list[:10]:
                embed_fields.append({
                    'name': f"🖥️ {dev['mac']}",
                    'value': f"**Vendor:** {dev['vendor']}\n**IP:** {dev.get('ip', 'No IP')}\n**VLAN:** {dev.get('vlan', 'N/A')}",
                    'inline': True
                })

            payload = {
                'username': 'OPNsense Device Monitor',
                'embeds': [{
                    'title': f'🔔 {count} New Device(s) Detected',
                    'description': f'New devices appeared on the network',
                    'color': 3447003,
                    'fields': embed_fields,
                    'footer': {
                        'text': f'OPNsense • {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}'
                    }
                }]
            }

            response = requests.post(
                webhook_url,
                json=payload,
                headers={'Content-Type': 'application/json'},
                timeout=10
            )

            log(f"[WEBHOOK] Response: HTTP {response.status_code}")
            if response.ok:
                log(f"Webhook SUCCESS: HTTP {response.status_code}")
                return True
            else:
                log(f"Webhook FAILED: HTTP {response.status_code}")
                return False

        # === GENERIC webhook ===
        else:
            payload = {
                'event': 'new_devices',
                'count': count,
                'timestamp': datetime.now().isoformat(),
                'hostname': os.uname().nodename,
                'devices': devices_list
            }

            response = requests.post(
                webhook_url,
                json=payload,
                headers={'Content-Type': 'application/json'},
                timeout=10
            )

            log(f"[WEBHOOK] Response: HTTP {response.status_code}")
            if response.ok:
                log(f"Webhook SUCCESS: HTTP {response.status_code}")
                return True
            else:
                log(f"Webhook FAILED: HTTP {response.status_code}")
                return False

    except Exception as e:
        log(f"Webhook ERROR: {e}")
        return False

    
def is_locally_administered(mac_address):
    """
    Detekuje jestli je MAC adresa lokálně administrovaná (virtuální/náhodná)
    Kontroluje druhý bit prvního oktetu (bit 1 zleva)
    
    Příklady:
    - 76:d1:1d:a6:a0:56 → True (lokální)
    - 00:1a:2b:3c:4d:5e → False (výrobce)
    """
    try:
        # Převeď první oktet (první 2 hex znaky) na integer
        first_byte = int(mac_address.replace(':', '').replace('-', '')[:2], 16)
        
        # Testuj bit 1 (druhý zleva): 0x02 = 00000010
        # Pokud je nastavený → lokálně administrovaná
        return (first_byte & 0x02) != 0
    except:
        return False
    
def lookup_vendor(mac_address):
    """Zjistí výrobce z MAC adresy"""
    
    # NEJDŘÍV zkontroluj jestli je to lokální MAC
    if is_locally_administered(mac_address):
        return 'Locally Administered (Virtual/Random)'
    
    # Pokud ne, hledej v OUI databázi
    if not oui_cache:
        load_oui_database()
    
    if not oui_cache:
        return 'Unknown'
    
    try:
        oui = mac_address.replace(':', '').replace('-', '').upper()[:6]
        vendor = oui_cache.get(oui, 'Unknown')
        
        if len(vendor) > 40:
            vendor = vendor[:37] + '...'
        
        return vendor
    except:
        return 'Unknown'

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
        is_active INTEGER DEFAULT 0
    )''')
    
    # Přidej sloupce pokud neexistují
    try:
        c.execute('ALTER TABLE devices ADD COLUMN notified INTEGER DEFAULT 0')
    except:
        pass
    
    try:
        c.execute('ALTER TABLE devices ADD COLUMN vendor TEXT')
    except:
        pass
    
    try:
        c.execute('ALTER TABLE devices ADD COLUMN is_active INTEGER DEFAULT 0')
    except:
        pass
    
    conn.commit()
    conn.close()

def get_active_interfaces():
    """
    Automaticky zjistí všechny aktivní VLAN interfacy
    Vrací seznam jako ['vlan0.11', 'vlan0.20', 'vlan0.30', ...]
    """
    interfaces = []
    
    try:
        output = subprocess.check_output(['ifconfig'], text=True)
        
        for line in output.splitlines():
            # Hledej VLAN interfacy (vlan0.11, vlan0.20, atd.)
            match = re.match(r'^(vlan\d+\.\d+):', line)
            if match:
                iface = match.group(1)
                
                # Kontrola že je UP a RUNNING
                if 'UP' in line and 'RUNNING' in line:
                    interfaces.append(iface)
    except:
        pass
    
    if not interfaces:
        # Fallback - pokud nejsou VLANy, použij hlavní interface
        interfaces = ['igc0']
    
    log(f"Monitoring interfaces: {', '.join(interfaces)}")
    return interfaces


def get_vlan_from_line(line):
    """Detekce VLAN"""
    match = re.search(r'on\s+(\S+)', line)
    if match:
        interface = match.group(1)
        
        if '.' in interface:
            vlan_num = interface.split('.')[-1]
            if vlan_num.isdigit():
                return 'VLAN' + vlan_num
        
        vlan_match = re.search(r'vlan(\d+)', interface, re.I)
        if vlan_match:
            return 'VLAN' + vlan_match.group(1)
        
        if interface not in ['em0', 'igb0', 'eth0']:
            return interface.upper()
    
    return 'LAN'

def get_arp_table():
    """ARP tabulka - zařízení s IP adresou"""
    devices = []
    load_oui_database()
    
    try:
        output = subprocess.check_output(['/usr/sbin/arp', '-an'], text=True)
        
        for line in output.splitlines():
            match = re.search(r'\(([0-9\.]+)\)\s+at\s+([0-9a-f:]+)', line, re.I)
            if match:
                ip = match.group(1)
                mac = match.group(2).lower()
                vlan = get_vlan_from_line(line)
                vendor = lookup_vendor(mac)
                
                hostname = ''
                try:
                    result = subprocess.run(['host', ip], capture_output=True, text=True, timeout=1)
                    if result.returncode == 0:
                        parts = result.stdout.split()
                        if len(parts) >= 5:
                            hostname = parts[4].rstrip('.')
                except:
                    pass
                
                devices.append({
                    'mac': mac,
                    'ip': ip,
                    'hostname': hostname,
                    'vendor': vendor,
                    'vlan': vlan
                })
    except Exception as e:
        log(f"ARP error: {e}")
    
    return devices

def get_dhcp_and_l2_devices():
    """
    Kombinovaný scan - najde zařízení bez IP:
    1. DHCP requesty (zařízení co se snaží získat IP)
    2. L2 aktivity (ostatní packety)
    
    Toto zachytí i zařízení odmítnutá "Deny unknown clients"
    """
    devices = []
    load_oui_database()
    
    interfaces = get_active_interfaces()
    all_seen_macs = set()
    
    # Scan každého interface
    for interface in interfaces:
        try:
            # Sleduj DHCP (port 67/68) + ARP + ICMP
            cmd = [
                'timeout', '5',
                '/usr/sbin/tcpdump',
                '-i', interface,
                '-e',  # Ethernet header (MAC adresy)
                '-n',  # No DNS
                '-l',  # Line buffered
                '-c', '200',  # Max 200 packetů
                '(port 67 or port 68 or arp or icmp)'
            ]
            
            output = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=6
            ).stdout
            
            # Parse všechny MAC adresy
            mac_pattern = re.compile(r'([0-9a-f]{2}:){5}[0-9a-f]{2}', re.I)
            
            for match in mac_pattern.finditer(output):
                mac = match.group(0).lower()
                
                # Ignoruj broadcast/multicast/spanning tree
                if mac.startswith(('ff:ff:', '01:00:5e:', '33:33:', '01:80:c2:')):
                    continue
                
                all_seen_macs.add(mac)
                
        except subprocess.TimeoutExpired:
            pass
        except Exception as e:
            log(f"L2 scan error on {interface}: {e}")
    
    # Získej MAC adresy z ARP (ty mají IP)
    arp_output = subprocess.run(
        ['/usr/sbin/arp', '-an'],
        capture_output=True,
        text=True
    ).stdout
    
    arp_macs = set()
    for match in re.finditer(r'at ([0-9a-f:]{17})', arp_output, re.I):
        arp_macs.add(match.group(1).lower())
    
    # Zařízení BEZ IP = viděli jsme na síti, ale NENÍ v ARP
    devices_without_ip = all_seen_macs - arp_macs
    
    # Vytvoř záznamy
    for mac in devices_without_ip:
        vendor = lookup_vendor(mac)
        
        devices.append({
            'mac': mac,
            'ip': None,
            'hostname': '',
            'vendor': vendor,
            'vlan': ''
        })
        
        log(f"⚠️  Device without IP: {mac} ({vendor})")
    
    return devices

def send_email(new_devices, config):
    """Email - HTML s inline CSS"""
    email_to = config.get('email_to')
    email_from = config.get('email_from', 'devicemonitor@opnsense.local')
    
    if not email_to or not new_devices:
        return False
    
    try:
        count = len(new_devices)
        subject = f'OPNsense: {count} {"nove zarizeni" if count == 1 else "novych zarizeni"} v siti'
        
        # HTML s INLINE CSS
        html = '<!DOCTYPE html>\n'
        html += '<html>\n'
        html += '<body style="font-family: Arial, sans-serif; padding: 20px;">\n'
        html += '<h2 style="color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 10px;">Nova zarizeni v siti</h2>\n'
        
        # Souhrn
        html += '<div style="background-color: #e7f3fe; padding: 15px; margin: 20px 0; border-left: 6px solid #2196F3;">\n'
        html += f'<p style="margin: 5px 0;"><strong>Pocet novych zarizeni:</strong> {count}</p>\n'
        html += f'<p style="margin: 5px 0;"><strong>Cas detekce:</strong> {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>\n'
        html += f'<p style="margin: 5px 0;"><strong>Server:</strong> {os.uname().nodename}</p>\n'
        html += '</div>\n'
        
        # Tabulka
        html += '<table style="border-collapse: collapse; width: 100%; margin-top: 20px;">\n'
        html += '<tr style="background-color: #4CAF50;">\n'
        html += '<th style="padding: 12px; color: white; text-align: left; border: 1px solid #ddd;">MAC adresa</th>\n'
        html += '<th style="padding: 12px; color: white; text-align: left; border: 1px solid #ddd;">IP adresa</th>\n'
        html += '<th style="padding: 12px; color: white; text-align: left; border: 1px solid #ddd;">Hostname</th>\n'
        html += '<th style="padding: 12px; color: white; text-align: left; border: 1px solid #ddd;">Vyrobce</th>\n'
        html += '<th style="padding: 12px; color: white; text-align: left; border: 1px solid #ddd;">VLAN</th>\n'
        html += '<th style="padding: 12px; color: white; text-align: left; border: 1px solid #ddd;">Prvni detekce</th>\n'
        html += '</tr>\n'
        
        for i, dev in enumerate(new_devices):
            bg_color = '#f2f2f2' if i % 2 == 0 else '#ffffff'
            
            # Speciální označení pro zařízení bez IP
            if not dev.get('ip'):
                bg_color = '#fff3cd'  # Žlutá - varování
            
            html += f'<tr style="background-color: {bg_color};">\n'
            html += f'<td style="padding: 10px; border: 1px solid #ddd;"><strong>{dev["mac"]}</strong></td>\n'
            
            # IP adresa - pokud není, ukaž varování
            ip_display = dev.get('ip') or '<strong style="color: #856404;">⚠️ BEZ IP</strong>'
            html += f'<td style="padding: 10px; border: 1px solid #ddd;">{ip_display}</td>\n'
            
            hostname = dev.get("hostname") or '<em style="color: #999;">neznamy</em>'
            html += f'<td style="padding: 10px; border: 1px solid #ddd;">{hostname}</td>\n'
            
            vendor = dev.get("vendor", "Unknown")
            html += f'<td style="padding: 10px; border: 1px solid #ddd;"><strong style="color: #FF9800;">{vendor}</strong></td>\n'
            html += f'<td style="padding: 10px; border: 1px solid #ddd;"><strong style="color: #2196F3;">{dev["vlan"]}</strong></td>\n'
            html += f'<td style="padding: 10px; border: 1px solid #ddd;">{dev["first_seen"]}</td>\n'
            html += '</tr>\n'
        
        html += '</table>\n'
        html += '<hr style="margin-top: 30px; border: none; border-top: 1px solid #ddd;">\n'
        html += '<p style="color: #666; font-size: 12px; margin-top: 20px;">OPNsense Device Monitor</p>\n'
        html += '</body>\n'
        html += '</html>\n'
        
        # Sestavení emailu
        message = f"From: {email_from}\n"
        message += f"To: {email_to}\n"
        message += f"Subject: {subject}\n"
        message += "MIME-Version: 1.0\n"
        message += "Content-Type: text/html; charset=UTF-8\n\n"
        message += html
        
        # Odešli
        result = subprocess.run(
            ['/usr/local/sbin/sendmail', '-t'],
            input=message,
            text=True,
            capture_output=True,
            timeout=10
        )
        
        if result.returncode == 0:
            log(f"Email sent: {count} devices to {email_to}")
            return True
        else:
            log(f"Email failed: {result.stderr}")
            return False
            
    except Exception as e:
        log(f"Email error: {e}")
        return False

def check_device_activity_pfctl():
    """
    Načte aktivní IP z pfctl -ss
    Vrací set() IP adres které jsou ONLINE (mají aktivní spojení)
    """
    active_ips = set()
    
    try:
        result = subprocess.run(
            ['pfctl', '-ss'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode != 0:
            log(f"pfctl warning: returned code {result.returncode}")
            return active_ips
        
        # Parsuj každý řádek
        for line in result.stdout.split('\n'):
            # Formát 1: "nat_ip (LOCAL_IP:port) -> external"
            # Hledej IP v závorce
            match = re.search(r'\((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):\d+\)', line)
            if match:
                ip = match.group(1)
                # Jen lokální IP
                if (ip.startswith('192.168.') or 
                    ip.startswith('10.') or 
                    re.match(r'^172\.(1[6-9]|2[0-9]|3[0-1])\.', ip)):
                    active_ips.add(ip)
                continue
            
            # Formát 2: "external <- LOCAL_IP:port"
            # Hledej IP za šipkou <-
            match = re.search(r'<-\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):\d+', line)
            if match:
                ip = match.group(1)
                # Jen lokální IP
                if (ip.startswith('192.168.') or 
                    ip.startswith('10.') or 
                    re.match(r'^172\.(1[6-9]|2[0-9]|3[0-1])\.', ip)):
                    active_ips.add(ip)
                continue
            
            # Formát 3: "LOCAL_IP:port -> internal" (lokální komunikace)
            # Hledej IP před ->
            match = re.search(r'^\s*all\s+\S+\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):\d+\s+->', line)
            if match:
                ip = match.group(1)
                # Jen lokální IP
                if (ip.startswith('192.168.') or 
                    ip.startswith('10.') or 
                    re.match(r'^172\.(1[6-9]|2[0-9]|3[0-1])\.', ip)):
                    active_ips.add(ip)
        
        log(f"pfctl: {len(active_ips)} active IPs")
        return active_ips
    
    except subprocess.TimeoutExpired:
        log("pfctl timeout")
        return set()
    except Exception as e:
        log(f"pfctl error: {e}")
        return set()

# ================================================================
# HLAVNÍ FUNKCE - REFAKTOROVANÉ
# ================================================================

def update_status_only():
    """
    Režim --update-only: Rychlá aktualizace online/offline statusu
    Používá pouze pfctl (bez ARP/DHCP/L2 scanu)
    Rychlost: ~100ms
    """
    log("Quick status update mode (pfctl only)")
    
    init_db()
    
    # Získej aktivní IPs z pfctl
    active_ips = check_device_activity_pfctl()
    log(f"Active IPs detected: {len(active_ips)}")
    
    # Aktualizuj databázi
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    # Nastav všechny na offline
    cursor.execute("UPDATE devices SET is_active = 0")
    
    # Aktivní na online + update last_seen
    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    for ip in active_ips:
        cursor.execute(
            "UPDATE devices SET is_active = 1, last_seen = ? WHERE ip = ?",
            (now, ip)
        )
    
    conn.commit()
    
    # Získej počty
    online_count = cursor.execute("SELECT COUNT(*) FROM devices WHERE is_active = 1").fetchone()[0]
    total_count = cursor.execute("SELECT COUNT(*) FROM devices").fetchone()[0]
    
    conn.close()
    
    log(f"Status updated: {online_count}/{total_count} devices online")
    print(f"OK: {online_count}/{total_count} online")
    
    return 0


def full_scan():
    """
    Režim normální: Kompletní scan sítě
    ARP + DHCP + L2 + pfctl + vendor lookup + email
    Rychlost: ~10-15 sekund
    """
    log("Starting full network scan...")
    
    config = load_config()
    init_db()
    db = sqlite3.connect(DB_FILE)
    
    # 1. Načti aktivní IP z pfctl (rychlé!)
    log("Checking device activity via pfctl...")
    active_ips = check_device_activity_pfctl()
    log(f"Active IPs detected: {len(active_ips)}")
    
    # 2. Získej všechna zařízení z ARP
    devices_with_ip = get_arp_table()
    log(f"ARP scan: {len(devices_with_ip)} devices with IP")
    
    # 3. Zařízení BEZ IP
    devices_without_ip = get_dhcp_and_l2_devices()
    log(f"L2 scan: {len(devices_without_ip)} devices without IP")
    
    # 4. Zpracuj - aktualizuj last_seen JEN pro AKTIVNÍ
    new_devices = []
    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    cursor = db.cursor()

    # NEJDŘÍV nastav VŠECHNY na neaktivní
    cursor.execute('UPDATE devices SET is_active = 0')

    for device in (devices_with_ip + devices_without_ip):
        mac = device['mac']
        
        # Zkontroluj jestli existuje
        cursor.execute('SELECT mac FROM devices WHERE mac = ?', (mac,))
        exists = cursor.fetchone()
        
        # Je zařízení AKTIVNÍ? (kontroluj IP v pfctl)
        device_ip = device.get('ip')
        is_active = 1 if (device_ip and device_ip in active_ips) else 0
        
        if exists:
            # UPDATE - aktualizuj is_active VŽDY, last_seen JEN pokud je aktivní
            if is_active:
                cursor.execute('''
                    UPDATE devices 
                    SET ip = ?, hostname = ?, vendor = ?, vlan = ?, last_seen = ?, is_active = ?
                    WHERE mac = ?
                ''', (device['ip'], device['hostname'], device['vendor'], device['vlan'], now, is_active, mac))
            else:
                # Neaktivní - aktualizuj jen IP/hostname/vendor a is_active
                cursor.execute('''
                    UPDATE devices 
                    SET ip = ?, hostname = ?, vendor = ?, vlan = ?, is_active = ?
                    WHERE mac = ?
                ''', (device['ip'], device['hostname'], device['vendor'], device['vlan'], is_active, mac))
        else:
            # INSERT nového zařízení
            cursor.execute('''
                INSERT INTO devices (mac, ip, hostname, vendor, vlan, last_seen, is_active)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (mac, device['ip'], device['hostname'], device['vendor'], device['vlan'], now, is_active))
            
            # Přidej do new_devices pro email
            device['first_seen'] = now
            new_devices.append(device)
            # log(f"New device: {mac} - {device['vendor']}")

    db.commit()
    
    log(f"[NOTIFY] {len(new_devices)} new devices detected!")
    # 5. Notifikace (email a/nebo webhook)
    if new_devices and config['enabled']:
        # Email
        if config.get('email_enabled') and config.get('email_to'):
            send_email(new_devices, config)
            log("Email notification sent")
        
        # Webhook
        if config.get('webhook_enabled') and config.get('webhook_url'):
            send_webhook(new_devices, config)
            log("Webhook notification sent")
    
    db.close()
    log(f"Scan completed. Active: {len(active_ips)}, New: {len(new_devices)}")
    print(f"Scan complete: {len(active_ips)} active, {len(new_devices)} new")
    
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
  %(prog)s --update-only      # Quick status update (pfctl only)
  %(prog)s --verbose          # Full scan with verbose output
  %(prog)s --help             # Show this help
        '''
    )
    
    parser.add_argument(
        '--update-only',
        action='store_true',
        help='Quick mode: only update online/offline status via pfctl (~100ms)'
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