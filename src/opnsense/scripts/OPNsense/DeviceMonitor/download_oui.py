#!/usr/local/bin/python3

import json
import subprocess
import os
import sys

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
OUI_FILE = PATHS['ouiFile']
DEFAULT_OUI_URLS = _defaults['config']['oui']['urls']
# ================================================================

def log(message):
    """Logování"""
    if DEBUG_LOGGING:
        subprocess.run(['logger', '-t', 'devicemonitor-oui', message])
        print(message)  # Také vypiš do konzole

def load_config():
    """Načtení konfigurace"""
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, 'r') as f:
                config = json.load(f)
                return config.get('urls', DEFAULT_OUI_URLS)
        except:
            pass
    
    return DEFAULT_OUI_URLS

def download_oui():
    """Stažení OUI databáze"""
    # Vytvoř adresář pokud neexistuje
    os.makedirs(os.path.dirname(OUI_FILE), exist_ok=True)
    
    urls = load_config()
    
    for url in urls:
        if DEBUG_LOGGING:
            log(f"Trying to download from: {url}")
        
        try:
            # OPRAVENO: Použij curl místo fetch (fetch má problémy s HTTPS)
            result = subprocess.run(
                ['curl', '-f', '-s', '-L', '-o', OUI_FILE, '--connect-timeout', '30', '--max-time', '300', url],
                capture_output=True,
                timeout=310
            )
            
            # Zkontroluj jestli se stáhlo
            if result.returncode == 0 and os.path.exists(OUI_FILE):
                size = os.path.getsize(OUI_FILE)
                if size > 1000:  # Alespoň 1 KB
                    os.chmod(OUI_FILE, 0o644)
                    if DEBUG_LOGGING:
                        log(f"SUCCESS: OUI database downloaded from {url} ({size} bytes)")
                    return True
                else:
                    if DEBUG_LOGGING:
                        log(f"Downloaded file too small: {size} bytes")
        except Exception as e:
            if DEBUG_LOGGING:
                log(f"Download failed from {url}: {e}")
            continue
    if DEBUG_LOGGING:
        log("ERROR: All download attempts failed")
    return False

if __name__ == '__main__':
    success = download_oui()
    sys.exit(0 if success else 1)