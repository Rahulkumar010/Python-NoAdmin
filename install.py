#!/usr/bin/env python3
"""
Python-NoAdmin Installer

A cross-platform Python installer that works without administrator access.
This script downloads and installs Python to a user-writable directory,
configures PATH, and installs pip.

Usage:
    python install.py                    # Install default version
    python install.py --version 3.11.9   # Install specific version
    python install.py --list             # List available versions
    python install.py --uninstall        # Remove installation
"""

import argparse
import json
import os
import platform
import shutil
import stat
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
import zipfile
from pathlib import Path
from typing import Optional, Tuple

# ============================================================================
# Configuration
# ============================================================================

DEFAULT_VERSION = "3.12.8"
INSTALL_DIR_NAME = ".python-nonadmin"

# python-build-standalone release info
PBS_RELEASE_TAG = "20241206"
PBS_BASE_URL = "https://github.com/indygreg/python-build-standalone/releases/download"

# Windows embeddable package
PYTHON_ORG_BASE = "https://www.python.org/ftp/python"
GET_PIP_URL = "https://bootstrap.pypa.io/get-pip.py"

# Available versions (can be extended)
AVAILABLE_VERSIONS = [
    "3.12.8",
    "3.12.7",
    "3.11.9",
    "3.11.8",
    "3.10.14",
    "3.10.13",
]

# ============================================================================
# Terminal Colors
# ============================================================================

class Colors:
    """ANSI color codes for terminal output."""
    RED = "\033[0;31m"
    GREEN = "\033[0;32m"
    YELLOW = "\033[0;33m"
    CYAN = "\033[0;36m"
    MAGENTA = "\033[0;35m"
    BOLD = "\033[1m"
    NC = "\033[0m"  # No Color

    @classmethod
    def disable(cls):
        """Disable colors (for non-TTY or Windows without ANSI support)."""
        cls.RED = cls.GREEN = cls.YELLOW = cls.CYAN = cls.MAGENTA = cls.BOLD = cls.NC = ""


# Disable colors if not a TTY or on older Windows
if not sys.stdout.isatty():
    Colors.disable()
elif sys.platform == "win32":
    # Enable ANSI on Windows 10+
    try:
        import ctypes
        kernel32 = ctypes.windll.kernel32
        kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
    except Exception:
        Colors.disable()


def info(msg: str) -> None:
    print(f"{Colors.CYAN}[INFO]{Colors.NC} {msg}")


def success(msg: str) -> None:
    print(f"{Colors.GREEN}[SUCCESS]{Colors.NC} {msg}")


def warn(msg: str) -> None:
    print(f"{Colors.YELLOW}[WARNING]{Colors.NC} {msg}")


def error(msg: str) -> None:
    print(f"{Colors.RED}[ERROR]{Colors.NC} {msg}")


def header(msg: str) -> None:
    print()
    print(f"{Colors.MAGENTA}{'=' * 50}{Colors.NC}")
    print(f"{Colors.MAGENTA}  {msg}{Colors.NC}")
    print(f"{Colors.MAGENTA}{'=' * 50}{Colors.NC}")
    print()


# ============================================================================
# Platform Detection
# ============================================================================

def get_platform_info() -> Tuple[str, str]:
    """
    Detect OS and architecture.
    
    Returns:
        Tuple of (os_name, arch) where os_name is 'windows', 'macos', or 'linux'
        and arch is 'x86_64' or 'aarch64'.
    """
    system = platform.system().lower()
    machine = platform.machine().lower()
    
    # Normalize OS
    if system == "darwin":
        os_name = "macos"
    elif system == "windows":
        os_name = "windows"
    elif system == "linux":
        os_name = "linux"
    else:
        raise RuntimeError(f"Unsupported operating system: {system}")
    
    # Normalize architecture
    if machine in ("x86_64", "amd64"):
        arch = "x86_64"
    elif machine in ("aarch64", "arm64"):
        arch = "aarch64"
    elif machine in ("i386", "i686"):
        arch = "x86"  # 32-bit
    else:
        raise RuntimeError(f"Unsupported architecture: {machine}")
    
    return os_name, arch


def get_install_dir() -> Path:
    """Get the installation directory path."""
    home = Path.home()
    return home / INSTALL_DIR_NAME


# ============================================================================
# Download URLs
# ============================================================================

def get_pbs_download_url(version: str, os_name: str, arch: str) -> str:
    """Get python-build-standalone download URL for Unix systems."""
    if os_name == "macos":
        target = f"{arch}-apple-darwin"
    elif os_name == "linux":
        target = f"{arch}-unknown-linux-gnu"
    else:
        raise ValueError(f"PBS not available for {os_name}")
    
    filename = f"cpython-{version}+{PBS_RELEASE_TAG}-{target}-install_only.tar.gz"
    return f"{PBS_BASE_URL}/{PBS_RELEASE_TAG}/{filename}"


