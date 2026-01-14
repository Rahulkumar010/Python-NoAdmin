#!/usr/bin/env bash
#
# Python-NoAdmin Installer - Unix Wrapper
#
# This script bootstraps a minimal Python to run the install.py script.
# It downloads a portable Python if not already present in bin/
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${SCRIPT_DIR}/bin"
INSTALL_SCRIPT="${SCRIPT_DIR}/install.py"

# Bootstrap Python version
BOOTSTRAP_VERSION="3.12.8"
PBS_RELEASE_TAG="20241206"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo ""
echo "============================================"
echo "  Python-NoAdmin Installer"
echo "============================================"
echo ""

# Detect platform
detect_platform() {
    local os arch
    
    case "$(uname -s)" in
        Darwin) os="macos" ;;
        Linux) os="linux" ;;
        *) error "Unsupported OS: $(uname -s)" ;;
    esac
    
    case "$(uname -m)" in
        x86_64|amd64) arch="x86_64" ;;
        aarch64|arm64) arch="aarch64" ;;
        *) error "Unsupported architecture: $(uname -m)" ;;
    esac
    
    echo "${os}_${arch}"
}

get_download_url() {
    local platform="$1"
    local filename
    
    case "$platform" in
        linux_x86_64)
            filename="cpython-${BOOTSTRAP_VERSION}+${PBS_RELEASE_TAG}-x86_64-unknown-linux-gnu-install_only.tar.gz"
            ;;
        linux_aarch64)
            filename="cpython-${BOOTSTRAP_VERSION}+${PBS_RELEASE_TAG}-aarch64-unknown-linux-gnu-install_only.tar.gz"
            ;;
        macos_x86_64)
            filename="cpython-${BOOTSTRAP_VERSION}+${PBS_RELEASE_TAG}-x86_64-apple-darwin-install_only.tar.gz"
            ;;
        macos_aarch64)
            filename="cpython-${BOOTSTRAP_VERSION}+${PBS_RELEASE_TAG}-aarch64-apple-darwin-install_only.tar.gz"
            ;;
        *)
            error "Unknown platform: $platform"
            ;;
    esac
    
    echo "https://github.com/indygreg/python-build-standalone/releases/download/${PBS_RELEASE_TAG}/${filename}"
}

# Check if bootstrap Python exists
BOOTSTRAP_PYTHON="${BIN_DIR}/python/bin/python3"

if [ -x "$BOOTSTRAP_PYTHON" ]; then
    info "Bootstrap Python found"
else
    info "Downloading bootstrap Python ${BOOTSTRAP_VERSION}..."
    
    # Detect platform and get URL
    PLATFORM=$(detect_platform)
    info "Detected platform: ${PLATFORM}"
    
    URL=$(get_download_url "$PLATFORM")
    info "URL: ${URL}"
    
    # Create directories
    mkdir -p "${BIN_DIR}/python"
    
    # Download
    TARBALL="${BIN_DIR}/python-bootstrap.tar.gz"
    
    if command -v curl &> /dev/null; then
        curl -L --progress-bar -o "$TARBALL" "$URL" || error "Download failed"
    elif command -v wget &> /dev/null; then
        wget -q --show-progress -O "$TARBALL" "$URL" || error "Download failed"
    else
        error "Neither curl nor wget found. Please install one of them."
    fi
    
    success "Download complete"
    
    # Extract (strip the 'python' prefix)
    info "Extracting..."
    tar -xzf "$TARBALL" -C "${BIN_DIR}/python" --strip-components=1
    
    # Cleanup
    rm -f "$TARBALL"
    
    # Remove quarantine on macOS
    if [ "$(uname -s)" = "Darwin" ]; then
        xattr -dr com.apple.quarantine "${BIN_DIR}/python" 2>/dev/null || true
    fi
    
    # Make executable
    chmod +x "${BIN_DIR}/python/bin/"* 2>/dev/null || true
    
    success "Bootstrap Python ready"
fi

# Run the Python installer
echo ""
info "Running installer..."
echo ""

exec "$BOOTSTRAP_PYTHON" "$INSTALL_SCRIPT" "$@"
