#!/usr/bin/env bash
# Ensure the per-project Plan dashboard is running, and print its URL.
#
# One server hosts EVERY plan-site and .plan.md in this project's plans/ dir —
# it replaces the old "one pm2 process per plan-site". Safe to run repeatedly:
# if the project's server is already up it just reuses it (no duplicate procs).
#
#   ./ensure.sh            # start-or-reuse, print the dashboard URL
#   ./ensure.sh --restart  # restart it (after editing the server)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"           # plans/_server
PLANS_DIR="$(cd .. && pwd)"
PROJECT_DIR="$(cd ../.. && pwd)"
NAME="$(basename "$PROJECT_DIR")-plans"
PORT="$(python3 plans_server.py --ensure-port "$PLANS_DIR")"
HOST="$(hostname)"

if [ "${1:-}" = "--restart" ]; then
  pm2 restart "$NAME" >/dev/null 2>&1 || true
elif pm2 describe "$NAME" >/dev/null 2>&1; then
  : # already registered — reuse it
else
  pm2 start "$(pwd)/plans_server.py" --name "$NAME" --interpreter python3 -- "$PORT" "$PLANS_DIR" >/dev/null
  pm2 save >/dev/null 2>&1 || true
fi

echo ""
echo "  $NAME  (one server for all plans in this project)"
echo "  ─────────────────────────────────────────────"
echo "  Dashboard:  http://${HOST}:${PORT}/"
echo "  (local:     http://localhost:${PORT}/ )"
echo ""
