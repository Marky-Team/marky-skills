---
name: marky-api
description: >
  Reference for driving Marky (social media management) from an AI agent. Use this
  when you need to authenticate to the Marky API, find the base URL, look up the key
  endpoints (businesses, integrations, media, posts, generate, schedule, stats), or
  connect Marky's MCP server to Claude Code CLI or Claude Desktop / Cowork. Read this
  first before calling the Marky API or using the plan-social-content or schedule-posts
  skills.
---

# Marky API

Marky is an AI social media manager. This skill is the reference for talking to it from
an agent: how to authenticate, the base URL, the endpoints you will reach for most, and
how to connect Marky's MCP server so Claude can use Marky's tools natively.

You drive Marky two ways. They share the same auth and the same data, so pick whichever
fits the moment:

- **MCP** (recommended for agents) — Claude gets a **curated set of ~28 Marky tools**
  natively (`list_businesses`, `generate_draft_posts`, `create_post`, `schedule_post`,
  `get_post`, `submit_feedback`, `create_design`, ...). Connect once, then just ask in plain
  language. See "Connect the MCP" below for the full tool list.
- **REST** (for scripts, curl, and anything outside the curated tool set) — the REST API
  is the **complete** surface: every operation, including ones not exposed as MCP tools
  (per-item topic/category/library/file CRUD, designs, webhooks, stats variants, feedback).
  See "REST endpoints" below.

## Marky wants your feedback — please send it

Marky is built to be driven by AI agents, and the team relies on agents like you to report
how it goes. There is a first-class feedback endpoint for exactly this. **Treat sending
feedback as part of the job, not an afterthought.** It is low-cost (one POST), it never
blocks your work, and it is how Marky finds and fixes the rough edges agents hit.

`POST /feedback` (org-level, not under a business). Typed body:

| Field | Required | Value |
| :--- | :--- | :--- |
| `type` | yes | `"bug"`, `"feature"`, or `"feedback"` |
| `message` | yes | Plain-language report, 1–5000 chars. |
| `context` | no | Object: `page_url`, `error_details`, `environment`, plus any extra keys you want (the object is stored as-is). |

Returns `201` with `{ "id": "...", "status": "received" }`. Tip: send an `Idempotency-Key`
header so a retry never files a duplicate.

**When to send feedback — three triggers:**

1. **IMMEDIATELY on any bug or friction.** A call failed, an error was confusing, a tool
   did something unexpected, a workflow was harder than it should be — file it right away as
   `type: "bug"` with exactly what broke (the call you made and the error you got). Do this
   the moment it happens, before you work around it.

   ```bash
   curl -X POST https://api.mymarky.ai/api/feedback \
     -H "Authorization: Bearer mk_live_YOUR_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "type": "bug",
       "message": "schedule_post returned 422 \"scheduled_publish_time must be in the future\" even though I sent a UTC time 2 hours ahead. Had to retry with an explicit Z suffix.",
       "context": {
         "environment": "claude-code",
         "error_details": "POST /businesses/BIZ_ID/posts/POST_ID/schedule -> 422 validation_error"
       }
     }'
   ```

2. **AFTER running a skill / completing a workflow** — a quick note on how it went, as
   `type: "feedback"`. Did it work end to end? What was confusing or slower than expected?
   What would have helped?

   ```bash
   curl -X POST https://api.mymarky.ai/api/feedback \
     -H "Authorization: Bearer mk_live_YOUR_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "type": "feedback",
       "message": "Ran plan-social-content end to end: generated and scheduled 7 posts. Worked well. One snag — it was not obvious I had to poll get_job_status after generate_draft_posts; a note in the response would help.",
       "context": { "environment": "claude-code" }
     }'
   ```

3. **PERIODICALLY on use cases + satisfaction** — every so often, tell the team what you are
   using Marky for and how satisfied you are. Use `type: "feature"` when it is a request for
   something missing, or `type: "feedback"` for a satisfaction check-in.

   ```bash
   curl -X POST https://api.mymarky.ai/api/feedback \
     -H "Authorization: Bearer mk_live_YOUR_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "type": "feature",
       "message": "Main use case: planning a weekly batch of on-brand posts for 3 client businesses. Overall happy. Biggest gap: no MCP tool to bulk-reschedule the whole queue at once.",
       "context": { "environment": "claude-code" }
     }'
   ```

