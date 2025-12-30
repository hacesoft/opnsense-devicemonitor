#!/usr/local/bin/python3

import time
import sys
import os
import signal
import json
import subprocess
from datetime import datetime

# ================================================================
# KONFIGURACE - ZAPNI/VYPNI FUNKCE
# ================================================================
INFO_LOGGING = True   # ← Důležité události (daemon started, scan completed)
DEBUG_LOGGING = False  # ← Detailní debug zprávy (config loaded každých 10s)

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
PID_FILE = PATHS['pidFile']
SCAN_SCRIPT = PATHS['scanScript']
DEFAULT_CONFIG = _defaults['config']
# ================================================================

running = True

def signal_handler(signum, frame):
    """Handler pro ukončení daemona"""
    global running
    log("Daemon stopping...", level='INFO')
    running = False

def log(message, level='INFO'):
    """
    Logování s 2 úrovněmi
    
    Args:
        message: Zpráva k zalogování
        level: 'INFO' (důležité události) nebo 'DEBUG' (detaily)
    """
    if level == 'INFO' and INFO_LOGGING:
        subprocess.run(['logger', '-t', 'devicemonitor', message])
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {message}")
    elif level == 'DEBUG' and DEBUG_LOGGING:
        subprocess.run(['logger', '-t', 'devicemonitor', f"DEBUG: {message}"])
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] DEBUG: {message}")

def load_config():
    """Načte runtime konfiguraci (enabled, email, interval)"""
    
    if not os.path.exists(CONFIG_FILE):
        log(f"Config file not found: {CONFIG_FILE}, using defaults", level='DEBUG')
        return {
            'enabled': DEFAULT_CONFIG['enabled'] == '1',
            'email_to': DEFAULT_CONFIG['email_to'],
            'email_from': DEFAULT_CONFIG['email_from'],
            'scan_interval': int(DEFAULT_CONFIG['scan_interval'])
        }
    
    try:
        with open(CONFIG_FILE, 'r') as f:
            config = json.load(f)
            
            enabled = config.get('enabled', '0') == '1'
            scan_interval = int(config.get('scan_interval', 300))
            
            # DEBUG level - zobrazí se jen když DEBUG_LOGGING = True
            log(f"Config loaded: enabled={enabled}, interval={scan_interval}s", level='DEBUG')
            
            return {
                'enabled': enabled,
                'email_to': config.get('email_to', ''),
                'email_from': config.get('email_from', DEFAULT_CONFIG['email_from']),
                'scan_interval': scan_interval
            }
            
    except Exception as e:
        log(f"Config load error: {e}", level='INFO')  # Chyby jsou INFO
        return {
            'enabled': False,
            'email_to': '',
            'email_from': DEFAULT_CONFIG['email_from'],
            'scan_interval': int(DEFAULT_CONFIG['scan_interval'])
        }

def run_scan():
    """Spustí scan script"""
    try:
        result = subprocess.run(
            ['/usr/local/bin/python3', SCAN_SCRIPT],
            capture_output=True,
            text=True,
            timeout=300
        )
        
        if result.returncode == 0:
            log("Scan completed successfully", level='INFO')
        else:
            log(f"Scan failed with code {result.returncode}", level='INFO')
            if result.stderr:
                log(f"Scan error: {result.stderr[:200]}", level='DEBUG')
        
        return result.returncode == 0
        
    except subprocess.TimeoutExpired:
        log(f"Scan timeout (>300s)", level='INFO')
        return False
    except Exception as e:
        log(f"Scan error: {e}", level='INFO')
        return False

def main():
    """Hlavní smyčka daemona"""
    global running
    
    # Registruj signal handlery
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    log("Daemon started", level='INFO')
    
    # Načti konfiguraci (včetně cest)
    config = load_config()
    
    # Zapiš PID do souboru (použij cestu z konfigurace)
    try:
        with open(PID_FILE, 'w') as f:
            f.write(str(os.getpid()))
        log(f"PID file created: {PID_FILE}", level='INFO')
    except Exception as e:
        log(f"Failed to create PID file: {e}", level='INFO')
    
    last_scan = 0
    last_config_state = None  # Pro sledování změn konfigurace
    last_interval = None      # Pro sledování změn intervalu
    
    while running:
        try:
            # Načti konfiguraci (cesty se nenačítají znovu, jen settings)
            config = load_config()
            
            # Loguj jen změny stavu
            current_state = config['enabled']
            current_interval = config['scan_interval']
            
            if current_state != last_config_state:
                if current_state:
                    log(f"Monitoring ENABLED (interval: {current_interval}s)", level='INFO')
                else:
                    log("Monitoring DISABLED", level='INFO')
                last_config_state = current_state
            
            # Loguj změnu intervalu (i když je enabled)
            elif current_state and current_interval != last_interval:
                log(f"Scan interval changed to {current_interval}s", level='INFO')
            
            last_interval = current_interval
            
            # Pokud je monitoring zapnutý
            if config['enabled']:
                current_time = time.time()
                interval = config['scan_interval']
                
                # Je čas na sken?
                if current_time - last_scan >= interval:
                    log(f"Running scheduled scan", level='INFO')
                    run_scan()
                    last_scan = current_time
            
            # Spinkej 10 sekund před další kontrolou
            time.sleep(10)
            
        except Exception as e:
            log(f"Daemon error: {e}", level='INFO')
            time.sleep(30)
    
    # Cleanup
    try:
        if os.path.exists(PID_FILE):
            os.remove(PID_FILE)
            log(f"PID file removed: {PID_FILE}", level='INFO')
    except Exception as e:
        log(f"Failed to remove PID file: {e}", level='INFO')
    
    log("Daemon stopped", level='INFO')

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        log(f"Fatal error: {e}", level='INFO')
        sys.exit(1)