#!/bin/bash

# --- Configuration ---
# These values are substituted from config.sh during setup
VHDX_PATH="{{VHDX_PATH}}"
MOUNT_NAME="{{VHDX_MOUNT_NAME}}"
CUSTOM_MOUNT_POINT="/mnt/$MOUNT_NAME"
WSL_MOUNT_POINT="/mnt/wsl/$MOUNT_NAME"

# --- Attachment/Mounting Logic ---

# 1. Try to unmount first for a clean start. Output redirected to /dev/null
/mnt/c/Windows/System32/wsl.exe --unmount "\\\\?\\$VHDX_PATH" 2>/dev/null

# 2. Re-attach and auto-mount the VHDX. All output (stdout & stderr) redirected to /dev/null
# The '2>&1' redirects stderr to stdout, and '>/dev/null' redirects stdout to null.
/mnt/c/Windows/System32/wsl.exe --mount --vhd "$VHDX_PATH" --partition 1 --name $MOUNT_NAME >/dev/null 2>&1

# --- Verification and Custom Message ---

# Check if the WSL-default mount point exists (meaning the mount was successful)
if [ -d "$WSL_MOUNT_POINT" ]; then

    # 3. Create the symlink for easy access (/mnt/__data) if it doesn't exist
    if [ ! -L "$CUSTOM_MOUNT_POINT" ]; then
        # Using 'sudo -n' to run without prompting for a password, as this is a startup script
        sudo -n ln -s "$WSL_MOUNT_POINT" "$CUSTOM_MOUNT_POINT" 2>/dev/null
    fi

    # Display the custom success message! 📢
    echo "✅ Project data VHDX mounted successfully at $CUSTOM_MOUNT_POINT"
fi
