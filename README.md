# WSL Setup Script

Automated setup script for configuring Debian/Ubuntu on Windows Subsystem for Linux (WSL).

## Features

- 🚀 **Automated Installation**: One command to set up your entire WSL environment
- 🔧 **Modular Design**: Run individual setup scripts independently
- 🔄 **Idempotent**: Safe to run multiple times without breaking existing setup
- 💾 **Automatic Backups**: Creates timestamped backups before overwriting files
- 📦 **Comprehensive Packages**: Installs all essential development tools
- 🎨 **Color-coded Output**: Clear visual feedback during installation
- 📝 **Detailed Logging**: Complete logs saved to `setup.log`

## What Gets Installed

### System Packages
- Essential build tools (ca-certificates, curl, git, gnupg, etc.)
- Documentation tools (man-db)

### Development Tools
- **Docker** (with Docker Compose, Buildx)
- **Node.js** (via NVM)
- **Bun** (JavaScript runtime)
- **Tailscale** (VPN/mesh networking)
- **Claude Code** (AI-powered code assistant)
- **Chrome for Testing** (headless browser with all dependencies)

### Configuration Files
- WSL boot configuration (`/etc/wsl.conf`)
- Filesystem mount table (`/etc/fstab`)
- Custom mount script (`~/mount__data.sh`)
- Bash aliases (`~/.bash_aliases`)
- SSH keys and configuration (`~/.ssh/`)
- Application configs (`~/.config/`)

## Directory Structure

```
wsl-setup-script/
├── README.md                    # This file
├── .gitignore                   # Git ignore rules
├── config.sh.example            # Configuration template
├── config.sh                    # Your config (create from example)
├── setup-wsl.sh                 # Main setup script
├── setup.log                    # Installation log (generated)
├── scripts/
│   ├── install-packages.sh      # Package installation
│   ├── configure-mount.sh       # Mount configuration
│   └── setup-dotfiles.sh        # Dotfiles setup
├── files/
│   ├── mount__data.sh           # VHDX mount script
│   ├── wsl.conf                 # WSL configuration
│   └── fstab                    # Filesystem table
└── dotfiles/
    ├── .bash_aliases.example    # Shell aliases template
    ├── .bash_aliases            # Your aliases (create from example)
    ├── .ssh/                    # SSH keys (ignored by git)
    └── .config/                 # Application configs
```

## Quick Start

### 0. Clone or Copy the Repository

**IMPORTANT**: First get the scripts into your WSL environment and set executable permissions:

```bash
# Option A: Clone from git (recommended)
git clone <your-repo-url> ~/wsl-setup-script

# Option B: Copy from Windows filesystem
# cp -r /mnt/<drive>/path/to/wsl-setup-script ~/wsl-setup-script

# Navigate to the directory
cd ~/wsl-setup-script

# Set executable permissions for all shell scripts
sudo find ./ -type f -name "*.sh" -exec chmod +x {} \;
```

### 1. Configure Settings

Copy the example files and edit them to match your environment:

```bash
# Copy the example configuration
cp config.sh.example config.sh

# Copy the example bash aliases (optional but recommended)
cp dotfiles/.bash_aliases.example dotfiles/.bash_aliases

# Edit with your settings
nano config.sh
nano dotfiles/.bash_aliases  # Customize your aliases
```

**IMPORTANT** - Update these in `config.sh`:
- `TARGET_USER` - Your WSL username (change from `yourusername`)
- `TARGET_HOME` - Your home directory (will be `/home/yourusername`)
- `CHROME_INSTALL_PATH` - Where to install Chrome for Testing (optional)

**Optional** - Customize `dotfiles/.bash_aliases`:
- Add your custom shell aliases and shortcuts
- Update `cdp` alias to point to your project directory

### 2. Run Setup

#### Option A: Run Everything (Recommended)

```bash
# Make sure you're in the right directory
cd ~/wsl-setup-script

# Run the main setup script
./setup-wsl.sh
```

This will:
1. Install all packages
2. Configure mount settings
3. Set up dotfiles

#### Option B: Run Individual Scripts

```bash
# Make sure you're in the right directory
cd ~/wsl-setup-script

# Run only what you need
./scripts/install-packages.sh    # Step 1: Install packages
./scripts/configure-mount.sh     # Step 2: Configure mounts
./scripts/setup-dotfiles.sh      # Step 3: Setup dotfiles
```

### 3. Restart WSL

After setup completes, restart WSL from Windows PowerShell:

```powershell
wsl --shutdown
```

Then start your WSL distribution again.

