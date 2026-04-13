# Newsletter Subscriber Backend — Design Spec

**Date:** 2026-04-13
**Author:** Hoang Phi Hai
**Status:** Draft — pending user review

---

## 1. Context & Goals

The Nerf Dev Blog currently embeds a Buttondown HTML form (`src/components/NewsletterForm.astro`) that POSTs cross-origin to `buttondown.com/api/emails/embed-subscribe/<user>` with `target="_blank"`. The blog owns no subscriber data — Buttondown is the only record.

**Goal:** Introduce a lightweight backend so the blog owns a copy of subscriber events while Buttondown continues to handle delivery, double opt-in, and unsubscribe compliance.

**Primary use cases:**
- Own the email list independently of Buttondown (mitigate vendor lock-in).
- Serve as the foundation for later features (per-post conversion analytics, segment tagging, exports) without re-plumbing forms.

**Non-goals (explicitly deferred):**
- Sending newsletters from our backend (Buttondown still sends).
- Double opt-in confirmation flow (Buttondown owns this).
- Unsubscribe UI (Buttondown owns this).
- Admin dashboard (use `wrangler d1 execute` for now).
- Per-post analytics joins (captured as future work; schema stays minimal).
- Webhook sync from Buttondown (future work).

---

## 2. Decisions Log

| # | Decision | Chosen | Alternatives rejected |
|---|----------|--------|-----------------------|
| 1 | Role of Buttondown | **Hybrid** — Worker forwards to Buttondown; D1 keeps a copy | Replace entirely (too much compliance work); D1-only (defer delivery = no newsletter) |
| 2 | Form UX | **AJAX with inline feedback** | Full-page POST (dated UX); progressive-enhancement hybrid (2× code) |
| 3 | Data fields | **Minimal** (5 fields) | Recommended 14-field (YAGNI); custom |
| 4 | Bot protection | **Rate limit + honeypot** | None (D1 gets dirty); CAPTCHA/Turnstile (overkill) |
| 5 | Buttondown failure handling | **Keep D1 row, mark `buttondown_failed`, manual retry later** | Rollback (outage = 100% fail); Queues (extra infra) |

---

## 3. Architecture

```
┌─────────────────────┐   POST /api/subscribe (same-origin)   ┌───────────────────────┐
│  Astro page         │ ────────────────────────────────────> │  Cloudflare Pages     │
│  NewsletterForm.    │   { email, website, source }          │  Function             │
│  astro (AJAX fetch) │ <──────────────────────────────────── │  functions/api/       │
│                     │   { ok: boolean, message|error }      │  subscribe.ts         │
└─────────────────────┘                                       └──────────┬────────────┘
                                                                         │
                                      ┌──────────────────────┬───────────┼───────────┐
                                      │                      │           │           │
                                      ▼                      ▼           ▼           ▼
                          ┌───────────────────────┐ ┌────────────────┐ ┌─────────────────────┐
                          │ CF Rate Limiting      │ │ Cloudflare D1  │ │ Buttondown REST API │
                          │ binding               │ │ subscribers    │ │ /v1/subscribers     │
                          │ (3 req / IP / 60s)    │ │ table          │ │                     │
                          └───────────────────────┘ └────────────────┘ └─────────────────────┘
```

**Platform choice — Astro API route with Cloudflare adapter (SSR).**
First iteration of this spec used a Pages Function under `functions/api/subscribe.ts`, but the Astro Cloudflare adapter produces `dist/_worker.js` that intercepts all routes — Pages Functions in the project root are bypassed. The idiomatic path with Astro + Cloudflare is:

- `output: "server"` in `astro.config.mjs`
- Mark every static page with `export const prerender = true` (keeps them as pre-built HTML)
- Add the dynamic endpoint at `src/pages/api/subscribe.ts` as an Astro `APIRoute` (`export const POST`)
- Cloudflare bindings (D1, env vars) are accessed via `locals.runtime.env`

