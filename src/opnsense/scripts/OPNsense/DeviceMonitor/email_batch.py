"""Oddělené fronty upozornění v databázi zařízení."""

# Předpony: b = příznak, d = slovník, f = desetinné číslo, i = celé číslo,
# l = seznam, o = objekt, s = řetězec, set = množina, x = hodnota proměnlivého typu.
# Historie: 2.4.15 – oddělené zámky a dávky nejvýš po 100 zařízeních.
# 2.4.12 – volitelné maximum doby čekání.
# 2.4.11 – posuvná prodleva, maximální okno a opakování po chybě.

from contextlib import closing
import fcntl
import json
from pathlib import Path
import sqlite3
import subprocess
import time


I_MAX_BATCH_ROWS = 100


def select_batch(l_rows, i_quiet_ms, i_max_ms):
    """Vrátí první skupinu seřazených záznamů a její termín v milisekundách."""
    if not l_rows:
        return [], 0

    d_first = l_rows[0]
    i_limit = d_first['queued_at'] + i_max_ms if i_max_ms is not None else None
    i_due = d_first['queued_at'] + i_quiet_ms
    if i_limit is not None:
        i_due = min(i_limit, i_due)
    l_batch = [d_first]
    for d_row in l_rows[1:]:
        i_queued_at = d_row['queued_at']
        if i_queued_at > i_due:
            break
        l_batch.append(d_row)
        i_due = i_queued_at + i_quiet_ms
        if i_limit is not None:
            i_due = min(i_limit, i_due)
    return l_batch, i_due


def deliver_batch(s_database, d_config, i_now, o_log, s_channel="email"):
    """Vyprázdní vypnutou frontu nebo odešle jednu splatnou dávku. Vrátí, zda opakovat po chybě."""
    b_email = s_channel == 'email'
    s_queue = 'email_queued_at' if b_email else 'webhook_queued_at'
    s_script = 'notify_email.php' if b_email else 'notify_webhook.php'
    b_enabled = d_config.get('email_enabled' if b_email else 'webhook_enabled')
    s_destination = d_config.get('email_to' if b_email else 'webhook_url')
    if not Path(s_database).is_file() or b_enabled is None:
        return False

    with Path(f'{s_database}.{s_channel}.lock').open('a') as o_lock:
        try:
            fcntl.flock(o_lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return False

        with closing(sqlite3.connect(s_database, timeout=5)) as o_database:
            o_database.row_factory = sqlite3.Row
            set_columns = {o_column['name'] for o_column in o_database.execute('PRAGMA table_info(devices)')}
            if s_queue not in set_columns:
                return False
            if not b_enabled:
                if o_database.execute(f'SELECT 1 FROM devices WHERE {s_queue} IS NOT NULL LIMIT 1').fetchone():
                    with o_database:
                        o_database.execute(f'UPDATE devices SET {s_queue} = NULL WHERE {s_queue} IS NOT NULL')
                return False
            if not d_config['enabled'] or not s_destination:
                return False

            # Název sloupce se vybírá z pevných literálů podle interního kanálu.
            s_known_select = ', is_known' if 'is_known' in set_columns else ''
            l_rows = [dict(o_row) for o_row in o_database.execute(f"""
                SELECT mac, substr(ip, 1, 64) AS ip, substr(hostname, 1, 1024) AS hostname,
                       substr(vendor, 1, 256) AS vendor, substr(vlan, 1, 256) AS vlan,
                       substr(first_seen, 1, 64) AS first_seen, substr(last_seen, 1, 64) AS last_seen,
                       is_active, notified, 1 AS notification_pending,
                       substr(custom_hostname, 1, 1024) AS custom_hostname,
                       {s_queue} AS queued_at {s_known_select}
                FROM devices WHERE {s_queue} IS NOT NULL
                ORDER BY {s_queue}, mac LIMIT ?
            """, (I_MAX_BATCH_ROWS,))]
            if b_email:
                b_use_max = d_config.get('email_batch_mode', 'bounded') == 'bounded'
                i_max_ms = d_config['email_batch_max'] * 1000 if b_use_max else None
                i_wait_ms = d_config['email_batch_wait'] * 1000
            else:
                i_max_ms = None
                i_wait_ms = 0
            l_batch, i_due = select_batch(l_rows, i_wait_ms, i_max_ms)
            if not l_batch or i_now < i_due:
                return False

            l_payload = [
                {s_key: x_value for s_key, x_value in d_row.items() if s_key != 'queued_at'}
                for d_row in l_batch
            ]
            o_result = subprocess.run(
                ['/usr/local/bin/php', f'/usr/local/opnsense/scripts/OPNsense/DeviceMonitor/{s_script}', '--batch-stdin'],
                input=json.dumps(l_payload), capture_output=True, text=True, timeout=120,
                pass_fds=(o_lock.fileno(),)
            )
            d_result = json.loads(o_result.stdout)
            if not isinstance(d_result, dict):
                raise ValueError('Invalid notification transport response')
            if o_result.returncode != 0 or d_result.get('result') != 'sent':
                o_log(f"{s_channel} batch delivery failed: {d_result.get('message', 'Unknown transport error')}")
                return True

            # Odstraň jen právě odeslané položky. Nové nálezy během odesílání zůstanou ve frontě.
            with o_database:
                o_database.executemany(
                    f'UPDATE devices SET {s_queue} = NULL WHERE mac = ? AND {s_queue} = ?',
                    ((d_row['mac'], d_row['queued_at']) for d_row in l_batch)
                )
            return False


def run_worker(o_stop, o_load_config, s_database, o_log, s_channel):
    """Obsluhuje termíny nezávisle na načítání Hostwatch a opakuje neúspěšná odeslání."""
    f_retry_at = 0
    while not o_stop.is_set():
        try:
            d_config = o_load_config()
            if time.monotonic() >= f_retry_at or d_config.get(f'{s_channel}_enabled') is False:
                if deliver_batch(s_database, d_config, time.time_ns() // 1_000_000, o_log, s_channel):
                    f_retry_at = time.monotonic() + 60
        except (OSError, sqlite3.Error, subprocess.SubprocessError, ValueError) as o_error:
            o_log(f"{s_channel} queue error: {o_error}")
            f_retry_at = time.monotonic() + 60
        o_stop.wait(1)
