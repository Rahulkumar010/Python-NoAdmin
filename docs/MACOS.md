# macOS Installation Guide

## Overview

This guide covers Python installation on macOS using python-build-standalone portable builds.

## Requirements

- macOS 10.15 (Catalina) or later
- curl (included with macOS)
- tar (included with macOS)
- Internet access
- ~150 MB free disk space

## Installation

```bash
# Make script executable
chmod +x bootstrap-unix.sh

# Run the bootstrap script
./bootstrap-unix.sh

# For a fresh reinstall
./bootstrap-unix.sh --force
```

## Architecture Support

| Mac Type | Architecture | Build Used |
|----------|--------------|------------|
| Intel Mac | x86_64 | `x86_64-apple-darwin` |
| Apple Silicon (M1/M2/M3) | aarch64 | `aarch64-apple-darwin` |

The script automatically detects your architecture.

## Installation Location

Default: `$HOME/.python-nonadmin`

This typically resolves to:
```
/Users/YourUsername/.python-nonadmin
```

## What Gets Installed

```
.python-nonadmin/
├── bin/
│   ├── python3           # Main Python interpreter
│   ├── python3.12        # Version-specific symlink
│   ├── pip3              # Package installer
│   └── ...
├── lib/
│   └── python3.12/       # Standard library
│       ├── site-packages/
│       └── ...
├── include/              # Header files
└── share/                # Documentation
```

## Gatekeeper and Quarantine

macOS may quarantine downloaded files. The bootstrap script handles this automatically, but if you encounter issues:

```bash
# Remove quarantine attribute manually
xattr -dr com.apple.quarantine ~/.python-nonadmin
```

If you see "cannot be opened because the developer cannot be verified":

1. Open **System Preferences > Security & Privacy > General**
2. Click "Allow Anyway" for the blocked application
3. Or use the xattr command above

## Shell Configuration

The script automatically adds Python to your PATH by modifying your shell profile:

| Shell | Profile Modified |
|-------|-----------------|
| Bash | `~/.bash_profile` or `~/.bashrc` |
| Zsh (default on macOS) | `~/.zshrc` |
| Fish | `~/.config/fish/config.fish` |

## Zsh (Default Shell) Notes

Since macOS Catalina, Zsh is the default shell. The configuration is added to `~/.zshrc`:

```bash
# Check your shell
echo $SHELL

# View added configuration
tail ~/.zshrc
```

## Using Homebrew Python Alongside

If you have Python installed via Homebrew:

```bash
# Check which python is active
which python3

# Homebrew Python
/opt/homebrew/bin/python3  # Apple Silicon
/usr/local/bin/python3     # Intel

# User Python
~/.python-nonadmin/bin/python3
```

PATH order determines which is used first. The user Python is added to the front of PATH.

## Proxy Configuration

For corporate environments:

```bash
# Set before running bootstrap
export HTTP_PROXY="http://proxy.company.com:8080"
export HTTPS_PROXY="http://proxy.company.com:8080"

# Run
./bootstrap-unix.sh
```

For permanent pip proxy:

```bash
pip config set global.proxy http://proxy.company.com:8080
```

## Troubleshooting

### "python3: command not found"

Restart your terminal or source your profile:

```bash
# For Zsh
source ~/.zshrc

# For Bash
source ~/.bash_profile
```

### SSL Certificate Errors

macOS may have certificate issues. Install certificates:

```bash
# If you have system Python with certifi
/Applications/Python\ 3.*/Install\ Certificates.command

# Or install certifi in user Python
pip3 install certifi
```

### Rosetta 2 on Apple Silicon

If running x86_64 apps on Apple Silicon, you may need Rosetta:

```bash
# Install Rosetta 2 (may require admin for first-time install)
softwareupdate --install-rosetta
```

However, the native aarch64 build is recommended for best performance.

### "Operation not permitted" errors

Check System Preferences > Security & Privacy > Privacy > Full Disk Access if you're running from a restricted context like an IDE terminal.

## Complete Uninstallation

```bash
# Remove installation directory
rm -rf ~/.python-nonadmin

# Remove PATH configuration from shell profile
# For Zsh:
sed -i '' '/Python-NoAdmin/d' ~/.zshrc

# For Bash:
sed -i '' '/Python-NoAdmin/d' ~/.bash_profile
```
