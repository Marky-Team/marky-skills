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

- **MCP** (recommended for agents) — Claude gets Marky's tools natively (`list_businesses`,
  `generate_posts`, `create_post`, `schedule_post`, `get_post`, ...). Connect once, then
  just ask in plain language. See "Connect the MCP" below.
- **REST** (for scripts and curl) — every MCP tool maps to one REST call. See "REST
  endpoints" below.

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
        "Authorization: Bearer mk_live_YOUR_KEY"
      ]
    }
  }
}
```

Save and fully restart Claude Desktop. Marky's tools appear under the tools menu. The same
config works in Claude Cowork.

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

### Common MCP tools

| Tool | What it does |
| :--- | :--- |
| `list_businesses` | List your workspaces. Grab the `id` you want as `business_id`. |
| `generate_posts` | Generate on-brand draft posts from a topic. Brand voice, colors, and logo come from the business automatically. |
| `create_post` | Create one post yourself (caption + platforms). |
| `schedule_post` | Schedule a post for a future time. |
| `get_post` | Check a post's status and per-platform publish results. |

The full tool list mirrors the REST endpoints below one-to-one.

## REST endpoints

All paths are relative to `https://api.mymarky.ai/api`. All need the Bearer header.

### Businesses (workspaces)

- `GET /businesses` — list your workspaces. Copy the `id` you want; that is your
  `business_id` for every other call.
- `GET /businesses/{business_id}` — one workspace.
- `POST /businesses` — create a workspace.

A business in the response looks like:

```json
{ "id": "your-business-uuid", "title": "My Business", "industry": "Marketing", "website": "https://mybusiness.com" }
```

### Integrations (connected social accounts)

- `GET /businesses/{business_id}/integrations` — list the social accounts connected to a
  business. **You connect accounts in the dashboard, not via the API** — the API can see
  them but cannot add new ones.

Each integration has:

```json
{ "id": "...", "platform": "instagram", "username": "...", "status": "VALID", "selected_page_name": "..." }
```

The field that names the platform is **`platform`** (e.g. `facebook`, `instagram`,
`linkedIn`, `tiktok`, `instagramStory`). Read it here before you choose `publish_to`
targets so you only post to platforms the account actually has connected.

### Media

- `POST /media?business_id={business_id}` — upload an image or video. Multipart form,
  field name `file`, up to 50 MB. Returns a `MediaResponse` with `original_url`. Pass that
  URL in a post's `media_urls`.

```bash
curl -X POST "https://api.mymarky.ai/api/media?business_id=BIZ_ID" \
  -H "Authorization: Bearer mk_live_YOUR_KEY" \
  -F "file=@/path/to/photo.jpg"
```

### Posts

- `POST /posts` — create a post.
  - `business_id` (required), `caption` (required)
  - `publish_to` — target platforms, e.g. `["instagram", "facebook", "linkedIn"]`
  - `media_urls` — image/video URLs to attach (use `original_url` from an upload)
  - `status` — initial status (`NEW` by default; `SCHEDULED` to lock a time)
  - `adhoc_publish_time` — ISO 8601 time, required if `status` is `SCHEDULED`
- `GET /posts?business_id={business_id}&status=NEW` — list posts (filter by status).
- `GET /posts/{post_id}` — one post, including `publish_results` (per-platform outcome).
- `PATCH /posts/{post_id}` — update a post (e.g. change `publish_to` or `caption`).
- `POST /posts/{post_id}/schedule` — schedule a post.
  - `publish_at` (required) — ISO 8601 time, must be in the future
  - `publish_to` — defaults to all connected platforms if omitted
- `POST /posts/{post_id}/publish` — publish immediately.

A created post:

```json
{ "id": "post-uuid", "business_id": "...", "caption": "...", "status": "NEW", "publish_to": ["instagram", "linkedIn"] }
```

### Generate on-brand posts (let Marky write them)

- `POST /posts/generate` — generate draft posts. Brand voice, colors, and logo are pulled
  from the business automatically.
  - `business_id` (required)
  - `content` — what to post about (used as the topic)
  - `website_url` — a page to scrape for context (alternative to `content`)
  - `custom_idea` — skip ideation and use this exact idea for every post
  - `count` — how many to generate (1-10)
  - `platforms` — target platforms
  - Returns a `job_id`.
- `GET /jobs/{job_id}` — poll until `status` is `completed`. Then list the new drafts with
  `GET /posts?business_id=...&status=NEW`.

### Stats (engagement)

- `GET /posts/{post_id}/stats` — engagement for one post.
- `GET /integrations/{integration_id}/posts` — posts published on a platform, with stats.
- `GET /integrations/{integration_id}/stats` — account-level audience stats.

### Topics, library, webhooks, keys

- `GET|POST /topics`, `GET|PATCH|DELETE /topics/{topic_id}` — content topics per business.
- `GET /library`, `POST /library/files`, `GET|DELETE /library/{media_id}` — your media library.
- `GET|POST /webhooks`, `DELETE /webhooks/{webhook_id}` — get notified when posts publish
  (`post.published`). Deliveries are signed with HMAC-SHA256 in the `X-Marky-Signature`
  header.
- `GET|POST /keys`, `DELETE /keys/{key_id}` — manage API keys.

## Platform name reference

Use these exact strings in `publish_to` (they must match the integration `platform`
value exactly, including camelCase):

| Platform | String |
| :--- | :--- |
| Facebook | `facebook` |
| Instagram | `instagram` |
| Instagram Story | `instagramStory` |
| LinkedIn | `linkedIn` |
| TikTok | `tiktok` |

Media rules of thumb:
- **Video** posts can target all platforms.
- **Image** posts target all except TikTok.
- **Text-only** posts target only `facebook` and `linkedIn` (Instagram, TikTok, and
  Stories all require media).

Always read `GET /businesses/{id}/integrations` first and only target platforms whose
`status` is `VALID`.

## Before you start

- **Connect your social accounts in the dashboard first.** This is a one-time step at
  [app.mymarky.ai](https://app.mymarky.ai). The API sees connected accounts but cannot add
  new ones.
- Find your `business_id` with `GET /businesses` (or from the dashboard URL
  `app.mymarky.ai/businesses/{business_id}`).
- Posts you create via the API show up in your normal Marky queue, so you can review them
  in the dashboard too.
