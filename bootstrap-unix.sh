#!/usr/bin/env bash
#
# Bootstrap Python without sudo/root access on macOS and Linux.
#
# Downloads and installs Python using python-build-standalone releases,
# then configures environment variables at the user level.
# No administrator privileges are required.
#
# Repository: Python-NoAdmin
# Requires: curl, tar, Internet access

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.json"

# Default values (overridden by config.json if present)
PYTHON_VERSION="3.12.8"
INSTALL_DIR_NAME=".python-nonadmin"
RELEASE_TAG="20241206"
BASE_URL="https://github.com/indygreg/python-build-standalone/releases/download"

# Load config if available
if command -v python3 &> /dev/null && [ -f "$CONFIG_FILE" ]; then
    PYTHON_VERSION=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['python_version'])" 2>/dev/null || echo "$PYTHON_VERSION")
    INSTALL_DIR_NAME=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['install_dir_name'])" 2>/dev/null || echo "$INSTALL_DIR_NAME")
    RELEASE_TAG=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['unix']['release_tag'])" 2>/dev/null || echo "$RELEASE_TAG")
elif command -v jq &> /dev/null && [ -f "$CONFIG_FILE" ]; then
    PYTHON_VERSION=$(jq -r '.python_version' "$CONFIG_FILE" 2>/dev/null || echo "$PYTHON_VERSION")
    INSTALL_DIR_NAME=$(jq -r '.install_dir_name' "$CONFIG_FILE" 2>/dev/null || echo "$INSTALL_DIR_NAME")
    RELEASE_TAG=$(jq -r '.unix.release_tag' "$CONFIG_FILE" 2>/dev/null || echo "$RELEASE_TAG")
fi

INSTALL_DIR="${HOME}/${INSTALL_DIR_NAME}"

# ============================================================================
# Colors and Output
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

info() { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================================================
# Platform Detection
# ============================================================================

detect_platform() {
    local os arch

    # Detect OS
    case "$(uname -s)" in
        Darwin)
            os="macos"
            ;;
        Linux)
            os="linux"
            ;;
        *)
            error "Unsupported operating system: $(uname -s)"
            exit 1
            ;;
    esac

    # Detect architecture
    case "$(uname -m)" in
        x86_64|amd64)
            arch="x86_64"
            ;;
        aarch64|arm64)
            arch="aarch64"
            ;;
        *)
            error "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac

    echo "${os}_${arch}"
}

get_download_url() {
    local platform="$1"
    local filename

    case "$platform" in
        linux_x86_64)
            filename="cpython-${PYTHON_VERSION}+${RELEASE_TAG}-x86_64-unknown-linux-gnu-install_only.tar.gz"
            ;;
        linux_aarch64)
            filename="cpython-${PYTHON_VERSION}+${RELEASE_TAG}-aarch64-unknown-linux-gnu-install_only.tar.gz"
            ;;
        macos_x86_64)
            filename="cpython-${PYTHON_VERSION}+${RELEASE_TAG}-x86_64-apple-darwin-install_only.tar.gz"
            ;;
        macos_aarch64)
            filename="cpython-${PYTHON_VERSION}+${RELEASE_TAG}-aarch64-apple-darwin-install_only.tar.gz"
            ;;
        *)
            error "Unknown platform: $platform"
            exit 1
            ;;
    esac

    echo "${BASE_URL}/${RELEASE_TAG}/${filename}"
}

# ============================================================================
# Pre-flight Checks
# ============================================================================

check_dependencies() {
    local missing=()

    if ! command -v curl &> /dev/null; then
        missing+=("curl")
    fi

    if ! command -v tar &> /dev/null; then
        missing+=("tar")
    fi

    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing required dependencies: ${missing[*]}"
        error "Please install them using your system package manager."
        exit 1
    fi
}

check_internet() {
    info "Checking internet connection..."
    if ! curl -s --head --connect-timeout 5 "https://github.com" > /dev/null 2>&1; then
        error "No internet connection. Cannot download Python."
        exit 1
    fi
    success "Internet connection OK"
}

# ============================================================================
# Installation
# ============================================================================