def get_windows_embed_url(version: str, arch: str) -> str:
    """Get Windows embeddable package URL."""
    if arch == "x86_64":
        arch_suffix = "amd64"
    elif arch == "x86":
        arch_suffix = "win32"
    elif arch == "aarch64":
        arch_suffix = "arm64"
    else:
        raise ValueError(f"Unknown Windows architecture: {arch}")
    
    return f"{PYTHON_ORG_BASE}/{version}/python-{version}-embed-{arch_suffix}.zip"


# ============================================================================
# Download and Extraction
# ============================================================================

def download_file(url: str, dest: Path, description: str = "file") -> None:
    """Download a file with progress indication."""
    info(f"Downloading {description}...")
    info(f"URL: {url}")
    
    try:
        # Create a request with a user agent
        request = urllib.request.Request(
            url,
            headers={"User-Agent": "Python-NoAdmin-Installer/1.0"}
        )
        
        with urllib.request.urlopen(request, timeout=60) as response:
            total_size = int(response.headers.get("Content-Length", 0))
            downloaded = 0
            block_size = 8192
            
            with open(dest, "wb") as f:
                while True:
                    chunk = response.read(block_size)
                    if not chunk:
                        break
                    f.write(chunk)
                    downloaded += len(chunk)
                    
                    if total_size > 0:
                        percent = (downloaded / total_size) * 100
                        mb_downloaded = downloaded / (1024 * 1024)
                        mb_total = total_size / (1024 * 1024)
                        print(f"\r  Progress: {percent:.1f}% ({mb_downloaded:.1f}/{mb_total:.1f} MB)", end="", flush=True)
            
            print()  # Newline after progress
        
        success(f"Downloaded: {dest.name}")
        
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"HTTP Error {e.code}: {e.reason}. URL may be invalid for this version.")
    except urllib.error.URLError as e:
        raise RuntimeError(f"Network error: {e.reason}. Check your internet connection.")


def extract_archive(archive: Path, dest: Path, strip_components: int = 0) -> None:
    """Extract a tar.gz or zip archive."""
    info(f"Extracting to: {dest}")
    
    dest.mkdir(parents=True, exist_ok=True)
    
    if archive.suffix == ".zip" or archive.name.endswith(".zip"):
        with zipfile.ZipFile(archive, "r") as zf:
            zf.extractall(dest)
    elif archive.name.endswith(".tar.gz") or archive.name.endswith(".tgz"):
        with tarfile.open(archive, "r:gz") as tf:
            if strip_components > 0:
                # Strip leading path components
                for member in tf.getmembers():
                    parts = member.name.split("/")
                    if len(parts) > strip_components:
                        member.name = "/".join(parts[strip_components:])
                        tf.extract(member, dest)
            else:
                tf.extractall(dest)
    else:
        raise ValueError(f"Unknown archive format: {archive.name}")
    
    success("Extraction complete")


# ============================================================================
# Windows-specific Installation
# ============================================================================

def install_windows(version: str, install_dir: Path, arch: str) -> Path:
    """Install Python on Windows using the embeddable package."""
    
    # Download embeddable package
    url = get_windows_embed_url(version, arch)
    
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        zip_file = temp_path / "python-embed.zip"
        
        download_file(url, zip_file, f"Python {version} embeddable package")
        
        # Extract
        if install_dir.exists():
            warn("Removing existing installation...")
            shutil.rmtree(install_dir)
        
        extract_archive(zip_file, install_dir)
    
    # Configure ._pth file to enable site-packages
    major_minor = "".join(version.split(".")[:2])
    pth_file = install_dir / f"python{major_minor}._pth"
    
    if pth_file.exists():
        info(f"Configuring {pth_file.name} for pip support...")
        content = pth_file.read_text()
        
        # Uncomment "import site"
        if "#import site" in content:
            content = content.replace("#import site", "import site")
            pth_file.write_text(content)
            success("Enabled 'import site'")
        elif "import site" not in content:
            with open(pth_file, "a") as f:
                f.write("\nimport site\n")
            success("Added 'import site'")
    
    python_exe = install_dir / "python.exe"
    return python_exe


# ============================================================================
# Unix-specific Installation  
# ============================================================================

