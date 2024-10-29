#!/usr/bin/env python
"""Restart mogenius service"""

from os import environ
from requests import get, post

MOGENIUS_EMAIL = environ["MOGENIUS_EMAIL"]
MOGENIUS_PASSWORD = environ["MOGENIUS_PASSWORD"]
MOGENIUS_NAMESPACE_ID = environ["MOGENIUS_NAMESPACE_ID"]
MOGENIUS_SERVICE_ID = environ["MOGENIUS_SERVICE_ID"]

response = post(
    url="https://api.mogenius.com/auth/login",
    data=f"grant_type=password&email={MOGENIUS_EMAIL}&password={MOGENIUS_PASSWORD}",
    headers={
        "accept": "application/json",
        "Authorization": "Basic OEVvREZMaHpxajRpZkc0N2tnV3l5cXI5QWRRN3ZIRFRqOkFldmdhS2VYYXJ1R245cjh6ZkgyUFh2ZkZpTHdpY0JnTQ==",
        "Content-Type": "application/x-www-form-urlencoded",
        "X-Device": "mogenius_api"
    }
)
accessToken = response.json()["accessToken"]

response = get(
    url=f"https://api.mogenius.com/namespace-service/restart-service/{MOGENIUS_SERVICE_ID}",
    headers={
        "accept": "text/plain",
        "namespace-id": MOGENIUS_NAMESPACE_ID,
        "authorization": f"Bearer {accessToken}",
    },
)

print(response.text)