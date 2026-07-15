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

Marky Skills gives your agent the ability to automate your social media. Out of
the box it can create content — posts, graphics, and videos in your brand style.
Upload and post it yourself, or sign up for a [Marky](https://app.mymarky.ai)
account to publish straight from your agent, optimize based on what's working,
and so much more.

## Install

### Claude Cowork

Watch the 4-minute setup walkthrough:

https://github.com/user-attachments/assets/06e1f9c7-cb18-4c18-914e-a1d93655dc10

### Claude Code (or Codex)

Paste this into your agent. It will take it from there...

```
Read https://raw.githubusercontent.com/Marky-Team/marky-skills/main/INSTALL_FOR_AGENTS.md and follow it.
```

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
| **`create-post-clips`** | "Turn my YouTube webinar into short clips and schedule them" |

### Steer & measure

| Skill | Example |
| :--- | :--- |
| **`review-performance`** | "What were my top posts last month? Repurpose the best one." |
| **`suggest-topics`** | "Suggest 10 topics my audience would love" |
| **`manage-library`** | "Save this pricing sheet so Marky can reference it in posts" |

## Community

- Follow Marky: [Facebook](https://www.facebook.com/mymarkyai) · [Instagram](https://www.instagram.com/mymarky.ai/)
- Questions about your account, billing, or connected socials: support@mymarky.ai
- Bugs and feature requests: [GitHub Issues](https://github.com/Marky-Team/marky-skills/issues)
- Security reports: [SECURITY.md](SECURITY.md)