### 4. Reload Shell Configuration

```bash
source ~/.bashrc
```

## Configuration Guide

### Creating Your Configuration

First, copy the example configuration:
```bash
cp config.sh.example config.sh
```

### Editing config.sh

The `config.sh` file contains all configurable paths and settings:

#### User Settings
```bash
TARGET_USER="yourusername"              # Your WSL username
TARGET_HOME="/home/${TARGET_USER}"      # Your home directory
```

#### Installation Paths
```bash
CHROME_INSTALL_PATH="${TARGET_HOME}/chrome"  # Chrome installation
NVM_DIR="${TARGET_HOME}/.nvm"                # Node Version Manager
BUN_INSTALL="${TARGET_HOME}/.bun"            # Bun runtime
```

#### Backup Settings
```bash
ENABLE_BACKUPS="true"          # Create backups before overwriting
BACKUP_SUFFIX=".backup.TIMESTAMP"  # Backup file suffix
```

#### Package Lists

You can customize which packages to install by editing the arrays in `config.sh`:

```bash
# Add/remove system packages
SYSTEM_PACKAGES=(
    ca-certificates
    curl
    git
    # Add your packages here
)

# Chrome dependencies (needed for headless browser)
CHROME_DEPENDENCIES=(
    libnspr4
    libnss3
    # All required Chrome libraries
)
```

## How It Works

### Main Setup Flow

```
setup-wsl.sh
    ├── Check system requirements
    ├── Confirm with user
    ├── Run install-packages.sh
    │   ├── Update system
    │   ├── Install Tailscale
    │   ├── Install Docker
    │   ├── Install Chrome dependencies
    │   ├── Install NVM & Node
    │   ├── Install Bun
    │   ├── Install Chrome for Testing
    │   └── Install Claude Code
    ├── Run configure-mount.sh
    │   ├── Copy wsl.conf → /etc/
    │   ├── Copy fstab → /etc/
    │   ├── Copy mount__data.sh → ~/
    │   └── Configure sudo for mount script
    └── Run setup-dotfiles.sh
        ├── Copy .bash_aliases → ~/
        ├── Copy .ssh/ → ~/.ssh/
        ├── Copy .config/ → ~/.config/
        └── Set proper permissions
```

### Idempotent Design

All scripts check if tools/files already exist before making changes:
- Packages: Checks if command exists before installing
- Files: Backs up existing files before overwriting
- Configuration: Skips if already configured

This means you can safely re-run scripts without breaking your setup.

### Backup System

When enabled (`ENABLE_BACKUPS="true"`), the scripts create backups:
- Format: `filename.backup.YYYYMMDD_HHMMSS`
- Example: `.bashrc.backup.20231122_143052`
- Location: Same directory as original file

## Mount Configuration

The setup configures WSL to automatically mount a VHDX on boot:

1. **wsl.conf**: Enables systemd and runs mount script on boot
2. **fstab**: Configures drive mounting (C: and D:)
3. **mount__data.sh**: Script to mount VHDX at `/mnt/__data`

### How the Mount Works

When WSL starts:
1. Systemd executes `~/mount__data.sh`
2. Script unmounts any existing VHDX
3. Script mounts new VHDX to `/mnt/__data`
4. Creates symlink `/mnt/wsl/__data` → `/mnt/__data`

## Troubleshooting

### Script Permission Denied

If you get "Permission denied" when running scripts, set executable permissions:

```bash
cd ~/wsl-setup-script
sudo find ./ -type f -name "*.sh" -exec chmod +x {} \;
```

### Docker Group Not Working

After installation, log out and log back in:
```bash
exit
# Then restart your WSL distribution
```

Or use `newgrp`:
```bash
newgrp docker
```

### NVM Command Not Found

Reload your shell:
```bash
source ~/.bashrc
# OR
source ~/.nvm/nvm.sh
```

### WSL Configuration Not Applied

Restart WSL completely:
```powershell
# From Windows PowerShell
wsl --shutdown
```

### Mount Script Fails

Check the mount script configuration in `files/mount__data.sh`:
- Verify VHDX path is correct
- Ensure VHDX file exists
- Check Windows disk path is accessible

### Chrome for Testing Issues

If Chrome fails to run, install missing dependencies:
```bash
sudo apt install -y libnspr4 libnss3 libatk1.0-0 libatk-bridge2.0-0 \
  libcups2 libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 \
  libxrandr2 libgbm1 libcairo2 libpango-1.0-0 libasound2
```

### Check Logs

