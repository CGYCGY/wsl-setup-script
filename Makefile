# WSL Setup Script Makefile
# Simplifies common setup tasks

.PHONY: help config check permissions setup install-packages configure-mount setup-dotfiles setup-docker-credentials show-config lint clean validate-config

# Default target
.DEFAULT_GOAL := help

#############################################
# HELP
#############################################

help:  ## Show this help message
	@echo ""
	@echo "WSL Setup Script - Available Commands"
	@echo "======================================"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Quick Start:"
	@echo "  1. make config          # Create your config.sh"
	@echo "  2. Edit config.sh       # Customize your settings"
	@echo "  3. make check           # Verify prerequisites"
	@echo "  4. make setup           # Run full setup"
	@echo ""

#############################################
# CONFIGURATION
#############################################

config:  ## Create config.sh from config.sh.example
	@if [ -f config.sh ]; then \
		echo -e "\033[33m⚠️  config.sh already exists. Remove it first if you want to recreate it.\033[0m"; \
		exit 1; \
	else \
		cp config.sh.example config.sh; \
		echo -e "\033[32m✅ Created config.sh from config.sh.example\033[0m"; \
		echo -e "\033[36m📝 Please edit config.sh and update:\033[0m"; \
		echo "   - TARGET_USER (your WSL username)"; \
		echo "   - VHDX_PATH (your VHDX file location)"; \
		echo "   - Other settings as needed"; \
	fi

validate-config:  ## Validate config.sh has no syntax errors
	@if [ ! -f config.sh ]; then \
		echo -e "\033[31m❌ config.sh not found. Run 'make config' first.\033[0m"; \
		exit 1; \
	fi
	@echo -e "\033[36m🔍 Validating config.sh syntax...\033[0m"
	@bash -n config.sh && echo -e "\033[32m✅ config.sh syntax is valid\033[0m"

show-config:  ## Display current configuration values
	@if [ ! -f config.sh ]; then \
		echo -e "\033[31m❌ config.sh not found. Run 'make config' first.\033[0m"; \
		exit 1; \
	fi
	@echo ""
	@echo "Current Configuration:"
	@echo "====================="
	@bash -c 'source config.sh && \
		echo "Target User:          $$TARGET_USER" && \
		echo "Target Home:          $$TARGET_HOME" && \
		echo "VHDX Path:            $$VHDX_PATH" && \
		echo "VHDX Mount Name:      $$VHDX_MOUNT_NAME" && \
		echo "Custom Mount Point:   $$CUSTOM_MOUNT_POINT" && \
		echo "WSL.exe Path:         $$WSL_EXE_PATH" && \
		echo "Mount Script Path:    $$MOUNT_SCRIPT_PATH" && \
		echo "WSL Automount:        $$WSL_AUTOMOUNT_ENABLED" && \
		echo "Chrome Install Path:  $$CHROME_INSTALL_PATH" && \
		echo "Enable Backups:       $$ENABLE_BACKUPS"'
	@echo ""

#############################################
# VALIDATION
#############################################

check:  ## Validate prerequisites before setup
	@echo -e "\033[36m🔍 Checking prerequisites...\033[0m"
	@echo ""
	@# Check if running on WSL
	@if ! grep -qi microsoft /proc/version; then \
		echo -e "\033[31m❌ This script must run on WSL (Windows Subsystem for Linux)\033[0m"; \
		exit 1; \
	else \
		echo -e "\033[32m✅ Running on WSL\033[0m"; \
	fi
	@# Check if running as root
	@if [ "$$(id -u)" -eq 0 ]; then \
		echo -e "\033[31m❌ Do not run as root (don't use sudo)\033[0m"; \
		exit 1; \
	else \
		echo -e "\033[32m✅ Not running as root\033[0m"; \
	fi
	@# Check if config.sh exists
	@if [ ! -f config.sh ]; then \
		echo -e "\033[31m❌ config.sh not found. Run 'make config' first.\033[0m"; \
		exit 1; \
	else \
		echo -e "\033[32m✅ config.sh exists\033[0m"; \
	fi
	@# Check if scripts directory exists
	@if [ ! -d scripts ]; then \
		echo -e "\033[31m❌ scripts/ directory not found\033[0m"; \
		exit 1; \
	else \
		echo -e "\033[32m✅ scripts/ directory exists\033[0m"; \
	fi
	@# Check if files directory exists
	@if [ ! -d files ]; then \
		echo -e "\033[31m❌ files/ directory not found\033[0m"; \
		exit 1; \
	else \
		echo -e "\033[32m✅ files/ directory exists\033[0m"; \
	fi
	@echo ""
	@echo -e "\033[32m✅ All prerequisites met! Ready to run setup.\033[0m"
	@echo ""

