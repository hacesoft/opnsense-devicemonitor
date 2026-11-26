#!/bin/sh

# Předpona s označuje řetězec nebo cestu.
# Historie: 2.3.7 – sjednocení typových předpon proměnných.

sPidFile="/var/run/devicemonitor.pid"
if [ -f "$sPidFile" ]; then
    sPid=$(cat "$sPidFile")
    if kill -0 "$sPid" 2>/dev/null; then
        echo "running"
        exit 0
    fi
    # Pidfile existuje ale proces neběží - vyčisti
    rm -f "$sPidFile"
fi
echo "stopped"
exit 0
