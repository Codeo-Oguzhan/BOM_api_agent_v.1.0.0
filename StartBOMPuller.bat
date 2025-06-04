@echo off
setlocal enabledelayedexpansion

REM Change directory to the script's location
cd /d "%~dp0"

echo ========================================
echo [%date% %time%] BOM Puller Auto-Updater
echo ========================================
echo [%date% %time%] Checking system dependencies...

REM ========================================
REM DEPENDENCY CHECKS
REM ========================================

echo Checking Python installation... 
REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [%date% %time%] ERROR: Python is not installed!
    echo Please install Python from https://www.python.org/downloads/
    echo Make sure to add Python to your PATH during installation.
    pause
    exit /b 1
) else (
    echo [%date% %time%] ✓ Python is installed
)

echo Checking requests package...
REM Check if requests package is installed
python -c "import requests" >nul 2>&1
if %errorlevel% neq 0 (
    echo [%date% %time%] Installing requests package...
    pip install requests
    if %errorlevel% neq 0 (
        echo [%date% %time%] ERROR: Failed to install requests package
        echo Please run 'pip install requests' manually.
        pause
        exit /b 1
    ) else (
        echo [%date% %time%] ✓ Requests package installed successfully
    )
) else (
    echo [%date% %time%] ✓ Requests package is installed
)

echo Checking Git installation...
REM Check if Git is installed
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [%date% %time%] Git is not installed. Attempting automatic installation...
    
    REM Try winget first (Windows Package Manager)
    winget --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo [%date% %time%] Using Windows Package Manager to install Git...
        winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
        if %errorlevel% equ 0 (
            echo [%date% %time%] ✓ Git installed successfully via winget
            echo [%date% %time%] Please restart this script to continue.
            pause
            exit /b 0
        )
    )
    
    REM Try chocolatey if winget failed
    choco --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo [%date% %time%] Using Chocolatey to install Git...
        choco install git -y
        if %errorlevel% equ 0 (
            echo [%date% %time%] ✓ Git installed successfully via Chocolatey
            echo [%date% %time%] Please restart this script to continue.
            pause
            exit /b 0
        )
    )
    
    REM Manual installation instructions
    echo [%date% %time%] ERROR: Could not install Git automatically.
    echo.
    echo Please install Git manually:
    echo 1. Download Git from: https://git-scm.com/download/win
    echo 2. Run the installer with default settings
    echo 3. Restart this script after installation
    echo.
    echo Alternatively, install a package manager:
    echo - Windows Package Manager: https://aka.ms/getwinget
    echo - Chocolatey: https://chocolatey.org/install
    echo.
    pause
    exit /b 1
) else (
    echo [%date% %time%] ✓ Git is installed
)

echo [%date% %time%] All dependencies verified successfully!
echo.

:START_LOOP
echo ========================================
echo [%date% %time%] Starting BOM Puller with Auto-Update
echo ========================================

REM Check if this is a Git repository
if not exist ".git" (
    echo [%date% %time%] WARNING: Not a Git repository. Auto-update disabled.
    goto SKIP_GIT_CHECK
)

echo [%date% %time%] Checking for Git updates...

REM Fetch latest changes from remote
echo [%date% %time%] Fetching latest changes from remote...
git fetch origin >nul 2>&1
if %errorlevel% neq 0 (
    echo [%date% %time%] WARNING: Failed to fetch from remote repository
    goto SKIP_GIT_CHECK
)

REM Check if there are updates available
git status -uno | find "Your branch is behind" >nul
if %errorlevel% equ 0 (
    echo [%date% %time%] Updates available! Pulling latest changes...
    git pull origin
    if %errorlevel% equ 0 (
        echo [%date% %time%] Repository updated successfully!
        echo [%date% %time%] Restarting with updated code...
        goto START_LOOP
    ) else (
        echo [%date% %time%] WARNING: Failed to pull updates. Continuing with current version.
    )
) else (
    echo [%date% %time%] Repository is up to date.
)

:SKIP_GIT_CHECK
:RUN_PYTHON
REM Start Python script with update checking
echo [%date% %time%] Starting BOM_puller.py with auto-update monitoring...
echo ---------------------------------------

REM Start Python script in background and get its PID
start /b python BOM_puller.py
set PYTHON_PID=%ERRORLEVEL%

REM Wait and check for updates every 5 minutes (300 seconds)
set /a CHECK_INTERVAL=300
echo [%date% %time%] Auto-update check will run every %CHECK_INTERVAL% seconds

:UPDATE_CHECK_LOOP
timeout /t %CHECK_INTERVAL% /nobreak >nul

REM Check if Git repository exists
if not exist ".git" goto UPDATE_CHECK_LOOP

REM Check if Git is available
git --version >nul 2>&1
if %errorlevel% neq 0 goto UPDATE_CHECK_LOOP

echo [%date% %time%] Checking for repository updates...

REM Fetch latest changes
git fetch origin >nul 2>&1
if %errorlevel% neq 0 goto UPDATE_CHECK_LOOP

REM Check if updates are available
git status -uno | find "Your branch is behind" >nul
if %errorlevel% equ 0 (
    echo [%date% %time%] New updates detected! Stopping current process...
    
    REM Kill Python processes
    taskkill /f /im python.exe >nul 2>&1
    timeout /t 3 >nul
    
    echo [%date% %time%] Pulling latest changes...
    git pull origin
    if %errorlevel% equ 0 (
        echo [%date% %time%] Update successful! Restarting...
        goto START_LOOP
    ) else (
        echo [%date% %time%] Update failed! Restarting with current version...
        goto RUN_PYTHON
    )
) else (
    echo [%date% %time%] No updates available. Continuing monitoring...
)

goto UPDATE_CHECK_LOOP
