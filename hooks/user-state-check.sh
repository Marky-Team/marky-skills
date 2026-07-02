#!/usr/bin/env bash
# SessionStart hook for the marky-skills plugin — cross-session cadence checks.
#
# WHY THIS EXISTS: skills are amnesiac (each session starts fresh), so we keep a
# tiny per-user state file, `user.toml`, in the plugin install dir. This hook
# reads it at session start and, if a cadence window is due, injects a short
# prompt into context so a Claude Code plugin user gets the nudge automatically.
# Non-plugin clients rely on the marky-api skill instructions instead.
#
# It is deliberately NON-INTRUSIVE: it only SURFACES the prompt. The agent +
# AskUserQuestion drive the actual ask, and the agent (per the marky-api skill)
# writes the updated timestamps/flags back to user.toml. This hook never asks,
# never submits feedback, and never opens a PR.
#
# Pure bash, no jq/python dependency on purpose — a plugin should not need an
# install just to read its own state file. Timestamps are ISO 8601 UTC (Z), all
# the same width, so a plain string ">" compare is a correct "is it due?" check.
#
# SessionStart stdout is added to the model's context. We emit the documented
# structured form so the text lands as `additionalContext`.

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TOML_PATH="${PLUGIN_ROOT}/user.toml"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

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

feedback_prompt=""
contribution_prompt=""
workspace_note=""

if [[ ! -f "$TOML_PATH" ]]; then
  # First run on this machine — no state yet. Surface both prompts and tell the
  # agent to create user.toml from the example (the skill documents the defaults).
  feedback_prompt="Marky feedback check-in is due. Ask the user (AskUserQuestion: Yes / No / Don't ask again) whether they want to share quick feedback on how the Marky API is working. Yes -> collect + POST /api/feedback, bump ask_feedback_next. No -> bump ask_feedback_next. Don't ask again -> set leave_feedback = off."
  contribution_prompt="Marky contribution check is due. If the user has locally built a new skill or substantially improved a SKILL.md that is generic/reusable, ask (AskUserQuestion: Yes / No / Don't ask again) whether to contribute it to the community repo Marky-Team/marky-skills-community. Follow CONTRIBUTING.md (sanitize + generalize, user reviews) before any PR. Never auto-open a PR."
  init_note="No user.toml found in the marky-skills plugin dir — create it from user.toml.example with defaults (leave_feedback=on, ask_feedback_interval=\"3 weeks\", suggest_contribution=on) per the marky-api skill, then write back the updated timestamps after asking."
else
  leave_feedback="$(read_toml feedback leave_feedback || true)"
  ask_feedback_next="$(read_toml feedback ask_feedback_next || true)"
  suggest_contribution="$(read_toml contribution suggest_contribution || true)"
  ask_contribution_next="$(read_toml contribution ask_contribution_next || true)"
  current_business_id="$(read_toml workspace current_business_id || true)"
  current_business_name="$(read_toml workspace current_business_name || true)"
  init_note=""

  # Orient the agent on the saved default business so it can skip re-listing
  # every business at the start of every session.
  if [[ -n "$current_business_id" ]]; then
    workspace_note="Current Marky business (from user.toml): ${current_business_name:-unnamed} (business_id ${current_business_id}). Do not list all businesses — confirm it with one get_business call if that tool is exposed, else use the id directly (a stale id 404s on first use: re-list, re-pick, write the new choice back to user.toml). The user can ask to switch at any time."
  fi

  # String compare is a valid time compare here: all stamps are ISO 8601 UTC Z.
  if [[ "$leave_feedback" == "on" && -n "$ask_feedback_next" && "$NOW" > "$ask_feedback_next" ]]; then
    feedback_prompt="Marky feedback check-in is due (now is past ask_feedback_next). Ask the user (AskUserQuestion: Yes / No / Don't ask again) whether they want to share quick feedback on how the Marky API is working. Yes -> collect + POST /api/feedback, set ask_feedback_next = now + ask_feedback_interval. No -> bump ask_feedback_next by one interval. Don't ask again -> set leave_feedback = off. Then write user.toml back."
  fi

  if [[ "$suggest_contribution" == "on" && -n "$ask_contribution_next" && "$NOW" > "$ask_contribution_next" ]]; then
    contribution_prompt="Marky contribution check is due. Check whether the user has locally built a new skill or substantially edited a SKILL.md (git status/diff the skills/ dir against origin/main). If it is genuinely generic/reusable, ask (AskUserQuestion: Yes / No / Don't ask again) whether to contribute it to the community repo Marky-Team/marky-skills-community. Yes -> follow CONTRIBUTING.md (sanitize + generalize, user reviews the diff), then open the PR; bump ask_contribution_next by ~2 weeks. No -> bump ask_contribution_next by ~2 weeks. Don't ask again -> set suggest_contribution = off. Never auto-open a PR. Then write user.toml back."
  fi
fi

# Nothing due and no saved workspace → stay silent (truly non-intrusive).
if [[ -z "$feedback_prompt" && -z "$contribution_prompt" && -z "${init_note:-}" && -z "$workspace_note" ]]; then
  exit 0
fi

REMINDER="marky-skills session-state check (from user.toml in the plugin dir)."
[[ -n "$workspace_note" ]] && REMINDER="$REMINDER $workspace_note"
[[ -n "${init_note:-}" ]] && REMINDER="$REMINDER $init_note"
[[ -n "$feedback_prompt" ]] && REMINDER="$REMINDER $feedback_prompt"
[[ -n "$contribution_prompt" ]] && REMINDER="$REMINDER $contribution_prompt"
REMINDER="$REMINDER Full logic + guardrails are in the marky-api skill's \"Session start\" section. This only surfaces the prompt — you drive the ask."

# jq is not guaranteed, so build the JSON by hand. Flatten newlines and escape
# the few characters that matter inside a JSON string.
escaped=$(printf '%s' "$REMINDER" | tr '\n' ' ' | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$escaped"
exit 0