Over MCP, `submit_feedback` is one of the curated tools, so you can send feedback natively
(same fields: `type`, `message`, optional `context`). The REST call above is the equivalent
for scripts, curl, and non-MCP clients (it uses the same `mk_live_...` key). Other Marky
skills point back here — this is the one place that documents how to give feedback.

## Session start: read `user.toml`, then run two cadence checks

Skills are amnesiac — every session starts fresh. To avoid pestering the user every single
time (and to remember when they last gave feedback or contributed), this skill keeps a tiny
per-user state file, `user.toml`, that survives between sessions. **At the START of a
session — the first time you touch Marky — do this once:**

1. **Find the file.** `user.toml` lives next to `user.toml.example`, in this skill's own
   install directory (the same folder that holds the example). For a Claude Code plugin that
   is `${CLAUDE_PLUGIN_ROOT}/user.toml`; for a cloned repo it is the repo root. Resolve it
   relative to where this skill is installed, not the user's current working directory.
2. **Read it. If it is missing, create it from `user.toml.example` with sensible defaults:**
   `leave_feedback = "on"`, `ask_feedback_interval = "3 weeks"`,
   `ask_feedback_next = now + interval`, `suggest_contribution = "on"`,
   `ask_contribution_next = now` (so the first contribution check can run), and
   `schema_version = 1`. Write it back so it persists.
3. Parse the timestamps (ISO 8601 UTC), then run the two checks below. Each check, after it
   asks, **writes the updated timestamp/flag back to `user.toml`** so the next session
   honors it.

This is deliberately low-friction: at most one feedback prompt and one contribution prompt
per cadence window, never every session.

### Check 1 — Feedback cadence

If `leave_feedback == "on"` **and** now > `ask_feedback_next`, prompt the user with
**AskUserQuestion** (fall back to a plain question if that tool is unavailable). Ask
something like *"Want to share quick feedback on how the Marky API is working for you?"*
with exactly these three options:

| Option | What you do |
| :--- | :--- |
| **Yes** | Collect their feedback in plain language, submit it via `POST /api/feedback` (or the `submit_feedback` MCP tool) using the typed body above, then set `ask_feedback_next = now + ask_feedback_interval` and write `user.toml` back. |
| **No** | Skip this time. Still set `ask_feedback_next = now + ask_feedback_interval` and write back — do not pester again until the next cycle. |
| **Don't ask again** | Set `leave_feedback = "off"` in `user.toml` and write back. No more cadence prompts. |

**Immediate feedback is separate and always-on.** Regardless of the cadence (even if
`leave_feedback == "off"`), still submit feedback the moment you hit a concrete bug or
friction, per the three triggers in "Marky wants your feedback" above. The cadence only
gates the *periodic check-in prompt*, not real-time bug reports.

### Check 2 — Contribution nudge

If `suggest_contribution == "on"` **and** now > `ask_contribution_next`, check whether the
user has locally built something worth sharing back with the community:

1. **Detect local skill work.** Compare the locally installed skills against the pristine
   published versions to find a NEW skill directory (one not in the published set) or a
   `SKILL.md` that has been substantially edited. The simplest reliable way is a content
   compare against the upstream repo — for a git checkout:

   ```bash
   git -C "$SKILL_INSTALL_DIR" fetch origin main --quiet
   git -C "$SKILL_INSTALL_DIR" status --porcelain skills/
   git -C "$SKILL_INSTALL_DIR" diff --stat origin/main -- skills/
   ```

   New untracked `skills/<name>/SKILL.md` files or non-trivial diffs to an existing
   `SKILL.md` are the signal. If the install is not a git checkout, compare file contents
   against the published copies the same way (re-fetch the upstream `SKILL.md` and diff). No
   local changes → nothing to offer; skip to the timestamp bump.

