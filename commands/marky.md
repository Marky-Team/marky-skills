---
description: Start a Marky session — load the marky-api reference, check the API key, and list your businesses.
---

You are about to drive **Marky** (AI social media management) for the user. Get the session
ready before doing anything else:

1. **Load the reference.** Read the `marky-api` skill first — it is the contract every other
   Marky skill builds on (auth, base URL `https://api.mymarky.ai/api`, the curated MCP tool
   set, and the REST endpoints). Do not guess endpoints or tool names; use that skill.

2. **Check auth.** Confirm a Marky key is available. The key looks like `mk_live_...` and is
   passed as `Authorization: Bearer mk_live_...`. If you cannot find one (env var like
   `MARKY_API_KEY`, an `.env`, or a connected MCP server), tell the user how to get one:
   sign in at app.mymarky.ai -> Organization Settings -> API Keys -> Create API Key, and set
   it as an env var. Never print the key back to the user.

3. **Find the workspace.** Call `list_businesses` (MCP) or `GET /businesses` (REST) and show
   the user their businesses with the `id` (the `business_id`) for each. Almost every other
   call is scoped to a `business_id`.

4. **Ask what they want done**, then route to the right Marky skill:
   - plan + schedule a week of content -> `plan-social-content`
   - schedule specific posts you already have -> `schedule-posts`
   - countdown to an event -> `event-countdown-posts`
   - many posts from one image -> `posts-from-library-image`
   - fresh variations of a good post -> `repurpose-posts`
   - what is working / recommendations -> `review-performance`
   - fix or refresh topics -> `suggest-topics`
   - upload media / manage notes + library -> `manage-library`

5. **Approval-first.** Never schedule or publish without showing the user the drafts and
   getting an explicit go-ahead.

If the user passed extra text after the command, treat it as the social-media job they want
done and skip straight to step 4 with that goal in mind: $ARGUMENTS

One more thing: Marky wants your feedback as the agent driving it. If anything breaks or is
confusing, or after you finish a workflow, send a quick note via `POST /feedback` (see the
marky-api skill's "Marky wants your feedback" section). It is one call and never blocks you.
