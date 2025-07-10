#!/usr/bin/env bash
#
set -euo pipefail

# Wait for startup
timeout 60s sh -c "until curl http://localhost:8080/healthz; do sleep 1; done"

# Make a search
curl http://localhost:8080/search?q=searxng