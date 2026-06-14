#!/usr/bin/env bash
# Serve this plan-site report standalone. Usage: ./serve.sh [port]
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
PORT="${1:-8920}"

echo ""
echo "  plan-site report"
echo "  ────────────────"
echo "  Report:  http://localhost:${PORT}/"
echo "  (also:   http://$(hostname):${PORT}/ )"
echo ""
echo "  Ctrl-C to stop."
echo ""

exec python3 "$(dirname "${BASH_SOURCE[0]}")/serve.py" "${PORT}"
