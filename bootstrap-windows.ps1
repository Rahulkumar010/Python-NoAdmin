<#
.SYNOPSIS
    Bootstrap Python without administrator access on Windows.

.DESCRIPTION
    Downloads and installs Python using the official embeddable package,
    then configures pip and environment variables at the user level.
    No administrator privileges are required.

.NOTES
    Repository: Python-NoAdmin
    Requires: PowerShell 5.1+, Internet access
#>

param(
    [string]$InstallDir = "$env:USERPROFILE\.python-nonadmin",
    [switch]$Force,
    [switch]$SkipPathUpdate
)

$ErrorActionPreference = "Stop"

# ============================================================================
# Configuration
# ============================================================================

$ConfigFile = Join-Path $PSScriptRoot "config.json"
if (Test-Path $ConfigFile) {
    $Config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
    $PythonVersion = $Config.python_version
    $EmbeddableUrl = $Config.windows.embeddable_url
    $GetPipUrl = $Config.windows.get_pip_url
} else {
    # Fallback defaults
    $PythonVersion = "3.12.8"
    $EmbeddableUrl = "https://www.python.org/ftp/python/3.12.8/python-3.12.8-embed-amd64.zip"
    $GetPipUrl = "https://bootstrap.pypa.io/get-pip.py"
}

$PythonMajorMinor = ($PythonVersion -split '\.')[0..1] -join ''
$PthFile = "python$PythonMajorMinor._pth"

# ============================================================================
# Functions
# ============================================================================

function Write-Status {
    param([string]$Message, [string]$Type = "INFO")
    $colors = @{
        "INFO" = "Cyan"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
    }
    Write-Host "[$Type] " -ForegroundColor $colors[$Type] -NoNewline
    Write-Host $Message
}

function Test-InternetConnection {
    try {
        $null = Invoke-WebRequest -Uri "https://www.python.org" -Method Head -TimeoutSec 5 -UseBasicParsing
        return $true
    } catch {
        return $false
    }
}

function Get-FileFromUrl {
    param(
        [string]$Url,
        [string]$OutFile
    )
    Write-Status "Downloading: $Url"
    
    # Use BITS for better reliability, fall back to Invoke-WebRequest
    try {
        Start-BitsTransfer -Source $Url -Destination $OutFile -ErrorAction Stop
    } catch {
        Write-Status "BITS transfer failed, using Invoke-WebRequest..." "WARNING"
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
    }
}

function Add-ToUserPath {
    param([string]$PathToAdd)
    
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$PathToAdd*") {
        $newPath = "$PathToAdd;$currentPath"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Status "Added to user PATH: $PathToAdd" "SUCCESS"
        return $true
    } else {
        Write-Status "Already in user PATH: $PathToAdd" "INFO"
        return $false
    }
}

# ============================================================================
# Pre-flight Checks
# ============================================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  Python-NoAdmin Bootstrap (Windows)" -ForegroundColor Magenta
Write-Host "  Python $PythonVersion" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""

# Check if already installed
if ((Test-Path $InstallDir) -and (-not $Force)) {
    Write-Status "Python already installed at: $InstallDir" "WARNING"
    Write-Status "Use -Force to reinstall" "INFO"
    
    $pythonExe = Join-Path $InstallDir "python.exe"
    if (Test-Path $pythonExe) {
        Write-Status "Existing version: $((& $pythonExe --version) 2>&1)" "INFO"
    }
    exit 0
}

# Check internet
Write-Status "Checking internet connection..."
if (-not (Test-InternetConnection)) {
    Write-Status "No internet connection. Cannot download Python." "ERROR"
    exit 1
}
Write-Status "Internet connection OK" "SUCCESS"

# ============================================================================
# Download and Extract Python
# ============================================================================

$TempDir = Join-Path $env:TEMP "python-nonadmin-setup"
$ZipFile = Join-Path $TempDir "python-embed.zip"

# Clean up any previous temp files
if (Test-Path $TempDir) {
    Remove-Item -Recurse -Force $TempDir
}
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

# Download embeddable package
Write-Status "Downloading Python $PythonVersion embeddable package..."
Get-FileFromUrl -Url $EmbeddableUrl -OutFile $ZipFile

