#!/usr/bin/env bash
# Usage: ./scripts/publish.sh <draft-filename-or-slug>
set -euo pipefail

QUERY="${1:?Usage: publish.sh <draft-slug>}"
DATE=$(date +%Y-%m-%d)

# Find matching draft
MATCH=$(find drafts/ -name "*${QUERY}*" -type f 2>/dev/null | head -1)

if [ -z "$MATCH" ]; then
  echo "❌ No draft found matching: $QUERY"
  echo "Available drafts:"
  ls drafts/ 2>/dev/null || echo "  (none)"
  exit 1
fi

BASENAME=$(basename "$MATCH")
# Strip old date prefix if present, re-prefix with today
CLEAN_NAME=$(echo "$BASENAME" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-//')
NEW_FILE="src/content/blog/${DATE}-${CLEAN_NAME}"

# Update frontmatter: draft false, set publishedDate
sed -i "s/^draft: true/draft: false/" "$MATCH"
sed -i "s/^publishedDate:.*/publishedDate: ${DATE}/" "$MATCH"

# Move
mv "$MATCH" "$NEW_FILE"

echo "🚀 Published: $NEW_FILE"
echo "Run 'npm run deploy' or 'claude deploy' to ship it live."