2. **Judge whether it is genuinely shareable.** Only proceed if it is a generic, reusable
   social-media job any Marky user could use — NOT a skill stuffed with the user's private
   prompts, client lists, internal business logic, or one-off specifics. When in doubt, do
   not nudge. (The full sanitize/generalize bar lives in `CONTRIBUTING.md`.)

3. **Ask with AskUserQuestion** — same three-option shape as the feedback prompt. Ask
   something like *"You've built/improved the `<name>` skill — want to contribute it back to
   the Marky community so others can use it?"*:

   | Option | What you do |
   | :--- | :--- |
   | **Yes** | **Read and follow `CONTRIBUTING.md`** — it is the canonical guide. Sanitize + generalize the skill first (strip business ids/keys/private context, rewrite so it is reusable for any Marky user), let the user review the final diff, then open the PR to the community repo. Bump `ask_contribution_next = now + 2 weeks` and write back. |
   | **No** | Bump `ask_contribution_next = now + 2 weeks` (a cooldown) and move on. Write back. |
   | **Don't ask again** | Set `suggest_contribution = "off"` in `user.toml` and write back. Never offer again. |

   Whichever they pick, update `ask_contribution_next` (or the flag) and write `user.toml`
   back before moving on.

#### Hard guardrails (always apply)

- **Generic and reusable only.** Never nudge to contribute a skill that carries the user's
  private prompts, client data, or internal business logic. When in doubt, do not nudge.
- **Never auto-open a PR.** A PR only happens after an explicit **Yes** AND the user has
  reviewed the sanitized content. No silent or automatic PRs, ever.
- **`CONTRIBUTING.md` is the canonical guide.** Do not re-derive the rules here — when the
  user says Yes, read `CONTRIBUTING.md` and follow its "Sanitize and generalize before you
  open a PR" section plus the quality bar and frontmatter spec.
- **Where it goes.** The contribution target is the community-tier repo
  `Marky-Team/marky-skills-community`. If that repo does not exist yet, tell the user it is
  coming and that their skill can target it once it is live — do not push to the private
  `Marky-Team/marky-skills` repo as a fallback.

## The shape: everything is scoped to a business

Almost every resource lives **under a business** (your workspace). The path always starts
with the business id:

```
/api/businesses/{business_id}/posts
/api/businesses/{business_id}/topics
/api/businesses/{business_id}/library
/api/businesses/{business_id}/integrations
...
```

So the first call you make is always `GET /businesses` to get your `business_id`, then you
slot that id into every path after it. Only a few org-level resources (`/keys`,
`/webhooks`, `/feedback`) sit outside a business.

### Pagination (list endpoints)

List endpoints (`GET /businesses`, `/posts`, `/topics`, ...) return **at most 20 items per
page** in a cursor-paginated envelope:

```json
{ "data": [ ... ], "has_more": true, "next_cursor": "..." }
```

If `has_more` is `true`, there are more results. Pass `?limit=100` to get a bigger page, or
page through with `?cursor=NEXT_CURSOR` until `has_more` is `false`. **This matters on the
very first call:** if your org has more than 20 workspaces, the one you want may not be on
page 1 of `GET /businesses` — use `?limit=100` (or page with the cursor) so you do not miss
it. Same for finding a specific post or topic in a long history.

## Get your API key

