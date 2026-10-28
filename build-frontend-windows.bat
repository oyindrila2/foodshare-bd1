@echo off
REM FoodShare BD - build the React website into backend\web (needs Node.js 18 or newer).
REM Run this once after downloading the project, and again after you change frontend code.
setlocal
cd /d "%~dp0frontend"

where npm >nul 2>nul
if errorlevel 1 (
  echo Node.js was not found. Install the LTS version from https://nodejs.org and run this file again.
  if not "%1"=="nopause" pause
  exit /b 1
)

echo Installing frontend packages (first time can take a few minutes)...
call npm install --no-audit --no-fund
if errorlevel 1 (
  echo npm install failed. Check your internet connection and try again.
  if not "%1"=="nopause" pause
  exit /b 1
)

echo Building the website...
set VITE_API_URL=/api
set VITE_USE_MOCK=false
call npm run build
if errorlevel 1 (
  echo The build failed. Read the error above.
  if not "%1"=="nopause" pause
  exit /b 1
)

if exist "..\backend\web" rmdir /s /q "..\backend\web"
xcopy /e /i /y /q dist "..\backend\web" >nul
echo.
echo Done. The website is in backend\web. Start the server with start-windows.bat
if not "%1"=="nopause" pause
endlocal
