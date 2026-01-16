FROM ghcr.io/astral-sh/uv:0.9.26-python3.13-alpine

ENV CWD=/usr/local/searxng
ENV SEARXNG_SETTINGS_PATH=${CWD}/settings.yml

# Compile Python files to .pyc bytecode files.
# This takes a little longer to install (part of the build process),
# but often speeds up the application's startup time in the container.
ENV UV_COMPILE_BYTECODE=1

WORKDIR $CWD

COPY searxng $CWD
COPY patch /tmp/

RUN apk add --no-cache \
        brotli \
        ca-certificates \
        git \
 && git apply /tmp/*.patch \
 && uv pip install \
        --system \
        --no-cache \
        --requirement requirements.txt \
        --requirement requirements-server.txt \
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
