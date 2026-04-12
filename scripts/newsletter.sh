#!/usr/bin/env bash
# Usage: ./scripts/newsletter.sh <post-slug> [--preview]
set -euo pipefail

SLUG="${1:?Usage: newsletter.sh <post-slug> [--preview]}"
PREVIEW="${2:-}"

# Load env
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

if [ -z "${BUTTONDOWN_API_KEY:-}" ]; then
  echo "❌ BUTTONDOWN_API_KEY not set in .env"
  exit 1
fi

# Find post
POST=$(find src/content/blog/ -name "*${SLUG}*" -type f | head -1)
if [ -z "$POST" ]; then
  echo "❌ No post found matching: $SLUG"
  exit 1
fi

# Check if already sent
if grep -q "sent: true" "$POST" 2>/dev/null; then
  echo "⚠️  Newsletter already sent for this post. Send anyway? (y/N)"
  read -r CONFIRM
  [ "$CONFIRM" != "y" ] && exit 0
fi

# Extract metadata
TITLE=$(grep '^title:' "$POST" | sed 's/title: *"//;s/"$//')
BODY=$(sed '1,/^---$/d' "$POST" | sed '/^---$/d')

echo "📬 Newsletter: $TITLE"
echo "   Post: $POST"

if [ "$PREVIEW" = "--preview" ]; then
  echo ""
  echo "--- PREVIEW ---"
  echo "Subject: $TITLE"
  echo ""
  echo "$BODY" | head -20
  echo "..."
  echo "--- END PREVIEW ---"
  exit 0
fi

# Send via Buttondown API
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "https://api.buttondown.com/v1/emails" \
  -H "Authorization: Token ${BUTTONDOWN_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"subject\": \"$TITLE\",
    \"body\": $(echo "$BODY" | jq -Rs .),
    \"status\": \"draft\"
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY_RESP=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
  # Mark as sent in frontmatter
  SENT_DATE=$(date +%Y-%m-%d)
  sed -i "/^minutesRead:/a newsletter:\n  sent: true\n  sentDate: ${SENT_DATE}" "$POST"
  echo "✅ Newsletter queued as draft in Buttondown!"
  echo "   → Go to buttondown.com to review and send"
else
  echo "❌ Failed (HTTP $HTTP_CODE): $BODY_RESP"
  exit 1
fi
