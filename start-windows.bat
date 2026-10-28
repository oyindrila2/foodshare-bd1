@echo off
REM FoodShare BD - double-click this file to start the whole app (website + API).
REM Do NOT open index.html directly; it only works through this server.
REM This script uses no ( ) blocks, so folder names like "foodshare (1)" cannot break it.
title FoodShare BD server
setlocal
cd /d "%~dp0backend"
if not exist "app\main.py" goto nobackend

echo.
echo [1/4] Looking for Python 3.10 or newer...
set "PY="
where python >nul 2>nul && python -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>nul && set "PY=python"
if not defined PY where py >nul 2>nul && py -3 -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>nul && set "PY=py -3"
if not defined PY goto nopython
echo       Using: %PY%

echo [2/4] Preparing the Python environment...
if exist "venv\Scripts\python.exe" goto havevenv
echo       Creating it, first time only. This can take a minute...
%PY% -m venv venv
if not exist "venv\Scripts\python.exe" goto novenv
:havevenv

echo [3/4] Installing / checking packages. First time: 1-3 minutes, please wait...
"venv\Scripts\python.exe" -m pip install --disable-pip-version-check -q -r requirements.txt
if errorlevel 1 goto nopip

if exist "web\index.html" goto webready
echo       The website is not built. Trying to build it with Node.js...
call "%~dp0build-frontend-windows.bat" nopause
cd /d "%~dp0backend"
:webready

echo [4/4] Starting the server. The browser opens by itself when it is ready.
"venv\Scripts\python.exe" run_server.py
echo.
echo The server has stopped. If you see an error above, send a screenshot of this window
echo (it is also saved in backend\startup-error.txt).
pause
exit /b 0

:nobackend
echo Cannot find the backend folder next to this file.
echo Extract the WHOLE ZIP first (right-click the ZIP, Extract All), then run start-windows.bat
echo from inside the extracted foodshare-project folder.
pause
exit /b 1

:nopython
echo Python 3.10 or newer was not found.
echo Install it from https://www.python.org/downloads/ and tick "Add python.exe to PATH".
echo Then run this file again.
pause
exit /b 1

:novenv
echo Could not create the Python environment (backend\venv).
echo Delete the backend\venv folder if it exists and try again.
pause
exit /b 1

:nopip
echo Package install failed. Check the internet connection and run this file again.
echo If it keeps failing, delete the backend\venv folder and try again.
pause
exit /b 1
