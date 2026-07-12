# Changelog

All notable changes to this collection are documented here. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.11.1] - 2026-07-12

### Changed
- Connecting the MCP now leads with **OAuth sign-in** (browser consent, org picker) for
  interactive clients — Claude Code (`/mcp` → Authenticate), claude.ai / Cowork custom
  connectors (previously documented as key-paste, which those surfaces never supported).
  `mk_live_` keys remain the documented path for automation (CI, scripts, headless
  agents) and keep working everywhere.

## [0.11.0] - 2026-07-12

### Added

- **Post review links, automatically.** A new `PostToolUse` hook fires after every
  post-writing MCP call (`create_post`, `schedule_post`, `queue_post`,
  `publish_post_now`, `update_post`) and injects the exact Marky app links —
  `app.mymarky.ai/post/{id}` plus the scheduled-queue view and queue position —
  into the agent's context, so the agent always hands the user a review link
  instead of describing the post. Deterministic; no longer relies on the agent
  remembering the app-links table.


## [0.10.1] - 2026-07-12

### Fixed

- The low-queue hook now finds your API key in MCP-only setups: if `MARKY_API_KEY`
  isn't in the environment, it recovers the key from the marky MCP server's
  Authorization header in `~/.claude.json`. Without this the check silently never
  fired for standard plugin installs. Also fixed a nonzero exit (surfaced as a hook
  error) on machines with no key at all.

## [0.10.0] - 2026-07-12

### Added

- **Low-queue notifications.** New opt-out `[notifications]` settings in `user.toml`
  (`low_queue_reminder`, `low_queue_threshold_days`, default on / 3 days) and a
  SessionStart hook (`hooks/queue-check.sh`) that checks the saved business's posting
  queue via the new `GET /queue/summary` endpoint (3s timeout, cached 6h in
  `~/.marky/queue-cache`, silent on any failure) and tells you at session start when
  the queue is about to run dry, with an offer to top it up. Needs `MARKY_API_KEY`
  in the environment. Non-plugin clients get the same behavior via the marky-api
  skill's Session start section.
- Docs for `get_queue_summary` (MCP + `GET /queue/summary`): `queued_count` plus
  next/last estimated publish times — the cheap "when does my queue run dry?" call.

### Changed

- **BREAKING (API):** `GET /businesses/{id}/queue` / `list_business_queue` now returns
  a paginated `CursorPage` (items under `data`, `limit`/`cursor` params) instead of a
  bare array, matching every other list endpoint. Docs updated.

## [0.9.1] - 2026-07-10

### Added

- Docs for the new top-level `link` field on posts (live in the API): clickable on
  Facebook (link attachment), Google Business (CTA button), and Pinterest (pin
  destination); other platforms ignore it. Set it whenever a post has a destination —
  clickable beats copy-paste. Per-platform links stay in `platform_overrides`.

## [0.9.0] - 2026-07-10

### Added

- **Per-platform tailoring is now the default.** Marky's API (shipped today) added
  `platform_overrides` to `create_post`/`update_post` — per-platform caption, media,
  title, link, and first_comment on ONE post — and `platform_writing_instructions`
  on the business (read on `get_business`; MERGE-patched via `update_business`, so
  `{"linkedIn": "..."}` touches only that key and null resets it).
  `schedule-posts` and `plan-social-content` now set overrides on every
  multi-platform post, and `references/platform-rules.md` documents the full flow:
  user instructions first, style baseline second, hard limits always.

## [0.8.0] - 2026-07-10

### Added

