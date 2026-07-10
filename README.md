<h1 align="center">Marky Skills</h1>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue.svg" alt="License"></a>
  <img src="https://img.shields.io/badge/skills-12-brightgreen" alt="12 skills">
  <a href="https://agentskills.io"><img src="https://img.shields.io/badge/format-Agent%20Skills-5865F2" alt="Agent Skills format"></a>
  <a href="https://github.com/Marky-Team/marky-skills/issues"><img src="https://img.shields.io/github/issues/Marky-Team/marky-skills.svg" alt="Issues"></a>
</p>

<p align="center"><b>Describe the posts. Marky ships them. Built for agents.</b></p>

<p align="center">
  <a href="#install">Install</a> |
  <a href="#skills">Skills</a> |
  <a href="https://app.mymarky.ai">Marky App</a> |
  <a href="https://docs.mymarky.ai">API Docs</a> |
  <a href="#contributing">Contributing</a>
</p>

Marky Skills is a collection of [Agent Skills](https://agentskills.io) that teach
coding agents how to drive [Marky](https://app.mymarky.ai) — AI social media
management — through its API and MCP server. Install them into Claude Code,
Cowork, Codex, Cursor, or any agent that supports skills, then run your
whole social workflow in plain language: generate on-brand posts, upload media,
schedule a week of content, review what is working, and repurpose your best posts.

Marky is the API- and MCP-driven social tool. These skills are the cheat sheet
that lets an agent use it well.

## Install

> **Are you an agent?** Read [INSTALL_FOR_AGENTS.md](INSTALL_FOR_AGENTS.md) and follow
> it. It covers every client: what to install, where the API key goes, and how to verify.

**Are you a human?** Copy this into your AI agent and it does the whole install for you —
detects your client, installs the skills, asks for your API key, saves everything in the
right place:

```
Read https://raw.githubusercontent.com/Marky-Team/marky-skills/main/INSTALL_FOR_AGENTS.md and follow it. Ask me for any API keys you need.
```

Works with Claude Code, Cowork, Codex, Cursor, Windsurf, and any agent that supports
[Agent Skills](https://agentskills.io). Manual per-client steps live in
[INSTALL_FOR_AGENTS.md](INSTALL_FOR_AGENTS.md) too — they read fine for humans.

Two notes worth knowing up front:

- **Updates:** after any update, your next session opens with a short what's-new summary.
  On Claude Code, auto-update is off by default for third-party marketplaces — enable it
  via `/plugin` → Marketplaces → `marky-skills` → **Enable auto-update**, or update
  manually with `/plugin marketplace update marky-skills`.
- **Then describe the job.** Once installed, just say what you want done:

  > Using `/plan-social-content`, plan and schedule a week of posts about our new
  > spring blend — mine my notes for material, draft in my voice, and show me
  > everything before scheduling.

## Skills

Marky Skills ships **12 skills** agents load on demand. Read **`marky-api`** first —
it is the reference every other skill builds on (auth, base URL, endpoints, and
how to connect Marky's MCP server).

### Start here

| Skill | Use when |
| :--- | :--- |
| **`marky-api`** | **Read first.** Authenticate to the Marky API, find the base URL and key endpoints, and connect Marky's MCP server to Claude Code, Cowork, or Codex. Every other skill reads its auth and endpoints from here. |
| **`build-brand-kit`** | You just connected a business, or generated posts feel generic. Point the agent at your website and it extracts your logo, colors, fonts, voice, tagline, and imagery style, shows you the kit for approval, and writes it to your brand profile — so everything Marky makes afterward looks and sounds like you. |

### Create & schedule

| Skill | Use when |
| :--- | :--- |
| **`schedule-posts`** | You have content ready (your own captions and media, or a topic for Marky to write) and want it on your connected accounts on a schedule. Covers media upload, post creation, on-brand generation, scheduling, and publish confirmation. |
| **`plan-social-content`** | You want a full week of on-brand posts produced and queued in one conversation. Mines your real material, drafts in your voice, and always gets your approval before scheduling. |
| **`create-post-graphic`** | A post announces, teaches, or compares something and a designed diagram would beat a stock photo. Authors branded HTML (layers, flows, loops, quote cards, sequences, steps), renders to PNG in your brand colors, and attaches it to the post. |
| **`create-post-countdown`** | You have an upcoming event (launch, sale, webinar, opening, holiday promo) and want a sequence of posts that build anticipation and end with a final reminder. |
| **`create-post-from-image`** | You have one strong image and want maximum mileage from it — several ready-to-review posts with different captions and angles, all using that image. |
| **`create-post-variations`** | A post did well (or you just like it) and you want fresh variations — new angles, new wording, or a specific call-to-action link. |
| **`create-post-video`** | You want a video post — a promo, stat animation, explainer, or captioned clip. Renders with [HyperFrames](https://github.com/heygen-com/hyperframes) in your brand colors, fonts, and logo, then uploads, captions, and schedules through Marky. |

### Steer & measure

| Skill | Use when |
| :--- | :--- |
| **`review-performance`** | You want to know your top posts, follower growth, and which topics, formats, and platforms get the best engagement — then get specific recommendations and optionally act on them. |
| **`suggest-topics`** | Your posts feel repetitive or off-target and you want fresh things to post about, or you want to add, edit, enable, disable, or remove the topics Marky writes from. |
| **`manage-library`** | You want to give Marky reference material to draw on — upload media, organize folders, and create or edit notes, briefs, and knowledge-base docs. |

## Quickstart (first action in 3 steps)

1. **Get a key.** Sign in at [app.mymarky.ai](https://app.mymarky.ai), open
   **Organization Settings -> API Keys**, click **Create API Key**, and copy the
   `mk_live_...` value (shown once).

2. **Connect Marky's MCP** so the agent can use Marky's tools natively.

   **Claude Code (with this plugin installed): nothing to configure.** The plugin
   ships Marky's MCP server (`.mcp.json`), so all it needs is your key in an
   environment variable. Set it before launching Claude Code:

   ```bash
   export MARKY_API_KEY="mk_live_YOUR_KEY"
   ```

   That's it — Marky's tools appear automatically. (No key set yet? The `marky-api`
   skill walks you through getting one and setting it.)

   **Cowork: add the MCP as a custom connector** (the plugin carries the skills,
   not the connector): **Settings → Connectors → Add → Add custom connector**,
   name `Marky`, URL `https://api.mymarky.ai/api/mcp`, leave the OAuth fields
   blank, and paste your `mk_live_...` key when asked. **Other clients (Codex /
   Cursor):** configure the MCP manually — full instructions, including the REST
   option, live in the `marky-api` skill.

3. **First post.** Connect a social account in the Marky dashboard first (the API
   can see accounts but cannot add them), then ask your agent:

   > "List my Marky businesses, generate 3 posts about our new spring blend, and
   > schedule one each morning this week."

## Every way to make post media

| Media | How | Skill |
| :--- | :--- | :--- |
| Branded diagrams | agent-authored HTML → PNG in your colors/fonts/logo | `create-post-graphic` |
| Photos (camera) | capture studio — webcam, saved straight to the agent | `plan-social-content` Stage 4 |
| Screenshots / screen recordings | capture studio — screen grab or full recording | `plan-social-content` Stage 4 |
| Talking-head clips | capture studio — webcam + teleprompter, then captions/packaging via HyperFrames | `plan-social-content` + `create-post-video` |
| Faceless composed video | HyperFrames renders from HTML, branded from your profile | `create-post-video` |
| AI-generated images | Marky's own generator (`/posts/generate` designs media for the post) | `schedule-posts` / `plan-social-content` |

Both local tools (review board + capture studio) follow the same pattern: a page opens in
your browser, you click/record, and the results land right back with the agent — nothing
to download and re-upload.

## What You Can Do

- Plan and schedule a full week of on-brand content from your own notes
- Generate posts about a topic and queue them across every connected platform
- Build a countdown campaign for a launch, sale, or event
- Turn one great photo into a batch of posts with different angles
- Repurpose your best-performing posts into fresh variations
- Review performance and get a concrete, data-backed content plan
- Keep your topics and content library tidy so every draft stays on-brand

## How It Works

Each skill is a plain Markdown `SKILL.md` file. When your agent hits a matching
job ("schedule these posts", "what's working", "plan my week"), it loads the
skill and follows the steps inside — which Marky endpoints to call, in what order,
with example requests and responses.

```
You -> Agent -> loads skill (SKILL.md) -> calls Marky API / MCP -> your socials
```

- **`marky-api`** holds the shared contract: how to authenticate with your
  `mk_live_...` key, the base URL (`https://api.mymarky.ai/api`), and the key
  endpoints (businesses, integrations, media, posts, generate, schedule, stats).
- The other skills are **job-shaped** — each one composes those endpoints into a
  complete workflow and defers to `marky-api` for the details.
- Nothing is scheduled without your go-ahead. The planning skills always show you
  the drafts and ask for approval first.

### The Claude Code plugin

Claude Code can install this repo as a **plugin**, not just a bundle of skills. The plugin
carries the same 11 skills **plus** the extras a plain skills install can't: a
**feedback-reminder hook** that loads Marky's "please send feedback" expectation into context
at the start of every session, a **session-state hook** that reads your local `user.toml` and
surfaces a feedback or contribution prompt only when one is actually due (cadence-gated, so it
never nags every session), and a **`/marky` slash command** that bootstraps a session
(loads the API reference, checks your key, lists your businesses). That is why it is the
preferred path on Claude Code.

Your cadence and preferences live in `~/.marky/user.toml` (copy `user.toml.example` to
start, or let the skill create it on first run — it survives plugin updates there). Set
`leave_feedback` or `suggest_contribution` to `off` there to silence either prompt.

(`marky@marky-skills` is `plugin-name@marketplace-name` — the plugin is `marky`, hosted in
the `marky-skills` repo. Run `/plugin` with no arguments to browse, manage, or remove it in
the interactive UI.)

## Why Marky Skills?

- **Plain language in, scheduled posts out.** No dashboards, no copy-paste — just
  describe the job.
- **On-brand by default.** Generation pulls from your business profile, topics,
  and library, so drafts sound like you.
- **Agent-native.** Works through Marky's MCP server (native tool calls) or plain
  REST. Use whichever your agent supports.
- **Approval-first.** The agent drafts and proposes; you approve before anything
  publishes.
- **Open and portable.** Apache-2.0-licensed Markdown skills that install into any
  agent that supports the Agent Skills format.

## Requirements

- A [Marky](https://app.mymarky.ai) account with at least one connected social account.
- An API key (`mk_live_...`) — see step 1 of the Quickstart.
- An agent that supports Agent Skills (Claude Code, Cowork, Codex, Cursor, ...).

## Documentation

- Marky app: [app.mymarky.ai](https://app.mymarky.ai)
- API & MCP docs: [docs.mymarky.ai](https://docs.mymarky.ai)
- Agent Skills format: [agentskills.io](https://agentskills.io)

## Community

- Questions about your account, billing, or connected socials: support@mymarky.ai
- Bugs and feature requests: [GitHub Issues](https://github.com/Marky-Team/marky-skills/issues)
- Security reports: [SECURITY.md](SECURITY.md)

## Contributing

Contributions are welcome — a new skill is just a well-written `SKILL.md`. See
[CONTRIBUTING.md](CONTRIBUTING.md) for the frontmatter spec, the quality bar, and
the checklist for adding a skill. Please also read our
[Code of Conduct](CODE_OF_CONDUCT.md).

## License

[Apache 2.0](LICENSE)
