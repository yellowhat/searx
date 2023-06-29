#!/bin/sh

export SEARX_VERSION=$(python3 -c "import six; import searx.version; six.print_(searx.version.VERSION_STRING)" 2>/dev/null)
printf '[INFO] Searx version: %s\n\n' "${SEARX_VERSION}"

echo "[INFO] Change ultrasecretkey"
sed -e "s/ultrasecretkey/$(openssl rand -hex 32)/g" \
    -i searx/settings.yml

# Start uwsgi
uwsgi --master --http-socket "0.0.0.0:8080" "uwsgi.ini"
