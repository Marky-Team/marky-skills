#!/usr/bin/env bash
# PostToolUse hook: keep ~/.marky/brand-cache.md in sync automatically.
#
# WHY: the SessionStart hook injects a cached brand snapshot (voice + design
# fields) so agents write and render on-brand from the first message. Before this hook, refreshing that
# cache relied on the agent following a skill instruction ("rewrite the file
# after get_workspace / update_workspace") — hope, not enforcement. This hook
# fires deterministically after every mcp__marky__get_workspace /
# mcp__marky__update_workspace call (and the deprecated get_business /
# update_business names, which the server still accepts) and rewrites the cache
# from the tool's actual response, so the snapshot can never drift from what the
# agent last saw. REST-path and non-plugin usage still rely on the skill
# instruction.
#
# The cache file keeps its `business_id:` first line (it is the workspace id):
# queue-check.sh and existing installs read that key, so it is not renamed.
#
# This hook needs python3 (JSON parsing is beyond sane bash) but must never
# break a session: any failure — no python3, unparseable payload, no workspace
# in the response — exits 0 silently. Worst case is the old behavior.

set -uo pipefail

command -v python3 >/dev/null 2>&1 || exit 0

# The heredoc below occupies stdin for python, so grab the hook event first
# and hand it over via the environment.
HOOK_PAYLOAD="$(cat)" python3 - <<'PY' || true
import json, os, sys
from datetime import datetime, timezone

# The brand fields worth caching, in display order: voice first (for copy),
# then design (for post-diagrams / any visual authoring — colors, fonts, logo).
VOICE_FIELDS = ["tone", "caption_writing_rules", "caption_suffix", "imagery_preferences"]
DESIGN_FIELDS = [
    "tagline", "ctas", "palettes", "header_font", "body_font",
    "logo_url", "logo_background_color", "logo_width",
]
FIELDS = VOICE_FIELDS + DESIGN_FIELDS

def find_business(node):
    """Recursively find a dict that looks like a Marky workspace (has an id and
    at least one voice field). MCP responses wrap payloads in content blocks
    whose text is itself JSON, so parse string leaves that look like JSON."""
    if isinstance(node, dict):
        if node.get("id") and any(node.get(f) for f in VOICE_FIELDS + ["palettes", "logo_url"]):
            return node
        for value in node.values():
            found = find_business(value)
            if found:
                return found
    if isinstance(node, list):
        for item in node:
            found = find_business(item)
            if found:
                return found
    if isinstance(node, str) and node.lstrip()[:1] in "{[":
        try:
            return find_business(json.loads(node))
        except ValueError:
            return None
    return None

try:
    event = json.loads(os.environ.get("HOOK_PAYLOAD", ""))
except ValueError:
    sys.exit(0)

GET_TOOLS = ("mcp__marky__get_workspace", "mcp__marky__get_business")
UPDATE_TOOLS = ("mcp__marky__update_workspace", "mcp__marky__update_business")

if event.get("tool_name") not in GET_TOOLS + UPDATE_TOOLS:
    sys.exit(0)

business = find_business(event.get("tool_response"))

# update_workspace may return a bare ack; fall back to the request itself,
# which carries business_id (the workspace id) plus whichever voice fields were
# being set.
if business is None and event.get("tool_name") in UPDATE_TOOLS:
    tool_input = event.get("tool_input") or {}
    business_id = tool_input.get("business_id") or tool_input.get("id")
    if business_id and any(tool_input.get(f) for f in FIELDS):
        business = dict(tool_input, id=business_id)

if not business:
    sys.exit(0)

state_dir = os.environ.get("MARKY_STATE_DIR") or os.path.expanduser("~/.marky")
os.makedirs(state_dir, exist_ok=True)
path = os.path.join(state_dir, "brand-cache.md")

# On a partial update, keep previously cached fields the response didn't carry —
# but only when the cache is for the same workspace.
previous = {}
try:
    with open(path) as f:
        lines = f.read().splitlines()
    if lines and lines[0] == f"business_id: {business['id']}":
        for line in lines:
            key, sep, value = line.partition(": ")
            if sep and key in FIELDS and value.strip():
                previous[key] = value.strip()
except OSError:
    pass

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
body_lines = []
for field in FIELDS:
    value = business.get(field)
    if value is None or value == "" or value == []:
        value = previous.get(field)
    if value in (None, "", []):
        continue
    if not isinstance(value, str):
        value = json.dumps(value, separators=(",", ":"))
    # Flatten so each field stays a single "key: value" line.
    body_lines.append(f"{field}: {' '.join(value.split())}")

if not body_lines:
    sys.exit(0)

with open(path, "w") as f:
    f.write(f"business_id: {business['id']}\nupdated: {now}\n\n")
    f.write("\n".join(body_lines) + "\n")
PY

exit 0
