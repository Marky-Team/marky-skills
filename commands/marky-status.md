---
description: One-glance Marky status — what's queued, what published, what failed, and which accounts need attention.
---

Give the user a compact status snapshot of their Marky account. Read the `marky-api`
skill first for auth and endpoints; use MCP tools when connected, otherwise REST with
the `mk_live_` key. Base URL: `https://api.mymarky.ai/api`.

**Workspace.** Use `workspace.current_business_id` from `~/.marky/user.toml` (see the
marky-api skill's "Session start" section). If it's empty, list businesses and let the
user pick before continuing.

Gather these four things (in parallel where you can), then report:

1. **Queue — what's going out.** `GET /businesses/{id}/queue` (or `list_posts` filtered
   to `SCHEDULED`). Show the next few scheduled posts: when, which platforms, and a
   short caption preview.

2. **Recently published — did it land?** Pull recently published posts and read each
   `publish_results`. Every platform entry should be `success`. Call out any `failed`
   entry with the platform and the error in plain language.

3. **Drafts waiting.** Count posts with `status=NEW`
   (`GET /businesses/{id}/posts?status=NEW`). If there are drafts sitting unscheduled,
   say so — they don't publish themselves.

4. **Account health.** `GET /businesses/{id}/integrations` (or
   `list_business_integrations`). Flag any integration whose `status` is not `valid` —
   those need a reconnect in the Marky dashboard before posts to that platform can go
   out.

**Report format** — short and scannable, worst news first:

- Lead with problems: failed publishes, invalid integrations. If there are none, say
  "All clear" up top.
- Then the queue: "Next up: X posts scheduled (next one {when} on {platforms})".
- Then drafts: "N drafts waiting to be scheduled" (omit if zero).
- Offer the obvious next actions: retry/reschedule a failed post, schedule the drafts,
  or open the calendar — deep-link
  `https://app.mymarky.ai/ws/{business_id}/social-posts?tab=scheduled` (see "Opening
  the app for the user" in the marky-api skill).

Do not change anything in this command — it is read-only. If the user asks to fix
something (reschedule, retry, delete), route to the right skill (`schedule-posts`,
`plan-social-content`) and get approval as usual.
