FROM docker.io/alpine:3.20.3

ENV CWD=/usr/local/searxng
ENV SEARXNG_SETTINGS_PATH=${CWD}/settings.yml
ENV UWSGI_SETTINGS_PATH=${CWD}/uwsgi.ini

WORKDIR $CWD

RUN adduser -u 977 -D -h "$CWD" -s /bin/sh searxng

COPY patch /tmp/

RUN apk add --no-cache \
        brotli \
        ca-certificates \
        git \
        py3-pip \
        python3 \
        uwsgi \
        uwsgi-python3 \
 && git clone --depth 1 https://github.com/searxng/searxng . \
 && chown -R searxng:searxng . \
 && git config --global --add safe.directory "$CWD" \
 && git apply /tmp/*.patch \
 && pip3 install --break-system-packages --no-cache --requirement requirements.txt \
 && rm -rf /root/.cache /tmp/*

COPY settings.yml $SEARXNG_SETTINGS_PATH
COPY uwsgi.ini $UWSGI_SETTINGS_PATH
COPY docker-entrypoint.sh ./

RUN python3 -m compileall -q searx \
 && find searx/static -a \( -name "*.html" -o -name "*.css" -o -name "*.js" \
        -o -name "*.svg" -o -name "*.ttf" -o -name "*.eot" \) \
        -type f -exec gzip -9 -k {} \+ -exec brotli --best {} \+

ENTRYPOINT ["/usr/local/searxng/docker-entrypoint.sh"]