def install_unix(version: str, install_dir: Path, os_name: str, arch: str) -> Path:
    """Install Python on macOS/Linux using python-build-standalone."""
    
    url = get_pbs_download_url(version, os_name, arch)
    
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        tarball = temp_path / "python.tar.gz"
        
        download_file(url, tarball, f"Python {version}")
        
        # Extract (strip 'python/' prefix from python-build-standalone)
        if install_dir.exists():
            warn("Removing existing installation...")
            shutil.rmtree(install_dir)
        
        extract_archive(tarball, install_dir, strip_components=1)
    
    # Handle macOS quarantine
    if os_name == "macos":
        info("Removing macOS quarantine attributes...")
        try:
            subprocess.run(
                ["xattr", "-dr", "com.apple.quarantine", str(install_dir)],
                check=False,
                capture_output=True
            )
            success("Quarantine attributes removed")
        except Exception:
            pass
    
    # Make binaries executable
    bin_dir = install_dir / "bin"
    if bin_dir.exists():
        for exe in bin_dir.iterdir():
            if exe.is_file():
                exe.chmod(exe.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    
    python_exe = bin_dir / "python3"
    return python_exe


# ============================================================================
# pip Installation
# ============================================================================

def install_pip(python_exe: Path, install_dir: Path) -> None:
    """Install or upgrade pip."""
    
    info("Checking pip installation...")
    
    # Check if pip already works
    result = subprocess.run(
        [str(python_exe), "-m", "pip", "--version"],
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        success(f"pip already installed: {result.stdout.strip()}")
        # Upgrade pip
        info("Upgrading pip to latest version...")
        subprocess.run(
            [str(python_exe), "-m", "pip", "install", "--upgrade", "pip", "--quiet"],
            check=False
        )
        return
    
    # Download and run get-pip.py
    info("Installing pip...")
    
    with tempfile.TemporaryDirectory() as temp_dir:
        get_pip_path = Path(temp_dir) / "get-pip.py"
        download_file(GET_PIP_URL, get_pip_path, "get-pip.py")
        
        result = subprocess.run(
            [str(python_exe), str(get_pip_path), "--no-warn-script-location"],
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            error(f"pip installation failed: {result.stderr}")
            raise RuntimeError("Failed to install pip")
    
    # Verify
    result = subprocess.run(
        [str(python_exe), "-m", "pip", "--version"],
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        success(f"pip installed: {result.stdout.strip()}")
    else:
        warn("pip installation may have issues")


# ============================================================================
# PATH Configuration
# ============================================================================

def configure_path_windows(install_dir: Path) -> None:
    """Add Python to user PATH on Windows."""
    import winreg
    
    scripts_dir = install_dir / "Scripts"
    paths_to_add = [str(install_dir), str(scripts_dir)]
    
    info("Updating user PATH...")
    
    try:
        # Open user environment key
        with winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Environment",
            0,
            winreg.KEY_READ | winreg.KEY_WRITE
        ) as key:
            try:
                current_path, _ = winreg.QueryValueEx(key, "PATH")
            except FileNotFoundError:
                current_path = ""
            
            # Add paths if not present
            path_parts = current_path.split(";") if current_path else []
            modified = False
            
            for path_to_add in paths_to_add:
                if path_to_add not in path_parts:
                    path_parts.insert(0, path_to_add)
                    modified = True
            
            if modified:
                new_path = ";".join(path_parts)
                winreg.SetValueEx(key, "PATH", 0, winreg.REG_EXPAND_SZ, new_path)
                success("Added to user PATH")
                warn("Restart your terminal for PATH changes to take effect")
            else:
                info("Already in user PATH")
                
    except Exception as e:
        warn(f"Could not update PATH automatically: {e}")
        info(f"Please add these directories to your PATH manually:")
        for p in paths_to_add:
            print(f"  {p}")


def configure_path_unix(install_dir: Path) -> None:
    """Add Python to PATH in shell profile on Unix."""
    
    bin_dir = install_dir / "bin"
    
    # Detect shell
    shell = os.environ.get("SHELL", "/bin/bash")
    shell_name = Path(shell).name
    
    if shell_name == "zsh":
        profile = Path.home() / ".zshrc"
    elif shell_name == "fish":
        profile = Path.home() / ".config" / "fish" / "config.fish"
    elif shell_name == "bash":
        bash_profile = Path.home() / ".bash_profile"
        bashrc = Path.home() / ".bashrc"
        profile = bash_profile if bash_profile.exists() else bashrc
    else:
        profile = Path.home() / ".profile"
    
    marker = "# Python-NoAdmin PATH"
    
    info(f"Configuring shell profile: {profile}")
    
    # Check if already configured
    if profile.exists():
        content = profile.read_text()
        if marker in content:
            info("Shell profile already configured")
            return
    
    # Add PATH configuration
    profile.parent.mkdir(parents=True, exist_ok=True)
    
    if shell_name == "fish":
        config = f"""
{marker}
set -gx PATH "{bin_dir}" $PATH
# End Python-NoAdmin
"""
    else:
        config = f"""
{marker}
export PATH="{bin_dir}:$PATH"
# End Python-NoAdmin
"""
    
    with open(profile, "a") as f:
        f.write(config)
    
    success(f"Added Python to PATH in {profile}")
    warn(f"Run 'source {profile}' or restart your terminal")


# ============================================================================
# Main Installation
# ============================================================================

def install(version: str, force: bool = False) -> None:
    """Main installation function."""
    
    os_name, arch = get_platform_info()
    install_dir = get_install_dir()
    
    header(f"Python-NoAdmin Installer")
    print(f"  Version: {version}")
    print(f"  Platform: {os_name} ({arch})")
    print(f"  Install directory: {install_dir}")
    print()
    
    # Check existing installation
    if install_dir.exists() and not force:
        warn(f"Python already installed at: {install_dir}")
        info("Use --force to reinstall")
        
        # Show existing version
        if os_name == "windows":
            python_exe = install_dir / "python.exe"
        else:
            python_exe = install_dir / "bin" / "python3"
        
        if python_exe.exists():
            result = subprocess.run(
                [str(python_exe), "--version"],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                info(f"Existing version: {result.stdout.strip()}")
        return
    
    # Install Python
    info(f"Installing Python {version}...")
    
    try:
        if os_name == "windows":
            python_exe = install_windows(version, install_dir, arch)
        else:
            python_exe = install_unix(version, install_dir, os_name, arch)
        
        # Verify Python works
        result = subprocess.run(
            [str(python_exe), "--version"],
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            raise RuntimeError("Python installation failed verification")
        
        success(f"Python installed: {result.stdout.strip()}")
        
        # Install pip
        install_pip(python_exe, install_dir)
        
        # Configure PATH
        if os_name == "windows":
            configure_path_windows(install_dir)
        else:
            configure_path_unix(install_dir)
        
        # Summary
        header("Installation Complete!")
        print(f"  Python: {python_exe}")
        
        if os_name == "windows":
            print(f"  pip: {install_dir / 'Scripts' / 'pip.exe'}")
        else:
            print(f"  pip: {install_dir / 'bin' / 'pip3'}")
        
        print()
        print(f"  {Colors.CYAN}Activate in current session:{Colors.NC}")
        if os_name == "windows":
            print(f"    {Colors.YELLOW}. .\\scripts\\activate.ps1{Colors.NC}")
        else:
            print(f"    {Colors.YELLOW}source ./scripts/activate.sh{Colors.NC}")
        print()
        
    except Exception as e:
        error(f"Installation failed: {e}")
        sys.exit(1)


def uninstall() -> None:
    """Uninstall Python-NoAdmin."""
    
    install_dir = get_install_dir()
    os_name, _ = get_platform_info()
    
    header("Python-NoAdmin Uninstaller")
    
    if not install_dir.exists():
        info(f"Nothing to uninstall. Directory not found: {install_dir}")
        return
    
    # Confirm
    print(f"This will remove: {install_dir}")
    response = input("Continue? [y/N] ").strip().lower()
    
    if response not in ("y", "yes"):
        info("Uninstallation cancelled")
        return
    
    # Remove installation
    info("Removing installation...")
    shutil.rmtree(install_dir)
    success(f"Removed: {install_dir}")
    
    # Note about PATH
    if os_name == "windows":
        info("Note: You may want to remove Python-NoAdmin entries from your user PATH")
        info("  System Properties > Environment Variables > User variables > PATH")
    else:
        info("Note: Remove Python-NoAdmin lines from your shell profile")
        info("  (e.g., ~/.bashrc, ~/.zshrc)")
    
    success("Uninstallation complete")


def list_versions() -> None:
    """List available Python versions."""
    print()
    print("Available Python versions:")
    print()
    for v in AVAILABLE_VERSIONS:
        marker = " (default)" if v == DEFAULT_VERSION else ""
        print(f"  • {v}{marker}")
    print()
    print("Note: Other versions may work but are not tested.")
    print()


# ============================================================================
# Entry Point
# ============================================================================

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Install Python without administrator access",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python install.py                    Install default Python version
  python install.py --version 3.11.9   Install specific version
  python install.py --list             List available versions
  python install.py --force            Force reinstall
  python install.py --uninstall        Remove installation
"""
    )
    
    parser.add_argument(
        "--version", "-v",
        default=DEFAULT_VERSION,
        help=f"Python version to install (default: {DEFAULT_VERSION})"
    )
    parser.add_argument(
        "--force", "-f",
        action="store_true",
        help="Force reinstall even if already installed"
    )
    parser.add_argument(
        "--list", "-l",
        action="store_true",
        dest="list_versions",
        help="List available Python versions"
    )
    parser.add_argument(
        "--uninstall", "-u",
        action="store_true",
        help="Uninstall Python-NoAdmin"
    )
    
    args = parser.parse_args()
    
    if args.list_versions:
        list_versions()
    elif args.uninstall:
        uninstall()
    else:
        install(args.version, args.force)


if __name__ == "__main__":
    main()
