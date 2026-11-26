"""Pasivní sběr čítačů PF pro známá zařízení."""

# Předpony: arr = posloupnost, b = příznak, d = slovník, f = desetinné číslo,
# i = celé číslo, o = objekt, s = řetězec, x = proměnlivý typ, by = bajty.
# Historie: 2.4.15 – časově a velikostně omezené čtení snímku PF.
# 2.4.9 – pevný čas 15minutového přehledu aktivity.
# 2.4.8 – sběr na pozadí a publikování snímků pro seznam zařízení.

from contextlib import closing
import json
import os
import selectors
from pathlib import Path
import sqlite3
import subprocess
import tempfile
import time

I_SAMPLE_INTERVAL = 30
I_ACTIVITY_WINDOW = 15 * 60
I_PF_MAX_BYTES = 16 * 1024 * 1024
I_PF_TIMEOUT = 20


def read_pf_snapshot(arr_command, i_max_bytes, i_timeout):
    """Vrátí omezený JSON výstup příkazu nebo ukončí pouze svůj proces configctl."""
    by_snapshot = bytearray()
    f_deadline = time.monotonic() + i_timeout
    with subprocess.Popen(arr_command, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL) as o_proc:
        try:
            with selectors.DefaultSelector() as o_selector:
                o_selector.register(o_proc.stdout, selectors.EVENT_READ)
                while True:
                    f_remaining = f_deadline - time.monotonic()
                    if f_remaining <= 0 or not o_selector.select(f_remaining):
                        raise subprocess.TimeoutExpired(arr_command, i_timeout)
                    by_chunk = os.read(o_proc.stdout.fileno(), min(65536, i_max_bytes + 1 - len(by_snapshot)))
                    if not by_chunk:
                        break
                    by_snapshot.extend(by_chunk)
                    if len(by_snapshot) > i_max_bytes:
                        raise ValueError(f'PF snapshot exceeds {i_max_bytes} bytes')
            i_status = o_proc.wait(timeout=max(0, f_deadline - time.monotonic()))
            if i_status != 0:
                raise subprocess.CalledProcessError(i_status, arr_command)
        finally:
            if o_proc.poll() is None:
                o_proc.kill()
    return json.loads(by_snapshot)



def read_counters(s_database):
    """Načte existující stavy PF a vrátí součty pro jednoznačné IP z databáze."""
    s_uri = Path(s_database).as_uri() + '?mode=ro'
    with closing(sqlite3.connect(s_uri, uri=True, timeout=3)) as o_database:
        d_keys = {
            s_ip: f'{s_mac}|{s_ip}'
            for s_ip, s_mac in o_database.execute("""
                SELECT ip, MIN(mac) FROM devices WHERE ip IS NOT NULL AND ip <> ''
                GROUP BY ip HAVING COUNT(*) = 1
            """)
        }
    d_counters = {s_key: (0, 0) for s_key in d_keys.values()}
    if not d_counters:
        return d_counters

    x_snapshot = read_pf_snapshot(
        ['/usr/local/sbin/configctl', 'filter', 'diag', 'top'], I_PF_MAX_BYTES, I_PF_TIMEOUT
    )
    if not isinstance(x_snapshot, dict) or not isinstance(x_snapshot.get('details'), list):
        raise ValueError('Invalid PF snapshot')
    for d_state in x_snapshot['details']:
        if not isinstance(d_state, dict):
            raise ValueError('Invalid PF state')
        arr_addresses = {d_state.get(s_field) for s_field in ('src_addr', 'dst_addr', 'gw_addr')}
        x_packets = d_state.get('pkts')
        for s_ip in arr_addresses & d_keys.keys():
            s_key = d_keys[s_ip]
            i_previous, i_states = d_counters[s_key]
            b_valid = type(x_packets) is int and x_packets >= 0 and i_previous is not None
            d_counters[s_key] = (i_previous + x_packets if b_valid else None, i_states + 1)
    return d_counters


