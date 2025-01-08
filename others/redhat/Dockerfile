FROM alpine:3.21.1

EXPOSE 8080
VOLUME /etc/searxng
VOLUME /var/log/uwsgi

ENV INSTANCE_NAME=searxng \
    SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml \
    UWSGI_SETTINGS_PATH=/etc/searxng/uwsgi.ini \
    CWD=/usr/local/searxng

WORKDIR $CWD

RUN adduser -u 977 -D -h "$CWD" -s /bin/sh searxng

RUN apk upgrade --no-cache \
 && apk add --no-cache --virtual build-dependencies \
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
 && pip3 install --upgrade pip \
 && pip3 install --no-cache -r requirements.txt \
 && apk del build-dependencies \
 && rm -rf .git /root/.cache

COPY settings.yml searx/settings.yml
COPY uwsgi.ini uwsgi.ini
COPY docker-entrypoint.sh docker-entrypoint.sh

RUN sed \
    -e "s/ultrasecretkey/$(openssl rand -hex 32)/g" \
    -i searx/settings.yml

RUN python3 -m compileall -q searx \
 && find searx/static -a \( -name "*.html" -o -name "*.css" -o -name "*.js" \
        -o -name "*.svg" -o -name "*.ttf" -o -name "*.eot" \) \
        -type f -exec gzip -9 -k {} \+ -exec brotli --best {} \+

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/searxng/docker-entrypoint.sh"]
