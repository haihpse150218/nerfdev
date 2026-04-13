#!/usr/bin/env bash
# Start local dev server for the subscribe API + blog.
#
# Usage:
#   bash scripts/start.sh          # build + start server (foreground)
#   bash scripts/start.sh --fresh  # also re-apply D1 migrations (safe: IF NOT EXISTS)
#   bash scripts/start.sh --clean  # wipe local subscribers table before start
#
# After server is ready, open a second terminal and run:
#   bash scripts/test.sh           # runs the curl test suite against :8788

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

DB_NAME="nerfdev-subscribers"
PORT="${PORT:-8788}"
ENV_FILE=".env"

FRESH=0
CLEAN=0
for arg in "$@"; do
  case "$arg" in
    --fresh) FRESH=1 ;;
    --clean) CLEAN=1 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "Unknown flag: $arg"; exit 2 ;;
  esac
done

echo "==> Checking prerequisites"
[[ -f "$ENV_FILE" ]] || { echo "Missing $ENV_FILE"; exit 1; }
command -v npx >/dev/null || { echo "npx not found"; exit 1; }

if [[ "$FRESH" -eq 1 ]]; then
  echo "==> Applying D1 migrations (local)"
  npx wrangler d1 migrations apply "$DB_NAME" --local --env-file="$ENV_FILE"
fi

if [[ "$CLEAN" -eq 1 ]]; then
  echo "==> Clearing subscribers table (local)"
  npx wrangler d1 execute "$DB_NAME" --local --env-file="$ENV_FILE" \
    --command="DELETE FROM subscribers;"
fi

echo "==> Building Astro site"
npm run build

echo "==> Starting wrangler pages dev on http://127.0.0.1:${PORT}"
echo "    (Ctrl+C to stop. In another terminal: bash scripts/test.sh)"
echo
exec npx wrangler pages dev ./dist --port "$PORT" --env-file="$ENV_FILE"