# Create install directory
if (Test-Path $InstallDir) {
    Write-Status "Removing existing installation..." "WARNING"
    Remove-Item -Recurse -Force $InstallDir
}
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

# Extract
Write-Status "Extracting to: $InstallDir"
Expand-Archive -Path $ZipFile -DestinationPath $InstallDir -Force

# ============================================================================
# Configure Python for pip
# ============================================================================

# The embeddable package disables site-packages by default via the ._pth file
# We need to uncomment "import site" to enable pip
$PthFilePath = Join-Path $InstallDir $PthFile

if (Test-Path $PthFilePath) {
    Write-Status "Configuring $PthFile for pip support..."
    $pthContent = Get-Content $PthFilePath -Raw
    
    # Uncomment "import site" if it's commented
    if ($pthContent -match '#\s*import site') {
        $pthContent = $pthContent -replace '#\s*import site', 'import site'
        Set-Content -Path $PthFilePath -Value $pthContent -NoNewline
        Write-Status "Enabled 'import site' in $PthFile" "SUCCESS"
    } elseif ($pthContent -notmatch 'import site') {
        # Add it if it doesn't exist at all
        Add-Content -Path $PthFilePath -Value "`nimport site"
        Write-Status "Added 'import site' to $PthFile" "SUCCESS"
    } else {
        Write-Status "'import site' already enabled" "INFO"
    }
} else {
    Write-Status "Warning: $PthFile not found" "WARNING"
}

# ============================================================================
# Install pip
# ============================================================================

$GetPipFile = Join-Path $TempDir "get-pip.py"
$PythonExe = Join-Path $InstallDir "python.exe"

Write-Status "Downloading get-pip.py..."
Get-FileFromUrl -Url $GetPipUrl -OutFile $GetPipFile

Write-Status "Installing pip..."
& $PythonExe $GetPipFile --no-warn-script-location 2>&1 | ForEach-Object { Write-Host "  $_" }

if ($LASTEXITCODE -ne 0) {
    Write-Status "Failed to install pip" "ERROR"
    exit 1
}

Write-Status "pip installed successfully" "SUCCESS"

# ============================================================================
# Create Scripts directory and add to PATH
# ============================================================================

$ScriptsDir = Join-Path $InstallDir "Scripts"
if (-not (Test-Path $ScriptsDir)) {
    New-Item -ItemType Directory -Path $ScriptsDir -Force | Out-Null
}

# ============================================================================
# Update User PATH
# ============================================================================

if (-not $SkipPathUpdate) {
    Write-Status "Updating user PATH environment variable..."
    $pathUpdated1 = Add-ToUserPath -PathToAdd $InstallDir
    $pathUpdated2 = Add-ToUserPath -PathToAdd $ScriptsDir
    
    if ($pathUpdated1 -or $pathUpdated2) {
        Write-Status "PATH updated. Restart your terminal for changes to take effect." "WARNING"
    }
    
    # Update current session
    $env:PATH = "$InstallDir;$ScriptsDir;$env:PATH"
}

# ============================================================================
# Clean up
# ============================================================================

Write-Status "Cleaning up temporary files..."
Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue

# ============================================================================
# Verification
# ============================================================================

Write-Host ""
Write-Status "Verifying installation..."

$pythonVersion = & $PythonExe --version 2>&1
Write-Status "Python: $pythonVersion" "SUCCESS"

$pipExe = Join-Path $ScriptsDir "pip.exe"
if (Test-Path $pipExe) {
    $pipVersion = & $pipExe --version 2>&1
    Write-Status "pip: $pipVersion" "SUCCESS"
} else {
    # Try pip via python -m pip
    $pipVersion = & $PythonExe -m pip --version 2>&1
    Write-Status "pip: $pipVersion" "SUCCESS"
}

# ============================================================================
# Summary
# ============================================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Install location: $InstallDir" -ForegroundColor White
Write-Host "  Python executable: $PythonExe" -ForegroundColor White
Write-Host ""
Write-Host "  To activate in current session:" -ForegroundColor Cyan
Write-Host "    . .\scripts\activate.ps1" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Or restart your terminal to use 'python' and 'pip' directly." -ForegroundColor Cyan
Write-Host ""

# Return success
exit 0
