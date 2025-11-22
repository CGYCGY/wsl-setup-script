#!/bin/bash

# Package Installation Script for WSL
# This script installs all required packages and tools

set -e  # Exit on error

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#############################################
# SYSTEM UPDATE
#############################################

install_system_packages() {
    log_info "Updating system packages..."
    sudo apt update
    sudo apt dist-upgrade -y

    log_info "Installing system packages: ${SYSTEM_PACKAGES[*]}"
    sudo apt install -y "${SYSTEM_PACKAGES[@]}"

    log_success "System packages installed"
}

#############################################
# TAILSCALE
#############################################

install_tailscale() {
    if command_exists tailscale; then
        log_warn "Tailscale already installed, skipping..."
        return 0
    fi

    log_info "Installing Tailscale..."
    curl -fsSL "${TAILSCALE_INSTALL_URL}" | sudo sh
    sudo apt-get install -y tailscale

    log_success "Tailscale installed"
}

#############################################
# DOCKER
#############################################

install_docker() {
    if command_exists docker; then
        log_warn "Docker already installed, skipping..."
        return 0
    fi

    log_info "Installing Docker..."

    # Setup Docker repository
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL "https://download.docker.com/linux/${DISTRO_ID}/gpg" -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add Docker repository (deb822 format)
    log_info "Adding Docker repository using deb822 format..."
    sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/${DISTRO_ID}
Suites: ${DISTRO_VERSION_CODENAME}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    # Install Docker packages
    sudo apt update
    sudo apt install -y "${DOCKER_PACKAGES[@]}"

    # Add user to docker group
    log_info "Adding user ${TARGET_USER} to docker group..."
    sudo usermod -aG "${DOCKER_GROUP}" "${TARGET_USER}"

    log_success "Docker installed (logout/login required for group changes)"
}

#############################################
# CHROME DEPENDENCIES
#############################################

install_chrome_deps() {
    log_info "Installing Chrome for Testing dependencies..."
    sudo apt install -y "${CHROME_DEPENDENCIES[@]}"
    log_success "Chrome dependencies installed"
}

#############################################
# NVM & NODE
#############################################

install_nvm_node() {
    if [ -d "${NVM_DIR}" ]; then
        log_warn "NVM already installed, skipping..."
        return 0
    fi

    log_info "Installing NVM ${NVM_VERSION}..."
    curl -o- "${NVM_INSTALL_URL}" | bash

    # Load NVM
    export NVM_DIR="${NVM_DIR}"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install latest Node.js
    log_info "Installing latest Node.js..."
    nvm install node

    log_success "NVM and Node.js installed"
}

#############################################
# BUN
#############################################

install_bun() {
    if command_exists bun; then
        log_warn "Bun already installed, skipping..."
        return 0
    fi

    log_info "Installing Bun..."
    curl -fsSL "${BUN_INSTALL_URL}" | bash

    # Export Bun paths
    export BUN_INSTALL="${BUN_INSTALL}"
    export PATH="${BUN_INSTALL}/bin:${PATH}"

    log_success "Bun installed"
}

#############################################
# CHROME FOR TESTING
#############################################

install_chrome() {
    if [ -d "${CHROME_INSTALL_PATH}" ] && [ -n "$(ls -A "${CHROME_INSTALL_PATH}" 2>/dev/null)" ]; then
        log_warn "Chrome for Testing already installed at ${CHROME_INSTALL_PATH}, skipping..."
        return 0
    fi

    log_info "Installing Chrome for Testing to ${CHROME_INSTALL_PATH}..."
    npx -y @puppeteer/browsers install chrome@stable --path "${CHROME_INSTALL_PATH}"

    log_success "Chrome for Testing installed"
}

#############################################
# CLAUDE CODE
#############################################

install_claude_code() {
    if command_exists claude; then
        log_warn "Claude Code already installed, skipping..."
        return 0
    fi

    log_info "Installing Claude Code..."
    curl -fsSL "${CLAUDE_CODE_INSTALL_URL}" | bash

    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi

    log_success "Claude Code installed"
}

#############################################
# MAIN EXECUTION
#############################################

main() {
    echo -e "${COLOR_BOLD}${COLOR_BLUE}================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}  WSL Package Installation${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}================================${COLOR_RESET}"
    echo ""

    log_info "Starting package installation for ${DISTRO_ID} ${DISTRO_VERSION_CODENAME}..."
    log_info "Log file: ${LOG_FILE}"
    echo ""

    install_system_packages
    echo ""

    install_tailscale
    echo ""

    install_docker
    echo ""

    install_chrome_deps
    echo ""

    install_nvm_node
    echo ""

    install_bun
    echo ""

    install_chrome
    echo ""

    install_claude_code
    echo ""

    echo -e "${COLOR_BOLD}${COLOR_GREEN}================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}  Installation Complete!${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}================================${COLOR_RESET}"
    echo ""
    log_warn "NOTE: Please logout and login again for group changes (docker) to take effect"
    log_info "You may need to run 'source ~/.bashrc' to update your PATH"
}

main "$@"
