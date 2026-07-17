# Brand voice and memory — the full protocol

Part of the `marky-api` skill. The main SKILL.md carries the four duties (read the brand
profile before drafting, persist critiques, keep the feedback log, keep performance
learnings); this file has the full detail — file formats, cache maintenance, examples,
and escalation rules. Read it before your first content-creation work of a session.

## Write like the business — pull the brand profile before drafting

Whenever YOU are about to write social content yourself (captions, hooks, hashtags, post
copy — anything user-facing), **first read the brand profile** with
`GET /businesses/{id}` (or `get_business`) and apply it: match `tone`, obey every line of
`caption_writing_rules`, append `caption_suffix`, and respect `imagery_preferences` when
choosing or describing visuals. Do this once per session per business and keep it in
mind — don't draft from a generic voice and fix it later. (Marky's own `/posts/generate`
endpoint applies these automatically; this rule is for content you author directly.)

### Maintain the `brand-cache.md` cache

In a Claude Code plugin install, the SessionStart hook injects a cached brand snapshot
into context so sessions start already on-brand with no fetch — both the voice fields
(for copy you write) and the design fields (colors, fonts, logo — for diagrams, cards,
or video frames you render). **Over MCP the cache maintains itself**: a PostToolUse hook
rewrites it automatically after every `get_business` / `update_business` call, so you
don't need to touch the file. On the REST path (or outside the plugin) you keep it fresh
yourself: **after every `GET /businesses/{id}` and after every profile update**, write
`~/.marky/brand-cache.md` in this shape — header lines, blank
line, then one `field: value` line each (non-string values as compact JSON):

```markdown
business_id: your-business-uuid
updated: 2026-07-08T00:00:00Z

tone: Warm, confident, and plain-spoken. No jargon.
caption_writing_rules: Never use emojis. Keep sentences short.
caption_suffix: #smallbusiness #local
imagery_preferences: Bright, natural light. Real people.
tagline: Service you can trust.
ctas: ["Call today","Book online"]
palettes: [{"name":"Brand","colors":["#0A0A0A","#FFFFFF","#E11D48"]}]
header_font: {"family":"Poppins"}
body_font: {"family":"Inter"}
logo_url: https://.../logo.png
```

(Pre-0.2.8 installs used `brand-voice.md` with voice fields only; the hooks read the old
name as a fallback until the next profile touch rewrites the new one.)

**The snapshot orients you; it does not replace the fetch.** The brand profile can be
edited by anyone at any time in the Marky dashboard (a teammate tweaking the tone, the
user on their phone), and the cache only updates when an agent touches the profile — so
treat the injected snapshot as possibly stale. Use it to sound right in conversation, but
before your FIRST authored-or-scheduled content of a session, make one `get_business`
call to pick up dashboard edits (over MCP the sync hook then rewrites the cache for you).
The workspace is always the source of truth; the file is disposable. When the user
switches business, rewrite the file for the new business — the hook only injects it when
its `business_id` matches the current workspace.

## Learn the user's style — persist critiques into the brand profile

When the user critiques generated content — *"I don't like how that wrote"*, *"too many
emojis"*, *"shorter"*, *"stop saying 'game-changer'"* — do **both** of these, not just the
first:

1. **Fix the content in front of you** (edit the draft, regenerate, whatever the moment
   needs).
2. **Persist the lasting preference into the brand profile** so every future generation —
   yours and Marky's own — honors it. Read the current values first
   (`GET /businesses/{id}` or `get_business`), then merge, don't clobber:
   - Voice/personality feedback → append or refine `tone`.
   - Concrete do/don't rules (emojis, sentence length, banned words, hashtags) → add a
     line to `caption_writing_rules`.
   - Image feedback → `imagery_preferences`.
   Write back with `PATCH /businesses/{id}` (REST) or `update_business` (MCP). Show the
   user the updated field text and confirm before writing — these fields steer all future
   content.