Reference: <https://docs.astro.build/en/guides/integrations-guide/cloudflare/#cloudflare-runtime>

---

## 4. Data Model (D1)

### 4.1 Schema

```sql
-- migrations/0001_init.sql
CREATE TABLE IF NOT EXISTS subscribers (
  id             TEXT PRIMARY KEY,            -- UUID v4 (crypto.randomUUID)
  email          TEXT NOT NULL UNIQUE,        -- lowercased, trimmed
  status         TEXT NOT NULL,               -- 'pending' | 'buttondown_failed'
  buttondown_id  TEXT,                        -- Buttondown subscriber UUID; NULL until confirmed handoff
  created_at     INTEGER NOT NULL             -- unix epoch seconds
);

CREATE INDEX IF NOT EXISTS idx_subscribers_status     ON subscribers(status);
CREATE INDEX IF NOT EXISTS idx_subscribers_created_at ON subscribers(created_at DESC);
```

### 4.2 Status state machine

```
         ┌────────────────┐
POST ──> │   pending      │  (Buttondown call succeeded; double opt-in pending on their side)
         └────────────────┘
                 │
                 │  (Buttondown API fails or times out on the create call)
                 ▼
         ┌────────────────────┐
         │ buttondown_failed  │  (retry manually via ops script — see §9)
         └────────────────────┘
```

Sync of `confirmed` / `unsubscribed` states is **out of scope for MVP** (deferred to webhook future work). The blog treats Buttondown as the source of truth for those states; D1 only knows "we attempted handoff".

### 4.3 Database name

- D1 database: **`nerfdev-subscribers`**
- Binding name (inside Worker): **`DB`**

---

## 5. API Contract

### 5.1 Endpoint

```
POST /api/subscribe
Content-Type: application/json
```

### 5.2 Request

```jsonc
{
  "email": "user@example.com",  // required, RFC-5321-ish validation
  "website": "",                // honeypot — MUST be empty string
  "source": "/blog/hello-world" // optional, informational only in MVP (not persisted)
}
```

### 5.3 Responses

| Status | Body | Condition |
|--------|------|-----------|
| `200 OK` | `{ "ok": true, "message": "Check your inbox to confirm." }` | New email accepted, Buttondown call succeeded |
| `200 OK` | `{ "ok": true, "message": "Already subscribed — check your inbox." }` | Email already in D1 (privacy-friendly; do not leak subscription state via status code) |
| `200 OK` | `{ "ok": true, "message": "Thanks! We'll retry shortly." }` | D1 write succeeded, Buttondown call failed — row marked `buttondown_failed` |
| `400 Bad Request` | `{ "ok": false, "error": "INVALID_EMAIL" }` | Email fails validation |
| `400 Bad Request` | `{ "ok": false, "error": "MISSING_FIELDS" }` | No email in body |
| `400 Bad Request` | `{ "ok": false, "error": "HONEYPOT_TRIGGERED" }` | `website` field non-empty |
| `429 Too Many Requests` | `{ "ok": false, "error": "RATE_LIMITED" }` | Rate limiter rejected |
| `500 Internal Server Error` | `{ "ok": false, "error": "INTERNAL_ERROR" }` | D1 write failed |

**Design note on 409 absence:** duplicate emails return `200 OK` with a neutral message. Returning 409 would let an attacker enumerate subscribers.

---

## 6. Worker Logic (Pages Function)

### 6.1 File: `src/pages/api/subscribe.ts`

