# Nerf Dev Blog — Claude CLI Management System

> Tech blog powered by Claude CLI
> Stack: Astro 5 + Markdown + Cloudflare Pages
> Newsletter: Buttondown (privacy-friendly)
> Management: Claude Code as content engine

---

## Architecture Overview

```
nerf-dev-blog/
├── CLAUDE.md                       # THIS FILE — CLI command center
├── astro.config.mjs                # Astro config + Cloudflare adapter
├── package.json
├── tsconfig.json
├── wrangler.toml                   # Cloudflare Pages config
├── .github/
│   └── workflows/
│       └── deploy.yml              # Auto-deploy on push to main
├── scripts/
│   ├── new-post.sh                 # Quick post scaffold
│   ├── publish.sh                  # Build + deploy pipeline
│   ├── newsletter.sh               # Send newsletter via Buttondown API
│   └── stats.sh                    # Blog stats: word count, post count, etc.
├── public/
│   ├── favicon.svg
│   ├── og/                         # Auto-generated OG images
│   └── assets/                     # Static images, files
├── src/
│   ├── content/
│   │   ├── config.ts               # Content collection schema (Zod)
│   │   └── blog/                   # All posts live here
│   │       └── YYYY-MM-DD-slug.md
│   ├── layouts/
│   │   ├── Base.astro              # HTML shell
│   │   └── Post.astro              # Single post layout
│   ├── pages/
│   │   ├── index.astro             # Home / latest posts
│   │   ├── blog/
│   │   │   ├── index.astro         # Blog archive
│   │   │   └── [...slug].astro     # Dynamic post pages
│   │   ├── tags/
│   │   │   └── [tag].astro         # Tag filtered view
│   │   ├── rss.xml.ts              # RSS feed
│   │   └── newsletter.astro        # Newsletter signup page
│   ├── components/
│   │   ├── Header.astro
│   │   ├── Footer.astro
│   │   ├── PostCard.astro
│   │   ├── TagList.astro
│   │   ├── NewsletterForm.astro
│   │   ├── TableOfContents.astro
│   │   └── CodeBlock.astro
│   └── styles/
│       └── global.css              # Design tokens + typography
└── drafts/                         # WIP posts (not built)
    └── *.md
```

---

## CLI Commands Reference

All commands run via `claude` in this project root.

### 📝 Content Creation

**New Post:**
```
claude "new post: <title>"
claude "new post: <title> --tags=<t1,t2> --series=<name>"
```
→ Creates `src/content/blog/YYYY-MM-DD-slug.md` with full frontmatter
→ Opens in $EDITOR if available

**New Draft:**
```
claude "draft: <title>"
```
→ Creates in `drafts/` — not built until promoted

**Promote Draft:**
```
claude "publish draft: <filename>"
```
→ Moves from `drafts/` → `src/content/blog/` with today's date prefix
→ Updates frontmatter `draft: false`, sets `publishedDate`

### ✏️ Content Editing

**Edit Post:**
```
claude "edit post: <slug-or-keyword>"
```
→ Finds matching post, opens for editing suggestions

**Improve Post:**
```
claude "improve: <slug>" 
```
→ Reviews post for: grammar, SEO, readability, code accuracy
→ Suggests improvements inline

**Add to Series:**
```
claude "add to series <name>: <slug>"
```
→ Updates frontmatter with series metadata + part number

**Translate Post:**
```
claude "translate <slug> to <lang>"
```
→ Creates translated version with `lang` frontmatter

### 🔍 Content Management

**List Posts:**
```
claude "list posts"
claude "list posts --tag=<tag>"
claude "list posts --status=draft"
claude "list drafts"
```

**Blog Stats:**
```
claude "blog stats"
```
→ Total posts, drafts, word count, tags breakdown, posting frequency

**Find Post:**
```
claude "find post about <topic>"
```
→ Searches titles, tags, content

**Check Health:**
```
claude "blog health"
```
→ Broken links, missing OG images, missing tags, SEO issues
→ Posts without descriptions, duplicate slugs

### 🚀 Publishing & Deploy

**Preview Build:**
```
claude "preview"
```
→ Runs `astro build && astro preview`

**Deploy:**
```
claude "deploy"
```
→ `git add . && git commit && git push origin main`
→ Cloudflare Pages auto-deploys from GitHub

**Force Deploy:**
```
claude "deploy now: <commit-message>"
```

### 📬 Newsletter

**Send Newsletter:**
```
claude "newsletter: <slug>"
```
→ Converts post to email-friendly HTML
→ Sends via Buttondown API
→ Logs send date in frontmatter

**Newsletter Preview:**
```
claude "newsletter preview: <slug>"
```
→ Generates email preview without sending

**Subscriber Stats:**
```
claude "newsletter stats"
```
→ Pulls subscriber count + open rates from Buttondown

