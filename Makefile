# WSL Setup Script Makefile
# Simplifies common setup tasks

.PHONY: help config check permissions setup install-packages configure-mount setup-dotfiles show-config lint clean validate-config

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
		echo "⚠️  config.sh already exists. Remove it first if you want to recreate it."; \
		exit 1; \
	else \
		cp config.sh.example config.sh; \
		echo "✅ Created config.sh from config.sh.example"; \
		echo "📝 Please edit config.sh and update:"; \
		echo "   - TARGET_USER (your WSL username)"; \
		echo "   - VHDX_PATH (your VHDX file location)"; \
		echo "   - Other settings as needed"; \
	fi

validate-config:  ## Validate config.sh has no syntax errors
	@if [ ! -f config.sh ]; then \
		echo "❌ config.sh not found. Run 'make config' first."; \
		exit 1; \
	fi
	@echo "🔍 Validating config.sh syntax..."
	@bash -n config.sh && echo "✅ config.sh syntax is valid"

show-config:  ## Display current configuration values
	@if [ ! -f config.sh ]; then \
		echo "❌ config.sh not found. Run 'make config' first."; \
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
	@echo "🔍 Checking prerequisites..."
	@echo ""
	@# Check if running on WSL
	@if ! grep -qi microsoft /proc/version; then \
		echo "❌ This script must run on WSL (Windows Subsystem for Linux)"; \
		exit 1; \
	else \
		echo "✅ Running on WSL"; \
	fi
	@# Check if running as root
	@if [ "$$(id -u)" -eq 0 ]; then \
		echo "❌ Do not run as root (don't use sudo)"; \
		exit 1; \
	else \
		echo "✅ Not running as root"; \
	fi
	@# Check if config.sh exists
	@if [ ! -f config.sh ]; then \
		echo "❌ config.sh not found. Run 'make config' first."; \
		exit 1; \
	else \
		echo "✅ config.sh exists"; \
	fi
	@# Check if scripts directory exists
	@if [ ! -d scripts ]; then \
		echo "❌ scripts/ directory not found"; \
		exit 1; \
	else \
		echo "✅ scripts/ directory exists"; \
	fi
	@# Check if files directory exists
	@if [ ! -d files ]; then \
		echo "❌ files/ directory not found"; \
		exit 1; \
	else \
		echo "✅ files/ directory exists"; \
	fi
	@echo ""
	@echo "✅ All prerequisites met! Ready to run setup."
	@echo ""

#############################################
# PERMISSIONS
#############################################

permissions:  ## Fix executable permissions on all shell scripts
	@echo "🔧 Setting executable permissions on shell scripts..."
	@find . -type f -name "*.sh" -exec chmod +x {} \;
	@echo "✅ Permissions updated"

#############################################
# SETUP COMMANDS
#############################################

setup:  ## Run full setup (all 3 steps)
	@if [ ! -f config.sh ]; then \
		echo "❌ config.sh not found. Run 'make config' first."; \
		exit 1; \
	fi
	@echo "🚀 Running full WSL setup..."
	@./setup-wsl.sh

install-packages:  ## Step 1: Install packages only
	@if [ ! -f config.sh ]; then \
		echo "❌ config.sh not found. Run 'make config' first."; \
		exit 1; \
	fi
	@echo "📦 Installing packages..."
	@./scripts/install-packages.sh

configure-mount:  ## Step 2: Configure mount settings only
	@if [ ! -f config.sh ]; then \
		echo "❌ config.sh not found. Run 'make config' first."; \
		exit 1; \
	fi
	@echo "💾 Configuring mount settings..."
	@./scripts/configure-mount.sh

setup-dotfiles:  ## Step 3: Setup dotfiles only
	@if [ ! -f config.sh ]; then \
		echo "❌ config.sh not found. Run 'make config' first."; \
		exit 1; \
	fi
	@echo "📝 Setting up dotfiles..."
	@./scripts/setup-dotfiles.sh

#############################################
# UTILITIES
#############################################

lint:  ## Run shellcheck on all shell scripts
	@if ! command -v shellcheck >/dev/null 2>&1; then \
		echo "❌ shellcheck not found. Install it with: sudo apt install shellcheck"; \
		exit 1; \
	fi
	@echo "🔍 Running shellcheck on all scripts..."
	@find . -type f -name "*.sh" -exec shellcheck {} \; && echo "✅ All scripts passed shellcheck"

clean:  ## Remove generated files (logs and backups)
	@echo "🧹 Cleaning up generated files..."
	@rm -f setup.log
	@find . -type f -name "*.backup.*" -delete
	@echo "✅ Cleanup complete"
