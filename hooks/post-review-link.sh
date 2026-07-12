#!/usr/bin/env bash
# PostToolUse hook: after a post is created, scheduled, queued, updated, or
# published via the MCP, inject the Marky app review links into the agent's
# context so it hands them to the user.
#
# WHY: users almost always want to eyeball a post in the Marky UI right after
# an agent schedules or creates it. Before this hook, surfacing the link relied
# on the agent remembering the app-links table in the marky-api skill — hope,
# not enforcement. This fires deterministically after every post-writing tool
# call and emits the exact URLs, so the agent can't forget and can't invent a
# wrong path (the workspace review route is NOT a stable direct link; only
# /post/{id} is).
#
# Must never break a session: any failure exits 0 silently.

set -uo pipefail

command -v python3 >/dev/null 2>&1 || exit 0

HOOK_PAYLOAD="$(cat)" python3 - <<'PY' || true
import json, os, sys

payload = json.loads(os.environ.get("HOOK_PAYLOAD", "{}") or "{}")
resp = payload.get("tool_response")

def find_post(node):
    """Find a dict that looks like a Marky post (id + business_id + one
    post-ish field). MCP responses wrap payloads in content blocks whose text
    is itself JSON, so parse string leaves that look like JSON."""
    if isinstance(node, dict):
        if node.get("id") and node.get("business_id") and (
            "caption" in node or "media_urls" in node or "publish_results" in node
        ):
            return node
        for v in node.values():
            found = find_post(v)
            if found:
                return found
    elif isinstance(node, list):
        for v in node:
            found = find_post(v)
            if found:
                return found
    elif isinstance(node, str) and node.lstrip()[:1] in "[{":
        try:
            return find_post(json.loads(node))
        except (ValueError, RecursionError):
            return None
    return None

post = find_post(resp)
if not post:
    sys.exit(0)

post_id = post["id"]
biz_id = post["business_id"]
status = post.get("status", "")
queue = post.get("queue") or {}

lines = [
    f"Marky review links for this post (share with the user — they almost always want to review in the Marky UI):",
    f"- This post: https://app.mymarky.ai/post/{post_id}",
]
if queue or status == "SCHEDULED":
    lines.append(
        f"- The scheduled queue: https://app.mymarky.ai/ws/{biz_id}/social-posts?tab=scheduled"
    )
if queue.get("estimated_publish_time"):
    lines.append(f"- Queue position {queue.get('position')}, estimated publish {queue['estimated_publish_time']}")

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": "\n".join(lines),
    }
}))
PY
exit 0
