---
title: "Hello World — Nerf Dev is Live"
description: "Why this blog exists, the stack behind it, and what to expect. / Tại sao blog này ra đời, stack đằng sau, và những thứ sẽ đọc ở đây."
publishedDate: 2026-04-12
author: "nerf-dev"
tags: ["meta"]
draft: false
featured: true
minutesRead: 4
---

> 🇬🇧 English first, 🇻🇳 Tiếng Việt theo sau.

---

## Writing principles / Nguyên tắc viết

Four lines:

1. **Write from experience.** No dictionary-style explanations — if I haven't run the code or broken it, I don't write about it.
2. **Short when possible.** A 500-word TIL beats a 5000-word "ultimate guide." When a post runs long, it's because it needs to.
3. **Have opinions.** "It depends" is a lazy answer. If there are two paths, pick one and explain why.
4. **Ship runnable code.** File paths, commands, output — something you can paste into a terminal right after reading.

**Bốn dòng:**

1. **Viết từ trải nghiệm thật.** Không từ điển hoá khái niệm — nếu mình chưa chạy được code hoặc chưa break nó, mình không viết.
2. **Ngắn khi có thể.** TIL 500 chữ > "ultimate guide" 5000 chữ. Nếu bài dài, đó là vì nó cần dài.
3. **Có opinion.** "It depends" là câu trả lời lười. Có 2 hướng → nói rõ hướng mình chọn và tại sao.
4. **Kèm code chạy được.** File path, command, output — đọc xong paste được vào terminal.

---

## The stack running this blog / Stack chạy blog này

The blog itself is a living post:

| Layer | Pick | Why |
|-------|------|-----|
| Framework | **Astro 5** (output: server) | Static-first, Markdown-native, island architecture, fast builds |
| Hosting | **Cloudflare Pages** | Free tier edge, zero-config, ship via `git push` |
| CI/CD | **GitHub Actions** + `wrangler pages deploy` | Explicit token control (skipped CF's built-in Git integration — ran into a stale-build-token issue) |
| Content | Markdown + Git | No CMS, no content DB — files are the source of truth |
| Newsletter | **Buttondown** + **Cloudflare D1** | Buttondown handles delivery/compliance; D1 keeps an owned copy (dual-call from the browser, in parallel) |
| "CMS" | **Claude Code** | The CLI edits, greps, commits — beats WordPress for my workflow |

Every push to `src/content/blog/*.md` → GH Actions builds → Pages deploys → live in ~90s. No admin panel. No staging magic. Git is the state.

A follow-up post will break down each decision: why dual-call instead of a worker proxy to Buttondown, why `output: server` for a near-static blog, etc.

**Tiếng Việt:**

Bản thân blog là một bài viết sống:

| Layer | Chọn | Lý do |
|-------|------|-------|
| Framework | **Astro 5** (output: server) | Static-first, MD native, island architecture, build nhanh |
| Hosting | **Cloudflare Pages** | Free tier edge, zero-config, ship qua `git push` |
| CI/CD | **GitHub Actions** + `wrangler pages deploy` | Control token rõ ràng (bỏ CF Git integration vì dính bug build token) |
| Content | Markdown + Git | Không CMS, không DB content — file là source of truth |
| Newsletter | **Buttondown** + **Cloudflare D1** | Buttondown lo delivery/compliance; D1 là copy riêng của mình (dual-call từ browser, song song) |
| "CMS" | **Claude Code** | CLI là cái viết được, grep được, commit được — đỡ hơn WordPress nhiều |

Mỗi lần push `src/content/blog/*.md` → GH Actions build → deploy → live sau ~90s. Không có admin panel. Không có staging magic. Git là state.

Bài sau sẽ mổ xẻ từng quyết định: tại sao dual-call thay vì để worker proxy tới Buttondown, tại sao dùng `output: server` cho blog gần-như-static.

---

## Topics / Sẽ viết về

- **Backend & infra** — serverless patterns on AWS Lambda + SQS + DynamoDB, compared with Cloudflare Workers + D1 + Queues when migrating for real.
- **Payment systems** — lessons from 1M+ transactions/day: idempotency, retry logic, reconciliation.
- **AI/LLM in production** — Bedrock Agent + Knowledge Base, prompt engineering for real problems, coding agents in the daily loop.
- **Tooling** — real shell scripts, CLI workflows, dotfile hackery — anything that saves 5 minutes a day.
- **Post-mortems** — production incidents (anonymized), root cause, what I learned.

Not going to write: SEO chasing, listicles, tutorials copied from official docs.

**Tiếng Việt:**

- **Back-end & infra** — serverless patterns trên AWS Lambda + SQS + DynamoDB, so với Cloudflare Workers + D1 + Queues khi phải migrate thật.
- **Payment systems** — lesson từ 1M+ transactions/day: idempotency, retry logic, reconciliation.
- **AI/LLM trong production** — Bedrock Agent + Knowledge Base, prompt engineering cho bài toán real, coding agent ở nhịp làm việc hằng ngày.
- **Tooling** — shell scripts thật, CLI workflows, dotfile hackery — cái nào tiết kiệm 5 phút/ngày.
- **Post-mortems** — lỗi prod thật (anonymized), root cause, cái mình học.

Không viết: SEO chasing, listicle, tutorial copy từ doc official.

---

## Subscribe

Form at [/newsletter](/newsletter). Buttondown handles delivery; Cloudflare D1 keeps a copy. No spam, no data selling, one-click unsubscribe. Frequency: ~1–2 posts/week to start.

Or grab the [RSS feed](/rss.xml) if you haven't left your reader.

**Tiếng Việt:**

Form ở [/newsletter](/newsletter). Buttondown lo delivery + D1 lưu copy. Không spam, không bán data, unsubscribe 1 click. Tần suất: 1–2 bài/tuần lúc đầu.

Hoặc [RSS](/rss.xml) nếu bạn là người chưa rời reader feed.

See you in the next post. / Hẹn bài sau.
