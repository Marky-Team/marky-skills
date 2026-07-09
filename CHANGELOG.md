# Changelog

All notable changes to this collection are documented here. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.2.5] - 2026-07-09

### Fixed

- **Brand-voice cache no longer masks dashboard edits.** The profile can be changed by
  anyone in the Marky dashboard at any time, but the local `brand-voice.md` snapshot only
  refreshed when an agent touched the profile — and the skill told agents to "skip the
  fetch" when the snapshot was injected, so a stale voice could persist indefinitely. The
  snapshot now carries its `updated` timestamp and a staleness warning, and the skill
  requires one `get_business` refresh before the first authored-or-scheduled content of a
  session. Also fixed the documented cache path (`~/.marky/brand-voice.md`, not the
  plugin dir).

## [0.2.4] - 2026-07-09

### Fixed

- **Settings now survive plugin renames too.** The 0.2.2 migration looked for the old
  `user.toml` in sibling version directories only, but the 0.2.0 slug rename
  (`marky-skills` -> `marky`) put previous installs under a different directory — so
  updating from 0.1.x still lost your saved business and cadence. The migration now also
  searches the old slug's install dirs (newest file wins). `brand-voice.md` migrates
  alongside.
- **No more feedback ask on first contact.** When `user.toml` was missing, the session
  hook claimed a feedback check-in was "due" — so fresh installs (and anyone who hit the
  migration bug above) got asked for feedback immediately. First run now just initializes
  state silently; the first cadence prompt comes one interval later, as documented.
- Genuinely-due cadence prompts now instruct the agent to use a real AskUserQuestion tool
  call instead of a prose question.

## [0.2.3] - 2026-07-08

### Fixed

- **Hook-loading errors on session start are gone.** Claude Code loads `hooks/hooks.json`
  automatically by convention; our manifests ALSO pointed at it explicitly, which raised
  "duplicate hooks file" and "file-path form not supported in a marketplace entry" errors.
  Removed the redundant `hooks` keys from plugin.json and marketplace.json.

### Changed

- README documents the self-update experience and recommends enabling marketplace
  auto-update (off by default for third-party marketplaces).

## [0.2.2] - 2026-07-08

### Fixed

- **Your settings now survive plugin updates.** `user.toml` (cadence prefs, your saved
  business) and `brand-voice.md` moved to `~/.marky/` — each plugin update installs to a
  fresh directory, so state kept beside the plugin was silently wiped every release.
  Existing files migrate automatically on the next session (the hook also checks the
  previous version's install dir).

## [0.2.1] - 2026-07-08

### Added

- **The plugin now keeps you posted about itself.** A new SessionStart hook
  (`hooks/update-check.sh`) notices when the installed version changed and opens the
  next session with a short "here's what's new" summary read from this changelog. If a
  newer version exists on main and your marketplace isn't set to auto-update, it offers
  the update once (snoozable, or stop-checking). State lives in `~/.marky/` so it
  survives version-to-version install paths. Silent on fresh installs, network failure,
  and when nothing changed.

### Changed

- **Key setup now says how to PERSIST `MARKY_API_KEY`** (`~/.claude/settings.json` `env`
  block recommended, shell profile as alternative). The old instructions showed a bare
  `export`, which dies with the terminal and never reaches GUI-launched Claude apps.

## [0.2.0] - 2026-07-08

### Changed

- **Plugin renamed `marky-skills` → `marky`.** The repo keeps its name; only the plugin
  slug changes, so skills namespace as `marky:<skill>` and the install command is
  `/plugin install marky@marky-skills`. Existing installs migrate automatically via the
  `renames` map in `marketplace.json`.

### Added

- **Bundled MCP server (`.mcp.json`).** Installing the plugin in Claude Code now
  auto-registers Marky's MCP server — no more manual `claude mcp add`. Set your key
  in the `MARKY_API_KEY` environment variable and Marky's tools appear automatically.
  The header uses `${MARKY_API_KEY:-}` so the config always parses (it 401s until the
  key is set, and the `marky-api` skill guides you through getting one). Other clients
  (Claude Desktop / Cowork / Cursor) still configure the MCP manually.

### Changed

- **`publish_to` → `restrict_publish_to`.** The post platform-target field was renamed
  across the Marky API (the old name now returns `422`). Every skill that creates,
  updates, or schedules a post now uses `restrict_publish_to`. Same meaning: omit or
  set it to null to publish to all connected platforms; pass a list to restrict.

## [0.1.1]

### Added

- **Workspace memory (`[workspace]` in `user.toml`).** Skills now remember the business the
  user operates on (`current_business_id` / `current_business_name`): `/marky` confirms a
  saved business with one `get_business` call instead of re-listing every business each
  session, writes the first selection back, and `hooks/user-state-check.sh` injects the
  saved business as session-start context so the agent begins every session oriented.
- **Cross-session state + cadence-gated prompts (`user.toml`).** A gitignored `user.toml`
  (schema documented in the committed `user.toml.example`) stores per-user prefs across
  otherwise-amnesiac sessions. The `marky-api` skill reads it at session start and runs two
  cadence-gated checks, each with an AskUserQuestion **Yes / No / Don't ask again** prompt:
  (1) a **feedback check-in** on an interval (default 3 weeks) — immediate bug/friction
  feedback is still always sent, separate from the cadence; and (2) a **contribution nudge**
  that detects locally built/improved skills and offers to help contribute generic, sanitized
  ones to the community repo `Marky-Team/marky-skills-community`. A second SessionStart hook
  (`hooks/user-state-check.sh`) surfaces a due prompt automatically for plugin users. New
  `CONTRIBUTING.md` "Sanitize and generalize before you open a PR" section is the canonical
  guardrail the nudge follows.
- **First-class Claude Code plugin.** The repo installs as a plugin via `/plugin` (the
  preferred path on Claude Code), carrying the skills plus a SessionStart **feedback-reminder
  hook** (`hooks/hooks.json` + `hooks/feedback-reminder.sh`) and a **`/marky` slash command**
  (`commands/marky.md`). README now routes by client: Claude Code -> `/plugin`, other clients
  -> `npx skills add`.
- **Feedback loop baked into the skills.** `marky-api` gained a prominent "Marky wants your
  feedback" section documenting `POST /feedback` (typed `type` / `message` / `context` body)
  with example payloads for the three triggers (on friction, after a skill, periodically).
  Every other skill points back to it.

- Six new skills: `review-performance`, `suggest-topics`, `manage-library`, `event-countdown-posts`, `repurpose-posts`, and `posts-from-library-image`.
- Repository scaffolding: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `CHANGELOG.md`, issue + pull-request templates, and `.editorconfig`.
- `scripts/lint-skills.mjs` — a zero-dependency linter that validates skill frontmatter and that the manifests stay in sync, wired into CI.

### Changed

- Rewrote `README.md` with a skill catalog, quickstart, and "how it works" overview.
- Corrected the MCP tool documentation in `marky-api`: the public MCP exposes a **curated
  set of 26 typed tools**, not "every REST op minus 3 destructive ops". The full curated list
  is documented, and operations outside it are marked REST-only.

## [0.1.0]

### Added

- Initial release with three skills: `marky-api`, `schedule-posts`, and `plan-social-content`.