- **`references/platform-rules.md`** in `marky-api` — the per-platform hard limits
  (caption/hashtag/carousel/video caps that cause real publish rejections, straight
  from Marky's publishing layer) plus the default style baseline per platform.
  `plan-social-content` tailors multi-platform batches against it. The user's own
  preferences always outrank the baseline.
- **Named hook-pattern palette** in `plan-social-content` (contrarian, question,
  story open, stat, list preview, bold claim, empathy, before/after, confession)
  with anti-patterns (throat-clearing openers, hashtag-first, generic-expert voice).
  Baseline only — brand rules, the feedback log, and performance learnings outrank
  it; hook choice is tagged in post `metadata` so `review-performance` can score
  patterns per audience.
- **Four-tier action plan** ends every `review-performance` run: quick wins /
  strategic shifts / experiments / stop-doing — every rec cites specific posts,
  benchmarks against the business's OWN averages, and flags thin samples.
- **`build-brand-kit` captures verbatim phrases and anti-patterns** — exact wording
  from the site ("no contracts, ever") and explicit "Never ..." rules, plus a
  brain-dump vs. question-at-a-time interview fallback for thin sites.
- **Five new MCP tools** (Marky server-side): `search_library`, `list_business_queue`,
  `get_integration_stats`, `list_integration_posts`, `get_external_post_stats`. The
  `review-performance` and `manage-library` skills now drive them as tools instead of
  curl — MCP-only clients (Cowork) can finally run a full performance review.
  Marky-side post generation and the design flow stay off the MCP deliberately: the
  agent writes its own posts.

## [0.7.2] - 2026-07-10

### Changed

- **`create-post-diagram` is now `create-post-graphic`.** The skill's output is mostly
  designed brand cards (graphics); true diagrams are the subset. Its default
  `media_type` tag flips to `graphic` accordingly (`diagram` when the output really is
  a flow/chart/steps visual). Behavior otherwise unchanged.
- **MCP-first everywhere.** The MCP is the surface agents use; REST is a stopgap for
  operations with no tool yet — and hitting one is a signal to report via
  `submit_feedback` so the tool gets added. `marky-api` reframed accordingly (intro,
  tool-table section, and the feedback section now lead with the `submit_feedback`
  tool), and every skill's feedback pointer now names the MCP tool instead of a REST
  call. `build-brand-kit` needs no REST at all. (from #55's Unreleased section)

## [0.7.1] - 2026-07-10

### Changed

- Tagging vocabulary: `media_type` gains `graphic` (a designed brand card) as distinct
  from `diagram` (a true flow/chart/steps visual) — most announcement cards are
  graphics, not diagrams, and conflating them would muddy the engagement cuts.
  (Shipped in #53; version + changelog landed here after colliding with 0.7.0.)

## [0.7.0] - 2026-07-10

### Added

- **New skill: `build-brand-kit`.** Point the agent at your website and it builds your
  brand kit in Marky: extracts the logo, colors, fonts, voice, tagline, CTAs, and
  imagery style from the site, shows you the proposed kit field-by-field (flagging
  anything it would replace), then writes it with the `update_business` MCP tool and
  proves it with a sample post or diagram. The natural first step after connecting a
  business — a thin brand profile is the top reason generated posts feel generic.
- **One-prompt agent install.** New `INSTALL_FOR_AGENTS.md`: paste a single prompt into
  any AI agent (Claude Code, Cowork, Codex, Cursor, ...) and it installs the skills,
  asks for your API key, saves it in the right place for that client, and verifies with
  a live call. README leads with the install prompt.
- **`/marky-status` now includes a performance snapshot.** A fifth gather step pulls
  engagement for the ~5 most recent posts and reports the best/worst performer with a
  one-line why, plus unanswered comments. Deep analysis (topics, formats, follower
  trends) still routes to `review-performance`.
- **`performance-learnings.md` — audience-measured taste memory.** New "Performance
  learnings" section in `marky-api`: a per-business markdown file of dated, data-backed
  lessons ("question-ending posts pull 3-4x comments"), stored in the Marky library or
  `~/.marky/fs/` per the `file_system` setting. `/marky-status` and `review-performance`
  offer to append findings (user approves the exact lines); `plan-social-content` reads
  it before drafting. Complements the feedback log: that file holds what the USER chose,
  this one holds what the AUDIENCE rewarded.

### Fixed

- **The connect/reconnect-socials page is now in the marky-api link table:**
  `/ws/{business_id}/business/profile`. Agents detecting an invalid integration sent
  users to business *settings*, which is the wrong page — accounts are connected on
  the business *profile* page.

### Changed

- **`marky-api` restructured for progressive disclosure** (per Anthropic's skill-creator
  best practices: keep SKILL.md under ~500 lines, move lookup material to `references/`).
  The SKILL.md (834 → ~400 lines) keeps auth, the business-scoped shape, the app link
  table, the feedback contract, the session-start protocol, the MCP tool table, a
  most-used-endpoints cheat sheet, and the four brand-memory duties. Full detail moved to
  `references/setup.md` (key creation + per-client MCP connect), `references/rest-endpoints.md`
  (complete REST reference), `references/brand-memory.md` (brand cache, style critiques,
  feedback log, performance learnings — full formats), and `references/contribution-nudge.md`
  (session-start Check 2 procedure). All section headings other skills point at are
  unchanged, so no cross-references broke.
- README install section slimmed to the agent pointer + one-prompt install; the
  per-client manual steps live in INSTALL_FOR_AGENTS.md (readable by humans too).

## [0.6.0] - 2026-07-10

### Added

- **Post metadata + the tagging convention.** Marky's API now supports `metadata` on
  posts (up to 50 string key/value pairs, yours, never interpreted by Marky). The
  marky-api skill documents it plus a shared tagging vocabulary (`media_type`,
  `format`, `hook`, `topic`, `created_by`); every creation skill now tags the posts it
  makes, and `review-performance` groups engagement by tag — so "diagrams out-engage
  photos 2:1" becomes a queryable fact instead of a hunch.

## [0.5.1] - 2026-07-10

### Changed

- **Video projects get a fixed home.** `create-post-video` now creates HyperFrames
  projects at `~/.marky/videos/<business_id>/<project-slug>/` instead of the current
  working directory — video workspaces are tens of MB and cwd might be inside a git
  repo or an iCloud-synced folder. Past projects accumulate per business as reusable
  templates (brand-remixed frame.md, storyboards). Skill also says to delete the
  project's `capture/` scratch after rendering. Verified hyperframes init/lint/validate
  all run clean from the hidden directory.

## [0.5.0] - 2026-07-09

### Added

- **Capture studio** (`scripts/capture-studio.py`, stdlib-python3). A local browser page
  for collecting the media only the user can provide — talking-head clips (webcam with a
  scrolling teleprompter of the agent's script), screen recordings, webcam photos, and
  screenshots — in one sitting. Captures POST straight back to the local server and land
  in a `captures/` folder next to the agent (no Downloads shuffle); Finish writes a
  `captures.json` manifest with per-item notes. Wired in as the preferred Stage 4 flow
  in `plan-social-content` and as the user-footage source for `create-post-video`.
  Binds 127.0.0.1 only; upload ids validated against tasks.json (no path traversal).
- README "Every way to make post media" matrix: diagrams, camera photos, screenshots /
  screen recordings, talking-head clips, faceless HyperFrames video, and Marky's own
  AI-generated images — with the skill that owns each.

## [0.4.2] - 2026-07-09

### Fixed

- **Board images click through to full size.** Cards crop media to a 4:5 tile, which
  hid the edges of wide diagrams and 16:9 frames — images now link to the original
  (zoom-in cursor, new tab), so visuals can actually be judged before approving.

## [0.4.1] - 2026-07-09

### Added

- **Captions are editable right on the review board.** In approve mode, click into any
  caption and rewrite it — edited cards highlight, and your version lands in
  `feedback.json` under `edits` and is used verbatim. The agent diffs your edit against
  its draft and applies the pattern to the rest of the batch (the delta IS the
  preference).
- **"Never / always" rules persist immediately.** A board note phrased as a rule
  ("never use exclamation marks") is written to the brand profile's
  `caption_writing_rules` right away (with confirmation) instead of waiting for the
  feedback-log recurrence bar.

## [0.4.0] - 2026-07-09

### Added

- **Review board** (`scripts/review-board.py`, stdlib-python3, zero deps). A local
  browser page for reviewing agent-produced content, in the design-shotgun style: the
  agent serves it in the background, hands you the URL in a blocking question, and reads
  your choices back from `feedback.json` when you submit. Two modes: **approve**
  (per-post approve/reject + comments — `plan-social-content` now uses it as the
  preferred Stage 6 approval gate for a weekly/monthly batch) and **pick** (choose one
  variant + star ratings — wired into `create-post-diagram` style choices and
  `create-post-video` cuts). Local media files are served by the board itself; binds
  127.0.0.1 only; falls back to chat review when python3 is unavailable.
- **Feedback log — taste memory across sessions.** Every board result is appended to
  `~/.marky/feedback-log.jsonl` (business, context, decisions, comments), and creation
  skills read the recent entries BEFORE generating: lean into approved topics and
  picked styles, drop what gets rejected. Preferences that recur ~3+ times escalate to
  the brand profile (`caption_writing_rules` / `imagery_preferences`) with user
  confirmation, so Marky's own generator learns them too.

## [0.3.2] - 2026-07-09

### Changed

- **`create-post-diagram` footers now show the actual logo.** When the business has a
  `logo_url`, the diagram footer renders the logo image (~48px tall, `object-fit:
  contain`, on `logo_background_color` when set) instead of a text wordmark. The
  wordmark (business name in the accent color) is now only the fallback for businesses
  with no logo. Base CSS + example updated to match.

## [0.3.1] - 2026-07-09

### Fixed

- **Correct `palettes` shape in the brand-profile docs.** On the business object,
  `palettes` is a list of palette objects (`{name, colors, text_color}`) — colors live at
  `palettes[0].colors`. The marky-api PATCH example showed the bare nested-array form,
  which only the generate endpoints' override accepts and would fail against
  `PATCH /businesses`. The brand-cache example is fixed to match.
- `create-post-diagram` now starts from the injected `brand-cache.md` snapshot and only
  fetches the business when the cache is missing or stale.

## [0.3.0] - 2026-07-09

### Added

- **`create-post-video` skill.** On-brand video posts end to end: renders with
  [HyperFrames](https://github.com/heygen-com/hyperframes) (video from HTML — offers the
  `npx skills add heygen-com/hyperframes` install if missing), styled from the brand
  cache (palettes, fonts, logo, tone), then uploads to Marky, captions in your voice,
  and schedules everywhere connected. Approval-gated like every creation skill.

### Changed

- **BREAKING (names only): creation skills are now prefixed `create-post-*`.**
  `post-diagrams` → `create-post-diagram`, `event-countdown-posts` →
  `create-post-countdown`, `posts-from-library-image` → `create-post-from-image`,
  `repurpose-posts` → `create-post-variations`. Behavior is unchanged; update anything
  that invokes the old names. Skill routing by description is unaffected.
- `/marky-status` is now registered in the plugin manifests (it shipped in 0.2.7 but was
  missing from the `commands` lists).

## [0.2.8] - 2026-07-09

### Changed

- **`brand-voice.md` is now `brand-cache.md`, and it carries design too.** The cached
  brand snapshot now includes the design fields (`tagline`, `ctas`, `palettes`,
  `header_font`, `body_font`, `logo_url`, `logo_background_color`, `logo_width`)
  alongside the voice fields — so diagrams, cards, and video frames an agent renders
  start on-brand with no fetch, same as copy. Non-string values serialize as compact
  JSON, one line per field. The SessionStart hook reads the old `brand-voice.md` as a
  fallback until the sync hook rewrites the new name on the next profile touch.

## [0.2.7] - 2026-07-09

### Added

- **`/marky-status` command.** One-glance account snapshot: what's queued, whether recent
  posts landed (`publish_results`), drafts waiting to be scheduled, and integrations that
  need a reconnect. Read-only; leads with problems, offers next actions.
- **Brand-voice cache now syncs itself.** A PostToolUse hook rewrites
  `~/.marky/brand-voice.md` automatically after every `get_business` / `update_business`
  MCP call — the SessionStart snapshot can no longer drift from what the agent last saw.
  Partial updates merge over cached fields for the same business; a different business id
  replaces the file. Needs `python3`; exits silently (old behavior) without it. REST-path
  usage still refreshes the cache per the marky-api skill instructions.

## [0.2.6] - 2026-07-09

### Changed

- **Cowork MCP setup corrected.** The plugin carries the skills, hooks, and `/marky`
  command, but Cowork does not read the plugin's `.mcp.json` — the MCP is added in the UI
  as a custom connector (Settings -> Connectors -> Add custom connector, name `Marky`,
  URL `https://api.mymarky.ai/api/mcp`, OAuth fields blank, paste your `mk_live_` key).
  The marky-api skill and README both document the click-path now; the README's
  "nothing to configure on Cowork" claim is gone.
- Claude Desktop instructions replaced with Codex CLI (`~/.codex/config.toml` with the
  same `mcp-remote` bridge). Cowork plugin install path documented in the README
  (Customize -> Plugins -> Add marketplace -> from repository).

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