One-off instructions ("make this one more playful") are not lasting preferences — apply
them and move on. Only persist feedback the user states as a general preference or repeats.

**Routing note:** style critique goes to the *brand profile*, not `POST /feedback`. The
feedback endpoint reports bugs/friction about Marky itself to the Marky team; it does not
change how Marky writes for this business.

## The feedback log — taste memory across sessions

The brand profile holds *stated* preferences; the feedback log holds *revealed* ones —
what the user actually approved, rejected, and picked on review boards
(`scripts/review-board.py`). It lives at `~/.marky/feedback-log.jsonl`, one JSON object
per line:

```json
{"date":"2026-07-09T12:00:00Z","business_id":"...","context":"weekly-posts",
 "mode":"approve","feedback":{"decisions":{"post-1":"approved"},"comments":{},"overall":"..."},
 "items":{"post-1":"Mon tip: ..."}}
```

Two duties, every creation skill:

1. **Write after every board.** When you read a board's `feedback.json`, append a line
   to the log — include `business_id`, a short `context` (`weekly-posts`,
   `diagram-styles`, `video-variants`, ...), the feedback verbatim, and an `items` map
   of id → one-line description so future sessions know what the ids referred to.
   Board `edits` (captions rewritten in place) are the strongest signal — diff them
   against what you drafted; the delta is the preference. And any comment phrased as a
   rule ("never ...", "always ...") skips the recurrence bar below: persist it to the
   brand profile immediately, with confirmation.
2. **Read before you generate.** Before drafting a batch, picking a diagram archetype,
   or styling variants, scan the last ~20 log entries for this `business_id` and lean
   into what won: topics and formats that got approved, styles that got picked,
   anything repeatedly rejected gets dropped. Comments are gold — they say *why*.

**Escalate patterns to the brand profile.** The log is local to this machine. When the
same preference shows up ~3+ times (always rejects emoji-heavy captions, always picks
the layers diagram), it has earned a line in `caption_writing_rules` /
`imagery_preferences` via `update_business` — confirm with the user, then it applies on
every machine and in Marky's own generator.

## Performance learnings — what the NUMBERS taught us

The feedback log holds what the user chose; `performance-learnings.md` holds what the
audience rewarded — data-backed lessons from real engagement ("first-person posts that
end with a question get 3-4x the comments", "video beats image on TikTok, image wins on
LinkedIn"). It is a plain markdown file of dated bullets, one learning per line, stored
per business where library files live (the Marky library by default; local only if the user opted into local library storage — see the marky-api storage rule):

- default → the Marky library file `/performance-learnings.md`
  (`POST /businesses/{id}/library/files` to create, files endpoints to read/update)
- local library storage → `~/.marky/fs/<business_id>/performance-learnings.md`

Format — newest first, each line dated and concrete enough to act on:

```markdown
# Performance learnings

- 2026-07-10: First-person posts ending with a question/"LMK" pull 3-4x the comments
  of polished announcement copy (10 comments vs ≤1 on Facebook).
- 2026-07-10: Founder reliability stories are the best LinkedIn reach (128 imp vs ~30
  typical). Behind-the-scenes engineering > product promo there.
```

Two duties:

1. **Read before you create.** Before drafting any batch of posts, read this file
   (alongside the feedback log and brand profile) and let it steer topic, format, and
   voice choices. Learnings here outrank generic best practices — they are measured on
   THIS audience.
2. **Write when the data speaks.** After reviewing performance (`/marky-status` step 5,
   or the `review-performance` skill), if a real pattern shows up — a clear winner or
   loser, not one-post noise — offer to append it. Show the user the exact lines first;
   write only on a yes. Prune entries the data later contradicts instead of letting the
   file accumulate stale rules.

Routing note: statements of user TASTE ("I hate emojis") go to the brand profile /
feedback log, not here. This file is only for what measured engagement showed.
