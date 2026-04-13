---
title: "Hello World — AI Nerfed the Dev. Good."
description: "AI is nerfing the barrier to ship. Nerf Dev is where we answer what comes next — deeper performance, AI/ML patterns in production, papers worth reading."
publishedDate: 2026-04-12
author: "nerf-dev"
tags: ["meta"]
draft: false
featured: true
minutesRead: 4
---

> 🇬🇧 English first, 🇻🇳 Tiếng Việt theo sau.

---

## The name / Về cái tên

**Nerf** — a gaming term: to reduce a thing's power, to make it less dominant. In 2026, AI has *nerfed* the developer. Boilerplate is free. Glue code is free. "CRUD app in a weekend" is now CRUD app in a coffee break. The skill that used to be the moat is no longer the moat.

Good. That was never the interesting part.

**Nerf Dev** is where we write about the part that *wasn't* nerfed — the taste, the depth, the 1000× performance gap between code that works and code that ships at scale. We're a small crew of engineers sharing what we actually learn: patterns, pitfalls, papers.

**Tiếng Việt:**

**Nerf** — thuật ngữ gaming: giảm sức mạnh của một thứ gì đó. Năm 2026, AI đã *nerf* dev. Boilerplate free. Glue code free. "CRUD app trong 2 ngày" giờ là CRUD app trong 1 ly cafe. Cái kỹ năng từng là moat đã hết là moat.

Tốt. Phần đó chưa bao giờ là phần thú vị.

**Nerf Dev** là nơi bọn mình viết về phần **không bị nerf** — sự sâu, cái khẩu vị kiến trúc, cái khoảng cách 1000× giữa code chạy được và code ship được ở scale. Bọn mình là nhóm dev nhỏ chia sẻ thứ mình học thật: patterns, pitfalls, papers.

---

## What the blog is for / Blog này viết gì

### 1. Performance — the part AI can't vibe-check
### 1. Performance — thứ AI không "cảm" được

LLMs are great at "make it work." They're weak at "make it 10× faster," "cut p99 in half," "drop infra cost 60%." That's where we live.

LLMs giỏi "làm cho nó chạy." Yếu ở "làm nhanh lên 10 lần," "giảm p99 còn một nửa," "cắt 60% chi phí infra." Đây là sân của bọn mình.

### 2. AI/ML in production — not tutorials
### 2. AI/ML trong production — không phải tutorial

Bedrock Agent thật, RAG pipeline thật, prompt evals thật, the moment where the demo works and the prod load breaks it. Anonymized when needed.

Bedrock Agent thật, RAG pipeline thật, prompt evals thật, cái khoảnh khắc demo chạy mà đưa lên prod tải là gãy. Anonymize khi cần.

### 3. Papers worth reading / Paper đáng đọc

Not a paper-reading club. We summarize only when a paper changed something we build. Signal over completeness.

Không phải câu lạc bộ đọc paper. Chỉ tóm tắt khi có paper nào đó đổi được cách bọn mình build. Signal > completeness.

### 4. Tooling that earns its keep / Tooling đáng tiền

CLIs, dotfiles, shell scripts, coding agents — anything saving 5+ minutes a day. If it saves 5 minutes, it saves a workday a quarter.

CLIs, dotfiles, shell scripts, coding agents — thứ nào tiết kiệm được 5 phút/ngày. Tiết kiệm 5 phút = tiết kiệm nửa ngày làm việc mỗi quý.

---

## Writing principles / Nguyên tắc viết

1. **Run it before writing it.** No conceptual hand-waving. / **Chạy trước, viết sau.** Không hand-wave khái niệm.
2. **Short when short works.** A 400-word TIL beats a 5,000-word survey. / **Ngắn khi ngắn đủ.** TIL 400 chữ > survey 5000 chữ.
3. **Opinions, not "it depends."** Pick the side, defend it, welcome the pushback. / **Có opinion, không "it depends."** Chọn 1 phía, bảo vệ nó, welcome pushback.
4. **Runnable artifacts.** File paths, commands, outputs. Paste-ready. / **Artifacts chạy được.** File path, command, output. Paste vào là chạy.

---

## The stack running this blog / Stack chạy blog này

The blog is its own first post. Meta, but that's the point.

Blog là bài viết đầu tiên của chính nó. Meta, nhưng đó là ý đồ.

| Layer | Pick | Why / Lý do |
|-------|------|-------------|
| Framework | **Astro 5** (`output: server`) | Static-first + Markdown-native + island hydration. Fast builds. |
| Hosting | **Cloudflare Pages** | Edge, free tier, ship via `git push`. |
| CI/CD | **GitHub Actions** + `wrangler pages deploy` | Explicit token control; skipped CF's Git integration after a stale-build-token incident. |
| Newsletter | **Buttondown** + **Cloudflare D1** | Buttondown → delivery + compliance. D1 → owned subscriber copy via parallel dual-call. |
| Content | Markdown + Git | No CMS. Files are the database. |
| "Editor" | **Claude Code** CLI | `claude "new post: ..."` then edit-commit-push. Beats any WYSIWYG we've used. |

Every `src/content/blog/*.md` push → GH Actions build → Pages deploy → live in ~90s. No admin panel. No staging magic. Git is the state.

Every decision here will get its own deep-dive post soon: why `output: server` for near-static, why dual-call instead of worker-to-Buttondown, why we rolled custom D1 on top of Buttondown.

Mỗi push `src/content/blog/*.md` → GH Actions build → Pages deploy → live sau ~90s. Không admin panel. Không staging magic. Git là state.

Mỗi quyết định trên sẽ có bài mổ xẻ riêng: tại sao `output: server` cho blog gần-như-static, tại sao dual-call thay vì worker-to-Buttondown, tại sao build thêm D1 trên Buttondown.

---

## Subscribe

Form at [/newsletter](/newsletter). Buttondown delivers, D1 keeps our copy. No spam, no data selling, 1-click unsubscribe. **Starting cadence: 1–2 posts/week.**

Prefer readers? [RSS is here](/rss.xml).

**Tiếng Việt:**

Form ở [/newsletter](/newsletter). Buttondown delivery, D1 giữ copy. Không spam, không bán data, unsubscribe 1 click. **Tần suất khởi đầu: 1–2 bài/tuần.**

Thích dùng reader? [RSS đây](/rss.xml).

---

AI nerfed the dev. We're raising the ceiling back. / AI đã nerf dev. Bọn mình nâng trần lên lại.

See you in the next one. / Hẹn bài tới.
