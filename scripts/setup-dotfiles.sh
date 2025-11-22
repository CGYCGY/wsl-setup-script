#!/bin/bash

# Dotfiles Setup Script for WSL
# This script configures shell aliases, SSH keys, and config files

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

backup_path() {
    local path="$1"

    if [ ! -e "${path}" ]; then
        return 0
    fi

    if [ "${ENABLE_BACKUPS}" = "true" ]; then
        local backup="${path}${BACKUP_SUFFIX}"
        log_info "Backing up ${path} to ${backup}"
        cp -r "${path}" "${backup}"
        log_success "Backup created"
    fi
}

#############################################
# BASH ALIASES
#############################################

setup_bash_aliases() {
    local src="${DOTFILES_DIR}/.bash_aliases"
    local dest="${TARGET_HOME}/.bash_aliases"

    log_info "Setting up bash aliases..."

    if [ ! -f "${src}" ]; then
        log_warn "Source .bash_aliases not found at ${src}, skipping..."
        return 0
    fi

    if [ -f "${dest}" ]; then
        log_warn "Existing .bash_aliases found"
        backup_path "${dest}"
    fi

    log_info "Copying .bash_aliases to ${dest}"
    cp "${src}" "${dest}"

    log_success "Bash aliases configured"
}

#############################################
# SSH CONFIGURATION
#############################################

setup_ssh() {
    local src_dir="${DOTFILES_DIR}/.ssh"
    local dest_dir="${TARGET_HOME}/.ssh"

    log_info "Setting up SSH configuration..."

    if [ ! -d "${src_dir}" ]; then
        log_warn "Source .ssh directory not found at ${src_dir}, skipping..."
        return 0
    fi

    # Create .ssh directory if it doesn't exist
    if [ ! -d "${dest_dir}" ]; then
        log_info "Creating .ssh directory..."
        mkdir -p "${dest_dir}"
        chmod 700 "${dest_dir}"
    else
        log_warn "Existing .ssh directory found"
        backup_path "${dest_dir}"
    fi

    # Copy SSH files
    log_info "Copying SSH files from ${src_dir} to ${dest_dir}"
    cp -r "${src_dir}"/* "${dest_dir}/" 2>/dev/null || true

    # Set proper permissions
    log_info "Setting SSH file permissions..."

    # Directory permissions
    chmod 700 "${dest_dir}"

    # Private key permissions (600)
    find "${dest_dir}" -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true
    find "${dest_dir}" -type f -name "*_rsa" ! -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true
    find "${dest_dir}" -type f -name "*_ed25519" ! -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true
    find "${dest_dir}" -type f -name "*_ecdsa" ! -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true

    # Public key permissions (644)
    find "${dest_dir}" -type f -name "*.pub" -exec chmod 644 {} \; 2>/dev/null || true

    # Config file permissions (600)
    [ -f "${dest_dir}/config" ] && chmod 600 "${dest_dir}/config"

    # Known hosts permissions (644)
    [ -f "${dest_dir}/known_hosts" ] && chmod 644 "${dest_dir}/known_hosts"

    # Authorized keys permissions (600)
    [ -f "${dest_dir}/authorized_keys" ] && chmod 600 "${dest_dir}/authorized_keys"

    log_success "SSH configuration complete"
}

#############################################
# CONFIG FILES
#############################################

setup_config() {
    local src_dir="${DOTFILES_DIR}/.config"
    local dest_dir="${TARGET_HOME}/.config"

    log_info "Setting up config files..."

    if [ ! -d "${src_dir}" ]; then
        log_warn "Source .config directory not found at ${src_dir}, skipping..."
        return 0
    fi

    # Create .config directory if it doesn't exist
    if [ ! -d "${dest_dir}" ]; then
        log_info "Creating .config directory..."
        mkdir -p "${dest_dir}"
    fi

    # Copy config files
    log_info "Copying config files from ${src_dir} to ${dest_dir}"

    # Copy each subdirectory separately to avoid overwriting everything
    for dir in "${src_dir}"/*; do
        if [ -d "${dir}" ]; then
            local dirname=$(basename "${dir}")
            local dest_subdir="${dest_dir}/${dirname}"

            if [ -d "${dest_subdir}" ]; then
                log_warn "Existing config directory found: ${dirname}"
                backup_path "${dest_subdir}"
            fi

            log_info "Copying ${dirname} config..."
            cp -r "${dir}" "${dest_dir}/"
        fi
    done

    log_success "Config files setup complete"
}

#############################################
# SOURCE BASHRC
#############################################

update_bashrc() {
    local bashrc="${TARGET_HOME}/.bashrc"

    log_info "Checking .bashrc configuration..."

    # Check if .bash_aliases is sourced in .bashrc
    if ! grep -q "\.bash_aliases" "${bashrc}" 2>/dev/null; then
        log_info "Adding .bash_aliases source to .bashrc..."
        cat >> "${bashrc}" <<'EOF'

# Source bash aliases if file exists
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
EOF
        log_success "Added .bash_aliases source to .bashrc"
    else
        log_info ".bash_aliases already sourced in .bashrc"
    fi
}

#############################################
# MAIN EXECUTION
#############################################

main() {
    echo -e "${COLOR_BOLD}${COLOR_BLUE}================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}  WSL Dotfiles Setup${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}================================${COLOR_RESET}"
    echo ""

    log_info "Starting dotfiles setup..."
    log_info "Log file: ${LOG_FILE}"
    echo ""

    setup_bash_aliases
    echo ""

    setup_ssh
    echo ""

    setup_config
    echo ""

    update_bashrc
    echo ""

    echo -e "${COLOR_BOLD}${COLOR_GREEN}================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}  Dotfiles Setup Complete!${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}================================${COLOR_RESET}"
    echo ""
    log_info "Run 'source ~/.bashrc' to load the new configuration"
}

main "$@"
