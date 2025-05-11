POD_FILE := pod.yaml
IMAGE    := searx:local

.DEFAULT_GOAL := help

.PHONY: build
build: ## Build container
	@echo "[INFO] Entering $(IMAGE) container..."
	podman build --tag "$(IMAGE)" .

.PHONY: stop
stop: ## Stop pod
	podman kube play "$(POD_FILE)" --force --down

.PHONY: run
run: build stop ## Build and run pod
	podman kube play "$(POD_FILE)"
	podman logs --follow searx-searx

.PHONY: help
help: ## Makefile Help Page
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[\/\%a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-21s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST) 2>/dev/null
