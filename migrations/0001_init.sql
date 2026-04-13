-- migrations/0001_init.sql
-- Newsletter subscriber backend — initial schema
-- See docs/superpowers/specs/2026-04-13-newsletter-subscriber-backend-design.md §4

CREATE TABLE IF NOT EXISTS subscribers (
  id             TEXT PRIMARY KEY,
  email          TEXT NOT NULL UNIQUE,
  status         TEXT NOT NULL,
  buttondown_id  TEXT,
  created_at     INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_subscribers_status     ON subscribers(status);
CREATE INDEX IF NOT EXISTS idx_subscribers_created_at ON subscribers(created_at DESC);
