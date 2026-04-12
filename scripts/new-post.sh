#!/usr/bin/env bash
# Usage: ./scripts/new-post.sh "My Post Title" [--tags=tag1,tag2] [--draft]
set -euo pipefail

TITLE="${1:?Usage: new-post.sh \"Post Title\" [--tags=t1,t2] [--draft]}"
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
DATE=$(date +%Y-%m-%d)
TAGS='["general"]'
DRAFT="false"
TARGET_DIR="src/content/blog"

# Parse flags
for arg in "${@:2}"; do
  case $arg in
    --tags=*)
      RAW_TAGS="${arg#*=}"
      TAGS=$(echo "$RAW_TAGS" | tr ',' '\n' | sed 's/^/"/;s/$/"/' | paste -sd',' | sed 's/^/[/;s/$/]/')
      ;;
    --draft)
      DRAFT="true"
      TARGET_DIR="drafts"
      ;;
  esac
done

FILE="$TARGET_DIR/$DATE-$SLUG.md"

# Safety check
if [ -f "$FILE" ]; then
  echo "❌ File already exists: $FILE"
  exit 1
fi

mkdir -p "$TARGET_DIR"

cat > "$FILE" << EOF
---
title: "$TITLE"
description: ""
publishedDate: $DATE
author: "nerf-dev"
tags: $TAGS
draft: $DRAFT
featured: false
minutesRead: 0
---

<!-- Write your post here -->


EOF

echo "✅ Created: $FILE"
echo "📝 Open and start writing!"

# Open in editor if available
if [ -n "${EDITOR:-}" ]; then
  $EDITOR "$FILE"
fi
