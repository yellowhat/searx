FROM docker.io/alpine:3.21.1

EXPOSE 8080
VOLUME /etc/searxng
VOLUME /var/log/uwsgi

ENV INSTANCE_NAME=searxng \
    SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml \
    UWSGI_SETTINGS_PATH=/etc/searxng/uwsgi.ini \
    CWD=/usr/local/searxng

WORKDIR $CWD

RUN adduser -u 977 -D -h "$CWD" -s /bin/sh searxng

RUN apk add --no-cache --virtual build-dependencies \
        build-base \
        py3-setuptools \
        python3-dev \
        libffi-dev \
        libxslt-dev \
        libxml2-dev \
        openssl-dev \
        tar \
 && apk add --no-cache \
        ca-certificates \
        git \
        su-exec \
        python3 \
        py3-pip \
        libxml2 \
        libxslt \
        openssl \
        tini \
        uwsgi \
        uwsgi-python3 \
        brotli \
 && git clone --depth 1 https://github.com/searxng/searxng . \
 && chown -R searxng:searxng . \
 && git config --global --add safe.directory "$CWD" \
 && pip3 install --break-system-packages --upgrade pip \
 && pip3 install --break-system-packages --no-cache -r requirements.txt \
 && apk del build-dependencies \
 && rm -rf /root/.cache

COPY settings.yml /etc/searxng/settings.yml
COPY uwsgi.ini uwsgi.ini
COPY docker-entrypoint.sh docker-entrypoint.sh

RUN python3 -m compileall -q searx \
 && find searx/static -a \( -name "*.html" -o -name "*.css" -o -name "*.js" \
        -o -name "*.svg" -o -name "*.ttf" -o -name "*.eot" \) \
        -type f -exec gzip -9 -k {} \+ -exec brotli --best {} \+ \
  # Avoid warning about file not found
 && cp searx/limiter.toml /etc/searxng/limiter.toml

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/searxng/docker-entrypoint.sh"]
