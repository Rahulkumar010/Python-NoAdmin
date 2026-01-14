# Windows Installation Guide

## Overview

This guide covers Python installation on Windows using the official Python embeddable package.

## Requirements

- Windows 10/11 (Windows 7/8 may work but are untested)
- PowerShell 5.1 or later (included with Windows 10+)
- Internet access
- ~100 MB free disk space

## Installation

```powershell
# Run the bootstrap script
.\bootstrap-windows.ps1

# For a fresh reinstall
.\bootstrap-windows.ps1 -Force
```

## Installation Location

Default: `%USERPROFILE%\.python-nonadmin`

This typically resolves to:
```
C:\Users\YourUsername\.python-nonadmin
```

## What Gets Installed

```
.python-nonadmin/
├── python.exe           # Main Python interpreter
├── pythonw.exe          # GUI Python (no console)
├── python312.dll        # Python DLL
├── python312._pth       # Path configuration
├── python312.zip        # Standard library (compressed)
├── Lib/                 # Additional libraries
│   └── site-packages/   # Installed packages
├── Scripts/             # pip, executables
│   ├── pip.exe
│   └── ...
└── DLLs/                # Extension modules
```

## PowerShell Execution Policy

If you see an execution policy error:

```powershell
# Check current policy
Get-ExecutionPolicy

# Set to allow local scripts (user-level, no admin needed)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

## Proxy Configuration

For corporate environments with proxy servers:

```powershell
# Set before running bootstrap
$env:HTTP_PROXY = "http://proxy.company.com:8080"
$env:HTTPS_PROXY = "http://proxy.company.com:8080"

# Then run
.\bootstrap-windows.ps1
```

To make pip respect the proxy permanently:

```powershell
pip config set global.proxy http://proxy.company.com:8080
```

## Antivirus Considerations

Some antivirus software may block downloads or quarantine Python files:

1. **Windows Defender**: Usually allows Python. If blocked, add an exclusion for the install directory.

2. **Corporate Antivirus**: May require IT whitelisting. As an alternative:
   - Manually download the embeddable package from python.org
   - Place it in the expected location
   - Run the script with `-SkipDownload` (if available)

## PATH Configuration

The bootstrap script adds two directories to your **user** PATH:

1. `%USERPROFILE%\.python-nonadmin` (for python.exe)
2. `%USERPROFILE%\.python-nonadmin\Scripts` (for pip and installed scripts)

This does **not** require administrator access as it modifies only user-level environment variables.

## Using Both System and User Python

If you have a system Python installed, the user-level PATH takes precedence in new terminals. To use system Python:

```powershell
# Check which python is active
where.exe python

# Full path to system Python (example)
C:\Python312\python.exe

# Full path to user Python
%USERPROFILE%\.python-nonadmin\python.exe
```

## Troubleshooting

### "python is not recognized"

Restart your terminal. If still failing:

```powershell
# Check if PATH was updated
$env:PATH -split ';' | Select-String "python-nonadmin"

# Manually add for current session
$env:PATH = "$env:USERPROFILE\.python-nonadmin;$env:USERPROFILE\.python-nonadmin\Scripts;$env:PATH"
```

### pip fails with SSL errors

This often indicates proxy issues or certificate problems:

```powershell
# Try with trusted host flags
pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org package-name
```

### "ImportError: No module named site"

The `._pth` file wasn't properly configured. Edit it manually:

```powershell
$pth = "$env:USERPROFILE\.python-nonadmin\python312._pth"
(Get-Content $pth) -replace '#import site', 'import site' | Set-Content $pth
```

## Complete Uninstallation

```powershell
# Remove installation directory
Remove-Item -Recurse -Force "$env:USERPROFILE\.python-nonadmin"

# Clean user PATH (manual step)
# Open: System Properties > Environment Variables > User variables
# Edit PATH and remove the python-nonadmin entries
```
