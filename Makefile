VERSION     := $(shell cat VERSION 2>/dev/null || echo "unknown")
INSTALL_DIR := $(HOME)/sound2transcript
PREFIX      ?= /usr/local
BIN_INSTALL := $(PREFIX)/bin

.PHONY: install download-model download-model-turbo lint test check install-launchd uninstall release help

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

install: ## Create directories, copy scripts, install symlinks
	@echo "Installing sound2transcript v$(VERSION)..."
	@mkdir -p $(INSTALL_DIR)/{models,recordings,transcripts,logs,config,bin}
	@if [ ! -f $(INSTALL_DIR)/config/config.env ]; then \
		cp config/config.env.template $(INSTALL_DIR)/config/config.env; \
		echo "Config created at $(INSTALL_DIR)/config/config.env"; \
	else \
		echo "Config already exists, skipping."; \
	fi
	@cp bin/stream-transcribe $(INSTALL_DIR)/bin/stream-transcribe
	@cp bin/gc $(INSTALL_DIR)/bin/gc
	@cp VERSION $(INSTALL_DIR)/VERSION
	@chmod +x $(INSTALL_DIR)/bin/stream-transcribe $(INSTALL_DIR)/bin/gc
	@mkdir -p $(BIN_INSTALL)
	@ln -sf $(INSTALL_DIR)/bin/stream-transcribe $(BIN_INSTALL)/stream-transcribe
	@ln -sf $(INSTALL_DIR)/bin/gc $(BIN_INSTALL)/gc
	@echo "Done. Next steps:"
	@echo "  1. make download-model   (1.5 GB download)"
	@echo "  2. Edit $(INSTALL_DIR)/config/config.env"
	@echo "  3. See docs/SETUP.md for audio routing"

download-model: ## Download ggml-medium.bin (1.5 GB)
	@echo "Downloading ggml-medium.bin (1.5 GB)..."
	@mkdir -p $(INSTALL_DIR)/models
	@curl -L --progress-bar \
		-o $(INSTALL_DIR)/models/ggml-medium.bin \
		"https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin"
	@echo "Model saved to $(INSTALL_DIR)/models/ggml-medium.bin"

download-model-turbo: ## Download ggml-large-v3-turbo-q5_0.bin (547 MB) - recommended
	@echo "Downloading ggml-large-v3-turbo-q5_0.bin (547 MB)..."
	@echo "This model is 6-8x faster than medium with comparable accuracy. See docs/MODELS.md"
	@mkdir -p $(INSTALL_DIR)/models
	@curl -L --progress-bar \
		-o $(INSTALL_DIR)/models/ggml-large-v3-turbo-q5_0.bin \
		"https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin"
	@echo "Model saved to $(INSTALL_DIR)/models/ggml-large-v3-turbo-q5_0.bin"
	@echo "Update MODEL_PATH in $(INSTALL_DIR)/config/config.env to use it."

install-launchd: ## Install daily GC scheduler (launchd)
	@sed 's|__INSTALL_DIR__|$(INSTALL_DIR)|g' \
		launchd/com.sound2transcript.gc.plist \
		> $(HOME)/Library/LaunchAgents/com.sound2transcript.gc.plist
	@launchctl load $(HOME)/Library/LaunchAgents/com.sound2transcript.gc.plist
	@echo "GC scheduler loaded. Runs daily at 03:30."

lint: ## Run shellcheck and shfmt
	@command -v shellcheck >/dev/null 2>&1 || { echo "Install: brew install shellcheck"; exit 1; }
	@command -v shfmt >/dev/null 2>&1 || { echo "Install: brew install shfmt"; exit 1; }
	shellcheck bin/stream-transcribe bin/gc
	shfmt -d -i 2 -ci bin/stream-transcribe bin/gc

test: ## Run bats tests
	@command -v bats >/dev/null 2>&1 || { echo "Install: brew install bats-core"; exit 1; }
	bats tests/

check: lint test ## Lint + test

release: ## Tag and push a release (usage: make release)
	@if git tag | grep -q "^v$(VERSION)$$"; then \
		echo "ERROR: Tag v$(VERSION) already exists. Bump VERSION first."; \
		exit 1; \
	fi
	git tag -a "v$(VERSION)" -m "Release v$(VERSION)"
	git push origin "v$(VERSION)"
	@echo "Tagged and pushed v$(VERSION)."
	@echo "Next: create GitHub release with 'gh release create v$(VERSION)'"

uninstall: ## Remove symlinks and launchd scheduler
	@-launchctl unload $(HOME)/Library/LaunchAgents/com.sound2transcript.gc.plist 2>/dev/null
	@-rm -f $(HOME)/Library/LaunchAgents/com.sound2transcript.gc.plist
	@-rm -f $(BIN_INSTALL)/stream-transcribe $(BIN_INSTALL)/gc
	@echo "Uninstalled. Data at $(INSTALL_DIR) was NOT removed."
	@echo "Remove manually: rm -rf $(INSTALL_DIR)"
