#!/usr/bin/env bash
# Redeploy koyeb service
set -euo pipefail

id=$(
    curl \
        --silent \
        --header "Authorization: Bearer $KOYEB_API_KEY" \
        https://app.koyeb.com/v1/services \
    | jq -r .services[0].id
)

curl \
    --silent \
    --request POST \
    --header "Authorization: Bearer $KOYEB_API_KEY" \
    "https://app.koyeb.com/v1/services/${id}/redeploy" | jq .
