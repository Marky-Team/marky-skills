---
name: plan-social-content
description: >
  Plan, write, and schedule a week of on-brand social media content for your business
  through the Marky API. Use this when you want a full week of posts produced and queued
  with one conversation: it mines real material from your own notes and updates, drafts in
  your voice, shows you everything for approval, then schedules across every platform you
  have connected. Always gets your approval before anything is scheduled. Uses the
  marky-api and schedule-posts skills to talk to Marky.
---

# Plan Social Content

Plan the next week of your social media as a repeatable batch. The goal is consistent,
on-brand posts that get your message in front of the right people, without you sitting down
to write every one from scratch.

This skill **plans and produces, then schedules only after you approve.** Posting to your
live accounts is brand-facing, so you review the whole batch and say go before a single
post is queued. That approval gate is the most important step. Never skip it.

**Read the `marky-api` skill first** for your `mk_live_` key, the base URL, and the
endpoints. Use the `schedule-posts` skill for the actual create/schedule calls.

**Marky wants your feedback.** If anything breaks or is confusing while you run this
skill — and again once you finish a week's plan — send Marky a quick note with one REST
call (`POST /feedback`, using your `mk_live_` key). See the **"Marky wants your feedback"**
section in the `marky-api` skill for when and how.

## Where your data lives

Keep a small folder somewhere on your machine (you choose where, e.g.
`~/marky-content/`). The recipe is in this skill; your data lives in the folder so it
builds up over time:

- `writing-style.md` — your voice profile: tone, words you like and avoid, do's and
  don'ts. Read it before drafting. Update it whenever an edit reveals a lasting preference.
- `calendar.md` — a human-readable view of the week's plan.
- `material.md` — running notes of post-worthy moments worth turning into content (a
  customer win, a lesson learned, a new offering, a behind-the-scenes detail).

If the folder is empty on the first run, that is fine. Start a `writing-style.md` by asking
the user a few questions about their brand voice, and create the rest as you go.

## Stages

### Stage 1 — Gather real material

Good posts are grounded in something real, not generic filler. Before drafting, collect a
handful of concrete things worth saying. Pull from whatever the user actually has:

- Their `material.md` notes (the richest source over time).
- Recent wins, launches, lessons, or behind-the-scenes moments they describe to you.
- Their website or a recent blog post (you can pass a `website_url` to Marky's generator to
  pull in page context).
- Their connected platforms' recent performance —
  `GET /businesses/{id}/integrations/{integration_id}/stats` and
  `GET /businesses/{id}/integrations/{integration_id}/posts` show what has landed before.

**Judgment gate:** not every real thing is postable. Skip anything that would worry
customers, expose private details, or name a person or customer without their consent. Keep
it grounded and safe.

### Stage 2 — Learn what is working (optional, once you have history)

If the business has posted through Marky for a few weeks, look at the engagement before
planning. Pull per-post stats (`GET /businesses/{id}/posts/{post_id}/stats`) and account stats, and notice
patterns: which topics, formats, and platforms get the most reach and engagement. Lean the
next week toward what works, but keep some variety so you keep learning. If there is no
history yet, skip this and come back to it later.

### Stage 3 — Plan the week

Design about 6 posts for the week.

- **Anchor every post to something real** from Stage 1. A post that sounds like a human who
  was actually there beats a generic one every time.
- **Keep variety** across topics and formats (a tip, a story, a result, a question, a
  behind-the-scenes look) so the feed does not feel repetitive.
- **Lead with the value to the reader,** not the feature or the jargon. Say what they get.
- **Cover the platforms you have connected.** Check
  `GET /businesses/{id}/integrations` and plan to reach each `valid` one.
- **Respect the brand profile and `writing-style.md` exactly.** Match the voice, and
  avoid anything on the brand's "don't" list.
- Write the week into `calendar.md` so it is easy to scan.

### Stage 4 — Ask for what only the user can give

Some posts need input only the user has: a photo, a screen recording, a short talking-head
clip, a specific number, a quote they want to use. List those clearly and concisely so the
user can gather them in one short sitting. If a post needs footage they cannot provide this
week, swap it for one that needs nothing extra.

### Stage 5 — Produce the drafts

For each post:

- **Write the caption** in the brand's voice. Pull the business's brand profile first
  (`GET /businesses/{id}` — `tone`, `caption_writing_rules`, `caption_suffix`; see
  "Write like the business" in the `marky-api` skill) and layer `writing-style.md` on top.
- **Prepare media.** Use the photos, graphics, or video the user provides. Upload each via
  `POST /businesses/{id}/media` and keep the returned `original_url`.
- **Or design a diagram.** When a post announces, teaches, or compares something and no
  photo exists, a branded diagram image often beats stock. Use the `post-diagrams` skill:
  it pulls the brand colors from the API, authors the diagram as HTML, renders a PNG, and
  uploads it.
- **Or let Marky write it.** For posts where the user just has a topic, use
  `POST /businesses/{id}/posts/generate` (brand voice, colors, and logo come from the
  business automatically), poll the job, and review the drafts.

### Stage 6 — Approve, then schedule (hard gate)

1. Present the full batch to the user: each post's caption, its media, and which platforms
   it targets.
2. **Stop and get explicit approval.** Do not schedule anything until the user says go.
   Apply their edits. If an edit reveals a lasting voice preference, write it into
   `writing-style.md` AND persist it to the business's brand profile (`tone` /
   `caption_writing_rules` via `PATCH /businesses/{id}` or `update_business`) so Marky's
   own generator learns it too — see "Learn the user's style" in the `marky-api` skill.
3. On approval, schedule through Marky (see the `schedule-posts` skill). Spread the posts
   across the week — for example one per day at a consistent time. Use
   `POST /businesses/{id}/posts/{post_id}/schedule` with a future `scheduled_publish_time`,
   and maximize `restrict_publish_to` to every platform the media supports.
4. Update `calendar.md` with the scheduled times.

### Stage 7 — Confirm

After the scheduled times pass, check `GET /businesses/{id}/posts/{post_id}` and read `publish_results`. Every
platform entry should be `success`. If one is `failed`, tell the user why (often an account
that needs reconnecting in the dashboard) so they can fix it.

## Maximize reach

When you schedule, target every platform the media supports rather than just one:

- **Video** -> all connected platforms.
- **Image** -> all except TikTok.
- **Text-only** -> Facebook and LinkedIn (the others require media).

## Cadence

Run this weekly. Most of the user's time goes into Stage 4 (gathering their photos/clips)
and Stage 6 (approving the batch). Revisit Stage 2 (learning from results) about once a
month, once enough posts have published to show a pattern. The approval gate stays manual
every time.
