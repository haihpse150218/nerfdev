#!/usr/bin/env bash
# Curl-based smoke tests for /api/subscribe.
# Run `bash scripts/start.sh` in another terminal first.

set -uo pipefail

BASE="${BASE:-http://127.0.0.1:8788}"
DB_NAME="nerfdev-subscribers"
ENV_FILE=".env"

pass=0
fail=0

# Args: label, expected_substring, json_body
run() {
  local label="$1" expected="$2" body="$3"
  local resp
  resp="$(curl -s -X POST "${BASE}/api/subscribe" \
    -H "Content-Type: application/json" \
    -d "$body")"
  if [[ "$resp" == *"$expected"* ]]; then
    echo "  PASS  $label"
    echo "        -> $resp"
    pass=$((pass + 1))
  else
    echo "  FAIL  $label"
    echo "        expected substring: $expected"
    echo "        got:                $resp"
    fail=$((fail + 1))
  fi
}

EMAIL_NEW="smoke-$(date +%s)@example.com"

echo "==> Smoke tests against $BASE/api/subscribe"
echo

run "T1 valid email"       '"ok":true'  "{\"email\":\"$EMAIL_NEW\",\"website\":\"\",\"source\":\"/blog/hello-world\"}"
run "T2 invalid email"     'INVALID_EMAIL'     '{"email":"not-an-email","website":""}'
run "T3 missing email"     'MISSING_FIELDS'    '{"website":""}'
run "T4 honeypot"          'HONEYPOT_TRIGGERED' '{"email":"bot@evil.com","website":"http://spam.com"}'
run "T5 duplicate silent"  'Already subscribed' "{\"email\":\"$EMAIL_NEW\",\"website\":\"\"}"

echo
echo "==> Current rows in local D1"
npx wrangler d1 execute "$DB_NAME" --local --env-file="$ENV_FILE" \
  --command="SELECT email, status, substr(buttondown_id,1,8) AS bd, datetime(created_at,'unixepoch') AS at FROM subscribers ORDER BY created_at DESC LIMIT 5;" \
  2>/dev/null | tail -20

echo
echo "==> Summary: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]] || exit 1
