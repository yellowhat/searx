#!/bin/sh

PORT=${PORT:-8080}

export SEARX_VERSION=$(python3 -c "import six; import searx.version; six.print_(searx.version.VERSION_STRING)" 2>/dev/null)
echo "[INFO] Searx version: ${SEARX_VERSION}"

echo "[INFO] Change ultrasecretkey"
sed -e "s/ultrasecretkey/$(openssl rand -hex 32)/g" \
    -i /etc/searxng/settings.yml

echo "[INFO] Starting uwsgi on port: $PORT"
uwsgi --master --http-socket "0.0.0.0:$PORT" "uwsgi.ini"
