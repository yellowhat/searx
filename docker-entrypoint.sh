#!/bin/sh
# Startup script

PORT=${PORT:-8080}

echo "[INFO] Change ultrasecretkey in $SEARXNG_SETTINGS_PATH"
sed -e "s/ultrasecretkey/$(hexdump -n 32 -e '32/1 "%02x"' /dev/urandom)/g" \
    -i "$SEARXNG_SETTINGS_PATH"

echo "[INFO] Starting uwsgi on port: $PORT"
uwsgi --master --http-socket "0.0.0.0:$PORT" "$UWSGI_SETTINGS_PATH"
