#!/usr/bin/env bash
#
# Uninstall Python-NoAdmin on macOS and Linux.
# Removes the installation directory and cleans up shell profile entries.
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

INSTALL_DIR="${HOME}/.python-nonadmin"

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  Python-NoAdmin Uninstaller${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# Confirm
read -p "This will remove Python-NoAdmin from $INSTALL_DIR. Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Uninstallation cancelled."
    exit 0
fi

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
    info "Removing installation directory..."
    rm -rf "$INSTALL_DIR"
    success "Removed: $INSTALL_DIR"
else
    warn "Installation directory not found: $INSTALL_DIR"
fi

# Clean shell profiles
clean_profile() {
    local profile="$1"
    if [ -f "$profile" ]; then
        if grep -q "Python-NoAdmin" "$profile"; then
            info "Cleaning: $profile"
            # Create backup
            cp "$profile" "${profile}.bak"
            # Remove Python-NoAdmin lines
            sed -i.tmp '/# Python-NoAdmin/,/# End Python-NoAdmin/d' "$profile"
            rm -f "${profile}.tmp"
            success "Cleaned: $profile (backup at ${profile}.bak)"
        fi
    fi
}

clean_profile "${HOME}/.bashrc"
clean_profile "${HOME}/.bash_profile"
clean_profile "${HOME}/.zshrc"
clean_profile "${HOME}/.profile"

# Fish config
FISH_CONFIG="${HOME}/.config/fish/config.fish"
if [ -f "$FISH_CONFIG" ] && grep -q "Python-NoAdmin" "$FISH_CONFIG"; then
    info "Cleaning Fish config..."
    cp "$FISH_CONFIG" "${FISH_CONFIG}.bak"
    sed -i.tmp '/# Python-NoAdmin/,/# End Python-NoAdmin/d' "$FISH_CONFIG"
    rm -f "${FISH_CONFIG}.tmp"
    success "Cleaned: $FISH_CONFIG"
fi

echo ""
success "Python-NoAdmin has been uninstalled."
info "Restart your terminal for PATH changes to take effect."
echo ""
