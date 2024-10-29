#!/bin/sh

export SEARX_VERSION=$(python3 -c "import six; import searx.version; six.print_(searx.version.VERSION_STRING)" 2>/dev/null)
printf '[INFO ]searx version: %s\n\n' "${SEARX_VERSION}"

# Start uwsgi
uwsgi --uid "$(id -u)" --gid "$(id -g)" --master --http-socket "0.0.0.0:8080" "uwsgi.ini"
