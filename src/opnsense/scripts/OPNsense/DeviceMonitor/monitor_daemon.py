#!/usr/local/bin/python3

# Předpony: b = příznak, d = slovník, f = desetinné číslo, i = celé číslo, o = objekt, s = řetězec.
# U konstant jsou tytéž předpony uvedené velkým písmenem.
# Historie: 2.4.16 – kontrola uloženého JSON před použitím.
# 2.4.15 – dva nezávislé pracovní cykly notifikací.
# 2.4.12 – načtení režimu dávkování e-mailů.
# 2.4.11 – samostatný pracovní cyklus e-mailové fronty.
# 2.4.8 – samostatné vlákno pro pasivní sběr čítačů PF.
# 2.3.7 – sjednocení typových předpon proměnných.

import time
import sys
import os
import signal
import json
import subprocess
import threading
from runtime_config import read_runtime_config
from pathlib import Path

from pf_traffic import collect
from email_batch import run_worker
from datetime import datetime

# ================================================================
# KONFIGURACE - ZAPNI/VYPNI FUNKCE
# ================================================================
B_INFO_LOGGING = True   # ← Důležité události (daemon started, scan completed)
B_DEBUG_LOGGING = False  # ← Detailní debug zprávy (config loaded každých 10s)

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
S_CONFIG_FILE = D_PATHS['configFile']
S_DB_FILE = D_PATHS['dbFile']
S_PF_SNAPSHOT = D_PATHS['pfTrafficFile']
S_PID_FILE = D_PATHS['pidFile']
S_SCAN_SCRIPT = D_PATHS['scanScript']
D_DEFAULT_CONFIG = d_defaults['config']
# ================================================================

b_running = True
o_worker_stop = threading.Event()

def signal_handler(i_signal, o_frame):
    """Handler pro ukončení daemona"""
    global b_running
    log("Daemon stopping...", s_level='INFO')
    b_running = False
    o_worker_stop.set()

S_LOG_FILE = "/var/log/devicemonitor.log"

def log(s_message, s_level='INFO'):
    """
    Logování přímo do souboru + syslog
    """
    s_timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    if s_level == 'INFO' and B_INFO_LOGGING:
        # Zapiš přímo do souboru
        try:
            with open(S_LOG_FILE, 'a') as o_file:
                o_file.write(f"[{s_timestamp}] {s_message}\n")
                o_file.flush()
        except Exception as o_error:
            pass  # Tiše ignoruj chyby
        
        # Pokus o syslog (nemusí fungovat)
        try:
            subprocess.run(['logger', '-t', 'devicemonitor', s_message], check=False)
        except:
            pass
        
    elif s_level == 'DEBUG' and B_DEBUG_LOGGING:
        try:
            with open(S_LOG_FILE, 'a') as o_file:
                o_file.write(f"[{s_timestamp}] DEBUG: {s_message}\n")
                o_file.flush()
        except:
            pass
        
        try:
            subprocess.run(['logger', '-t', 'devicemonitor', f"DEBUG: {s_message}"], check=False)
        except:
            pass

def load_config():
    """Načte runtime konfiguraci (enabled, email, interval)"""
    
    if not os.path.exists(S_CONFIG_FILE):
        log(f"Config file not found: {S_CONFIG_FILE}, using defaults", s_level='DEBUG')
        return {
            'enabled': D_DEFAULT_CONFIG['enabled'] == '1',
            'firewall_traffic_enabled': D_DEFAULT_CONFIG['firewall_traffic_enabled'] == '1',
            'email_to': D_DEFAULT_CONFIG['email_to'],
            'email_enabled': D_DEFAULT_CONFIG['email_enabled'] == '1',
            'webhook_enabled': D_DEFAULT_CONFIG['webhook_enabled'] == '1',
            'webhook_url': D_DEFAULT_CONFIG['webhook_url'],
            'email_batch_mode': D_DEFAULT_CONFIG['email_batch_mode'],
            'email_batch_wait': D_DEFAULT_CONFIG['email_batch_wait'],
            'email_batch_max': D_DEFAULT_CONFIG['email_batch_max'],
            'email_from': D_DEFAULT_CONFIG['email_from'],
            'scan_interval': int(D_DEFAULT_CONFIG['scan_interval'])
        }
    
    try:
        d_config = read_runtime_config(S_CONFIG_FILE, D_DEFAULT_CONFIG)

        b_enabled = d_config.get('enabled', '0') == '1'
        i_batch_max = min(3600, max(1, int(d_config.get('email_batch_max', D_DEFAULT_CONFIG['email_batch_max']))))
        s_batch_mode = 'quiet' if d_config.get('email_batch_mode') == 'quiet' else 'bounded'
        i_batch_wait = min(3600, max(0, int(d_config.get('email_batch_wait', D_DEFAULT_CONFIG['email_batch_wait']))))
        if s_batch_mode == 'bounded':
            i_batch_wait = min(i_batch_max, i_batch_wait)
        i_scan_interval = int(d_config.get('scan_interval', 300))

        # DEBUG level - zobrazí se jen když DEBUG_LOGGING = True
        log(f"Config loaded: enabled={b_enabled}, interval={i_scan_interval}s", s_level='DEBUG')

        return {
            'enabled': b_enabled,
            'firewall_traffic_enabled': d_config.get('firewall_traffic_enabled', '0') == '1',
            'email_to': d_config.get('email_to', ''),
            'email_enabled': d_config.get('email_enabled', '1') == '1',
            'webhook_enabled': d_config.get('webhook_enabled', '0') == '1',
            'webhook_url': d_config.get('webhook_url', ''),
            'email_batch_mode': s_batch_mode,
            'email_batch_wait': i_batch_wait,
            'email_batch_max': i_batch_max,
            'email_from': d_config.get('email_from', D_DEFAULT_CONFIG['email_from']),
            'scan_interval': i_scan_interval
        }

    except Exception as o_error:
        log(f"Config load error: {o_error}", s_level='INFO')  # Chyby jsou INFO
        return {
            'enabled': False,
            'firewall_traffic_enabled': None,
            'email_to': '',
            'email_enabled': None,
            'webhook_enabled': None,
            'email_from': D_DEFAULT_CONFIG['email_from'],
            'scan_interval': int(D_DEFAULT_CONFIG['scan_interval'])
        }