1. Sign in at [app.mymarky.ai](https://app.mymarky.ai).
2. Open **Organization Settings -> API Keys** (left sidebar -> Settings, then scroll to
   API Keys).
3. Click **Create API Key**, name it, and copy the `mk_live_...` value. It is only shown
   once, so save it somewhere safe.

Notes:
- You must be an **org admin** to create keys.
- A key has access to every workspace (business) in your organization.
- Keep the key in an environment variable or `.env` file, never in source control.
- Each org can have up to 10 active keys. Revoke a leaked key from the same page.

## Base URL and auth

```
Base URL:  https://api.mymarky.ai/api
Auth:      Authorization: Bearer mk_live_YOUR_KEY
```

Every request needs the Bearer header:

```bash
curl https://api.mymarky.ai/api/businesses \
  -H "Authorization: Bearer mk_live_YOUR_KEY"
```

Error responses:

| Status | Meaning |
|--------|---------|
| `401` | Missing or invalid API key |
| `403` | Business does not belong to your org |
| `404` | Business or resource not found |
| `429` | Rate limit exceeded (check the `Retry-After` header) |

Rate limits: 100 requests per minute per org.

## Connect the MCP

The Marky MCP server lets an agent call Marky's tools directly instead of you pasting REST
instructions.

```
MCP endpoint:  https://api.mymarky.ai/api/mcp
Transport:     streamable HTTP
Auth:          Authorization: Bearer mk_live_YOUR_KEY
```

### Claude Code CLI

One command. Replace `mk_live_YOUR_KEY` with your key:

```bash
claude mcp add --transport http marky https://api.mymarky.ai/api/mcp \
  --header "Authorization: Bearer mk_live_YOUR_KEY"
```

Then ask: *"List my Marky businesses."* Claude calls `list_businesses` and shows your
workspaces. Each has an `id` you use as `business_id` for everything else.

### Claude Desktop / Cowork

Claude Desktop talks to local (stdio) MCP servers, so you bridge to Marky's remote HTTP
server with the open-source `mcp-remote` package (run on demand via `npx`, no install).

Edit your Claude Desktop config file:
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

Add Marky under `mcpServers`:

```json
{
  "mcpServers": {
    "marky": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "https://api.mymarky.ai/api/mcp",
        "--header",
        "Authorization:${MARKY_AUTH}"
      ],
      "env": {
        "MARKY_AUTH": "Bearer mk_live_YOUR_KEY"
      }
    }
  }
}
```

Save and fully restart Claude Desktop. Marky's tools appear under the tools menu. The same
config works in Claude Cowork. (The key sits in the `env` block on purpose, so the space in
`Bearer mk_live_...` is passed as one piece and not split apart.)

### Any other MCP client (Cursor, custom agents)

Most clients take a config like this:

```json
{
  "mcpServers": {
    "marky": {
      "transport": "http",
      "url": "https://api.mymarky.ai/api/mcp",
      "headers": { "Authorization": "Bearer mk_live_YOUR_KEY" }
    }
  }
}
```

### The MCP tools (the curated set)

The MCP does **not** mirror the whole REST API. It exposes a **curated set of 28 typed
tools** — the high-value content actions an autonomous agent actually needs. Everything
else stays **REST-only** (still fully usable over REST, just not as an MCP tool). This is a
deliberate allowlist on the server, so an agent holding a content key can't nuke a
workspace, leak keys, or get lost in low-value per-item CRUD.

These are the **only** tool names the MCP server exposes. If you need an operation that is
not in this list, call it over REST (see "REST endpoints" below).

| Tool | What it does |
| :--- | :--- |
| `list_businesses` | List your workspaces. Grab the `id` you want as `business_id`. |
| `get_business` | Read one workspace, including its brand profile fields. |
| `create_business` | Create a new workspace. |
| `update_business` | Set the brand profile (tone, palettes, fonts, logo). |
| `list_posts` | List a business's posts (filter by status). |
| `get_post` | Check a post's status and per-platform publish results. |
| `create_post` | Create one post yourself (caption + platforms + media). |
| `update_post` | Edit a post (caption, `publish_to`, media). |
| `generate_draft_posts` | Generate on-brand draft posts from a topic. Returns a `job_id`. |
| `get_job_status` | Poll the `job_id` from `generate_draft_posts` until it completes. |
| `schedule_post` | Schedule a post for a future time. |
| `queue_post` | Drop a post into the next open posting-schedule slot. |
| `publish_post_now` | Publish a post immediately. |
| `get_post_analytics` | Engagement stats for one Marky post. |
| `revise_post_design` | Revise a post's design with a plain-language instruction. |
| `list_business_queue` | The current queued / scheduled lineup. |
| `get_posting_schedule` | Read the weekly recurring time slots. |
| `update_posting_schedule` | Set the weekly recurring time slots. |
| `list_topics` | List content topics. |
| `create_topic` | Add a content topic. |
| `list_categories` | List content categories. |
| `upload_media` | Upload an image or video; returns a URL for `media_urls`. |
| `search_library` | Search your uploaded media library. |
| `list_business_integrations` | List connected social accounts (read `platform` + `status`). |
| `list_business_reviews` | Read your Google Business reviews. |
| `search_templates` | Find design templates to use in generation. |
| `create_design` | Render a design from a template (text + palette + logo). Returns `image_urls`. |
| `submit_feedback` | Send a bug report, feature request, or general feedback to the Marky team. |

**REST-only (not MCP tools)** — reach these over REST when you need them: per-item topic /
category / library / file / folder GET-DELETE-UPDATE, `list_templates`, `list_library`, the
secondary stats endpoints (`get_integration_stats`, `list_integration_posts`,
`get_external_post_stats`), webhooks, API-key create/list/revoke, `delete_business`, and
`delete_post`.

## REST endpoints

All paths are relative to `https://api.mymarky.ai/api`. All need the Bearer header. Almost
every path is nested under `/businesses/{business_id}`.

### Businesses (workspaces)

- `GET /businesses` — list your workspaces. Copy the `id` you want; that is your
  `business_id` for every other call.
- `GET /businesses/{business_id}` — one workspace (includes the brand profile fields).
- `POST /businesses` — create a workspace (`name` is required).
- `PATCH /businesses/{business_id}` — update a workspace, **including the brand profile**
  (see below).
- `DELETE /businesses/{business_id}` — delete a workspace (REST only, not an MCP tool).

A business in the response looks like:

```json
{ "id": "your-business-uuid", "name": "My Business", "industry": "Marketing", "website": "https://mybusiness.com", "language": "English" }
```

### Brand profile (flat fields on the business)

There is **no separate brand-profile endpoint**. The brand lives as flat fields on the
business object — read them with `GET /businesses/{id}` and set them with
`PATCH /businesses/{id}`. Marky applies them automatically whenever it writes captions or
renders designs:

```bash
curl -X PATCH https://api.mymarky.ai/api/businesses/BIZ_ID \
  -H "Authorization: Bearer mk_live_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "tone": "Warm, confident, and plain-spoken. No jargon.",
    "caption_writing_rules": "Never use emojis. Keep sentences short.",
    "caption_suffix": "\n\n#smallbusiness #local",
    "imagery_preferences": "Bright, natural light. Real people, not stock-looking shots.",
    "tagline": "Service you can trust.",
    "ctas": ["Call today", "Book online"],
    "palettes": [["#0A0A0A", "#FFFFFF", "#E11D48"]],
    "header_font": { "family": "Poppins" },
    "body_font": { "family": "Inter" },
    "logo_url": "https://.../logo.png",
    "logo_background_color": "#00000000",
    "logo_width": 240
  }'
```

Every field is optional — send only what you want to change. Key brand fields: `tone`,
`caption_writing_rules`, `caption_suffix`, `custom_caption_prompt`, `imagery_preferences`,
`tagline`, `ctas`, `palettes`, `header_font`, `body_font`, `logo_url`,
`logo_background_color`, `logo_width`.

### Integrations (connected social accounts)

- `GET /businesses/{business_id}/integrations` — list the social accounts connected to a
  business. **You connect accounts in the dashboard, not via the API** — the API can see
  them but cannot add new ones.

Each integration has:

```json
{ "id": "...", "platform": "instagram", "username": "...", "status": "valid", "selected_page_name": "..." }
```

The field that names the platform is **`platform`** (e.g. `facebook`, `instagram`,
`linkedIn`, `tiktok`, `instagramStory`). Read it here before you choose `publish_to`
targets so you only post to platforms the account actually has connected. Target only
integrations whose `status` is `valid`.

### Media

- `POST /businesses/{business_id}/media` — upload an image or video. Multipart form, field
  name `file`, up to 50 MB. Optional `alt_text` query param. Returns a `MediaResponse` with
  `original_url`. Pass that URL in a post's `media_urls`.

```bash
curl -X POST "https://api.mymarky.ai/api/businesses/BIZ_ID/media" \
  -H "Authorization: Bearer mk_live_YOUR_KEY" \
  -F "file=@/path/to/photo.jpg"
```

### Posts

- `POST /businesses/{business_id}/posts` — create a post.
  - `caption` (required)
  - `publish_to` — target platforms, e.g. `["instagram", "facebook", "linkedIn"]`
    (case-insensitive)
  - `media_urls` — image/video URLs to attach (use `original_url` from an upload)
  - `status` — `NEW` (default draft) or `SCHEDULED`
  - `scheduled_publish_time` — ISO 8601 time, required if `status` is `SCHEDULED`
- `GET /businesses/{business_id}/posts?status=NEW` — list posts (filter by status).
- `GET /businesses/{business_id}/posts/{post_id}` — one post, including `publish_results`
  (per-platform outcome) and `scheduled_publish_time`.
- `PATCH /businesses/{business_id}/posts/{post_id}` — update a post (e.g. change
  `publish_to`, `caption`, or `media_urls`).
- `DELETE /businesses/{business_id}/posts/{post_id}` — delete a post.
- `POST /businesses/{business_id}/posts/{post_id}/schedule` — schedule a post.
  - `scheduled_publish_time` (required) — ISO 8601 time, must be in the future
  - `publish_to` — defaults to all connected platforms if omitted
- `POST /businesses/{business_id}/posts/{post_id}/queue` — drop the post into the
  business's posting schedule (the next open slot) instead of a fixed time.
- `POST /businesses/{business_id}/posts/{post_id}/publish` — publish immediately.

A created post:

```json
{ "id": "post-uuid", "business_id": "...", "caption": "...", "status": "NEW", "publish_to": ["instagram", "linkedIn"] }
```

### Generate on-brand posts (let Marky write them)

- `POST /businesses/{business_id}/posts/generate` — generate draft posts. Brand voice,
  colors, and logo are pulled from the business automatically.
  - `content` — what to post about (used as the topic)
  - `website_url` — a page to scrape for context (alternative to `content`)
  - `custom_idea` — skip ideation and use this exact idea for every post
  - `count` — how many to generate (1-10)
  - `creative_formats` — which post formats to round-robin (e.g. `["image"]`, `["video"]`)
  - `ai_image_type` — sub-type when generating AI images: `design`, `photo`, `infographic`,
    or `meme`
  - `ai_image_style` — visual style for AI images (e.g. `corporate-flat`, `isometric`)
  - `template_ids` — restrict design generation to specific templates
  - `voice` — override the brand tone for this generation only
  - `include_stock` — allow stock photos (Unsplash/Pexels)
  - `aspect_ratio` — media aspect, e.g. `1:1`, `9:16`
  - Returns a `job_id`.
- `GET /businesses/{business_id}/jobs/{job_id}` — poll until `status` is `completed`. Then
  list the new drafts with `GET /businesses/{business_id}/posts?status=NEW`.

### Stats (engagement)

- `GET /businesses/{business_id}/posts/{post_id}/stats` — engagement for one Marky post.
- `GET /businesses/{business_id}/integrations/{integration_id}/posts` — posts published on
  a platform, with stats.
- `GET /businesses/{business_id}/integrations/{integration_id}/stats` — account-level
  audience stats.
- `GET /businesses/{business_id}/integrations/{integration_id}/posts/{external_post_id}/stats`
  — stats for one already-published post by its provider id.

### Topics, categories, posting schedule

- `GET|POST /businesses/{business_id}/topics`,
  `GET|PATCH|DELETE /businesses/{business_id}/topics/{topic_id}` — content topics.
- `GET|POST /businesses/{business_id}/categories`,
  `GET|PATCH|DELETE /businesses/{business_id}/categories/{category_id}` — content
  categories. A topic can reference a `category_id`.
- `GET|PUT /businesses/{business_id}/posting-schedule` — the weekly recurring time slots
  used when you `queue` a post. PUT takes `timeslots` like `["MON 15:00", "FRI 09:00"]`
  and an optional `jitter_minutes`.
- `GET /businesses/{business_id}/queue` — the current queued/scheduled lineup.

### Library, folders, files

- `GET /businesses/{business_id}/library` — your uploaded media library.
- `GET /businesses/{business_id}/library/search?query=...` — search the library.
- `POST /businesses/{business_id}/library/files` — create a text file (`path` + `content`).
- `GET|DELETE /businesses/{business_id}/library/{media_id}` — one media item.
- `GET|POST /businesses/{business_id}/folders`,
  `GET|PATCH|DELETE /businesses/{business_id}/folders/{folder_id}` — organize files.
- `GET /businesses/{business_id}/files`,
  `GET|PUT|DELETE /businesses/{business_id}/files/{file_id}` — text docs / knowledge base.
- `POST /businesses/{business_id}/files/{file_id}/media` — attach uploaded media to a file
  (body: `{ "media_ids": ["MEDIA_ID"] }`).

### Reviews, templates, designs

- `GET /businesses/{business_id}/reviews` — your Google Business reviews (reviewer, star
  rating, text, reply). `order_by` accepts `updateTime desc` (default), `rating`, or
  `rating desc`.
- `GET /businesses/{business_id}/templates` — list available design templates (each item
  has a `template_id`, `name`, `page_count`, `preview_url`).
- `POST /businesses/{business_id}/templates/search` — find the best-matching template for
  filters like `is_meme` / `has_image_slot`. Returns a **single** template object under a
  `template` key (with its full `pages` / `image_slots`), not a list. Use the `template_id`
  from it in `POST /designs`.
- `POST /businesses/{business_id}/designs` — render a design from a template
  (`template_id`, `text_content`, `palette`, `logo_url`, `filler_media`, ...). Returns the
  rendered `image_urls`.
- `POST /businesses/{business_id}/posts/{post_id}/design/edit` — revise a post's design with
  a plain-language `instruction` (e.g. "make the headline tan").

### Org-level (not under a business)

- `GET|POST /webhooks`, `DELETE /webhooks/{webhook_id}`,
  `GET /webhooks/{webhook_id}/deliveries` — get notified when posts publish
  (`post.published`). Deliveries are signed with HMAC-SHA256 in the `X-Marky-Signature`
  header.
- `GET|POST /keys`, `DELETE /keys/{key_id}` — manage API keys (REST only; key
  create/revoke are not MCP tools).
- `POST /feedback` — send feedback to the Marky team. Body: `type` (`bug` / `feature` /
  `feedback`), `message`, optional `context`. See "Marky wants your feedback" near the top
  for when and how to use it — please do.

## Platform name reference

`publish_to` is **case-insensitive**, so `linkedin` and `linkedIn` both work. The
integration `platform` field returns these canonical strings:

| Platform | String |
| :--- | :--- |
| Facebook | `facebook` |
| Instagram | `instagram` |
| Instagram Story | `instagramStory` |
| LinkedIn | `linkedIn` |
| TikTok | `tiktok` |

These five are the common targets. The `publish_to` enum also accepts `twitter`,
`linkedInProfile`, `pinterest`, `googleBusiness`, and `youtube` — but only target a platform
that shows up as a `valid` integration on the business.

Media rules of thumb:
- **Video** posts can target all platforms.
- **Image** posts target all except TikTok.
- **Text-only** posts target only `facebook` and `linkedIn` (Instagram, TikTok, and
  Stories all require media).

Always read `GET /businesses/{id}/integrations` first and only target platforms whose
`status` is `valid`.

## Before you start

- **Connect your social accounts in the dashboard first.** This is a one-time step at
  [app.mymarky.ai](https://app.mymarky.ai). The API sees connected accounts but cannot add
  new ones.
- Find your `business_id` with `GET /businesses` (or from the dashboard URL
  `app.mymarky.ai/businesses/{business_id}`).
- Posts you create via the API show up in your normal Marky queue, so you can review them
  in the dashboard too.
