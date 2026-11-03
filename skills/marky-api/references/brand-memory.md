# Brand voice and memory — the full protocol

Part of the `marky-api` skill. The main SKILL.md carries the four duties (read the brand
documents before drafting, persist critiques, keep the feedback log, keep performance
learnings); this file has the full detail — file formats, cache maintenance, examples,
and escalation rules. Read it before your first content-creation work of a session.

## The brand lives in two documents

Since Marky API version 2026-11-03 a workspace keeps its whole brand in two markdown
fields. The rule: **words go to `strategy`, visuals go to `design_style`.**

| Field | What goes in it |
| :--- | :--- |
| `strategy` | Goal, audience, voice, calls to action and tagline, caption rules (do/don't lines, banned words, the line every caption ends with), content pillars, what we won't do, what we've learned. 6,000 characters. |
| `design_style` | Colours with exact hex codes (which leads, the accent), fonts, the logo (a `Logo: https://...` line, its background colour, where it sits, when it appears), imagery and whether stock photos are OK, whitespace, content mix, post shape (1:1, 4:5, 9:16). Then a `## Treatments` table of named looks. 5,000 characters. |

There are no separate `tone`, caption-rule, palette, font or logo fields on the
workspace any more. Sending one to `update_workspace` / `PATCH /workspaces/{id}` is
rejected (422). If you are on an older copy of these skills that still names them,
update the Marky plugin.

**Both documents are replaced whole on every write.** Read the current text, edit it,
send all of it back; whatever you leave out is deleted. The response's `field_budgets`
says how much room each document has left, and `warnings` flags one that is over: when
you see a warning, tighten that document in the same turn.

## Write like the business — read the two documents before drafting

Whenever YOU are about to write social content yourself (captions, hooks, hashtags, post
copy — anything user-facing), **first read the workspace** with `GET /workspaces/{id}` (or
`get_workspace`) and apply it: follow the voice, audience and every caption rule in
`strategy` (and end each caption with its closing line, once, if it names one), and
follow `design_style` for anything visual. Also follow the matching entry in
`platform_writing_instructions` for each platform. Do this once per session per
workspace and keep it in mind — don't draft from a generic voice and fix it later.

### Maintain the `brand-cache.md` cache

In a Claude Code plugin install, `~/.marky/brand-cache.md` keeps a recent copy of the
workspace's brand so a session can start on-brand without a fetch. **Over MCP the cache
maintains itself**: a PostToolUse hook rewrites it after every `get_workspace` /
`update_workspace` call, so you don't need to touch the file. On the REST path (or
outside the plugin) you keep it fresh yourself: **after every `GET /workspaces/{id}` and
after every update**, write it in this shape — header lines, blank line, one-line facts,
then each document under its own heading:

```markdown
business_id: your-workspace-uuid
updated: 2026-11-03T00:00:00Z

name: Hope Copiers
website: https://hopecopiers.com
language: en

## design_style
Lead colour is deep teal #0F4C5C on off-white #F7F5F0; coral #E36414 is the accent.
Headlines in Poppins SemiBold, body in Inter.
Logo: https://.../logo.png
Logo small in the top-left corner of every picture.

## strategy
## Voice
Warm, confident, and plain-spoken. No jargon.
## Caption rules
- Never use emojis.
- End every caption with: #smallbusiness #local
```

(Caches written by plugin versions before 0.18.0 hold the old one-line fields; the hook
replaces them on the next `get_workspace`.)

**The snapshot orients you; it does not replace the fetch.** The documents can be
edited by anyone at any time in the Marky dashboard (a teammate tweaking the voice, the
user on their phone), and the cache only updates when an agent reads or writes the
workspace — so treat it as possibly stale. Before your FIRST authored-or-scheduled
content of a session, make one `get_workspace` call to pick up dashboard edits (over MCP
the sync hook then rewrites the cache for you). The workspace is always the source of
truth; the file is disposable. When the user switches workspace, rewrite the file for
the new workspace — its `business_id` line (the workspace id; the key keeps its old name
so existing cache files stay valid) must match the current workspace.

## Learn the user's style — persist critiques into the documents

When the user critiques generated content — *"I don't like how that wrote"*, *"too many
emojis"*, *"shorter"*, *"stop saying 'game-changer'"*, *"less orange"* — do **both** of
these, not just the first:

1. **Fix the content in front of you** (edit the draft, regenerate, whatever the moment
   needs).
2. **Persist the lasting preference into the right document** so every future generation
   honors it. Read the current text first (`GET /workspaces/{id}` or `get_workspace`),
   then merge, don't clobber:
   - Voice/personality feedback → the `## Voice` section of `strategy`.
   - Concrete do/don't rules (emojis, sentence length, banned words, hashtags) → a line
     in the `## Caption rules` section of `strategy`.
   - Image, colour, font or logo feedback → `design_style` (the prose for something true
     of every post, a Treatments row for one look).
   Write the whole document back with `PATCH /workspaces/{id}` (REST) or
   `update_workspace` (MCP). Show the user the changed lines and confirm before writing —
   these documents steer all future content.

One-off instructions ("make this one more playful") are not lasting preferences — apply
them and move on. Only persist feedback the user states as a general preference or repeats.

**Routing note:** style critique goes to the *two documents*, not `POST /feedback`. The
feedback endpoint reports bugs/friction about Marky itself to the Marky team; it does not
change how Marky writes for this workspace.

## The feedback log — taste memory across sessions

The two documents hold *stated* preferences; the feedback log holds *revealed* ones —
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
   matching document immediately, with confirmation.
2. **Read before you generate.** Before drafting a batch, picking a diagram archetype,
   or styling variants, scan the last ~20 log entries for this `business_id` and lean
   into what won: topics and formats that got approved, styles that got picked,
   anything repeatedly rejected gets dropped. Comments are gold — they say *why*.

**Escalate patterns to the documents.** The log is local to this machine. When the
same preference shows up ~3+ times (always rejects emoji-heavy captions, always picks
the layers diagram), it has earned a line in `strategy` (words) or `design_style`
(visuals) via `update_workspace` — confirm with the user, then it applies on every
machine and to Max.

## Performance learnings — what the NUMBERS taught us

The feedback log holds what the user chose; `performance-learnings.md` holds what the
audience rewarded — data-backed lessons from real engagement ("first-person posts that
end with a question get 3-4x the comments", "video beats image on TikTok, image wins on
LinkedIn"). It is a plain markdown file of dated bullets, one learning per line, stored
per workspace where library files live (the Marky library by default; local only if the user opted into local library storage — see the marky-api storage rule):

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
   (alongside the feedback log and the two documents) and let it steer topic, format, and
   voice choices. Learnings here outrank generic best practices — they are measured on
   THIS audience.
2. **Write when the data speaks.** After reviewing performance (`/marky-status` step 5,
   or the `review-performance` skill), if a real pattern shows up — a clear winner or
   loser, not one-post noise — offer to append it. Show the user the exact lines first;
   write only on a yes. Prune entries the data later contradicts instead of letting the
   file accumulate stale rules.

Routing note: statements of user TASTE ("I hate emojis") go to the `strategy` /
`design_style` documents or the feedback log, not here. This file is only for what measured engagement showed.
