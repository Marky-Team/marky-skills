# Changelog

All notable changes to this collection are documented here. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

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
