@echo off
REM Python-NoAdmin Installer - Windows Wrapper
REM
REM This script bootstraps a minimal Python to run the install.py script.
REM Downloads using pure Windows tools (curl/certutil) - NO PowerShell required.
REM

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "BIN_DIR=%SCRIPT_DIR%bin"
set "BOOTSTRAP_PYTHON=%BIN_DIR%\python\python.exe"
set "INSTALL_SCRIPT=%SCRIPT_DIR%install.py"

REM Python version and URL for bootstrap
set "BOOTSTRAP_VERSION=3.12.8"
set "BOOTSTRAP_URL=https://www.python.org/ftp/python/3.12.8/python-3.12.8-embed-amd64.zip"

echo.
echo ============================================
echo   Python-NoAdmin Installer
echo ============================================
echo.

REM Check if bootstrap Python already exists
if exist "%BOOTSTRAP_PYTHON%" (
    echo [INFO] Bootstrap Python found
    goto :run_installer
)

REM Download and extract bootstrap Python
echo [INFO] Downloading bootstrap Python %BOOTSTRAP_VERSION%...
echo [INFO] URL: %BOOTSTRAP_URL%

REM Create bin directory
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%BIN_DIR%\python" mkdir "%BIN_DIR%\python"

set "ZIP_FILE=%BIN_DIR%\python-bootstrap.zip"

REM Try download methods in order of preference (no PowerShell!)

REM Method 1: curl.exe (built into Windows 10 1803+, April 2018)
where curl.exe >nul 2>&1
if %errorlevel%==0 (
    echo [INFO] Using curl.exe...
    curl.exe -L -o "%ZIP_FILE%" "%BOOTSTRAP_URL%" --progress-bar
    if %errorlevel%==0 goto :download_success
    echo [WARNING] curl failed, trying alternative...
)

REM Method 2: certutil (available on all Windows versions, no PowerShell)
echo [INFO] Using certutil...
certutil -urlcache -split -f "%BOOTSTRAP_URL%" "%ZIP_FILE%" >nul 2>&1
if %errorlevel%==0 (
    REM Clean up certutil cache
    certutil -urlcache -split -f "%BOOTSTRAP_URL%" delete >nul 2>&1
    goto :download_success
)

REM Method 3: bitsadmin (legacy but widely available)
echo [INFO] Using bitsadmin...
bitsadmin /transfer "PythonDownload" /download /priority high "%BOOTSTRAP_URL%" "%ZIP_FILE%" >nul 2>&1
if %errorlevel%==0 goto :download_success

REM All methods failed
echo [ERROR] Failed to download bootstrap Python.
echo [ERROR] Please download manually from: %BOOTSTRAP_URL%
echo [ERROR] And extract to: %BIN_DIR%\python\
exit /b 1

:download_success
echo [SUCCESS] Download complete

REM Extract ZIP file without PowerShell
REM Method 1: tar (available in Windows 10 1803+)
where tar.exe >nul 2>&1
if %errorlevel%==0 (
    echo [INFO] Extracting with tar...
    tar.exe -xf "%ZIP_FILE%" -C "%BIN_DIR%\python"
    if %errorlevel%==0 goto :extract_success
)

REM Method 2: Use VBScript for extraction (works on older Windows)
echo [INFO] Extracting with VBScript...
set "VBS_SCRIPT=%BIN_DIR%\unzip.vbs"

(
echo Set objShell = CreateObject("Shell.Application"^)
echo Set objSource = objShell.NameSpace("%ZIP_FILE%"^)
echo Set objTarget = objShell.NameSpace("%BIN_DIR%\python"^)
echo objTarget.CopyHere objSource.Items, 4 + 16
) > "%VBS_SCRIPT%"

cscript //nologo "%VBS_SCRIPT%"
set "EXTRACT_RESULT=%errorlevel%"
del "%VBS_SCRIPT%" 2>nul

if not "%EXTRACT_RESULT%"=="0" (
    echo [ERROR] Failed to extract bootstrap Python
    exit /b 1
)

:extract_success
echo [SUCCESS] Extraction complete

REM Delete zip file
del "%ZIP_FILE%" 2>nul

REM Enable site-packages for the bootstrap Python (modify ._pth file)
set "PTH_FILE=%BIN_DIR%\python\python312._pth"
if exist "%PTH_FILE%" (
    echo [INFO] Configuring Python for site-packages...
    
    REM Use pure batch to modify the file
    set "PTH_TEMP=%BIN_DIR%\python\python312._pth.tmp"
    
    (
        for /f "usebackq delims=" %%a in ("%PTH_FILE%") do (
            set "line=%%a"
            if "!line!"=="#import site" (
                echo import site
            ) else (
                echo !line!
            )
        )
    ) > "%PTH_TEMP%"
    
    move /y "%PTH_TEMP%" "%PTH_FILE%" >nul
    echo [SUCCESS] Python configured
)

echo [SUCCESS] Bootstrap Python ready

:run_installer
REM Run the Python installer script
echo.
echo [INFO] Running installer...
echo.

"%BOOTSTRAP_PYTHON%" "%INSTALL_SCRIPT%" %*

endlocal
