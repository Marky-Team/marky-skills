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

**Watch the 4-minute setup walkthrough:**

https://github.com/user-attachments/assets/06e1f9c7-cb18-4c18-914e-a1d93655dc10

## Install

> **Are you an agent?** Read [INSTALL_FOR_AGENTS.md](INSTALL_FOR_AGENTS.md) and follow
> it. It covers every client: what to install, where the API key goes, and how to verify.

**Are you a human?** Copy this into your AI agent and it does the whole install for you —
detects your client, installs the skills, asks for your API key, saves everything in the
right place:

```
Read https://raw.githubusercontent.com/Marky-Team/marky-skills/main/INSTALL_FOR_AGENTS.md and follow it.
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

| Skill | Example |
| :--- | :--- |
| **`marky-api`** | "Connect me to Marky" — the agent reads this first for auth, endpoints, and the MCP connection. |
| **`build-brand-kit`** | "`/build-brand-kit` for my website nike.com" |

### Create & schedule

| Skill | Example |
| :--- | :--- |
| **`schedule-posts`** | "Schedule this post for Friday at 9am on Instagram and LinkedIn" |
| **`plan-social-content`** | "Plan a week of posts for my business. Ask me what's coming up first." |
| **`create-post-graphic`** | "Turn these 4 steps into a branded diagram for the post" |
| **`create-post-countdown`** | "Make a countdown series for our July 30 launch" |
| **`create-post-from-image`** | "Here's a photo from the job site — make 3 posts out of it" |
| **`create-post-variations`** | "That review post did great — make 5 fresh variations" |
| **`create-post-video`** | "Make a short video post about our weekend sale" |

### Steer & measure

| Skill | Example |
| :--- | :--- |
| **`review-performance`** | "What were my top posts last month? Repurpose the best one." |
| **`suggest-topics`** | "Suggest 10 topics my audience would love" |
| **`manage-library`** | "Save this pricing sheet so Marky can reference it in posts" |

## Community

- Questions about your account, billing, or connected socials: support@mymarky.ai
- Bugs and feature requests: [GitHub Issues](https://github.com/Marky-Team/marky-skills/issues)
- Security reports: [SECURITY.md](SECURITY.md)

