#!/usr/bin/env bash
# Export subscribers from production D1 to CSV.
#
# Usage:
#   bash scripts/export-subscribers.sh            # to stdout
#   bash scripts/export-subscribers.sh out.csv    # to file
#   REMOTE=0 bash scripts/export-subscribers.sh   # export from local D1 instead

set -euo pipefail
cd "$(dirname "$0")/.."

FLAG="--remote"
[[ "${REMOTE:-1}" == "0" ]] && FLAG="--local"

OUT="${1:-/dev/stdout}"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

npx wrangler d1 execute nerfdev-subscribers "$FLAG" --env-file=.env --json \
  --command="SELECT id, email, status, buttondown_id, created_at FROM subscribers ORDER BY created_at DESC;" \
  > "$tmp"

# Wrangler returns: [{"results":[{...},{...}],"success":true,...}]
# Flatten to CSV using node (already installed as npm dep)
node -e '
  const fs = require("fs");
  const raw = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const rows = raw[0]?.results ?? [];
  console.log("id,email,status,buttondown_id,created_at_iso");
  for (const r of rows) {
    const iso = new Date(r.created_at * 1000).toISOString();
    const esc = (v) => v == null ? "" : `"${String(v).replace(/"/g, `""`)}"`;
    console.log([r.id, r.email, r.status, r.buttondown_id, iso].map(esc).join(","));
  }
' "$tmp" > "$OUT"

[[ "$OUT" != "/dev/stdout" ]] && echo "Wrote $(wc -l < "$OUT") lines to $OUT"
