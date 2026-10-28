#!/usr/bin/env bash
# FoodShare BD - build the React website into backend/web (needs Node.js 18+).  Run: bash build-frontend.sh
set -e
cd "$(dirname "$0")/frontend"
command -v npm >/dev/null 2>&1 || { echo "Node.js not found. Install it from https://nodejs.org"; exit 1; }
npm install --no-audit --no-fund
VITE_API_URL=/api VITE_USE_MOCK=false npm run build
rm -rf ../backend/web
cp -r dist ../backend/web
echo "Done. The website is in backend/web. Start the server with: bash start-mac-linux.sh"
