import type { APIRoute } from "astro";

// D1 + rate-limit binding provided by Cloudflare Pages runtime.
// Buttondown subscribe is handled by the frontend in parallel (hidden iframe
// form POST with fingerprint). This endpoint only owns D1 tracking.
type Env = {
  DB: D1Database;
  RATE_LIMITER?: { limit: (opts: { key: string }) => Promise<{ success: boolean }> };
};

export const POST: APIRoute = async ({ request, locals }) => {
  const env = (locals as unknown as { runtime?: { env: Env } }).runtime?.env;
  if (!env?.DB) {
    console.error("D1 binding missing on locals.runtime.env");
    return json({ ok: false, error: "INTERNAL_ERROR" }, 500);
  }

  const body = (await request.json().catch(() => null)) as
    | { email?: string; website?: string; source?: string }
    | null;

  if (!body || !body.email) {
    return json({ ok: false, error: "MISSING_FIELDS" }, 400);
  }

  if (body.website && body.website.length > 0) {
    return json({ ok: false, error: "HONEYPOT_TRIGGERED" }, 400);
  }

  const email = body.email.trim().toLowerCase();
  if (!isValidEmail(email)) {
    return json({ ok: false, error: "INVALID_EMAIL" }, 400);
  }

  if (env.RATE_LIMITER) {
    const ip = request.headers.get("CF-Connecting-IP") ?? "unknown";
    const { success: allowed } = await env.RATE_LIMITER.limit({ key: ip });
    if (!allowed) return json({ ok: false, error: "RATE_LIMITED" }, 429);
  }

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
      return json({ ok: true, message: "Already subscribed." });
    }
    console.error("D1 insert failed:", msg);
    return json({ ok: false, error: "INTERNAL_ERROR" }, 500);
  }

  return json({ ok: true, message: "Saved." });
};

function isValidEmail(s: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s) && s.length <= 254;
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
