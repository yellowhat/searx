#!/bin/sh
# Startup script

PORT=${PORT:-8080}

echo "[INFO] Copy settings.yaml to /tmp"
cp "$SEARXNG_SETTINGS_PATH" /tmp/settings.yaml

export SEARXNG_SETTINGS_PATH=/tmp/settings.yaml

echo "[INFO] Change ultrasecretkey in $SEARXNG_SETTINGS_PATH"
sed -e "s|ultrasecretkey|$(hexdump -n 32 -e '32/1 "%02x"' /dev/urandom)|g" \
    -i "$SEARXNG_SETTINGS_PATH"

echo "[INFO] Starting granian on port: $PORT"
exec granian \
    --process-name searxng \
    --interface wsgi \
    --no-ws \
    --loop uvloop \
    --blocking-threads 4 \
    --blocking-threads-idle-timeout 300 \
    --workers-kill-timeout 30 \
    --host "0.0.0.0" \
    --port "$PORT" \
    searx.webapp:app