```ts
import type { APIRoute } from "astro";

type Env = {
  DB: D1Database;
  BUTTONDOWN_API_KEY?: string;
  RATE_LIMITER?: { limit: (opts: { key: string }) => Promise<{ success: boolean }> };
};

export const POST: APIRoute = async ({ request, locals }) => {
  const env = (locals as unknown as { runtime?: { env: Env } }).runtime?.env;
  if (!env?.DB) return json({ ok: false, error: "INTERNAL_ERROR" }, 500);
  // 1) Parse body
  const body = await request.json().catch(() => null) as
    | { email?: string; website?: string; source?: string }
    | null;
  if (!body || !body.email) return json({ ok: false, error: "MISSING_FIELDS" }, 400);

  // 2) Honeypot
  if (body.website && body.website.length > 0) {
    return json({ ok: false, error: "HONEYPOT_TRIGGERED" }, 400);
  }

  // 3) Normalize + validate email
  const email = body.email.trim().toLowerCase();
  if (!isValidEmail(email)) return json({ ok: false, error: "INVALID_EMAIL" }, 400);

  // 4) Rate limit (per-IP)
  const ip = request.headers.get("CF-Connecting-IP") ?? "unknown";
  const { success: allowed } = await env.RATE_LIMITER.limit({ key: ip });
  if (!allowed) return json({ ok: false, error: "RATE_LIMITED" }, 429);

  // 5) Insert D1 row
  const id = crypto.randomUUID();
  const now = Math.floor(Date.now() / 1000);
  try {
    await env.DB
      .prepare("INSERT INTO subscribers (id, email, status, created_at) VALUES (?, ?, 'pending', ?)")
      .bind(id, email, now)
      .run();
  } catch (e) {
    const msg = String(e);
    if (msg.includes("UNIQUE") || msg.includes("2067")) {
      return json({ ok: true, message: "Already subscribed — check your inbox." });
    }
    console.error("D1 insert failed", msg);
    return json({ ok: false, error: "INTERNAL_ERROR" }, 500);
  }

  // 6) Forward to Buttondown
  try {
    const bdRes = await fetch("https://api.buttondown.com/v1/subscribers", {
      method: "POST",
      headers: {
        Authorization: `Token ${env.BUTTONDOWN_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ email_address: email }),
    });

    if (!bdRes.ok) {
      const errText = await bdRes.text();
      throw new Error(`Buttondown ${bdRes.status}: ${errText}`);
    }

    const bdData = (await bdRes.json()) as { id: string };
    await env.DB
      .prepare("UPDATE subscribers SET buttondown_id = ? WHERE id = ?")
      .bind(bdData.id, id)
      .run();

    return json({ ok: true, message: "Check your inbox to confirm." });
  } catch (e) {
    console.error("Buttondown forward failed", String(e));
    await env.DB
      .prepare("UPDATE subscribers SET status = 'buttondown_failed' WHERE id = ?")
      .bind(id)
      .run();
    return json({ ok: true, message: "Thanks! We'll retry shortly." });
  }
};

