#!/bin/sh
# Startup script

PORT=${PORT:-8080}

echo "[INFO] Change ultrasecretkey"
sed -e "s/ultrasecretkey/$(openssl rand -hex 32)/g" \
    -i /etc/searxng/settings.yml

echo "[INFO] Starting uwsgi on port: $PORT"
uwsgi --master --http-socket "0.0.0.0:$PORT" "uwsgi.ini"