download_and_extract() {
    local url="$1"
    local temp_dir
    temp_dir=$(mktemp -d)
    local tarball="${temp_dir}/python.tar.gz"

    info "Downloading Python ${PYTHON_VERSION}..."
    info "URL: ${url}"

    if ! curl -L --progress-bar -o "$tarball" "$url"; then
        error "Failed to download Python"
        rm -rf "$temp_dir"
        exit 1
    fi

    # Create install directory
    if [ -d "$INSTALL_DIR" ]; then
        if [ "${FORCE:-false}" = "true" ]; then
            warn "Removing existing installation..."
            rm -rf "$INSTALL_DIR"
        else
            warn "Python already installed at: $INSTALL_DIR"
            warn "Use --force to reinstall"
            rm -rf "$temp_dir"
            exit 0
        fi
    fi

    mkdir -p "$INSTALL_DIR"

    info "Extracting to: ${INSTALL_DIR}"
    # python-build-standalone tarballs extract to a 'python' directory
    tar -xzf "$tarball" -C "$INSTALL_DIR" --strip-components=1

    # Clean up
    rm -rf "$temp_dir"
    success "Extraction complete"
}

# ============================================================================
# Shell Configuration
# ============================================================================

get_shell_profile() {
    local shell_name
    shell_name=$(basename "${SHELL:-/bin/bash}")

    case "$shell_name" in
        bash)
            if [ -f "${HOME}/.bash_profile" ]; then
                echo "${HOME}/.bash_profile"
            else
                echo "${HOME}/.bashrc"
            fi
            ;;
        zsh)
            echo "${HOME}/.zshrc"
            ;;
        fish)
            echo "${HOME}/.config/fish/config.fish"
            ;;
        *)
            echo "${HOME}/.profile"
            ;;
    esac
}

configure_shell() {
    local profile
    profile=$(get_shell_profile)
    local bin_dir="${INSTALL_DIR}/bin"
    local marker="# Python-NoAdmin configuration"

    info "Configuring shell profile: ${profile}"

    # Check if already configured
    if grep -q "$marker" "$profile" 2>/dev/null; then
        warn "Shell profile already configured"
        return 0
    fi

    # Create profile if it doesn't exist
    touch "$profile"

    # Add configuration
    cat >> "$profile" << EOF

${marker}
export PATH="${bin_dir}:\$PATH"
# End Python-NoAdmin configuration
EOF

    success "Added Python to PATH in ${profile}"
    warn "Run 'source ${profile}' or restart your terminal"
}

# ============================================================================
# macOS-specific handling
# ============================================================================

handle_quarantine() {
    if [ "$(uname -s)" = "Darwin" ]; then
        info "Removing macOS quarantine attributes..."
        xattr -dr com.apple.quarantine "$INSTALL_DIR" 2>/dev/null || true
        success "Quarantine attributes removed"
    fi
}

# ============================================================================
# Verification
# ============================================================================

verify_installation() {
    local python_exe="${INSTALL_DIR}/bin/python3"
    local pip_exe="${INSTALL_DIR}/bin/pip3"

    echo ""
    info "Verifying installation..."

    if [ -x "$python_exe" ]; then
        success "Python: $("$python_exe" --version 2>&1)"
    else
        error "Python executable not found or not executable"
        exit 1
    fi

    if [ -x "$pip_exe" ]; then
        success "pip: $("$pip_exe" --version 2>&1)"
    else
        warn "pip not found, attempting to bootstrap..."
        "$python_exe" -m ensurepip --upgrade 2>/dev/null || true
        if [ -x "$pip_exe" ]; then
            success "pip: $("$pip_exe" --version 2>&1)"
        fi
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force|-f)
                FORCE=true
                shift
                ;;
            --install-dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --force, -f        Force reinstall even if already installed"
                echo "  --install-dir DIR  Custom installation directory"
                echo "  --help, -h         Show this help message"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    echo ""
    echo -e "${MAGENTA}============================================${NC}"
    echo -e "${MAGENTA}  Python-NoAdmin Bootstrap (Unix)${NC}"
    echo -e "${MAGENTA}  Python ${PYTHON_VERSION}${NC}"
    echo -e "${MAGENTA}============================================${NC}"
    echo ""

    # Pre-flight checks
    check_dependencies
    check_internet

    # Detect platform
    local platform
    platform=$(detect_platform)
    info "Detected platform: ${platform}"

    # Get download URL
    local url
    url=$(get_download_url "$platform")

    # Download and extract
    download_and_extract "$url"

    # Handle macOS quarantine
    handle_quarantine

    # Configure shell
    configure_shell

    # Verify
    verify_installation

    # Summary
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo "  Install location: ${INSTALL_DIR}"
    echo "  Python executable: ${INSTALL_DIR}/bin/python3"
    echo ""
    echo -e "${CYAN}  To activate in current session:${NC}"
    echo -e "${YELLOW}    source ./scripts/activate.sh${NC}"
    echo ""
    echo -e "${CYAN}  Or restart your terminal to use 'python3' and 'pip3' directly.${NC}"
    echo ""
}

main "$@"
