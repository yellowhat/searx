FROM ghcr.io/astral-sh/uv:0.7.19-python3.13-alpine

ENV CWD=/usr/local/searxng
ENV SEARXNG_SETTINGS_PATH=${CWD}/settings.yml

WORKDIR $CWD

COPY patch /tmp/

RUN apk add --no-cache \
        brotli \
        ca-certificates \
        git \
 && git clone --depth 1 https://github.com/searxng/searxng . \
 && git config --global --add safe.directory "$CWD" \
 && git apply /tmp/*.patch \
 && uv pip install --system --no-cache --requirement requirements.txt \
 && uv pip install --system --no-cache granian==2.4.1 \
 && rm -rf /root/.cache /tmp/*

COPY settings.yml $SEARXNG_SETTINGS_PATH
COPY --chmod=755 docker-entrypoint.sh ./

RUN python3 -m compileall -q searx \
 && find searx/static -a \( \
        -name "*.html" -o \
        -name "*.css" -o \
        -name "*.js" -o \
        -name "*.svg" -o \
        -name "*.ttf" -o \
        -name "*.eot" \
    \) -type f -exec gzip -9 -k {} \+ -exec brotli --best {} \+

ENTRYPOINT ["/usr/local/searxng/docker-entrypoint.sh"]
