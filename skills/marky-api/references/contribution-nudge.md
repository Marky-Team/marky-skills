# Check 2 — Contribution nudge (full procedure)

Part of the `marky-api` skill's session-start checks. Read this ONLY when the trigger
condition in SKILL.md is met: `suggest_contribution == "on"` and now >
`ask_contribution_next` in `~/.marky/user.toml`. Then check whether the user has locally
built something worth sharing back with the community:

1. **Detect local skill work.** Compare the locally installed skills against the pristine
   published versions to find a NEW skill directory (one not in the published set) or a
   `SKILL.md` that has been substantially edited. The simplest reliable way is a content
   compare against the upstream repo — for a git checkout:

   ```bash
   git -C "$SKILL_INSTALL_DIR" fetch origin main --quiet
   git -C "$SKILL_INSTALL_DIR" status --porcelain skills/
   git -C "$SKILL_INSTALL_DIR" diff --stat origin/main -- skills/
   ```

   New untracked `skills/<name>/SKILL.md` files or non-trivial diffs to an existing
   `SKILL.md` are the signal. If the install is not a git checkout, compare file contents
   against the published copies the same way (re-fetch the upstream `SKILL.md` and diff). No
   local changes → nothing to offer; skip to the timestamp bump.

2. **Judge whether it is genuinely shareable.** Only proceed if it is a generic, reusable
   social-media job any Marky user could use — NOT a skill stuffed with the user's private
   prompts, client lists, internal business logic, or one-off specifics. When in doubt, do
   not nudge. (The full sanitize/generalize bar lives in `CONTRIBUTING.md`.)

3. **Ask with AskUserQuestion** — same three-option shape as the feedback prompt. Ask
   something like *"You've built/improved the `<name>` skill — want to contribute it back to
   the Marky community so others can use it?"*:

   | Option | What you do |
   | :--- | :--- |
   | **Yes** | **Read and follow `CONTRIBUTING.md`** — it is the canonical guide. Sanitize + generalize the skill first (strip business ids/keys/private context, rewrite so it is reusable for any Marky user), let the user review the final diff, then open the PR to the community repo. Bump `ask_contribution_next = now + 2 weeks` and write back. |
   | **No** | Bump `ask_contribution_next = now + 2 weeks` (a cooldown) and move on. Write back. |
   | **Don't ask again** | Set `suggest_contribution = "off"` in `user.toml` and write back. Never offer again. |

   Whichever they pick, update `ask_contribution_next` (or the flag) and write `user.toml`
   back before moving on.

## Hard guardrails (always apply)

- **Generic and reusable only.** Never nudge to contribute a skill that carries the user's
  private prompts, client data, or internal business logic. When in doubt, do not nudge.
- **Never auto-open a PR.** A PR only happens after an explicit **Yes** AND the user has
  reviewed the sanitized content. No silent or automatic PRs, ever.
- **`CONTRIBUTING.md` is the canonical guide.** Do not re-derive the rules here — when the
  user says Yes, read `CONTRIBUTING.md` and follow its "Sanitize and generalize before you
  open a PR" section plus the quality bar and frontmatter spec.
- **Where it goes.** The contribution target is the community-tier repo
  `Marky-Team/marky-skills-community`. If that repo does not exist yet, tell the user it is
  coming and that their skill can target it once it is live — do not push to the private
  `Marky-Team/marky-skills` repo as a fallback.
