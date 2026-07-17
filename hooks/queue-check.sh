#!/usr/bin/env bash
# SessionStart hook — low-posting-queue notification.
#
# WHY: the whole job of a posting queue is to never run dry. This hook
# checks how many days of queued
# posts remain for their saved business and, when that drops to/below their
# threshold, injects a one-line heads-up so the agent can offer to top up.
#
# HOW IT STAYS FAST (the update-check.sh pattern): one small REST call
# (GET /businesses/{id}/queue/summary — an aggregate endpoint added for exactly
# this) with a 3s timeout, cached in ~/.marky/queue-cache for 6h. Queue depth
# changes on human timescales, so a stale-but-cached answer is never
# meaningfully wrong. Any failure (no key, no network, bad response) is SILENT —
# a session must never open with plumbing noise.
#
# REST, not MCP, deliberately: hooks are plain shell scripts outside the model
# loop, so MCP tools don't exist here. The agent acting on the nudge uses MCP
# (get_queue_summary / queue_post) as usual.
#
# Pure bash, no jq — same rationale as the other hooks.

set -euo pipefail

STATE_DIR="${MARKY_STATE_DIR:-${HOME}/.marky}"  # override for tests
# The persistent "which business" source is brand-cache.md (line 1:
# "business_id: <id>"), written by the brand-cache-sync hook whenever
# get_business/update_business runs. There is no user.toml anymore.
BRAND_CACHE="${STATE_DIR}/brand-cache.md"
CACHE_FILE="${STATE_DIR}/queue-cache"
API_BASE="${MARKY_API_BASE:-https://api.mymarky.ai/api}"
NOW_EPOCH="$(date +%s)"
CACHE_TTL=21600  # 6h — queue depth doesn't change faster than this matters

[[ -f "$BRAND_CACHE" ]] || exit 0  # no known business yet → nothing to check

read_cache() {
  # key=value lines; missing file or key → empty string.
  [[ -f "$CACHE_FILE" ]] || { echo ""; return; }
  sed -n "s/^${1}=//p" "$CACHE_FILE" 2>/dev/null | head -1
}

# ISO 8601 UTC → epoch seconds. Tries GNU date, then BSD (macOS) date; empty on
# failure. Fractional seconds / offsets are cut — day precision is all we need.
iso_to_epoch() {
  local trimmed="${1:0:19}"
  date -u -d "${trimmed}Z" +%s 2>/dev/null \
    || date -u -j -f "%Y-%m-%dT%H:%M:%S" "$trimmed" +%s 2>/dev/null \
    || echo ""
}

# ── Config: which business, and the threshold ───────────────────────────────
# Default threshold is 3 days. Muting ("stop reminding me about my queue") is
# NOT read here — it lives in the agent's memory; this hook always emits the
# heads-up when the queue is low and tells the agent to stay silent if muted.
threshold_days=3
business_id="$(sed -n 's/^business_id:[[:space:]]*//p' "$BRAND_CACHE" | head -1)"
business_name="$(sed -n 's/^name:[[:space:]]*//p' "$BRAND_CACHE" | head -1)"
[[ -z "$business_id" ]] && exit 0

# ── Queue state: cache first, network only when stale ───────────────────────
queued_count=""
run_out=""

cached_biz="$(read_cache business_id)"
cached_at="$(read_cache fetched_epoch)"
if [[ "$cached_biz" == "$business_id" && -n "$cached_at" ]] \
  && (( NOW_EPOCH - cached_at < CACHE_TTL )); then
  queued_count="$(read_cache queued_count)"
  run_out="$(read_cache run_out)"
else
  # Key discovery: env var first; else recover it from the marky MCP server's
  # Authorization header in ~/.claude.json — MCP-only setups (the common plugin
  # install) never export MARKY_API_KEY, and without this fallback the check
  # would silently never fire for exactly the users the plugin targets.
  api_key="${MARKY_API_KEY:-}"
  if [[ -z "$api_key" ]]; then
    api_key="$(grep -o '"Bearer mk_live_[A-Za-z0-9_.~-]*"' "${CLAUDE_CONFIG_PATH:-${HOME}/.claude.json}" 2>/dev/null \
      | head -1 | sed 's/^"Bearer //; s/"$//' || true)"
  fi
  [[ -z "$api_key" ]] && exit 0
  body="$(curl -fsS -m 3 -H "Authorization: Bearer ${api_key}" \
    "${API_BASE}/businesses/${business_id}/queue/summary" 2>/dev/null || true)"
  if [[ -n "$body" ]]; then
    queued_count="$(printf '%s' "$body" | sed -n 's/.*"queued_count"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' | head -1)"
    run_out="$(printf '%s' "$body" | sed -n 's/.*"last_estimated_publish_time"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
    mkdir -p "$STATE_DIR"
    printf 'business_id=%s\nfetched_epoch=%s\nqueued_count=%s\nrun_out=%s\n' \
      "$business_id" "$NOW_EPOCH" "$queued_count" "$run_out" > "$CACHE_FILE"
  else
    # Fetch failed → fall back to the stale cache if it's for this business.
    [[ "$cached_biz" == "$business_id" ]] || exit 0
    queued_count="$(read_cache queued_count)"
    run_out="$(read_cache run_out)"
  fi
fi

[[ "$queued_count" =~ ^[0-9]+$ ]] || exit 0

# ── Days until the queue runs dry ────────────────────────────────────────────
if [[ "$queued_count" -eq 0 || -z "$run_out" ]]; then
  days_left=0
  run_out_label="now"
else
  run_out_epoch="$(iso_to_epoch "$run_out")"
  [[ -z "$run_out_epoch" ]] && exit 0  # unparseable date beats a false alarm
  days_left=$(( (run_out_epoch - NOW_EPOCH) / 86400 ))
  (( days_left < 0 )) && days_left=0
  run_out_label="${run_out:0:10}"
fi

(( days_left > threshold_days )) && exit 0

NOTE="LOW_QUEUE: the posting queue for '${business_name:-$business_id}' is low — ${queued_count} post(s) queued, running dry ${run_out_label} (~${days_left} day(s) left; threshold ${threshold_days} days). FIRST check your memory: if the user has muted queue reminders (or set a different day threshold), honor that and stay silent. Otherwise, at the START of your first reply tell the user in one plain line, then offer to top the queue up (plan a batch via /plan-social-content or queue posts via /schedule-posts -> queue_post). Do not block on it if they asked for something else. Data is from GET /queue/summary, cached up to 6h — refresh with one get_queue_summary call before acting on exact numbers. If the user says 'stop reminding me about my queue' (or gives a new threshold), save that as a memory."

escaped=$(printf '%s' "$NOTE" | tr '\n' ' ' | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$escaped"
exit 0
