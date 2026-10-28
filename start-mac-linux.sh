#!/usr/bin/env bash
# FoodShare BD - start the whole app (website + API).  Run:  bash start-mac-linux.sh
# Do NOT open index.html directly; it only works through this server.
set -e
cd "$(dirname "$0")/backend"

PY=python3
command -v $PY >/dev/null 2>&1 || PY=python
$PY -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)" || {
  echo "FoodShare BD needs Python 3.10 or newer."; exit 1; }

if [ ! -x venv/bin/python ]; then
  echo "Creating the Python environment, first time only..."
  $PY -m venv venv
fi
venv/bin/python -m pip install --disable-pip-version-check -q -r requirements.txt
if [ ! -f web/index.html ]; then
  echo "The website is not built yet. Building it now (needs Node.js)..."
  bash ../build-frontend.sh || echo "Could not build the website; the API still runs (see http://localhost:5000/docs)."
fi

exec venv/bin/python run_server.py
