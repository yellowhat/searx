IMAGE := "searx:local"
POD_FILE := "searx.yaml"

set shell := ["bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

@_:
    just --list --unsorted

# Build container
build:
    podman build --tag "{{ IMAGE }}" .

# Stop pod
stop:
    (cd local && podman kube play "{{ POD_FILE }}" --force --down)

# Build, run pod and show searx logs
run: build stop
    (cd local && podman kube play "{{ POD_FILE }}")
    podman logs --follow searx-searx

# Build, run pod and test
test: build stop
    (cd local && podman kube play "{{ POD_FILE }}")
    bash tests/test.sh