def run_scan():
    """Spustí scan script"""
    try:
        o_process_result = subprocess.run(
            ['/usr/local/bin/python3', S_SCAN_SCRIPT],
            capture_output=True,
            text=True,
            timeout=300
        )
        
        if o_process_result.returncode == 0:
            log("Scan completed successfully", s_level='INFO')
        else:
            log(f"Scan failed with code {o_process_result.returncode}", s_level='INFO')
            if o_process_result.stderr:
                log(f"Scan error: {o_process_result.stderr[:200]}", s_level='DEBUG')
        
        return o_process_result.returncode == 0
        
    except subprocess.TimeoutExpired:
        log(f"Scan timeout (>300s)", s_level='INFO')
        return False
    except Exception as o_error:
        log(f"Scan error: {o_error}", s_level='INFO')
        return False

def main():
    """Hlavní smyčka daemona"""
    global b_running
    
    # Registruj signal handlery
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    log("Daemon started", s_level='INFO')
    
    try:
        Path(S_PF_SNAPSHOT).unlink(missing_ok=True)
    except OSError as o_error:
        log(f"PF snapshot cleanup failed: {o_error}")
    o_pf_worker = threading.Thread(
        target=collect, args=(o_worker_stop, load_config, S_DB_FILE, S_PF_SNAPSHOT, log),
        name='pf-traffic', daemon=True
    )
    o_pf_worker.start()
    for s_channel in ('email', 'webhook'):
        threading.Thread(
            target=run_worker, args=(o_worker_stop, load_config, S_DB_FILE, log, s_channel),
            name=f'{s_channel}-batch', daemon=True
        ).start()

    f_last_scan = 0
    b_last_config_state = None  # Pro sledování změn konfigurace
    i_last_interval = None      # Pro sledování změn intervalu
    
    while b_running:
        try:
            # Načti konfiguraci (cesty se nenačítají znovu, jen settings)
            d_config = load_config()
            
            # Loguj jen změny stavu
            b_current_state = d_config['enabled']
            i_current_interval = d_config['scan_interval']
            
            if b_current_state != b_last_config_state:
                if b_current_state:
                    log(f"Monitoring ENABLED (interval: {i_current_interval}s)", s_level='INFO')
                else:
                    log("Monitoring DISABLED", s_level='INFO')
                b_last_config_state = b_current_state
            
            # Loguj změnu intervalu (i když je enabled)
            elif b_current_state and i_current_interval != i_last_interval:
                log(f"Scan interval changed to {i_current_interval}s", s_level='INFO')
            
            i_last_interval = i_current_interval
            
            # Pokud je monitoring zapnutý
            if d_config['enabled']:
                f_current_time = time.time()
                i_interval = d_config['scan_interval']
                
                # Je čas na sken?
                if f_current_time - f_last_scan >= i_interval:
                    log(f"Running scheduled scan", s_level='INFO')
                    run_scan()
                    f_last_scan = f_current_time
            
            # Spinkej 10 sekund před další kontrolou
            time.sleep(10)
            
        except Exception as o_error:
            log(f"Daemon error: {o_error}", s_level='INFO')
            time.sleep(30)
    
    log("Daemon stopped", s_level='INFO')

if __name__ == '__main__':
    try:
        main()
    except Exception as o_error:
        log(f"Fatal error: {o_error}", s_level='INFO')
        sys.exit(1)