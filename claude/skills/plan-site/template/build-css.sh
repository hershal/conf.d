#!/usr/bin/env bash
# Recompile the self-contained Tailwind v4 stylesheet from ALL pages in this
# report folder, so the bundle stays dependency-free (no CDN at view time).
# Run this after adding/editing any .html page that uses new utility classes.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
REPORT_DIR="$(pwd)"

# Tailwind v4 standalone CLI, cached in a shared tmp dir across runs.
TW_DIR="/tmp/plan-site-tw"
TW="${TW_DIR}/node_modules/.bin/tailwindcss"
if [ ! -x "$TW" ]; then
  echo "Installing @tailwindcss/cli (one-time, into ${TW_DIR})…"
  mkdir -p "$TW_DIR"
  (cd "$TW_DIR" && npm init -y >/dev/null 2>&1 && npm install @tailwindcss/cli@4.2.2 >/dev/null 2>&1)
fi

cat > "${TW_DIR}/plan-site-in.css" <<CSS
@import "tailwindcss";
@source "${REPORT_DIR}";
@custom-variant dark (&:where(.dark, .dark *));
CSS

(cd "$TW_DIR" && "$TW" -i plan-site-in.css -o "${REPORT_DIR}/assets/tailwind.css" --minify)
echo "Wrote assets/tailwind.css ($(wc -c < "${REPORT_DIR}/assets/tailwind.css") bytes)"
