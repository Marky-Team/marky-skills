#!/usr/bin/env bash
# SessionStart hook — plugin self-update loop (the gstack pattern).
#
# Two markers, both surfaced as additionalContext for the agent to act on:
#
#   JUST_UPGRADED  — the installed version changed since we last saw it.
#                    The agent reads CHANGELOG.md and tells the user what's new.
#   UPDATE_AVAILABLE — the repo's main branch has a newer version than the
#                    one installed. The agent offers to update (never silently).
#
# State lives in ~/.marky/plugin-update-state — deliberately OUTSIDE the plugin
# install dir, because Claude Code installs each version to a new versioned
# cache path, so anything stored next to the plugin is lost on every update
# (which is exactly the moment this state matters).
#
# Remote checks are cached for 24h and time out after 3s; any network failure
# is silent. Pure bash, no jq — same rationale as the other hooks.

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STATE_DIR="${MARKY_STATE_DIR:-${HOME}/.marky}"  # override for tests
STATE_FILE="${STATE_DIR}/plugin-update-state"
REMOTE_MANIFEST_URL="https://raw.githubusercontent.com/Marky-Team/marky-skills/main/.claude-plugin/plugin.json"
NOW_EPOCH="$(date +%s)"
CHECK_INTERVAL=86400  # 24h between remote checks

read_manifest_version() {
  # Pull `"version": "x.y.z"` out of a plugin.json without jq.
  sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" 2>/dev/null | head -1
}

read_state() {
  # key=value lines; missing file or key → empty string.
  [[ -f "$STATE_FILE" ]] || { echo ""; return; }
  sed -n "s/^${1}=//p" "$STATE_FILE" 2>/dev/null | head -1
}

write_state() {
  # Upsert key=value, preserving other keys.
  mkdir -p "$STATE_DIR"
  local tmp="${STATE_FILE}.tmp.$$"
  { [[ -f "$STATE_FILE" ]] && grep -v "^${1}=" "$STATE_FILE" || true; } > "$tmp"
  echo "${1}=${2}" >> "$tmp"
  mv "$tmp" "$STATE_FILE"
}

LOCAL_VERSION="$(read_manifest_version "${PLUGIN_ROOT}/.claude-plugin/plugin.json")"
[[ -z "$LOCAL_VERSION" ]] && exit 0

NOTE=""

# ── 1. Just upgraded? ────────────────────────────────────────────────────────
LAST_SEEN="$(read_state last_seen_version)"
if [[ -n "$LAST_SEEN" && "$LAST_SEEN" != "$LOCAL_VERSION" ]]; then
  NOTE="JUST_UPGRADED: the Marky plugin updated ${LAST_SEEN} -> ${LOCAL_VERSION} since the user's last session. At the START of your first reply, briefly tell the user what's new: read ${PLUGIN_ROOT}/CHANGELOG.md and summarize the entries between ${LAST_SEEN} and ${LOCAL_VERSION} in 2-4 plain sentences (lead with what they can now do, not internals). Then continue with whatever they asked."
fi
write_state last_seen_version "$LOCAL_VERSION"

# ── 2. Update available? (skip when we just upgraded — one message at a time)
if [[ -z "$NOTE" ]]; then
  LAST_CHECK="$(read_state last_check_epoch)"
  REMOTE_VERSION="$(read_state cached_remote_version)"
  if [[ -z "$LAST_CHECK" || $(( NOW_EPOCH - LAST_CHECK )) -ge $CHECK_INTERVAL ]]; then
    FETCHED="$(curl -fsS -m 3 "$REMOTE_MANIFEST_URL" 2>/dev/null | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || true)"
    [[ -n "$FETCHED" ]] && { REMOTE_VERSION="$FETCHED"; write_state cached_remote_version "$FETCHED"; }
    write_state last_check_epoch "$NOW_EPOCH"
  fi

  SNOOZE_UNTIL="$(read_state snooze_until_epoch)"
  if [[ -n "$REMOTE_VERSION" && "$REMOTE_VERSION" != "$LOCAL_VERSION" ]]; then
    NEWEST="$(printf '%s\n%s\n' "$LOCAL_VERSION" "$REMOTE_VERSION" | sort -V | tail -1)"
    if [[ "$NEWEST" == "$REMOTE_VERSION" && ( -z "$SNOOZE_UNTIL" || "$NOW_EPOCH" -ge "$SNOOZE_UNTIL" ) ]]; then
      NOTE="UPDATE_AVAILABLE: Marky plugin v${REMOTE_VERSION} is out (installed: v${LOCAL_VERSION}). Once, at a natural pause (never mid-task), ask the user (AskUserQuestion: Update now / Not now / Stop checking) whether to update. Update now -> run \`claude plugin marketplace update marky-skills\` then \`claude plugin update marky@marky-skills\` in bash; if those CLI commands are unavailable, tell them to run /plugin marketplace update marky-skills in a new prompt. After a successful update, the next session announces what's new automatically. Not now -> snooze 7 days: run \`bash -c 'echo snooze_until_epoch=$(( $(date +%s) + 604800 )) >> ${STATE_FILE}'\` (the hook dedupes keys). Stop checking -> snooze ~10 years the same way."
    fi
  fi
fi

[[ -z "$NOTE" ]] && exit 0

escaped=$(printf '%s' "$NOTE" | tr '\n' ' ' | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$escaped"
exit 0