def update_device(d_previous, i_packets, i_states, i_now):
    """Započte přírůstek a po 15 minutách bez něj zahájí nový součet."""
    i_baseline = d_previous.get('baseline')
    i_baseline_at = d_previous.get('baselineAt', 0)
    i_seen_at = d_previous.get('seenAt', 0)
    i_delta = 0
    s_reading = 'firewallNoStates' if i_states == 0 else 'firewallUnchanged'
    if i_packets is None:
        s_reading = 'firewallReadFailed'
    elif i_packets > 0:
        if i_baseline is None or not 0 <= i_now - i_baseline_at < I_ACTIVITY_WINDOW:
            s_reading = 'firewallBaseline'
        elif i_packets < i_baseline:
            s_reading = 'firewallLower'
        else:
            i_delta = i_packets - i_baseline
        i_baseline = i_packets
        i_baseline_at = i_now

    b_continue = i_seen_at > 0 and 0 <= i_now - i_seen_at < I_ACTIVITY_WINDOW
    return {
        'baseline': i_baseline,
        'baselineAt': i_baseline_at,
        'startedAt': d_previous.get('startedAt', i_now),
        'seenAt': i_now if i_delta > 0 else i_seen_at,
        'totalPackets': (d_previous.get('totalPackets', 0) if b_continue else 0) + i_delta,
        'reading': s_reading,
        'sampleAt': i_now,
    }


def write_snapshot(o_path, d_history, i_now, b_available, i_next_review, d_last_review):
    """Zapíše veřejné souhrny do dočasného souboru a atomicky je vystaví pro web."""
    d_rows = {
        s_key: {s_field: d_row[s_field] for s_field in (
            'startedAt', 'seenAt', 'totalPackets', 'reading', 'sampleAt'
        )}
        for s_key, d_row in d_history.items()
    }
    s_temp_path = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', dir=o_path.parent, delete=False) as o_file:
            s_temp_path = o_file.name
            json.dump({
                'sampleAt': i_now,
                'available': b_available,
                'rows': d_rows,
                'nextReviewAt': i_next_review,
                'lastReview': d_last_review,
            }, o_file)
            os.fchmod(o_file.fileno(), 0o644)
        os.replace(s_temp_path, o_path)
    finally:
        if s_temp_path is not None:
            Path(s_temp_path).unlink(missing_ok=True)


def collect(o_stop, o_load_config, s_database, s_snapshot, o_log):
    """Čte PF každých 30 sekund v samostatném vlákně služby Device Monitor."""
    o_path = Path(s_snapshot)
    d_history = {}
    b_enabled_before = False
    b_available_before = True
    i_next_review = 0
    d_last_review = None
    while not o_stop.is_set():
        f_started = time.monotonic()
        b_enabled = o_load_config()['firewall_traffic_enabled']
        try:
            if b_enabled:
                b_available = True
                try:
                    d_counters = read_counters(s_database)
                except (OSError, sqlite3.Error, subprocess.SubprocessError, ValueError, TypeError) as o_error:
                    b_available = False
                    if b_available_before:
                        o_log(f'PF reading unavailable: {o_error}')
                i_now = int(time.time())
                if b_available:
                    d_history = {
                        s_key: update_device(d_history.get(s_key, {}), i_packets, i_states, i_now)
                        for s_key, (i_packets, i_states) in d_counters.items()
                    }
                if i_next_review == 0 or i_next_review - i_now > I_ACTIVITY_WINDOW:
                    i_next_review = i_now + I_ACTIVITY_WINDOW
                elif i_now >= i_next_review:
                    d_last_review = None
                    if b_available:
                        i_active = sum(
                            0 <= i_now - d_row['seenAt'] < I_ACTIVITY_WINDOW
                            for d_row in d_history.values() if d_row['seenAt'] > 0
                        )
                        d_last_review = {'at': i_now, 'active': i_active}
                    i_next_review += ((i_now - i_next_review) // I_ACTIVITY_WINDOW + 1) * I_ACTIVITY_WINDOW
                if not o_stop.is_set():
                    write_snapshot(o_path, d_history, i_now, b_available, i_next_review, d_last_review)
                b_available_before = b_available
            elif b_enabled is False and b_enabled_before:
                o_path.unlink(missing_ok=True)
                d_history = {}
                i_next_review = 0
                d_last_review = None
                b_available_before = True
            if b_enabled is not None:
                b_enabled_before = b_enabled
        except OSError as o_error:
            o_log(f'PF snapshot error: {o_error}')
        o_stop.wait(max(1, I_SAMPLE_INTERVAL - (time.monotonic() - f_started)))
