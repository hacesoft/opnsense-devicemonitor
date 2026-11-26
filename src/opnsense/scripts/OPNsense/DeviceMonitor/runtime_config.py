"""Bezpečné načtení uložených nastavení bez použití poškozených hodnot."""

# Předpony: d = slovník, i = celé číslo, o = objekt, s = řetězec, x = proměnlivý typ.
# Historie: 2.4.16 – společná kontrola velikosti a typů JSON konfigurace.

import json

I_MAX_CONFIG_BYTES = 64 * 1024
D_RANGES = {'scan_interval': (60, 3600), 'smtp_port': (1, 65535),
            'email_batch_wait': (0, 3600), 'email_batch_max': (1, 3600)}


def read_runtime_config(s_config_file, d_defaults):
    """Načte známá pole z omezeného objektu. Neplatný soubor vyvolá ValueError."""
    with open(s_config_file, 'rb') as o_file:
        x_data = o_file.read(I_MAX_CONFIG_BYTES + 1)
    if len(x_data) > I_MAX_CONFIG_BYTES:
        raise ValueError('Configuration file is too large')
    d_config = json.loads(x_data)
    if not isinstance(d_config, dict):
        raise ValueError('Configuration must be a JSON object')

    d_result = {}
    for s_key, x_default in d_defaults.items():
        if s_key not in d_config:
            continue
        x_value = d_config[s_key]
        if type(x_default) is int or s_key in {'scan_interval', 'smtp_port'}:
            if not (type(x_value) is int or isinstance(x_value, str) and len(x_value) <= 10
                    and x_value.isascii() and x_value.isdecimal()):
                raise ValueError(f'Invalid integer field: {s_key}')
            if s_key in D_RANGES:
                i_min, i_max = D_RANGES[s_key]
                if not i_min <= int(x_value) <= i_max:
                    raise ValueError(f'Integer field out of range: {s_key}')
        elif not isinstance(x_value, str) or len(x_value) > 4096 or any(ord(s_char) < 32 or ord(s_char) == 127 for s_char in x_value):
            raise ValueError(f'Invalid text field: {s_key}')
        if s_key in {'enabled', 'email_enabled', 'webhook_enabled', 'firewall_traffic_enabled'} and x_value not in {'0', '1'}:
            raise ValueError(f'Invalid switch field: {s_key}')
        d_result[s_key] = x_value
    return d_result
