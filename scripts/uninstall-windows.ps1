<#
.SYNOPSIS
    Uninstall Python-NoAdmin on Windows.

.DESCRIPTION
    Removes the Python-NoAdmin installation directory and cleans up
    user PATH environment variable entries.
#>

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$InstallDir = "$env:USERPROFILE\.python-nonadmin"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Python-NoAdmin Uninstaller" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if installed
if (-not (Test-Path $InstallDir)) {
    Write-Host "[WARNING] Installation not found at: $InstallDir" -ForegroundColor Yellow
    exit 0
}

# Confirm unless -Force
if (-not $Force) {
    $response = Read-Host "This will remove Python-NoAdmin from $InstallDir. Continue? [y/N]"
    if ($response -notmatch '^[Yy]') {
        Write-Host "[INFO] Uninstallation cancelled." -ForegroundColor Cyan
        exit 0
    }
}

# Remove installation directory
Write-Host "[INFO] Removing installation directory..." -ForegroundColor Cyan
try {
    Remove-Item -Recurse -Force $InstallDir
    Write-Host "[SUCCESS] Removed: $InstallDir" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to remove installation: $_" -ForegroundColor Red
    exit 1
}

# Clean PATH
Write-Host "[INFO] Cleaning user PATH..." -ForegroundColor Cyan
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$pathParts = $currentPath -split ';' | Where-Object { $_ -notlike "*python-nonadmin*" }
$newPath = $pathParts -join ';'

if ($newPath -ne $currentPath) {
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Write-Host "[SUCCESS] Removed python-nonadmin entries from user PATH" -ForegroundColor Green
} else {
    Write-Host "[INFO] No python-nonadmin entries found in user PATH" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "[SUCCESS] Python-NoAdmin has been uninstalled." -ForegroundColor Green
Write-Host "[INFO] Restart your terminal for PATH changes to take effect." -ForegroundColor Cyan
Write-Host ""
