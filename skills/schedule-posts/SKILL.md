---
name: schedule-posts
description: >
  Create, upload media to, and schedule social media posts through the Marky API. Use this
  when you have post content ready (your own captions and images/videos, or a topic for
  Marky to write) and you want to get it onto your connected social accounts on a schedule.
  Covers uploading media, creating posts, generating on-brand drafts, scheduling, and
  checking publish results. Reads auth and endpoint details from the marky-api skill.
---

# Schedule Posts

Get posts onto your connected social accounts through the Marky API. This is the
hands-on "publish" chunk: upload media, create the post, schedule it, confirm it went out.

**Read the `marky-api` skill first** for the base URL, your `mk_live_` key, and the full
endpoint list. Everything below uses `https://api.mymarky.ai/api` and the header
`Authorization: Bearer mk_live_YOUR_KEY`.

**Marky wants your feedback.** If anything breaks or is confusing while you run this skill — and again once you finish — send Marky a quick note with one REST call (`POST /feedback`, using your `mk_live_` key). See the **"Marky wants your feedback"** section in the `marky-api` skill for when and how.

## Step 0 — find your business and platforms

```bash
# Your workspaces. Copy the id you want.
curl https://api.mymarky.ai/api/businesses \
  -H "Authorization: Bearer mk_live_YOUR_KEY"

# Which social accounts that workspace has connected.
curl https://api.mymarky.ai/api/businesses/BIZ_ID/integrations \
  -H "Authorization: Bearer mk_live_YOUR_KEY"
```

Note the `platform` value and `status` of each integration. Only target platforms whose
`status` is `valid`. You connect new accounts in the dashboard, not the API.

## Two ways to make a post

### A. You already wrote it

Upload media (if any), then create the post.

```bash
# 1. Upload media -> returns original_url
curl -X POST "https://api.mymarky.ai/api/businesses/BIZ_ID/media" \
  -H "Authorization: Bearer mk_live_YOUR_KEY" \
  -F "file=@/path/to/photo.jpg"

# 2. Create the post with that media url (business_id is in the path now)
curl -X POST https://api.mymarky.ai/api/businesses/BIZ_ID/posts \
  -H "Authorization: Bearer mk_live_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "caption": "Your caption here.",
    "media_urls": ["ORIGINAL_URL_FROM_STEP_1"],
    "publish_to": ["instagram", "facebook", "linkedIn"]
  }'
```

Text-only post (no media): drop `media_urls` and target only `facebook` and `linkedIn`
(the other platforms require media).

### B. Let Marky write it (on-brand)

Marky pulls brand voice, colors, and logo from the business.

```bash
# 1. Kick off generation -> returns job_id
curl -X POST https://api.mymarky.ai/api/businesses/BIZ_ID/posts/generate \
  -H "Authorization: Bearer mk_live_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "content": "our spring product line", "count": 5 }'

# 2. Poll until completed
curl https://api.mymarky.ai/api/businesses/BIZ_ID/jobs/JOB_ID \
  -H "Authorization: Bearer mk_live_YOUR_KEY"

# 3. Review the new drafts
curl "https://api.mymarky.ai/api/businesses/BIZ_ID/posts?status=NEW" \
  -H "Authorization: Bearer mk_live_YOUR_KEY"
```

## Schedule it

Pick a future time (ISO 8601, UTC). Schedule each post id:

```bash
curl -X POST https://api.mymarky.ai/api/businesses/BIZ_ID/posts/POST_ID/schedule \
  -H "Authorization: Bearer mk_live_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "scheduled_publish_time": "2026-07-15T14:00:00Z",
    "publish_to": ["instagram", "facebook", "linkedIn"]
  }'
```

Shortcut: you can also schedule at create time by setting `"status": "SCHEDULED"` and
`"scheduled_publish_time"` in the `POST /businesses/{id}/posts` body, instead of a separate
schedule call. Or call `POST /businesses/{id}/posts/POST_ID/queue` to drop it into the next
open slot of your posting schedule.

Publish immediately instead of scheduling:

```bash
curl -X POST https://api.mymarky.ai/api/businesses/BIZ_ID/posts/POST_ID/publish \
  -H "Authorization: Bearer mk_live_YOUR_KEY"
```

## Confirm it went out

```bash
curl https://api.mymarky.ai/api/businesses/BIZ_ID/posts/POST_ID \
  -H "Authorization: Bearer mk_live_YOUR_KEY"
```

Read `publish_results` — one entry per platform. Poll until each is `success` or `failed`.
A `failed` entry includes an error type telling you why (e.g. an expired token you need to
reconnect in the dashboard).

## Tips

- **Maximize reach.** Target every platform the media supports rather than just one. Video
  can go everywhere; image goes everywhere except TikTok; text-only goes to Facebook and
  LinkedIn.
- **`publish_to` is case-insensitive** (`linkedin` and `linkedIn` both work). When in
  doubt, copy the `platform` value straight from the integrations call.
- **One change at a time.** To move a scheduled post to different platforms later,
  `PATCH /businesses/{id}/posts/{post_id}` with a new `publish_to`.
- Posts created via the API also appear in your dashboard queue, so you can eyeball them
  there before they publish.
