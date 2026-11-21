@echo off
title FoodLink APK Download Server
cd /d "%~dp0"

echo ======================================================================
echo    FoodLink APK Download Server
echo ======================================================================

where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed or not in PATH!
    echo Please install Python from https://www.python.org/
    pause
    exit /b 1
)

python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/qr', timeout=2)" >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] FoodLink APK Server is ALREADY RUNNING and HEALTHY on port 8080!
    echo.
    python -c "import socket; s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.connect(('8.8.8.8', 80)); ip = s.getsockname()[0]; s.close(); print(f'  - Direct APK Link:   http://{ip}:8080/foodlink.apk'); print(f'  - Mobile Web Portal: http://{ip}:8080/'); print(f'  - QR Code Hub:       http://{ip}:8080/qr')"
    echo ======================================================================
    echo.
    echo Press any key to open the QR Code Hub in your browser...
    pause >nul
    start "" "http://127.0.0.1:8080/qr"
    exit /b 0
)

echo Starting server...
python serve_apk.py

if %errorlevel% neq 0 (
    echo.
    echo [!] Server exited with an error code %errorlevel%.
    pause
)