All operations are logged to `setup.log`:
```bash
tail -f setup.log          # Follow log in real-time
less setup.log             # Browse full log
grep ERROR setup.log       # Find errors
```

## Customization

### Adding New Packages

Edit `config.sh` and add to `SYSTEM_PACKAGES` array:

```bash
SYSTEM_PACKAGES=(
    ca-certificates
    curl
    git
    your-package-here
)
```

### Adding Custom Scripts

1. Create new script in `scripts/` directory
2. Add to `setup-wsl.sh` main function
3. Make executable: `chmod +x scripts/your-script.sh`

### Changing Default Paths

Edit `config.sh` before running setup:
- Source paths: `FILES_DIR`, `DOTFILES_DIR`
- Destination paths: `TARGET_HOME`, `CHROME_INSTALL_PATH`

## Git Version Control

### Before Committing

1. **Remove Sensitive Files**: SSH private keys are automatically excluded by `.gitignore`
2. **Check .gitignore**: Verify sensitive files are listed
3. **Review Changes**: `git status` to see what will be committed

### Safe Files to Commit
- ✅ Scripts (`.sh` files)
- ✅ Configuration templates (`config.sh.example`, `.bash_aliases.example`)
- ✅ Mount configurations (`wsl.conf`, `fstab`, `mount__data.sh`)
- ✅ Claude Code settings (`dotfiles/.config/ccstatusline/settings.json`)
- ✅ Other config files in `dotfiles/.config/`
- ✅ Directory structure (`.gitkeep` files)
- ✅ Documentation (`README.md`)

### Never Commit (Automatically Ignored)
- ❌ Your personal config (`config.sh`)
- ❌ Your personal aliases (`dotfiles/.bash_aliases`)
- ❌ **All SSH keys and files** in `dotfiles/.ssh/` (except `.gitkeep`)
- ❌ `.env` files
- ❌ Log files (`*.log`)
- ❌ Backup files (`*.backup.*`)

### Dotfiles Directory Behavior
- **`.ssh/`**: Directory is tracked (via `.gitkeep`), but ALL files inside are ignored for security
- **`.config/`**: Files can be committed (like Claude Code settings)
- **`.bash_aliases`**: Ignored (use `.bash_aliases.example` as template)

### Recommended Git Workflow

```bash
# Navigate to the script directory
cd ~/wsl-setup-script

# Initialize git repository (if not already a git repo)
git init

# Add all files (respects .gitignore)
git add .

# Check what will be committed
git status

# Commit
git commit -m "Initial WSL setup scripts"

# Add remote and push
git remote add origin <your-repo-url>
git push -u origin main
```

## Advanced Usage

### Dry Run (Preview Changes)

Currently not implemented, but you can check what will be installed:

```bash
# View package lists
cat config.sh | grep -A 20 "SYSTEM_PACKAGES"
cat config.sh | grep -A 20 "CHROME_DEPENDENCIES"

# View what files will be copied
ls -la files/
ls -la dotfiles/
```

### Custom Configuration

Create a `local-config.sh` (not tracked by git):

```bash
# local-config.sh
source ./config.sh

# Override settings
TARGET_USER="your-username"
CHROME_INSTALL_PATH="/opt/chrome"
```

Then use it:
```bash
source ./local-config.sh && ./scripts/install-packages.sh
```

### Selective Installation

Skip steps by commenting out in `setup-wsl.sh`:

```bash
# Comment out steps you don't need
# run_script "scripts/install-packages.sh"
run_script "scripts/configure-mount.sh"
run_script "scripts/setup-dotfiles.sh"
```

## Requirements

- Windows 10/11 with WSL2
- Debian or Ubuntu distribution in WSL
- Internet connection
- Sudo privileges

## Compatibility

Tested on:
- ✅ Debian (latest)
- ✅ Ubuntu 22.04 LTS
- ✅ Ubuntu 20.04 LTS

## License

This setup script is provided as-is for personal use.

## Contributing

To add improvements:
1. Test changes thoroughly
2. Update documentation
3. Ensure idempotent behavior
4. Add logging for new operations

## Support

For issues or questions:
1. Check `setup.log` for errors
2. Review troubleshooting section
3. Verify `config.sh` settings
4. Test individual scripts

## Version History

### v1.0 (2024)
- Initial release
- Modular script architecture
- Automated package installation
- Mount configuration
- Dotfiles management
- Comprehensive documentation

## Credits

Created for automating WSL development environment setup with support for:
- Docker containerization
- Node.js/Bun JavaScript runtimes
- Chrome for Testing (Puppeteer)
- Claude Code AI assistant
- Tailscale networking