### 🏷️ SEO & Metadata

**Generate OG Image:**
```
claude "og image: <slug>"
```
→ Creates SVG-based OG image in `public/og/<slug>.png`

**SEO Audit:**
```
claude "seo check: <slug>"
```
→ Title length, description, heading structure, keyword density

**Generate Sitemap:**
```
claude "sitemap"
```
→ Auto-handled by Astro's sitemap integration

---

## Frontmatter Schema

Every post MUST follow this schema:

```yaml
---
title: "Post Title Here"
description: "1-2 sentence summary for SEO + social cards"
publishedDate: 2026-04-12          # ISO date
updatedDate: 2026-04-12            # Optional, set on edit
author: "nerf-dev"                 # Author handle
tags: ["astro", "cloudflare"]      # 1-5 tags, lowercase
series:                            # Optional
  name: "Building X from Scratch"
  part: 1
draft: false                       # true = not published
featured: false                    # true = pinned to home
cover:                             # Optional
  src: "/assets/covers/slug.webp"
  alt: "Description of cover"
newsletter:                        # Auto-set by newsletter command
  sent: true
  sentDate: 2026-04-12
minutesRead: 5                     # Auto-calculated
---
```

### Validation Rules
- `title`: Required, max 70 chars (SEO)
- `description`: Required, max 160 chars (SEO)
- `tags`: Required, 1-5 tags, lowercase kebab-case
- `publishedDate`: Required for non-drafts
- `slug`: Derived from filename, kebab-case, no special chars

---

## Writing Conventions

### Markdown Extensions
- Use `:::note`, `:::warning`, `:::tip` for callout blocks
- Code blocks with filename: ` ```ts title="src/example.ts" `
- Use `## ` for main sections, `### ` for subsections
- Max heading depth: `###` (3 levels)

### Content Guidelines
- **Tone**: Direct, technical, opinionated. No fluff.
- **Code**: Always tested, always with context
- **Length**: 800-2500 words ideal. Under 500 = should be a TIL
- **TIL posts**: Tag with `til`, keep under 500 words, one concept
- **Series**: Multi-part posts share a `series` object in frontmatter

### Image Handling
- Store in `public/assets/blog/<slug>/`
- Use WebP format, max 1200px wide
- Always include alt text
- Reference as `/assets/blog/<slug>/image.webp`

---

## Environment Setup

### Required Env Vars (`.env`)
```bash
# Buttondown Newsletter
BUTTONDOWN_API_KEY=your-key-here

# Cloudflare (optional if using wrangler CLI)
CLOUDFLARE_ACCOUNT_ID=your-id
CLOUDFLARE_API_TOKEN=your-token

# Site
SITE_URL=https://nerfdev.xyz       # Update with actual domain
```

### First Time Setup
```bash
# 1. Clone + install
git clone <repo-url> nerf-dev-blog
cd nerf-dev-blog
npm install

# 2. Set env vars
cp .env.example .env
# Edit .env with your keys

# 3. Dev server
npm run dev

# 4. First post
claude "new post: Hello World --tags=meta"
```

---

## Workflow: Typical Blog Post Lifecycle

```
1. claude "draft: My New Post Title"        # Create draft
2. Write content in drafts/                  # Write in editor
3. claude "improve: my-new-post-title"       # AI review
4. claude "publish draft: my-new-post-title" # Promote to blog
5. claude "seo check: my-new-post-title"     # SEO audit
6. claude "og image: my-new-post-title"      # Generate OG
7. claude "deploy now: publish my-new-post"  # Ship it
8. claude "newsletter: my-new-post-title"    # Send to subs
```

---

## Tech Decisions & Rationale

| Choice | Why |
|--------|-----|
| **Astro 5** | Static-first, MD native, fast builds, island architecture |
| **Markdown** | Git-friendly, portable, Claude CLI can read/write natively |
| **Cloudflare Pages** | Free tier generous, edge-fast, zero-config deploys |
| **Buttondown** | Privacy-first, Markdown emails, simple API, free tier |
| **No CMS** | Claude CLI IS the CMS. Files are the database. |
| **No DB** | Markdown frontmatter = structured data. Git = version control. |

---

## Claude CLI Behavior Rules

1. **Always validate frontmatter** against schema before saving
2. **Auto-calculate `minutesRead`** on create/edit (words / 200)
3. **Slugify titles** to kebab-case, strip special chars
4. **Date prefix filenames** as `YYYY-MM-DD-slug.md`
5. **Never overwrite** existing posts without confirmation
6. **Git commit message format**: `blog: <action> "<title>"`
7. **Backup before destructive edits**: copy to `.backup/` first
8. **Log all newsletter sends** in frontmatter to prevent double-send
