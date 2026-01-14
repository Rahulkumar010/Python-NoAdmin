#!/usr/bin/env bash
#
# Activate Python-NoAdmin environment in the current shell session.
#
# Usage: source ./scripts/activate.sh
#

INSTALL_DIR="${HOME}/.python-nonadmin"
BIN_DIR="${INSTALL_DIR}/bin"

# Check if installed
if [ ! -d "$INSTALL_DIR" ]; then
    echo "[ERROR] Python-NoAdmin not installed at: $INSTALL_DIR"
    echo "Run install.sh first."
    return 1 2>/dev/null || exit 1
fi

# Store original PATH for deactivation
if [ -z "$_PYTHON_NONADMIN_OLD_PATH" ]; then
    export _PYTHON_NONADMIN_OLD_PATH="$PATH"
fi

# Add to PATH
export PATH="${BIN_DIR}:${PATH}"

# Set marker for compatibility
export PYTHON_NONADMIN_ACTIVE="1"

# Define deactivate function
deactivate_python_nonadmin() {
    if [ -n "$_PYTHON_NONADMIN_OLD_PATH" ]; then
        export PATH="$_PYTHON_NONADMIN_OLD_PATH"
        unset _PYTHON_NONADMIN_OLD_PATH
    fi
    unset PYTHON_NONADMIN_ACTIVE
    unset -f deactivate_python_nonadmin 2>/dev/null
    echo "[INFO] Python-NoAdmin deactivated"
}

# Confirmation
PYTHON_VERSION=$("${BIN_DIR}/python3" --version 2>&1)
echo ""
echo -e "\033[0;32m[SUCCESS]\033[0m Python-NoAdmin activated"
echo "  Python: ${PYTHON_VERSION}"
echo "  Location: ${INSTALL_DIR}"
echo ""
echo "  To deactivate: deactivate_python_nonadmin"
echo ""
