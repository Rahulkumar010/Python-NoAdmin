#
# Activate Python-NoAdmin environment for Fish shell.
#
# Usage: source ./scripts/activate.fish
#

set -l INSTALL_DIR "$HOME/.python-nonadmin"
set -l BIN_DIR "$INSTALL_DIR/bin"

# Check if installed
if not test -d $INSTALL_DIR
    echo "[ERROR] Python-NoAdmin not installed at: $INSTALL_DIR"
    echo "Run bootstrap-unix.sh first."
    return 1
end

# Store original PATH for deactivation
if not set -q _PYTHON_NONADMIN_OLD_PATH
    set -gx _PYTHON_NONADMIN_OLD_PATH $PATH
end

# Add to PATH
set -gx PATH $BIN_DIR $PATH

# Set marker for compatibility
set -gx PYTHON_NONADMIN_ACTIVE 1

# Define deactivate function
function deactivate_python_nonadmin
    if set -q _PYTHON_NONADMIN_OLD_PATH
        set -gx PATH $_PYTHON_NONADMIN_OLD_PATH
        set -e _PYTHON_NONADMIN_OLD_PATH
    end
    set -e PYTHON_NONADMIN_ACTIVE
    functions -e deactivate_python_nonadmin
    echo "[INFO] Python-NoAdmin deactivated"
end

# Confirmation
set PYTHON_VERSION (eval $BIN_DIR/python3 --version 2>&1)
echo ""
echo "[SUCCESS] Python-NoAdmin activated"
echo "  Python: $PYTHON_VERSION"
echo "  Location: $INSTALL_DIR"
echo ""
echo "  To deactivate: deactivate_python_nonadmin"
echo ""