function isValidEmail(s: string): boolean {
  // Pragmatic — RFC-compliant regex is unreadable; this handles 99% and Buttondown validates too.
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s) && s.length <= 254;
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
```

### 6.2 Idempotency

- `email UNIQUE` constraint = single source of idempotency. Double-submits from a retry-happy browser collapse to one record. The response message for duplicates is intentionally identical-shaped to first-time success.

---

## 7. Frontend Changes

### 7.1 `src/components/NewsletterForm.astro`

**Changes:**
1. Remove `action="https://buttondown.com/..."` and `target="_blank"`.
2. Add hidden honeypot field, hidden via CSS (not `hidden` attribute — bots check for that):
   ```html
   <input type="text" name="website" tabindex="-1" autocomplete="off" class="honeypot" />
   ```
   ```css
   .honeypot { position: absolute; left: -9999px; opacity: 0; height: 0; width: 0; }
   ```
3. Add a `<script>` island that intercepts submit and calls `fetch('/api/subscribe', …)`.
4. Add `status` region for inline feedback (idle / submitting / success / error).

### 7.2 States

| State | Trigger | UI |
|-------|---------|----|
| idle | initial | form enabled, no message |
| submitting | click subscribe | disable button, show "…" text |
| success | `ok: true` | replace form with message (the API `message` string) |
| error | `ok: false` or network fail | re-enable form, show red inline message above button |

Error messages mapping (user-facing):
- `INVALID_EMAIL` → "That doesn't look like a valid email."
- `RATE_LIMITED` → "Too many tries — please wait a minute."
- `MISSING_FIELDS`, `HONEYPOT_TRIGGERED`, `INTERNAL_ERROR` → "Something went wrong. Please try again."

---

## 8. Bot & Spam Protection

### 8.1 Honeypot

See §7.1. Zero runtime cost; blocks the naive bot class that fills every input.

### 8.2 Rate limiting

Uses Cloudflare's **Rate Limiting binding** (free, edge-native).

**Preferred — configure via Pages dashboard** (Settings → Functions → Rate Limiting bindings), since Pages Functions do not always honor `[[unsafe.bindings]]` in `wrangler.toml` reliably across adapter versions.

Binding values:
- Binding name: `RATE_LIMITER`
- Namespace ID: `1001` (any unique integer per project)
- Limit: `3` requests
- Period: `60` seconds

Key = `CF-Connecting-IP` (set in code, not the binding). Exceed → 429.

Reference: <https://developers.cloudflare.com/workers/runtime-apis/bindings/rate-limit/>

### 8.3 Escalation path (if spam is still a problem)

Add **Cloudflare Turnstile** (invisible CAPTCHA, free) — drop-in `<script>` + server-side token verify. Not in MVP.

---

## 9. Error Handling & Ops

### 9.1 Runtime errors

| Failure | User sees | D1 state | Ops action |
|---------|-----------|----------|------------|
| Malformed JSON | 400 MISSING_FIELDS | no row | none |
| Invalid email | 400 INVALID_EMAIL | no row | none |
| D1 INSERT fails (non-unique) | 500 | no row | investigate D1 health (Cloudflare status) |
| Duplicate email | 200 (silent) | existing row untouched | none |
| Buttondown 5xx / timeout | 200 "we'll retry shortly" | row with `status='buttondown_failed'` | run retry script |

### 9.2 Retry script (ops-only, deferred impl)

```bash
# List failed records
wrangler d1 execute nerfdev-subscribers --remote \
  --command="SELECT id, email FROM subscribers WHERE status = 'buttondown_failed' ORDER BY created_at"

# Retry is a manual script that walks failed rows and re-calls Buttondown API.
# To be built as scripts/retry-buttondown.ts when first failure occurs.
```

### 9.3 Observability

- Structured console logs on failure paths (`console.error`). Visible in Cloudflare dashboard → Pages → Functions → Logs.
- No external APM in MVP.

---

## 10. Deployment & Configuration

### 10.1 Local setup (one-time)

```bash
# Create D1 database
npx wrangler d1 create nerfdev-subscribers
# → copy the database_id from output into wrangler.toml

# Apply migration locally
npx wrangler d1 migrations apply nerfdev-subscribers --local

# Apply migration remotely
npx wrangler d1 migrations apply nerfdev-subscribers --remote
```

### 10.2 `wrangler.toml` additions

```toml
# existing
name = "nerf-dev-blog"
compatibility_date = "2024-12-01"
compatibility_flags = ["nodejs_compat"]   # required — Astro SSR bundles `sharp`
pages_build_output_dir = "./dist"

[[d1_databases]]
binding = "DB"
database_name = "nerfdev-subscribers"
database_id = "<fill-from-wrangler-d1-create-output>"
migrations_dir = "migrations"

