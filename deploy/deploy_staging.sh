#!/usr/bin/env bash
# Deploy the Flask app to the staging host (invoked by Jenkins / GitHub Actions).
set -euo pipefail
APP_DIR="${STAGING_APP_DIR:-/opt/flask_practice}"
echo "Syncing application to $APP_DIR ..."
rsync -a --delete --exclude '.git' --exclude '.venv' ./ "$APP_DIR/"
cd "$APP_DIR"
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt gunicorn
sudo systemctl restart flask-staging   # gunicorn service unit on the staging host
echo "Staging deploy complete."
