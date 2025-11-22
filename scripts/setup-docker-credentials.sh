#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Docker Credential Helper Setup${NC}"
echo -e "${BLUE}For Debian/Ubuntu WSL2${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print status messages
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Step 1: Install required packages
echo -e "${YELLOW}Step 1: Installing required packages...${NC}"
echo ""

if ! command -v gpg &> /dev/null || ! command -v pass &> /dev/null; then
    print_info "Updating package list and installing dependencies..."
    sudo apt update
    sudo apt install -y gnupg2 pass golang-docker-credential-helpers
    print_status "Packages installed successfully"
else
    print_status "Required packages already installed"
fi

echo ""

# Step 2: Check for GPG key
echo -e "${YELLOW}Step 2: Checking for GPG key...${NC}"
echo ""

if gpg --list-keys 2>/dev/null | grep -q "uid"; then
    print_status "GPG key found!"
    echo ""
    gpg --list-keys | grep -A 1 "^pub\|^uid"
    echo ""
    
    # Get the first GPG key ID
    GPG_ID=$(gpg --list-keys --keyid-format LONG 2>/dev/null | grep "^pub" | head -n1 | awk '{print $2}' | cut -d'/' -f2)
    
    if [ -z "$GPG_ID" ]; then
        # Fallback: try to get email
        GPG_ID=$(gpg --list-keys 2>/dev/null | grep "uid" | head -n1 | grep -oP '(?<=<)[^>]+(?=>)')
    fi
    
    print_info "Using GPG key: $GPG_ID"
else
    print_warning "No GPG key found!"
    echo ""
    echo -e "${YELLOW}You need to create a GPG key first. Run this command:${NC}"
    echo ""
    echo -e "${GREEN}gpg --full-generate-key${NC}"
    echo ""
    echo "Follow the prompts:"
    echo "  1. Choose: RSA and RSA (default)"
    echo "  2. Key size: 4096"
    echo "  3. Expiration: 0 (doesn't expire) or your preference"
    echo "  4. Enter your name and email"
    echo "  5. Create a PASSPHRASE (this protects your GPG key - remember it!)"
    echo ""
    echo -e "${YELLOW}After creating the key, run this script again.${NC}"
    exit 1
fi

echo ""

# Step 3: Initialize pass
echo -e "${YELLOW}Step 3: Initializing pass (password store)...${NC}"
echo ""

if [ -d "$HOME/.password-store" ]; then
    print_status "Pass already initialized"
else
    if [ -n "$GPG_ID" ]; then
        print_info "Initializing pass with GPG key: $GPG_ID"
        pass init "$GPG_ID"
        print_status "Pass initialized successfully"
    else
        print_error "Could not determine GPG key ID"
        echo "Please run manually: pass init YOUR_EMAIL@example.com"
        exit 1
    fi
fi

echo ""

# Step 4: Configure Docker
echo -e "${YELLOW}Step 4: Configuring Docker...${NC}"
echo ""

mkdir -p ~/.docker

# Backup existing config if it exists
if [ -f ~/.docker/config.json ]; then
    print_info "Backing up existing config to ~/.docker/config.json.backup"
    cp ~/.docker/config.json ~/.docker/config.json.backup
fi

# Create new config with credsStore
cat > ~/.docker/config.json << 'EOF'
{
  "credsStore": "pass"
}
EOF

print_status "Docker config created with credential helper"

echo ""

# Step 5: Registry selection
echo -e "${YELLOW}Step 5: Select which registry to configure:${NC}"
echo ""
echo "1) Docker Hub (docker.io)"
echo "2) GitHub Packages (ghcr.io)"
echo "3) Both"
echo ""
read -p "Enter your choice (1/2/3): " CHOICE

echo ""

case $CHOICE in
    1)
        REGISTRIES=("docker.io")
        ;;
    2)
        REGISTRIES=("ghcr.io")
        ;;
    3)
        REGISTRIES=("docker.io" "ghcr.io")
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

# Step 6: Login instructions
echo -e "${YELLOW}Step 6: Login to registries${NC}"
echo ""
print_warning "You need to login manually to complete the setup"
echo ""

for REGISTRY in "${REGISTRIES[@]}"; do
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Login to: $REGISTRY${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ "$REGISTRY" = "docker.io" ]; then
        echo "Run this command:"
        echo -e "${GREEN}docker login${NC}"
        echo ""
        echo "Enter:"
        echo "  - Username: Your Docker Hub username"
        echo "  - Password: Your Docker Hub password or access token"
    else
        echo "Run this command:"
        echo -e "${GREEN}docker login ghcr.io${NC}"
        echo ""
        echo "Enter:"
        echo "  - Username: Your GitHub username (not email!)"
        echo "  - Password: Your GitHub Personal Access Token (PAT)"
        echo ""
        echo -e "${YELLOW}Your PAT needs these permissions:${NC}"
        echo "  ✓ write:packages"
        echo "  ✓ read:packages"
        echo "  ✓ repo (if using private repos)"
        echo ""
        echo "Create PAT at: ${BLUE}https://github.com/settings/tokens${NC}"
    fi
    echo ""
    
    read -p "Press Enter when you're ready to login to $REGISTRY..."
    
    if [ "$REGISTRY" = "docker.io" ]; then
        docker login
    else
        docker login ghcr.io
    fi
    
    if [ $? -eq 0 ]; then
        print_status "Successfully logged in to $REGISTRY"
    else
        print_error "Login to $REGISTRY failed"
    fi
    
    echo ""
done

# Final message
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
print_status "Credential helper configured"
print_status "Your credentials are now encrypted with GPG"
print_status "The warning should no longer appear"
echo ""
print_info "Your credentials are stored in: ~/.password-store/"
print_info "They are encrypted with your GPG key"
echo ""
echo -e "${YELLOW}Note:${NC} You may need to enter your GPG passphrase when Docker"
echo "accesses the credentials (e.g., when pulling/pushing images)."
echo ""
