<h1 align="center">Marky Skills</h1>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue.svg" alt="License"></a>
  <img src="https://img.shields.io/badge/skills-9-brightgreen" alt="9 skills">
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
Claude Desktop / Cowork, Cursor, or any agent that supports skills, then run your
whole social workflow in plain language: generate on-brand posts, upload media,
schedule a week of content, review what is working, and repurpose your best posts.

Marky is the API- and MCP-driven social tool. These skills are the cheat sheet
that lets an agent use it well.

## Install

Pick the path for your client. **Claude Code users: install the plugin** — it is the
preferred path.

### Claude Code → install as a plugin (preferred)

Claude Code can install this repo as a **plugin**, not just a bundle of skills. The plugin
carries the same 9 skills **plus** the extras a plain skills install can't: a
**feedback-reminder hook** that loads Marky's "please send feedback" expectation into context
at the start of every session, a **session-state hook** that reads your local `user.toml` and
surfaces a feedback or contribution prompt only when one is actually due (cadence-gated, so it
never nags every session), and a **`/marky` slash command** that bootstraps a session
(loads the API reference, checks your key, lists your businesses). That is why it is the
preferred path on Claude Code.

Your cadence and preferences live in a gitignored `user.toml` in the plugin dir (copy
`user.toml.example` to start, or let the skill create it on first run). Set `leave_feedback`
or `suggest_contribution` to `off` there to silence either prompt.

Add the marketplace, then install the plugin:

```
/plugin marketplace add Marky-Team/marky-skills
/plugin install marky-skills@marky-skills
```

(`marky-skills@marky-skills` is `plugin-name@marketplace-name` — both happen to be
`marky-skills` here. Run `/plugin` with no arguments to browse, manage, or remove it in the
interactive UI.)

Then run `/marky` (or just describe the job) to start.

### Other clients (Cursor, Claude Desktop / Cowork, …) → install the skills

Anything that supports the [Agent Skills](https://agentskills.io) format installs the skills
directly:

```bash
npx skills add marky-team/marky-skills
```

The installer auto-detects your agent and drops the skills in the right place. Run
`npx skills add marky-team/marky-skills --skill <name>` to install just one (bare name, no
leading `/`). (This also works in Claude Code, but the plugin path above is preferred there
because it carries the hook + command too.)

### Then describe the job

Either way, once installed, just say what you want done:

> Using `/plan-social-content`, plan and schedule a week of posts about our new
> spring blend — mine my notes for material, draft in my voice, and show me
> everything before scheduling.

The skills teach agents the Marky workflow: authenticate once, find your
businesses and connected accounts, generate on-brand drafts, schedule them, and
confirm they published.

## Skills

Marky Skills ships **9 skills** agents load on demand. Read **`marky-api`** first —
it is the reference every other skill builds on (auth, base URL, endpoints, and
how to connect Marky's MCP server).

### Start here

| Skill | Use when |
| :--- | :--- |
| **`marky-api`** | **Read first.** Authenticate to the Marky API, find the base URL and key endpoints, and connect Marky's MCP server to Claude Code or Claude Desktop / Cowork. Every other skill reads its auth and endpoints from here. |

### Create & schedule

| Skill | Use when |
| :--- | :--- |
| **`schedule-posts`** | You have content ready (your own captions and media, or a topic for Marky to write) and want it on your connected accounts on a schedule. Covers media upload, post creation, on-brand generation, scheduling, and publish confirmation. |
| **`plan-social-content`** | You want a full week of on-brand posts produced and queued in one conversation. Mines your real material, drafts in your voice, and always gets your approval before scheduling. |
| **`event-countdown-posts`** | You have an upcoming event (launch, sale, webinar, opening, holiday promo) and want a sequence of posts that build anticipation and end with a final reminder. |
| **`posts-from-library-image`** | You have one strong image and want maximum mileage from it — several ready-to-review posts with different captions and angles, all using that image. |
| **`repurpose-posts`** | A post did well (or you just like it) and you want fresh variations — new angles, new wording, or a specific call-to-action link. |

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

   Claude Code CLI:

   ```bash
   claude mcp add --transport http marky https://api.mymarky.ai/api/mcp \
     --header "Authorization: Bearer mk_live_YOUR_KEY"
   ```

   Claude Desktop / Cowork — add this to `claude_desktop_config.json` and restart:

   ```json
   {
     "mcpServers": {
       "marky": {
         "command": "npx",
         "args": ["-y", "mcp-remote", "https://api.mymarky.ai/api/mcp",
                  "--header", "Authorization: Bearer mk_live_YOUR_KEY"]
       }
     }
   }
   ```

   (Full instructions, including the REST option, live in the `marky-api` skill.)

3. **First post.** Connect a social account in the Marky dashboard first (the API
   can see accounts but cannot add them), then ask your agent:

   > "List my Marky businesses, generate 3 posts about our new spring blend, and
   > schedule one each morning this week."

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
- An agent that supports Agent Skills (Claude Code, Claude Desktop / Cowork, Cursor, ...).

## Documentation

- Marky app: [app.mymarky.ai](https://app.mymarky.ai)
- API & MCP docs: [docs.mymarky.ai](https://docs.mymarky.ai)
- Agent Skills format: [agentskills.io](https://agentskills.io)

## Community

- Questions about your account, billing, or connected socials: support@mymarky.ai
- Bugs and feature requests: [GitHub Issues](https://github.com/Marky-Team/marky-skills/issues)
- Security reports: [SECURITY.md](SECURITY.md)

## Community skills

This repo is the **officially curated, maintained** set. For community-contributed
skills — open to anyone, use at your own risk, not officially maintained — see the
companion repo: [**`Marky-Team/marky-skills-community`**](https://github.com/Marky-Team/marky-skills-community).
A proven community skill can **graduate** into this repo.

## Contributing

Contributions are welcome — a new skill is just a well-written `SKILL.md`. See
[CONTRIBUTING.md](CONTRIBUTING.md) for the frontmatter spec, the quality bar, and
the checklist for adding a skill. Please also read our
[Code of Conduct](CODE_OF_CONDUCT.md). For experimental or niche skills, contribute
to [`marky-skills-community`](https://github.com/Marky-Team/marky-skills-community) instead.

## License

[Apache 2.0](LICENSE)
