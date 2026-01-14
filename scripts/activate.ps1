<#
.SYNOPSIS
    Activate Python-NoAdmin environment in the current PowerShell session.

.DESCRIPTION
    Adds the Python-NoAdmin installation to the current session's PATH.
    Does not modify system or user environment variables permanently.

.EXAMPLE
    . .\scripts\activate.ps1
#>

$InstallDir = "$env:USERPROFILE\.python-nonadmin"
$ScriptsDir = Join-Path $InstallDir "Scripts"

# Check if installed
if (-not (Test-Path $InstallDir)) {
    Write-Host "[ERROR] Python-NoAdmin not installed at: $InstallDir" -ForegroundColor Red
    Write-Host "Run install.cmd first." -ForegroundColor Yellow
    return
}

# Store original PATH for deactivation
if (-not $env:_PYTHON_NONADMIN_OLD_PATH) {
    $env:_PYTHON_NONADMIN_OLD_PATH = $env:PATH
}

# Add to PATH
$env:PATH = "$InstallDir;$ScriptsDir;$env:PATH"

# Set VIRTUAL_ENV-like variable for compatibility
$env:PYTHON_NONADMIN_ACTIVE = "1"

# Define deactivate function
function global:Deactivate-PythonNoAdmin {
    if ($env:_PYTHON_NONADMIN_OLD_PATH) {
        $env:PATH = $env:_PYTHON_NONADMIN_OLD_PATH
        Remove-Item Env:\_PYTHON_NONADMIN_OLD_PATH -ErrorAction SilentlyContinue
    }
    Remove-Item Env:\PYTHON_NONADMIN_ACTIVE -ErrorAction SilentlyContinue
    Remove-Item Function:\Deactivate-PythonNoAdmin -ErrorAction SilentlyContinue
    Write-Host "[INFO] Python-NoAdmin deactivated" -ForegroundColor Cyan
}

# Confirmation
$pythonVersion = & (Join-Path $InstallDir "python.exe") --version 2>&1
Write-Host ""
Write-Host "[SUCCESS] Python-NoAdmin activated" -ForegroundColor Green
Write-Host "  Python: $pythonVersion" -ForegroundColor White
Write-Host "  Location: $InstallDir" -ForegroundColor White
Write-Host ""
Write-Host "  To deactivate: Deactivate-PythonNoAdmin" -ForegroundColor Cyan
Write-Host ""
