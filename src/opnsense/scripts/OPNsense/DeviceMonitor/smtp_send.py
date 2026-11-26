#!/usr/local/bin/python3

# Předpony: d = slovník, i = celé číslo, l = seznam, o = objekt, s = řetězec, x = hodnota proměnlivého typu.
# U konstant jsou tytéž předpony uvedené velkým písmenem.
# Historie: 2.4.16 – kontrola uloženého nastavení SMTP.
# 2.3.7 – sjednocení typových předpon proměnných.

"""Direct SMTP transport for OPNsense Device Monitor.

Uses only Python standard-library modules. Configuration is read from the
Device Monitor JSON config. Message data is accepted as JSON on stdin so SMTP
credentials never appear in the process command line.
"""

import json
import os
import smtplib
import socket
import ssl
import sys
from email.charset import QP, Charset
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.utils import formataddr, getaddresses

from runtime_config import read_runtime_config

S_CONFIG_FILE = "/var/db/devicemonitor/config.json"
D_SMTP_FIELDS = {
    'smtp_host': '', 'smtp_port': 587, 'smtp_encryption': '', 'smtp_username': '',
    'smtp_password': '', 'email_from': '', 'email_to': '',
}


def fail(x_message, i_exit_code=1):
    print(json.dumps({"result": "failed", "message": str(x_message)}, ensure_ascii=False))
    raise SystemExit(i_exit_code)


def load_config():
    try:
        d_data = read_runtime_config(S_CONFIG_FILE, D_SMTP_FIELDS)
    except FileNotFoundError:
        fail(f"Configuration file not found: {S_CONFIG_FILE}")
    except (OSError, ValueError) as o_error:
        fail(f"Cannot read SMTP configuration: {o_error}")
    return d_data


def parse_recipients(x_value):
    # Support a single address as before, while also accepting comma/semicolon
    # separated recipients for direct SMTP.
    s_raw = str(x_value or "").replace(";", ",")
    l_recipients = [s_addr.strip() for _, s_addr in getaddresses([s_raw]) if s_addr.strip()]
    if not l_recipients:
        fail("No valid recipient email address configured")
    return l_recipients


def main():
    d_config = load_config()

    try:
        d_payload = json.load(sys.stdin)
    except (json.JSONDecodeError, UnicodeDecodeError) as o_error:
        fail(f"Invalid message payload: {o_error}")

    s_host = str(d_config.get("smtp_host", "")).strip()
    try:
        i_port = int(d_config.get("smtp_port", 587))
    except (TypeError, ValueError):
        fail("Invalid SMTP port")

    s_encryption = str(d_config.get("smtp_encryption", "starttls")).strip().lower()
    s_username = str(d_config.get("smtp_username", "")).strip()
    s_password = str(d_config.get("smtp_password", ""))
    s_mail_from = str(d_config.get("email_from", "devicemonitor@opnsense.local")).strip()
    l_recipients = parse_recipients(d_config.get("email_to", ""))

    if not s_host:
        fail("SMTP server is not configured")
    if i_port < 1 or i_port > 65535:
        fail("SMTP port must be between 1 and 65535")
    if s_encryption not in {"none", "starttls", "ssl"}:
        fail("Invalid SMTP encryption mode")
    if not s_mail_from:
        fail("Sender email address is not configured")

    s_subject = str(d_payload.get("subject", "OPNsense Device Monitor"))
    s_html_body = str(d_payload.get("html", ""))
    s_text_body = str(d_payload.get("text", "OPNsense Device Monitor notification"))

    o_mime_message = MIMEMultipart("alternative")
    o_mime_message["Subject"] = s_subject
    o_mime_message["From"] = formataddr((socket.gethostname(), s_mail_from))
    o_mime_message["To"] = ", ".join(l_recipients)

    # Follow the same robust MIME approach used by arp/ndp-logging: provide
    # both plain-text and HTML alternatives and force quoted-printable UTF-8.
    o_qp_charset = Charset("utf-8")
    o_qp_charset.body_encoding = QP
    o_mime_message.attach(MIMEText(s_text_body, "plain", o_qp_charset))
    o_mime_message.attach(MIMEText(s_html_body, "html", o_qp_charset))

    o_context = ssl.create_default_context()
    o_server = None
    try:
        if s_encryption == "ssl":
            o_server = smtplib.SMTP_SSL(s_host, i_port, timeout=10, context=o_context)
        else:
            o_server = smtplib.SMTP(s_host, i_port, timeout=10)
            o_server.ehlo()
            if s_encryption == "starttls":
                o_server.starttls(context=o_context)
                o_server.ehlo()

        if s_username:
            o_server.login(s_username, s_password)

        o_server.sendmail(s_mail_from, l_recipients, o_mime_message.as_string())
        print(json.dumps({"result": "sent", "message": "Email sent", "transport": "smtp"}))
    except Exception as o_error:
        fail(o_error)
    finally:
        if o_server is not None:
            try:
                o_server.quit()
            except Exception:
                pass


if __name__ == "__main__":
    main()