#############################################
# PERMISSIONS
#############################################

permissions:  ## Fix executable permissions on all shell scripts
	@echo -e "\033[36m🔧 Setting executable permissions on shell scripts...\033[0m"
	@find . -type f -name "*.sh" -exec chmod +x {} \;
	@echo -e "\033[32m✅ Permissions updated\033[0m"

#############################################
# SETUP COMMANDS
#############################################

setup:  ## Run full setup (all 4 steps)
	@if [ ! -f config.sh ]; then \
		echo -e "\033[31m❌ config.sh not found. Run 'make config' first.\033[0m"; \
		exit 1; \
	fi
	@echo -e "\033[36m🚀 Running full WSL setup...\033[0m"
	@./setup-wsl.sh

install-packages:  ## Step 1: Install packages only
	@if [ ! -f config.sh ]; then \
		echo -e "\033[31m❌ config.sh not found. Run 'make config' first.\033[0m"; \
		exit 1; \
	fi
	@echo -e "\033[36m📦 Installing packages...\033[0m"
	@./scripts/install-packages.sh

configure-mount:  ## Step 2: Configure mount settings only
	@if [ ! -f config.sh ]; then \
		echo -e "\033[31m❌ config.sh not found. Run 'make config' first.\033[0m"; \
		exit 1; \
	fi
	@echo -e "\033[36m💾 Configuring mount settings...\033[0m"
	@./scripts/configure-mount.sh

setup-dotfiles:  ## Step 3: Setup dotfiles only
	@if [ ! -f config.sh ]; then \
		echo -e "\033[31m❌ config.sh not found. Run 'make config' first.\033[0m"; \
		exit 1; \
	fi
	@echo -e "\033[36m📝 Setting up dotfiles...\033[0m"
	@./scripts/setup-dotfiles.sh

setup-docker-credentials:  ## Step 4: Setup Docker credential storage (optional)
	@if [ ! -f config.sh ]; then \
		echo -e "\033[31m❌ config.sh not found. Run 'make config' first.\033[0m"; \
		exit 1; \
	fi
	@echo -e "\033[36m🔐 Setting up Docker credentials...\033[0m"
	@./scripts/setup-docker-credentials.sh

#############################################
# UTILITIES
#############################################

lint:  ## Run shellcheck on all shell scripts
	@if ! command -v shellcheck >/dev/null 2>&1; then \
		echo -e "\033[31m❌ shellcheck not found. Install it with: sudo apt install shellcheck\033[0m"; \
		exit 1; \
	fi
	@echo -e "\033[36m🔍 Running shellcheck on all scripts...\033[0m"
	@find . -type f -name "*.sh" -exec shellcheck {} \; && echo -e "\033[32m✅ All scripts passed shellcheck\033[0m"

clean:  ## Remove generated files (logs and backups)
	@echo -e "\033[36m🧹 Cleaning up generated files...\033[0m"
	@rm -f setup.log
	@find . -type f -name "*.backup.*" -delete
	@echo -e "\033[32m✅ Cleanup complete\033[0m"
