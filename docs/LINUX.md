# Linux Installation Guide

## Overview

This guide covers Python installation on Linux using python-build-standalone portable builds.

## Requirements

- Linux with glibc 2.17+ (most modern distributions)
- curl
- tar
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

| Architecture | Build Used |
|--------------|------------|
| x86_64 (Intel/AMD 64-bit) | `x86_64-unknown-linux-gnu` |
| aarch64 (ARM 64-bit) | `aarch64-unknown-linux-gnu` |

The script automatically detects your architecture.

## Installation Location

Default: `$HOME/.python-nonadmin`

This typically resolves to:
```
/home/YourUsername/.python-nonadmin
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

## Supported Distributions

The python-build-standalone builds work on most Linux distributions:

| Distribution | Status |
|--------------|--------|
| Ubuntu 18.04+ | ✅ Supported |
| Debian 10+ | ✅ Supported |
| Fedora 30+ | ✅ Supported |
| CentOS/RHEL 7+ | ✅ Supported |
| Arch Linux | ✅ Supported |
| Alpine Linux | ⚠️ Use musl build |
| Older distributions | ⚠️ May need musl build |

## glibc Requirements

The default builds require glibc 2.17 or later. Check your version:

```bash
ldd --version
```

If your glibc is older, you have two options:

### Option 1: Use musl builds (for very old systems)

Edit `config.json` to use musl builds:

```json
"linux_x86_64": "cpython-3.12.8+20241206-x86_64-unknown-linux-musl-install_only.tar.gz"
```

### Option 2: Build from source

For maximum compatibility, build Python from source in your home directory (beyond scope of this tool).

## Shell Configuration

The script modifies your shell profile:

| Shell | Profile Modified |
|-------|-----------------|
| Bash | `~/.bashrc` or `~/.bash_profile` |
| Zsh | `~/.zshrc` |
| Fish | `~/.config/fish/config.fish` |

## Using Alongside System Python

Most Linux distributions include a system Python:

```bash
# Check which python is active
which python3

# System Python locations
/usr/bin/python3           # Debian/Ubuntu
/usr/bin/python3.x         # Fedora

# User Python
~/.python-nonadmin/bin/python3
```

> **Important**: Never uninstall or break system Python on Linux, as many system tools depend on it.

## Running on Shared Systems

On shared systems (university clusters, shared servers):

1. The installation is completely within your home directory
2. No system-wide changes are made
3. Your Python won't affect other users
4. You can install packages without sudo

```bash
# Install packages to your personal Python
pip3 install numpy pandas matplotlib

# Create virtual environments
python3 -m venv ~/my-project-env
```

## HPC / Cluster Environments

On HPC systems with module systems:

```bash
# Don't load system Python modules
# module unload python  # If needed

# Use your personal Python
source ~/.python-nonadmin/bin/activate.sh
```

## Proxy Configuration

For corporate or university networks:

```bash
# Set before running bootstrap
export HTTP_PROXY="http://proxy.company.com:8080"
export HTTPS_PROXY="http://proxy.company.com:8080"
export NO_PROXY="localhost,127.0.0.1"

# Run
./bootstrap-unix.sh
```

For permanent pip proxy:

```bash
pip config set global.proxy http://proxy.company.com:8080
```

## SELinux Considerations

On SELinux-enabled systems (RHEL, Fedora, CentOS), the binaries should work without issues since they're in your home directory. If you encounter permission errors:

```bash
# Check SELinux status
getenforce

# Temporarily set permissive (if you have access)
sudo setenforce 0

# Or restore proper context
restorecon -Rv ~/.python-nonadmin
```

## Troubleshooting

### "python3: command not found"

Restart your terminal or source your profile:

```bash
source ~/.bashrc
# or
source ~/.zshrc
```

### "error while loading shared libraries"

This usually indicates glibc version mismatch:

```bash
# Check glibc version
ldd --version

# If too old, try musl build (edit config.json)
```

### SSL/TLS Certificate Errors

Install CA certificates:

```bash
# Ubuntu/Debian
sudo apt-get install ca-certificates

# Fedora/RHEL
sudo dnf install ca-certificates

# Or use pip's bundled certificates
pip3 install certifi
```

### Permission Denied

Ensure the script and binaries are executable:

```bash
chmod +x bootstrap-unix.sh
chmod -R +x ~/.python-nonadmin/bin/
```

## Complete Uninstallation

```bash
# Remove installation directory
rm -rf ~/.python-nonadmin

# Remove PATH configuration from shell profile
# For Bash:
sed -i '/Python-NoAdmin/d' ~/.bashrc

# For Zsh:
sed -i '/Python-NoAdmin/d' ~/.zshrc
```

## Container/Docker Usage

For containerized environments:

```dockerfile
# In Dockerfile (as non-root user)
RUN curl -LO https://github.com/.../bootstrap-unix.sh && \
    chmod +x bootstrap-unix.sh && \
    ./bootstrap-unix.sh
ENV PATH="/home/user/.python-nonadmin/bin:$PATH"
```
