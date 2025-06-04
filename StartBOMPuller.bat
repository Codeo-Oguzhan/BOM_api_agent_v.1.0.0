@echo off
REM Change directory to the script's location
cd /d "%~dp0"

echo Checking Python installation... 
REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python is not installed! Please install Python from https://www.python.org/downloads/
    echo [%date% %time%] Python is not installed
    pause
    exit /b 1
) else (
    echo [%date% %time%] Python seems to be installed on the machine
)

echo Checking requests package...
REM Check if requests package is installed
python -c "import requests" >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing requests package...
    echo [%date% %time%] Requests package not found, attempting installation... 
    pip install requests
    if %errorlevel% neq 0 (
        echo Failed to install requests package. Please run 'pip install requests' manually.
        echo [%date% %time%] Failed to install requests package
        pause
        exit /b 1
    ) else (
        echo [%date% %time%] Requests package installed successfully
    )
) else (
    echo [%date% %time%] Requests package seems to be installed on the machine
)

REM Run the Python script
echo [%date% %time%] Starting BOM_puller.py
echo ---------------------------------------
python BOM_puller.py
echo [%date% %time%] BOM_puller.py execution completed

REM Pause so the window stays open
pause
