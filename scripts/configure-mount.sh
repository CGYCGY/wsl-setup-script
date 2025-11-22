#!/bin/bash

# Mount Configuration Script for WSL
# This script configures WSL mount settings and boot scripts

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

backup_file() {
    local file="$1"

    if [ ! -f "${file}" ]; then
        return 0
    fi

    if [ "${ENABLE_BACKUPS}" = "true" ]; then
        local backup="${file}${BACKUP_SUFFIX}"
        log_info "Backing up ${file} to ${backup}"
        sudo cp "${file}" "${backup}"
        log_success "Backup created"
    fi
}

copy_file() {
    local src="$1"
    local dest="$2"
    local use_sudo="${3:-false}"

    if [ ! -f "${src}" ]; then
        log_error "Source file not found: ${src}"
        return 1
    fi

    log_info "Copying ${src} to ${dest}"

    if [ "${use_sudo}" = "true" ]; then
        sudo cp "${src}" "${dest}"
    else
        cp "${src}" "${dest}"
    fi

    log_success "File copied successfully"
}

#############################################
# WSL CONFIGURATION
#############################################

configure_wsl_conf() {
    local src="${FILES_DIR}/wsl.conf"
    local dest="/etc/wsl.conf"

    log_info "Configuring /etc/wsl.conf..."

    if [ -f "${dest}" ]; then
        log_warn "Existing wsl.conf found"
        backup_file "${dest}"
    fi

    # Substitute configuration values
    log_info "Substituting configuration values..."
    sed -e "s|{{MOUNT_SCRIPT_PATH}}|${MOUNT_SCRIPT_PATH}|g" \
        -e "s|{{WSL_AUTOMOUNT_ENABLED}}|${WSL_AUTOMOUNT_ENABLED}|g" \
        "${src}" | sudo tee "${dest}" >/dev/null

    log_success "wsl.conf configured (automount=${WSL_AUTOMOUNT_ENABLED})"
    log_warn "You need to restart WSL for changes to take effect: wsl.exe --shutdown"
}

#############################################
# FSTAB CONFIGURATION
#############################################

configure_fstab() {
    local dest="/etc/fstab"

    # Only configure fstab if automount is disabled
    if [ "${WSL_AUTOMOUNT_ENABLED}" = "true" ]; then
        log_info "Automount is enabled, skipping fstab configuration..."
        return 0
    fi

    log_info "Configuring /etc/fstab..."

    if [ -f "${dest}" ]; then
        log_warn "Existing fstab found"
        backup_file "${dest}"
    fi

    # Generate fstab from configured mounts
    log_info "Generating fstab from configuration..."
    {
        for mount in "${FSTAB_MOUNTS[@]}"; do
            echo "${mount}"
        done
    } | sudo tee "${dest}" >/dev/null

    log_success "fstab configured with ${#FSTAB_MOUNTS[@]} mount(s)"
}

#############################################
# MOUNT SCRIPT
#############################################

configure_mount_script() {
    local src="${FILES_DIR}/${MOUNT_SCRIPT_NAME}"
    local dest="${MOUNT_SCRIPT_PATH}"

    log_info "Configuring mount script..."

    if [ -f "${dest}" ]; then
        log_warn "Existing mount script found"
        backup_file "${dest}"
    fi

    # Copy and substitute variables from config.sh
    log_info "Substituting configuration values..."

    # Escape backslashes for sed replacement (prevent sed from interpreting them)
    local ESCAPED_VHDX_PATH="${VHDX_PATH//\\/\\\\}"
    local ESCAPED_WSL_EXE_PATH="${WSL_EXE_PATH//\\/\\\\}"

    sed -e "s|{{VHDX_PATH}}|${ESCAPED_VHDX_PATH}|g" \
        -e "s|{{VHDX_MOUNT_NAME}}|${VHDX_MOUNT_NAME}|g" \
        -e "s|{{CUSTOM_MOUNT_POINT}}|${CUSTOM_MOUNT_POINT}|g" \
        -e "s|{{WSL_EXE_PATH}}|${ESCAPED_WSL_EXE_PATH}|g" \
        "${src}" > "${dest}"

    # Make executable
    log_info "Setting executable permissions..."
    chmod +x "${dest}"

    log_success "Mount script configured at ${dest}"
}

#############################################
# SUDO CONFIGURATION FOR MOUNT SCRIPT
#############################################

configure_sudo_nopasswd() {
    local sudoers_file="/etc/sudoers.d/mount-nopasswd"

    log_info "Configuring sudo without password for mount script..."

    # Check if already configured
    if sudo grep -q "${TARGET_USER}.*${MOUNT_SCRIPT_NAME}" /etc/sudoers.d/* 2>/dev/null; then
        log_warn "Sudo configuration already exists, skipping..."
        return 0
    fi

    # Create sudoers entry
    echo "${TARGET_USER} ALL=(ALL) NOPASSWD: /bin/bash -c ${MOUNT_SCRIPT_PATH}" | sudo tee "${sudoers_file}" >/dev/null
    sudo chmod 0440 "${sudoers_file}"

    log_success "Sudo configuration created"
}

#############################################
# MAIN EXECUTION
#############################################

main() {
    echo -e "${COLOR_BOLD}${COLOR_BLUE}================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}  WSL Mount Configuration${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}================================${COLOR_RESET}"
    echo ""

    log_info "Starting mount configuration..."
    log_info "Log file: ${LOG_FILE}"
    echo ""

    configure_wsl_conf
    echo ""

    configure_fstab
    echo ""

    configure_mount_script
    echo ""

    configure_sudo_nopasswd
    echo ""

    echo -e "${COLOR_BOLD}${COLOR_GREEN}================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}  Configuration Complete!${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_GREEN}================================${COLOR_RESET}"
    echo ""
    log_warn "IMPORTANT: You must restart WSL for changes to take effect"
    log_info "Run this command from Windows PowerShell: wsl --shutdown"
    log_info "Then restart your WSL distribution"
}

main "$@"
