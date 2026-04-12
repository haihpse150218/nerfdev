#!/usr/bin/env bash
# Blog stats — quick overview
set -euo pipefail

BLOG_DIR="src/content/blog"
DRAFT_DIR="drafts"

echo "📊 Nerf Dev Blog Stats"
echo "━━━━━━━━━━━━━━━━━━━━━"

# Post counts
PUBLISHED=$(find "$BLOG_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
DRAFTS=$(find "$DRAFT_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
echo "📝 Published posts: $PUBLISHED"
echo "📋 Drafts: $DRAFTS"

# Total word count
if [ "$PUBLISHED" -gt 0 ]; then
  WORDS=$(cat "$BLOG_DIR"/*.md 2>/dev/null | wc -w | tr -d ' ')
  echo "📖 Total words: $WORDS"
  AVG=$((WORDS / PUBLISHED))
  echo "📏 Avg words/post: $AVG"
fi

# Tags breakdown
echo ""
echo "🏷️  Tags:"
if [ "$PUBLISHED" -gt 0 ]; then
  grep -h '^tags:' "$BLOG_DIR"/*.md 2>/dev/null \
    | sed 's/tags: *\[//;s/\]//;s/"//g' \
    | tr ',' '\n' \
    | sed 's/^ *//;s/ *$//' \
    | sort | uniq -c | sort -rn \
    | head -10 \
    | while read count tag; do
        echo "   $tag ($count)"
      done
fi

# Recent posts
echo ""
echo "🕐 Last 5 posts:"
if [ "$PUBLISHED" -gt 0 ]; then
  ls -t "$BLOG_DIR"/*.md 2>/dev/null | head -5 | while read f; do
    TITLE=$(grep '^title:' "$f" | sed 's/title: *"//;s/"$//')
    DATE=$(grep '^publishedDate:' "$f" | sed 's/publishedDate: *//')
    echo "   [$DATE] $TITLE"
  done
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━"
