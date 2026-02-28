INSTALL_DIR := $(HOME)/sound2transcript
BIN_INSTALL  := /usr/local/bin

.PHONY: install download-model lint test check install-launchd uninstall help

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

install: ## Create directories, copy scripts, install symlinks
	@echo "Installing sound2transcript..."
	@mkdir -p $(INSTALL_DIR)/{models,recordings,transcripts,logs,config,bin}
	@if [ ! -f $(INSTALL_DIR)/config/config.env ]; then \
		cp config/config.env.template $(INSTALL_DIR)/config/config.env; \
		echo "Config created at $(INSTALL_DIR)/config/config.env"; \
	else \
		echo "Config already exists, skipping."; \
	fi
	@cp bin/stream-transcribe $(INSTALL_DIR)/bin/stream-transcribe
	@cp bin/gc $(INSTALL_DIR)/bin/gc
	@chmod +x $(INSTALL_DIR)/bin/stream-transcribe $(INSTALL_DIR)/bin/gc
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

uninstall: ## Remove symlinks and launchd scheduler
	@-launchctl unload $(HOME)/Library/LaunchAgents/com.sound2transcript.gc.plist 2>/dev/null
	@-rm -f $(HOME)/Library/LaunchAgents/com.sound2transcript.gc.plist
	@-rm -f $(BIN_INSTALL)/stream-transcribe $(BIN_INSTALL)/gc
	@echo "Uninstalled. Data at $(INSTALL_DIR) was NOT removed."
	@echo "Remove manually: rm -rf $(INSTALL_DIR)"
