#!/bin/bash

# WSL Setup Script - Main Orchestrator
# This script runs all setup steps in the correct order

set -e  # Exit on error

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration
source "${SCRIPT_DIR}/config.sh"

#############################################
# HELPER FUNCTIONS
#############################################

log_info() {
    echo -e "${COLOR_CYAN}[INFO]${COLOR_RESET} $1" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $1" | tee -a "${LOG_FILE}"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1" | tee -a "${LOG_FILE}"
}

print_banner() {
    clear
    echo -e "${COLOR_BOLD}${COLOR_BLUE}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║                                                ║"
    echo "║           WSL Setup Script v1.0                ║"
    echo "║                                                ║"
    echo "║  Automated setup for Debian/Ubuntu on WSL      ║"
    echo "║                                                ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${COLOR_RESET}"
    echo ""
}

print_step() {
    local step=$1
    local total=$2
    local desc=$3

    echo ""
    echo -e "${COLOR_BOLD}${COLOR_CYAN}[Step ${step}/${total}]${COLOR_RESET} ${COLOR_BOLD}${desc}${COLOR_RESET}"
    echo -e "${COLOR_CYAN}$(printf '=%.0s' {1..50})${COLOR_RESET}"
    echo ""
}

confirm_action() {
    local message=$1

    echo -e "${COLOR_YELLOW}${message}${COLOR_RESET}"
    read -p "Continue? (y/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "Setup cancelled by user"
        exit 0
    fi
}

run_script() {
    local script=$1
    local script_path="${SCRIPT_DIR}/${script}"

    if [ ! -f "${script_path}" ]; then
        log_error "Script not found: ${script_path}"
        return 1
    fi

    log_info "Running ${script}..."
    bash "${script_path}"

    if [ $? -ne 0 ]; then
        log_error "Script failed: ${script}"
        return 1
    fi

    log_success "Script completed: ${script}"
    return 0
}

#############################################
# SYSTEM CHECKS
#############################################

check_requirements() {
    log_info "Checking system requirements..."

    # Check if running on WSL
    if ! grep -qi microsoft /proc/version; then
        log_error "This script is designed to run on WSL (Windows Subsystem for Linux)"
        exit 1
    fi

    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        log_error "Please do not run this script as root (don't use sudo)"
        exit 1
    fi

    # Check if script directory exists
    if [ ! -d "${SCRIPT_DIR}/scripts" ]; then
        log_error "Scripts directory not found: ${SCRIPT_DIR}/scripts"
        exit 1
    fi

    # Check if files directory exists
    if [ ! -d "${SCRIPT_DIR}/files" ]; then
        log_error "Files directory not found: ${SCRIPT_DIR}/files"
        exit 1
    fi

    log_success "System requirements check passed"
}

#############################################
# MAIN EXECUTION
#############################################

main() {
    # Print banner
    print_banner

    # Initialize log file
    echo "=== WSL Setup Started at $(date) ===" > "${LOG_FILE}"

    log_info "Detected distribution: ${DISTRO_ID} ${DISTRO_VERSION_CODENAME}"
    log_info "Target user: ${TARGET_USER}"
    log_info "Target home: ${TARGET_HOME}"
    log_info "Log file: ${LOG_FILE}"
    echo ""

    # Check requirements
    check_requirements
    echo ""

    # Confirm before starting
    confirm_action "This script will install packages and configure your WSL environment."

    # Step 1: Install packages
    print_step 1 4 "Installing Packages"
    if ! run_script "scripts/install-packages.sh"; then
        log_error "Package installation failed"
        exit 1
    fi

    # Step 2: Configure mount
    print_step 2 4 "Configuring Mount Settings"
    if ! run_script "scripts/configure-mount.sh"; then
        log_error "Mount configuration failed"
        exit 1
    fi

    # Step 3: Setup dotfiles
    print_step 3 4 "Setting Up Dotfiles"
    if ! run_script "scripts/setup-dotfiles.sh"; then
        log_error "Dotfiles setup failed"
        exit 1
    fi

    # Step 4: Setup Docker credentials (optional)
    echo ""
    echo -e "${COLOR_YELLOW}Optional: Configure Docker credential storage with GPG${COLOR_RESET}"
    echo "This will securely store your Docker credentials and eliminate the warning about"
    echo "storing passwords unencrypted in config.json."
    echo ""
    read -p "Do you want to setup Docker credentials now? (y/N): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step 4 4 "Setting Up Docker Credentials"
        if ! run_script "scripts/setup-docker-credentials.sh"; then
            log_warn "Docker credentials setup skipped or failed"
            log_info "You can run it later with: make setup-docker-credentials"
        fi
    else
        log_info "Docker credentials setup skipped"
        log_info "You can run it later with: make setup-docker-credentials"
    fi

    # Print completion message
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_GREEN}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║                                                ║"
    echo "║            Setup Complete! 🎉                  ║"
    echo "║                                                ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${COLOR_RESET}"
    echo ""

    # Next steps
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Next Steps:${COLOR_RESET}"
    echo ""
    echo "1. ${COLOR_YELLOW}Restart WSL${COLOR_RESET} (required for mount configuration):"
    echo "   ${COLOR_CYAN}wsl --shutdown${COLOR_RESET} (run from Windows PowerShell)"
    echo ""
    echo "2. ${COLOR_YELLOW}Reload your shell configuration:${COLOR_RESET}"
    echo "   ${COLOR_CYAN}source ~/.bashrc${COLOR_RESET}"
    echo ""
    echo "3. ${COLOR_YELLOW}Verify installations:${COLOR_RESET}"
    echo "   - Docker: ${COLOR_CYAN}docker --version${COLOR_RESET}"
    echo "   - Node: ${COLOR_CYAN}node --version${COLOR_RESET}"
    echo "   - Bun: ${COLOR_CYAN}bun --version${COLOR_RESET}"
    echo "   - Claude: ${COLOR_CYAN}claude --version${COLOR_RESET}"
    echo ""

    log_info "Setup completed successfully at $(date)"
    log_info "Full log available at: ${LOG_FILE}"
}

# Run main function
main "$@"