# Rate Limiting binding: configured via Pages dashboard (see §8.2)
```

### 10.3 Secrets (Cloudflare Pages → Settings → Environment variables)

| Name | Scope | Source |
|------|-------|--------|
| `BUTTONDOWN_API_KEY` | Production + Preview, encrypted | Buttondown dashboard → Settings → API |

`.env` (local, for `wrangler pages dev` only — already `.gitignore`d):
```
BUTTONDOWN_API_KEY=...
```

### 10.4 CI/CD

No changes to `.github/workflows/deploy.yml` — Pages Functions are deployed automatically with the static build. D1 migrations are applied out-of-band via `wrangler d1 migrations apply --remote` (manual on first run and on schema change).

---

## 11. Testing Strategy

| Layer | Approach |
|-------|----------|
| Unit (email validation, isValidEmail) | Vitest, pure function tests |
| Integration (Worker + D1) | `wrangler pages dev` with `--local` D1; curl the endpoint |
| Buttondown integration | Use Buttondown's real API in a scratch newsletter, or stub `fetch` in tests |
| End-to-end (form → worker → D1 → Buttondown) | Manual smoke test on a preview deploy before production |

No automated E2E in MVP.

---

## 12. Future Work (Explicitly Out of Scope)

Tracked here so they aren't lost:

1. **Buttondown webhook handler** — `/api/buttondown/webhook` to sync `confirmed` / `unsubscribed` back into D1 (requires new columns: `confirmed_at`, `unsubscribed_at`).
2. **Per-post conversion analytics** — persist `source_url`, `utm_*` columns (a superset of current "minimal" fields).
3. **Retry worker** — Cloudflare Queue + scheduled consumer to replace manual retry script.
4. **Admin UI** — protected `/admin/subscribers` page using Cloudflare Access.
5. **Export CSV** — token-gated endpoint for backup / migration.
6. **Turnstile** — only if honeypot + rate limit prove insufficient.

---

## 13. References

### Cloudflare
- Pages Functions routing: <https://developers.cloudflare.com/pages/functions/routing/>
- Pages Functions bindings: <https://developers.cloudflare.com/pages/functions/bindings/>
- D1 overview: <https://developers.cloudflare.com/d1/>
- D1 migrations: <https://developers.cloudflare.com/d1/reference/migrations/>
- D1 Workers API: <https://developers.cloudflare.com/d1/worker-api/>
- Rate Limiting binding: <https://developers.cloudflare.com/workers/runtime-apis/bindings/rate-limit/>
- Pages environment variables & secrets: <https://developers.cloudflare.com/pages/functions/bindings/#environment-variables>
- Wrangler config reference: <https://developers.cloudflare.com/workers/wrangler/configuration/>
- Turnstile (future): <https://developers.cloudflare.com/turnstile/>

### Buttondown
- API index: <https://docs.buttondown.com/api>
- Create subscriber: <https://docs.buttondown.com/api-subscribers-create>
- Webhook events (future): <https://docs.buttondown.com/api-webhooks-introduction>

### Astro
- Cloudflare adapter: <https://docs.astro.build/en/guides/integrations-guide/cloudflare/>
- Client directives: <https://docs.astro.build/en/reference/directives-reference/#client-directives>

### Anti-spam
- OWASP honeypot technique: <https://owasp.org/www-community/controls/Blocking_Brute_Force_Attacks> (honeypot section)

---

## 14. Open Questions

*(None as of this revision — all five design decisions resolved.)*

---

## Changelog

| Date | Change |
|------|--------|
| 2026-04-13 | Initial draft. All 5 design decisions captured. |
| 2026-04-13 | Post-implementation revision: switched from Pages Function (`functions/api/`) to Astro API route (`src/pages/api/`) because Astro's `_worker.js` intercepts all routes. Added `output: "server"` + per-page `prerender = true`. Added `nodejs_compat` flag. |
| 2026-04-13 | **Architecture v2: dual-call parallel.** Buttondown firewall (auditing_mode=aggressive + IP auditing) blocked server-side REST calls from the Worker, even after account-level config attempts. Pivoted: worker now ONLY writes D1 (decision #1 reinterpreted — still "hybrid" but the Buttondown leg moved to the browser). Frontend submits a hidden `<form target=iframe>` to `buttondown.com/api/emails/embed-subscribe/<name>` so Buttondown's own fingerprint/anti-bot pipeline runs. No wait between the two calls; UI resolves off the local `/api/subscribe` response only (iframe response is cross-origin). Consequence: D1 status stays `pending` permanently unless webhook sync is added later; row may exist in D1 even if Buttondown rejected. |
