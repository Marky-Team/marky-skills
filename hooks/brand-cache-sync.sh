#!/usr/bin/env bash
# PostToolUse hook: keep ~/.marky/brand-cache.md in sync automatically.
#
# WHY: agents read this snapshot to write and render on-brand from the first
# message. Before this hook, refreshing that cache relied on the agent following
# a skill instruction ("rewrite the file after get_workspace / update_workspace")
# — hope, not enforcement. This hook fires deterministically after every
# mcp__marky__get_workspace / mcp__marky__update_workspace call (and the
# deprecated get_business / update_business names, which the server still
# accepts) and rewrites the cache from the tool's actual response, so the
# snapshot can never drift from what the agent last saw. REST-path and
# non-plugin usage still rely on the skill instruction.
#
# WHAT IS CACHED (since Marky API version 2026-11-03): a workspace keeps its
# brand in two markdown documents, design_style (how posts look: colours, fonts,
# logo, content mix, format) and strategy (what they say: voice, audience, calls
# to action, caption rules). The old structured fields (tone, palettes, fonts,
# logo_url, ...) left the API, so they are no longer cached.
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

# One-line facts, then the two documents (kept as markdown under a heading each).
LINE_FIELDS = ["name", "website", "language", "brand_style_grid_url"]
DOC_FIELDS = ["design_style", "strategy"]
FIELDS = LINE_FIELDS + DOC_FIELDS

def find_business(node):
    """Recursively find a dict that looks like a Marky workspace (an id plus one
    of the two brand documents, even if null). MCP responses wrap payloads in
    content blocks whose text is itself JSON, so parse string leaves that look
    like JSON."""
    if isinstance(node, dict):
        if node.get("id") and any(f in node for f in DOC_FIELDS):
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

def read_previous(path, business_id):
    """What was cached last time, but only when the cache is for this workspace.

    One-line facts are "key: value" lines; each document is everything under its
    "## <field>" heading up to the next such heading.
    """
    previous = {}
    try:
        with open(path) as f:
            lines = f.read().splitlines()
    except OSError:
        return previous
    if not lines or lines[0] != f"business_id: {business_id}":
        return previous
    current_doc = None
    for line in lines[1:]:
        heading = line[3:].strip() if line.startswith("## ") else None
        if heading in DOC_FIELDS:
            current_doc = heading
            previous[current_doc] = ""
            continue
        if current_doc:
            previous[current_doc] += line + "\n"
            continue
        key, sep, value = line.partition(": ")
        if sep and key in LINE_FIELDS and value.strip():
            previous[key] = value.strip()
    return {k: v.strip() for k, v in previous.items() if v.strip()}

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
# which carries business_id (the workspace id) plus whichever fields were
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

# On a partial update, keep previously cached values the response didn't carry.
previous = read_previous(path, business["id"])

def value_of(field):
    value = business.get(field)
    if value in (None, ""):
        value = previous.get(field)
    return value if isinstance(value, str) and value.strip() else None

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
parts = []
for field in LINE_FIELDS:
    value = value_of(field)
    if value:
        # Flatten so each fact stays a single "key: value" line.
        parts.append(f"{field}: {' '.join(value.split())}")
# The documents keep their markdown (a flattened Treatments table is unreadable).
for field in DOC_FIELDS:
    value = value_of(field)
    if value:
        parts.append(f"\n## {field}\n{value.strip()}")

if not parts:
    sys.exit(0)

with open(path, "w") as f:
    f.write(f"business_id: {business['id']}\nupdated: {now}\n\n")
    f.write("\n".join(parts) + "\n")
PY

exit 0
