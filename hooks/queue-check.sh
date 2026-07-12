#!/usr/bin/env bash
# SessionStart hook — low-posting-queue notification.
#
# WHY: the whole job of a posting queue is to never run dry. If the user opted
# in (user.toml [notifications]), this hook checks how many days of queued
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
TOML_PATH="${STATE_DIR}/user.toml"
CACHE_FILE="${STATE_DIR}/queue-cache"
API_BASE="${MARKY_API_BASE:-https://api.mymarky.ai/api}"
NOW_EPOCH="$(date +%s)"
CACHE_TTL=21600  # 6h — queue depth doesn't change faster than this matters

[[ -f "$TOML_PATH" ]] || exit 0

# Read a `key = "value"` (or bare) value from a [section] of the TOML file.
# Minimal, good enough for this flat schema; not a general TOML parser.
read_toml() {
  section="$1"
  key="$2"
  awk -v section="[$section]" -v key="$key" '
    $0 == section { in_section = 1; next }
    /^\[/         { in_section = 0 }
    in_section {
      line = $0
      sub(/#.*/, "", line)                  # strip comments
      if (line ~ "^[[:space:]]*" key "[[:space:]]*=") {
        sub("^[^=]*=[[:space:]]*", "", line)
        gsub(/[[:space:]]*$/, "", line)
        gsub(/^"|"$/, "", line)             # strip surrounding quotes
        print line
        exit
      }
    }
  ' "$TOML_PATH"
}

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

# ── Config: opted out, or nothing to check? ─────────────────────────────────
reminder="$(read_toml notifications low_queue_reminder || true)"
[[ "$reminder" == "off" ]] && exit 0  # missing key = on (opt-out feature)

threshold_days="$(read_toml notifications low_queue_threshold_days || true)"
[[ "$threshold_days" =~ ^[0-9]+$ ]] || threshold_days=3

business_id="$(read_toml workspace current_business_id || true)"
business_name="$(read_toml workspace current_business_name || true)"
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
  [[ -z "${MARKY_API_KEY:-}" ]] && exit 0
  body="$(curl -fsS -m 3 -H "Authorization: Bearer ${MARKY_API_KEY}" \
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

NOTE="LOW_QUEUE: the posting queue for '${business_name:-$business_id}' is low — ${queued_count} post(s) queued, running dry ${run_out_label} (~${days_left} day(s) left; user's threshold is ${threshold_days}). At the START of your first reply, tell the user in one plain line, then offer to top the queue up (plan a batch via /plan-social-content or queue posts via /schedule-posts -> queue_post). Do not block on it if they asked for something else. Data is from GET /queue/summary, cached up to 6h — refresh with one get_queue_summary call before acting on exact numbers. The user can tune this in ~/.marky/user.toml [notifications]: low_queue_reminder = \"off\" silences it, low_queue_threshold_days changes when it fires."

escaped=$(printf '%s' "$NOTE" | tr '\n' ' ' | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$escaped"
exit 0
