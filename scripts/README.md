# Scripts

Thư mục này chứa các shell script tự động hoá thao tác thường xuyên trên blog: tạo post, publish, gửi newsletter, deploy, vận hành D1 (dev & production), thống kê.

Tất cả script chạy từ **project root** (`d:\NerfDev`) và đều dùng bash:

```bash
bash scripts/<tên>.sh [args]
```

Script có đuôi `.sh` yêu cầu bash. Trên Windows chạy qua **Git Bash**, **WSL**, hoặc `npm run <alias>` (xem mapping cuối trang).

---

## Danh sách script

| Script | Vai trò | Dependencies |
|--------|---------|--------------|
| [`new-post.sh`](#new-postsh) | Tạo file post mới (published hoặc draft) với frontmatter chuẩn | bash, coreutils |
| [`publish.sh`](#publishsh) | Promote draft thành published post | bash, coreutils |
| [`newsletter.sh`](#newslettersh) | Convert post → email draft trên Buttondown | `jq`, `curl`, `BUTTONDOWN_API_KEY` |
| [`stats.sh`](#statssh) | Quick blog stats (posts, words, tags, recent) | bash, coreutils |
| [`start.sh`](#startsh) | Build + chạy `wrangler pages dev` (test `/api/subscribe` local) | Node/npm, wrangler |
| [`test.sh`](#testsh) | Curl smoke tests cho `/api/subscribe` | `curl`, wrangler (để dump D1) |
| [`export-subscribers.sh`](#export-subscriberssh) | Export subscribers từ D1 → CSV | wrangler, Node |

---

## `new-post.sh`

**Purpose:** Tạo 1 file markdown mới trong `src/content/blog/` (hoặc `drafts/`) với frontmatter YAML chuẩn sẵn.

**Usage:**
```bash
bash scripts/new-post.sh "Post Title"                       # published
bash scripts/new-post.sh "Post Title" --tags=astro,cloudflare
bash scripts/new-post.sh "WIP Idea" --draft                 # vào drafts/
```

**Flags:**
- `--tags=tag1,tag2` — tags (mặc định `["general"]`, luôn lowercase)
- `--draft` — tạo vào `drafts/` thay vì `src/content/blog/`

**Side effects:**
- Slug: lowercase + kebab-case từ title.
- File name: `YYYY-MM-DD-<slug>.md`.
- Tự fail nếu file đã tồn tại (không ghi đè).
- Nếu `$EDITOR` set → mở luôn file trong editor đó.

---

## `publish.sh`

**Purpose:** Chuyển 1 draft từ `drafts/` sang `src/content/blog/`, update frontmatter (`draft: false`, `publishedDate: today`), re-prefix ngày trong filename.

**Usage:**
```bash
bash scripts/publish.sh my-draft-slug
```

Tìm match theo substring `*<slug>*` trong `drafts/`. Nếu match nhiều file, chọn file đầu tiên.

**Side effects:**
- `sed -i` sửa frontmatter.
- `mv` file sang `src/content/blog/<today>-<slug>.md`.
- **Không** commit — chạy `git add` + `git commit` thủ công sau.

---

## `newsletter.sh`

**Purpose:** Convert 1 published post sang email **draft** trên Buttondown (status=`draft`). Bạn review + send qua Buttondown dashboard.

**Usage:**
```bash
bash scripts/newsletter.sh my-post-slug               # queue draft
bash scripts/newsletter.sh my-post-slug --preview     # preview, không gửi
```

**Required env:** `BUTTONDOWN_API_KEY` trong `.env`.

**Side effects:**
- Nếu post đã `newsletter.sent: true` → prompt confirm y/N.
- Khi Buttondown 2xx: append vào frontmatter:
  ```yaml
  newsletter:
    sent: true
    sentDate: YYYY-MM-DD
  ```
- Post body = everything sau frontmatter `---`. Markdown được JSON-escape bằng `jq -Rs .`.

**Gotchas:**
- Script tạo **draft**, không auto-send → cần mở Buttondown để bấm Send.
- Cần `jq` (`winget install jqlang.jq` hoặc `apt install jq`).

---

## `stats.sh`

**Purpose:** In nhanh thống kê blog: số post, drafts, tổng words, avg words/post, top tags, 5 post gần nhất.

**Usage:**
```bash
bash scripts/stats.sh
```

Không side effects. Chỉ đọc filesystem.

---

## `start.sh`

**Purpose:** Start môi trường dev local cho phần **backend subscriber** (D1 + `/api/subscribe`). Build Astro rồi chạy `wrangler pages dev` trên port 8788 với D1 local.

**Usage:**
```bash
bash scripts/start.sh                    # build + serve
bash scripts/start.sh --fresh            # + apply D1 migrations (IF NOT EXISTS)
bash scripts/start.sh --clean            # + DELETE FROM subscribers
PORT=4000 bash scripts/start.sh          # override port
```

**Flags:**
- `--fresh` — reapply `migrations/*.sql` vào D1 local (an toàn, mọi migration đều `IF NOT EXISTS`).
- `--clean` — truncate bảng `subscribers` local trước khi start.

**Yêu cầu:** file `.env` ở root với `BUTTONDOWN_API_KEY`.

**Output:** process foreground. Ctrl+C để dừng. Terminal B chạy `scripts/test.sh`.

Xem section "Local D1 file" cuối trang để biết data lưu ở đâu.

---

## `test.sh`

**Purpose:** Curl-based smoke test 5 scenarios của `/api/subscribe`. Chỉ verify **API contract** (không verify Buttondown thật — xem note cuối).

**Usage:**
```bash
# Terminal A: bash scripts/start.sh
# Terminal B:
bash scripts/test.sh
BASE=http://127.0.0.1:4000 bash scripts/test.sh   # override base URL
```

**Test cases:**

| # | Case | Expected substring |
|---|------|--------------------|
| T1 | valid email (`smoke-<ts>@example.com`) | `"ok":true` |
| T2 | invalid email (`not-an-email`) | `INVALID_EMAIL` |
| T3 | missing email | `MISSING_FIELDS` |
| T4 | honeypot filled | `HONEYPOT_TRIGGERED` |
| T5 | duplicate (POST T1 lần 2) | `Already subscribed` |

**Output:** PASS/FAIL từng case + top 5 row D1 local + summary.

**Note — `@example.com` và Buttondown:** Buttondown firewall block test domains (`example.com`, `test.com`). Row T1 sẽ có `status='buttondown_failed'` ở D1 → đây là **expected**, vì test này chỉ check API contract (`ok:true`). Buttondown chỉ test thật khi deploy production với email real.

---

## `export-subscribers.sh`

**Purpose:** Export subscribers từ D1 **production** (mặc định) hoặc local sang CSV để backup / migration / phân tích.

**Usage:**
```bash
bash scripts/export-subscribers.sh                       # stdout
bash scripts/export-subscribers.sh subs.csv              # file
bash scripts/export-subscribers.sh backups/subs-$(date +%Y-%m-%d).csv
REMOTE=0 bash scripts/export-subscribers.sh local.csv    # D1 local
```

**CSV columns:** `id, email, status, buttondown_id, created_at_iso`.

**Yêu cầu:** wrangler + `.env` với `CLOUDFLARE_API_TOKEN` + `CLOUDFLARE_ACCOUNT_ID` (đã set từ trước).

**Recommend cadence:** chạy weekly, commit backup vào folder private (hoặc cloud drive). Đừng commit file subscribers vào repo public.

---

## npm aliases

`package.json` alias sẵn 1 số script cho tiện:

| npm command | Tương đương |
|-------------|-------------|
| `npm run new-post` | `bash scripts/new-post.sh` |
| `npm run publish-draft` | `bash scripts/publish.sh` |
| `npm run newsletter` | `bash scripts/newsletter.sh` |
| `npm run stats` | `bash scripts/stats.sh` |
| `npm run deploy` | `git add . && git commit -m 'blog: update' && git push origin main` (ít dùng — chỉ tiện cho quick ship) |

`start.sh`, `test.sh`, `export-subscribers.sh` **chưa** alias — gõ `bash scripts/<tên>.sh` là rõ ràng nhất.

---

## Local D1 file

Script `start.sh` / `test.sh` đọc-ghi D1 **local** (emulator Miniflare):

```
.wrangler/state/v3/d1/miniflare-D1DatabaseObject/
  <hash>.sqlite          ← file DB chính
  <hash>.sqlite-shm
  <hash>.sqlite-wal
```

- Đã `.gitignore` (line 5).
- Persistent giữa các lần start (không bị xoá khi Ctrl+C dev server).
- Muốn wipe hoàn toàn: `rm -rf .wrangler/state/v3/d1/` hoặc chạy `start.sh --clean`.
- Query thủ công: `sqlite3 .wrangler/state/v3/d1/miniflare-D1DatabaseObject/*.sqlite`.

## Production D1

- Nằm trên Cloudflare edge (region APAC/SIN với account hiện tại).
- Persistent qua mọi deploy — deploy code **không** xoá data.
- Query: thêm flag `--remote` vào mọi lệnh wrangler:
  ```bash
  npx wrangler d1 execute nerfdev-subscribers --remote --env-file=.env \
    --command="SELECT COUNT(*) FROM subscribers;"
  ```

---

## Khi nào thêm script mới?

Thêm 1 script `.sh` khi thao tác thoả **cả 3**:

1. Cần chạy > 2 lần/tháng.
2. Dùng > 3 lệnh shell hoặc có logic (parse flags, loop, conditional).
3. Có thể fail — script giúp chuẩn hoá error handling (`set -euo pipefail`).

Thao tác 1-lệnh → dùng npm alias hoặc command history.
