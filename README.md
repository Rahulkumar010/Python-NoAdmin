# Python-NoAdmin

**Bootstrap Python without administrator, root, or sudo access.**

A cross-platform solution for developers working in restricted environments who need a fully functional Python runtime without elevated privileges.

![Python](https://img.shields.io/badge/Python-3.10%20%7C%203.11%20%7C%203.12-blue?logo=python&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)
![No Admin](https://img.shields.io/badge/Admin-Not%20Required-success)
---

## Quick Start

### Windows

```cmd
install.cmd
```

### macOS / Linux

```bash
chmod +x install.sh
./install.sh
```

That's it! The installer will:
1. Download a bootstrap Python (first run only)
2. Install your chosen Python version to `~/.python-nonadmin`
3. Install pip
4. Configure your PATH

---

## Advanced Usage

```bash
# Install specific version
./install.sh --version 3.11.9

# Force reinstall
./install.sh --force

# List available versions
./install.sh --list

# Uninstall
./install.sh --uninstall
```

### Windows (PowerShell)

```powershell
# All the same flags work
.\install.cmd --version 3.11.9
.\install.cmd --list
.\install.cmd --uninstall
```

---

## Features

- **No admin/sudo required** – Installs entirely in user-writable directories
- **Cross-platform** – Works on Windows, macOS (Intel & Apple Silicon), and Linux (x86_64 & ARM64)
- **Version selection** – Install any supported Python version
- **Complete Python** – Includes pip and full standard library
- **Virtual environment support** – Create isolated environments as usual
- **Self-contained** – Uses bundled bootstrap Python, no dependencies

---

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  install.cmd / install.sh                                   │
│  ↓                                                          │
│  Downloads bootstrap Python to bin/python/ (first run)      │
│  ↓                                                          │
│  Runs install.py with bootstrap Python                      │
│  ↓                                                          │
│  install.py downloads target Python version                 │
│  ↓                                                          │
│  Installs to ~/.python-nonadmin                             │
│  ↓                                                          │
│  Configures pip + PATH                                      │
└─────────────────────────────────────────────────────────────┘
```

### Platform-Specific Approaches

| Platform | Bootstrap Python | Target Python |
|----------|-----------------|---------------|
| Windows | Python embeddable package | Python embeddable package |
| macOS | python-build-standalone | python-build-standalone |
| Linux | python-build-standalone | python-build-standalone |

---

## Installation Directory

| Platform | Location |
|----------|----------|
| Windows | `%USERPROFILE%\.python-nonadmin` |
| macOS | `$HOME/.python-nonadmin` |
| Linux | `$HOME/.python-nonadmin` |

---

## Verifying Installation

```bash
python --version
pip --version
python -c "import sys; print(sys.executable)"
python examples/demo.py
```

---

## Activating in Current Session

After installation, either restart your terminal or:

### Windows (PowerShell)
```powershell
. .\scripts\activate.ps1
```

### macOS / Linux
```bash
source ./scripts/activate.sh
```

---

## Creating Virtual Environments

```bash
python -m venv myproject-env

# Activate
# Windows: .\myproject-env\Scripts\Activate.ps1
# Unix: source myproject-env/bin/activate

pip install requests flask pandas
```

---

## Troubleshooting

### Windows

**Execution policy error:**
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

**Corporate proxy:**
```powershell
$env:HTTP_PROXY = "http://proxy.company.com:8080"
$env:HTTPS_PROXY = "http://proxy.company.com:8080"
.\install.cmd
```

### macOS

**Gatekeeper warning:**
```bash
xattr -dr com.apple.quarantine ~/.python-nonadmin
```

### Linux

**glibc version mismatch:**
- Default builds require glibc 2.17+
- For very old systems, consider building from source

---

## Platform-Specific Documentation

- [Windows Guide](docs/WINDOWS.md)
- [macOS Guide](docs/MACOS.md)
- [Linux Guide](docs/LINUX.md)

---

## Use Cases

- 🏢 **Corporate laptops** – Work on locked-down enterprise machines
- 🎓 **Academic labs** – Develop on shared university computers
- 🔒 **Sandboxed environments** – CI/CD pipelines with limited permissions
- 💾 **Portable development** – Run Python from USB drives
- 🧪 **Testing** – Isolated Python versions for testing

---

## Configuration

Edit `config.json` to change default Python version and download URLs.

Supported versions (tested):
- 3.12.8 (default)
- 3.12.7
- 3.11.9
- 3.11.8
- 3.10.14
- 3.10.13

---

## Uninstallation

```bash
./install.sh --uninstall
# or on Windows:
install.cmd --uninstall
```

This removes the `~/.python-nonadmin` directory. You may also want to clean up shell profile entries manually.

---

## License

MIT License - See [LICENSE](LICENSE) for details.

---

## Contributing

Contributions welcome! 
