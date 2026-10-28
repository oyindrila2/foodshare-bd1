@echo off
REM FoodShare BD - run all backend tests (uses a temporary database, your foodshare.db is not touched).
cd /d "%~dp0backend"
if not exist venv\Scripts\python.exe python -m venv venv
venv\Scripts\python.exe -m pip install --disable-pip-version-check -q -r requirements-dev.txt
venv\Scripts\python.exe -m pytest -q
pause
