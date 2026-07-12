---
description: One-glance Marky status — what's queued, what published, what failed, how recent posts performed, and which accounts need attention.
---

Give the user a compact status snapshot of their Marky account. Read the `marky-api`
skill first for auth and endpoints; use MCP tools when connected, otherwise REST with
the `mk_live_` key. Base URL: `https://api.mymarky.ai/api`.

**Workspace.** Use `workspace.current_business_id` from `~/.marky/user.toml` (see the
marky-api skill's "Session start" section). If it's empty, list businesses and let the
user pick before continuing.

Gather these five things (in parallel where you can), then report:

1. **Queue — what's going out.** `get_queue_summary` (`GET /businesses/{id}/queue/summary`)
   for the headline (how many queued, when the queue runs dry), then
   `GET /businesses/{id}/queue` (paginated — items under `data`) or `list_posts` filtered
   to `SCHEDULED` for the next few posts: when, which platforms, a short caption preview.

2. **Recently published — did it land?** Pull recently published posts and read each
   `publish_results`. Every platform entry should be `success`. Call out any `failed`
   entry with the platform and the error in plain language.

3. **Drafts waiting.** Count posts with `status=NEW`
   (`GET /businesses/{id}/posts?status=NEW`). If there are drafts sitting unscheduled,
   say so — they don't publish themselves.

4. **Account health.** `GET /businesses/{id}/integrations` (or
   `list_business_integrations`). Flag any integration whose `status` is not `valid` —
   those need a reconnect on the business profile page (see the marky-api link table)
   before posts to that platform can go out.

5. **Performance snapshot.** Pull engagement for the ~5 most recently published posts
   (`get_post_analytics` / `GET /posts/{post_id}/stats`, one call per post). Report the
   best and worst performer with one line each on WHY (format, topic, voice, platform),
   and surface unanswered comments (`comment_count` > 0 is a prompt to go look). This is
   a snapshot, not an audit — for topic/format breakdowns, follower trends, and
   recommendations, route to the `review-performance` skill.

**Report format** — short and scannable, worst news first:

- Lead with problems: failed publishes, invalid integrations. If there are none, say
  "All clear" up top.
- Then the queue: "Next up: X posts scheduled (next one {when} on {platforms})".
- Then drafts: "N drafts waiting to be scheduled" (omit if zero).
- Then the performance snapshot: best/worst recent post and the one-line why.
- Offer the obvious next actions: retry/reschedule a failed post, schedule the drafts,
  or open the calendar — deep-link
  `https://app.mymarky.ai/ws/{business_id}/social-posts?tab=scheduled` (see "Opening
  the app for the user" in the marky-api skill).

**Save what the numbers taught you.** When the snapshot shows a real pattern (not noise —
a clear best/worst gap, a format or voice that repeatedly wins), OFFER to record it in
the business's `performance-learnings.md` (see "Performance learnings" in the `marky-api`
skill for the file's home and format). Creation skills read that file before drafting,
so a saved learning steers every future batch. Ask first, show the exact lines you would
append, and only write on a yes.

Apart from that optional learnings append, this command is read-only. If the user asks
to fix something (reschedule, retry, delete), route to the right skill
(`schedule-posts`, `plan-social-content`) and get approval as usual.
