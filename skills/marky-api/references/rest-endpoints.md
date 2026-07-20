# REST endpoints — the full reference

Part of the `marky-api` skill. This is the complete REST surface with request/response
shapes and examples. The main SKILL.md carries a cheat sheet of the most-used calls;
come here when you need a resource that isn't on it (library, folders, files, designs,
templates, webhooks, keys, reviews, categories) or the full field detail of one that is.

All paths are relative to `https://api.mymarky.ai/api`. All need the Bearer header. Almost
every path is nested under `/businesses/{business_id}`.

## Contents

- [Businesses (workspaces)](#businesses-workspaces)
- [Brand profile (flat fields on the business)](#brand-profile-flat-fields-on-the-business)
- [Integrations (connected social accounts)](#integrations-connected-social-accounts)
- [Media](#media)
- [Posts](#posts)
- [Generate on-brand posts](#generate-on-brand-posts-let-marky-write-them)
- [Stats (engagement)](#stats-engagement)
- [Topics, categories, posting schedule](#topics-categories-posting-schedule)
- [Library, folders, files](#library-folders-files)
- [Reviews, templates, designs](#reviews-templates-designs)
- [Org-level (not under a business)](#org-level-not-under-a-business)

## Businesses (workspaces)

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

## Brand profile (flat fields on the business)

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
    "palettes": [{ "name": "Brand", "colors": ["#0A0A0A", "#FFFFFF", "#E11D48"] }],
    "header_font": { "family": "Poppins" },
    "body_font": { "family": "Inter" },
    "logo_url": "https://.../logo.png",
    "logo_background_color": "#00000000",
    "logo_width": 240
  }'
```

Every field is optional — send only what you want to change. **Shape note:** on the
business object, `palettes` is a list of palette OBJECTS (`{name, colors, text_color}`),
so the colors live at `palettes[0].colors`. (The bare nested-array form
`[["#hex", ...]]` is only accepted by the generate endpoints' `palettes` override.)
Key brand fields: `tone`,
`caption_writing_rules`, `caption_suffix`, `custom_caption_prompt`, `imagery_preferences`,
`tagline`, `ctas`, `palettes`, `header_font`, `body_font`, `logo_url`,
`logo_background_color`, `logo_width`.

## Integrations (connected social accounts)

- `GET /businesses/{business_id}/integrations` — list the social accounts connected to a
  business. **You connect accounts in the dashboard, not via the API** — the API can see
  them but cannot add new ones.

Each integration has:

```json
{ "id": "...", "platform": "instagram", "username": "...", "status": "valid", "selected_page_name": "..." }
```

The field that names the platform is **`platform`** (e.g. `facebook`, `instagram`,
`linkedIn`, `tiktok`, `instagramStory`). Read it here before you choose `restrict_publish_to`
targets so you only post to platforms the account actually has connected. Target only
integrations whose `status` is `valid`.

## Media

- `POST /businesses/{business_id}/media` — upload an image or video. Multipart form, field
  name `file`, up to 50 MB. Optional `alt_text` query param. Returns a `MediaResponse` with
  `original_url`. Pass that URL in a post's `media_urls`.

```bash
curl -X POST "https://api.mymarky.ai/api/businesses/BIZ_ID/media" \
  -H "Authorization: Bearer mk_live_YOUR_KEY" \
  -F "file=@/path/to/photo.jpg"
```

## Posts

- `POST /businesses/{business_id}/posts` — create a post.
  - `caption` (required)
  - `platform_overrides` — per-platform variants: a list of `{platform, caption,
    media_urls, title, link, first_comment}` objects (all content fields optional;
    unset falls back to the post's own). On PATCH the list REPLACES the whole set
    (`[]` clears). Set these on every multi-platform post — see
    `references/platform-rules.md`.
  - `restrict_publish_to` — target platforms, e.g. `["instagram", "facebook", "linkedIn"]`
    (case-insensitive)
  - `media_urls` — image/video URLs to attach (use `original_url` from an upload)
  - `status` — `NEW` (default draft) or `SCHEDULED`
  - `scheduled_publish_time` — ISO 8601 time, required if `status` is `SCHEDULED`
  - `link` — clickable destination URL, for the platforms that support link posts:
    the Facebook link attachment, the Google Business CTA button, and the Pinterest
    pin destination. Other platforms ignore it — put the link in the caption there.
    Must be http(s). Per-platform links go in `platform_overrides` instead.
  - `metadata` — up to 50 string key/value pairs, YOUR analytics dimensions (see
    "Tag every post" in the main SKILL.md). Returned verbatim on every read; Marky never
    interprets it. Limits: key <=40 chars, value <=500 chars.
- `GET /businesses/{business_id}/posts?status=NEW` — list posts (filter by status;
  also accepts the review verdicts `LIKED` and `REJECTED`).
- `GET /businesses/{business_id}/posts/{post_id}` — one post, including `publish_results`
  (per-platform outcome) and `scheduled_publish_time`.
- `PATCH /businesses/{business_id}/posts/{post_id}` — update a post (e.g. change
  `restrict_publish_to`, `caption`, `media_urls`, `link`, or `metadata`).
  - `status` — move the post through the TEAM review workflow: `NEW` tells the
    user's team it's ready for review (it appears on the app's review page),
    `LIKED` records a reviewer's approval, `REJECTED` a decline. Marky does not
    gate publishing on these — they are the team's own workflow state. Only
    valid on posts currently in `NEW`/`LIKED`/`REJECTED` (scheduling has its own
    endpoint; published posts are immutable).

### Team review comments

The review-page discussion thread, for reviewer-tier workflows:

- `GET /businesses/{business_id}/posts/{post_id}/comments` — list comments
  (newest first, `CursorPage`, includes `author_name` and `resolved`).
- `POST /businesses/{business_id}/posts/{post_id}/comments` — add a comment
  (`body`, max 2000 chars). API-key calls are attributed to the key's creator.
- `PATCH /businesses/{business_id}/posts/{post_id}/comments/{comment_id}` —
  set `resolved: true|false`.
- `DELETE /businesses/{business_id}/posts/{post_id}` — delete a post.
- `POST /businesses/{business_id}/posts/{post_id}/schedule` — schedule a post.
  - `scheduled_publish_time` (required) — ISO 8601 time, must be in the future
  - `restrict_publish_to` — defaults to all connected platforms if omitted
- `POST /businesses/{business_id}/posts/{post_id}/queue` — drop the post into the
  business's posting schedule (the next open slot) instead of a fixed time.
- `POST /businesses/{business_id}/posts/{post_id}/publish` — publish immediately.

A created post:

```json
{ "id": "post-uuid", "business_id": "...", "caption": "...", "status": "NEW", "restrict_publish_to": ["instagram", "linkedIn"] }
```

## Generate on-brand posts (let Marky write them)

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

## Stats (engagement)

- `GET /businesses/{business_id}/posts/{post_id}/stats` — engagement for one Marky post.
- `GET /businesses/{business_id}/integrations/{integration_id}/posts` — posts published on
  a platform, with stats.
- `GET /businesses/{business_id}/integrations/{integration_id}/stats` — account-level
  audience stats.
- `GET /businesses/{business_id}/integrations/{integration_id}/posts/{external_post_id}/stats`
  — stats for one already-published post by its provider id.

## Topics, categories, posting schedule

- `GET|POST /businesses/{business_id}/topics`,
  `GET|PATCH|DELETE /businesses/{business_id}/topics/{topic_id}` — content topics.
- `GET|POST /businesses/{business_id}/categories`,
  `GET|PATCH|DELETE /businesses/{business_id}/categories/{category_id}` — content
  categories. A topic can reference a `category_id`.
- `GET|PUT /businesses/{business_id}/posting-schedule` — the weekly recurring time slots
  used when you `queue` a post. PUT takes `timeslots` like `["MON 15:00", "FRI 09:00"]`
  and an optional `jitter_minutes`.
- `GET /businesses/{business_id}/queue` — the current queued lineup, soonest first.
  Paginated (items under `items`, `limit`/`cursor` params, follow the `next`
  cursor until it is null).
- `GET /businesses/{business_id}/queue/summary` — aggregate queue health in one call:
  `queued_count`, `next_estimated_publish_time`, `last_estimated_publish_time` (when
  the queue runs dry). Use this instead of paging the list when you only need "is the
  queue low?".

## Library, folders, files

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

## Reviews, templates, designs

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

## Org-level (not under a business)

- `GET|POST /webhooks`, `DELETE /webhooks/{webhook_id}`,
  `GET /webhooks/{webhook_id}/deliveries` — get notified when posts publish
  (`post.published`). Deliveries are signed with HMAC-SHA256 in the `X-Marky-Signature`
  header.
- `GET|POST /keys`, `DELETE /keys/{key_id}` — manage API keys (REST only; key
  create/revoke are not MCP tools).
- `POST /feedback` — send feedback to the Marky team. Body: `type` (`bug` / `feature` /
  `feedback`), `message`, optional `context`. See "Marky wants your feedback" in the main
  SKILL.md for when and how to use it — please do.
