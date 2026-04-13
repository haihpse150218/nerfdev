---
title: "Hello World — Nerf Dev is Live"
description: "Tại sao mình dựng blog này, stack đằng sau nó, và thứ bạn có thể chờ đọc ở đây."
publishedDate: 2026-04-12
author: "nerf-dev"
tags: ["meta"]
draft: false
featured: true
minutesRead: 3
---

## Nguyên tắc viết

Bốn dòng:

1. **Viết từ trải nghiệm thật.** Không từ điển hoá khái niệm — nếu mình chưa chạy được code hoặc chưa break nó, mình không viết.
2. **Ngắn khi có thể.** TIL 500 chữ > "ultimate guide" 5000 chữ. Nếu bài dài, đó là vì nó cần dài.
3. **Có opinion.** "It depends" là câu trả lời lười. Nếu có 2 hướng, nói rõ hướng mình chọn và tại sao.
4. **Kèm code chạy được.** File path, command, output — đọc xong paste được vào terminal.

## Stack chạy blog này

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

Sắp tới sẽ có bài mổ xẻ từng quyết định: tại sao dual-call thay vì để worker proxy tới Buttondown, tại sao dùng `output: server` cho blog gần-như-static, v.v.

## Sẽ viết về

- **Back-end & infra**: serverless patterns trên AWS Lambda + SQS + DynamoDB, so sánh với Cloudflare Workers + D1 + Queues — thực tế khi phải migrate
- **Payment systems**: những lesson từ 1M+ transactions/day, idempotency, retry logic, reconciliation
- **AI/LLM trong production**: Bedrock Agent + Knowledge Base, prompt engineering cho bài toán real, coding agent ở nhịp làm việc hằng ngày
- **Tooling**: shell scripts thật, CLI workflows, dotfile hackery — cái nào tiết kiệm được 5 phút/ngày
- **Post-mortems**: lỗi prod thật (anonymized), root cause, cái mình học

Không viết: SEO chasing, listicle, tutorial copy từ doc official.

## Subscribe nếu muốn đọc

Form ở [/newsletter](/newsletter). Dưới nó là Buttondown lo delivery + Cloudflare D1 lưu copy. Không spam, không bán data, unsubscribe 1 click. Tần suất ước lượng: 1–2 bài/tuần lúc đầu, có thể thay đổi.

Hoặc subscribe [RSS](/rss.xml) nếu bạn là người chưa rời reader feed.

Hẹn bài sau.
