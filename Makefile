IMAGE         := searx:local
.DEFAULT_GOAL := help

.PHONY: build
build: ## Build container
	@echo "[INFO] Entering $(IMAGE) container..."
	podman build --tag "$(IMAGE)" .

.PHONY: run
run: build ## Build and run  container
	podman run \
		--interactive \
		--tty \
		--rm \
		--publish 8080:8080 \
		"$(IMAGE)"

.PHONY: help
help: ## Makefile Help Page
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[\/\%a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-21s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST) 2>/dev/null
