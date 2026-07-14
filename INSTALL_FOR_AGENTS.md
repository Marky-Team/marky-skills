# Marky — agent install guide

You are an AI agent installing Marky's skills for your user. Marky is a social media
manager: it writes, designs, schedules, and publishes posts. These skills teach you to
drive it. Follow the steps for YOUR client type, top to bottom. Ask the user only for
what the steps say to ask.

## 1. Detect your client and install the skills

**Claude Code** — install the plugin (skills + session hooks + `/marky` command + the
MCP server config, all in one):

```
claude plugin marketplace add Marky-Team/marky-skills
claude plugin install marky@marky-skills
```

If those CLI commands are unavailable, tell the user to type `/plugin marketplace add
Marky-Team/marky-skills` and then `/plugin install marky@marky-skills` in their next
prompt.

Then have the user **sign in**: they type `/mcp`, pick **marky**, choose
**Authenticate** — their browser opens Marky's page, they click Allow and pick their
organization. That is the whole auth setup: **no API key needed.** (Headless/CI use
is the exception — see step 2.) Skip to step 4.

**Cowork / Claude Desktop / claude.ai** — you cannot install this yourself; give the
user these two UI steps: (1) Customize -> Plugins -> Add -> Add marketplace -> Add from
a repository -> `Marky-Team/marky-skills`, then + on the Marky plugin. (2) Settings ->
Connectors -> Add -> Add custom connector; name `Marky`, URL
`https://api.mymarky.ai/api/mcp`, leave the OAuth fields blank, click Add, then
Connect — their browser opens Marky's sign-in page; they click Allow and pick their
organization. **No API key is needed on these surfaces** — skip steps 2 and 3.

**Codex, Cursor, Windsurf, or any other agent that supports Agent Skills:**

```bash
npx skills add marky-team/marky-skills -g
```

(`-g` installs user-level so Marky works from any directory, which is what you want for
"run my social media from wherever I'm working".)

## 2. Get the API key (Codex / Cursor / headless only)

Claude Code, Cowork, Claude Desktop, and claude.ai all signed in with OAuth in
step 1 — skip to step 4. An API key is only needed for clients that can't open a
browser to sign in (Codex, Cursor, other MCP clients) and for headless/CI runs.
Ask the user for their Marky API key (`mk_live_...`). If they don't have one, send them
to **https://app.mymarky.ai/connect-claude** — one click creates it (org admins only; a
key is shown in full exactly once, so tell them to copy it right away). No account? They
can start free at https://app.mymarky.ai.

## 3. Save the key permanently

Pick the location for YOUR client. Never write the key into a repository.

**Claude Code (headless/CI only — interactive sessions use OAuth, step 1)** — merge
the key into `~/.claude/settings.json` for REST calls, and register a key-authed MCP
server (the bundled server uses OAuth and won't read the key):

```bash
node -e 'const fs=require("fs"),os=require("os"),d=os.homedir()+"/.claude",p=d+"/settings.json";fs.mkdirSync(d,{recursive:true});let s={};try{s=JSON.parse(fs.readFileSync(p,"utf8"))}catch{};s.env={...s.env,MARKY_API_KEY:"mk_live_THE_KEY"};fs.writeFileSync(p,JSON.stringify(s,null,2));console.log("Saved "+p)'
claude mcp add --transport http marky-key https://api.mymarky.ai/api/mcp \
  --header "Authorization: Bearer mk_live_THE_KEY"
```

**Codex** — add to `~/.codex/config.toml` (the key sits in `env` on purpose so the space
in `Bearer ...` survives):

```toml
[mcp_servers.marky]
command = "npx"
args = ["-y", "mcp-remote", "https://api.mymarky.ai/api/mcp", "--header", "Authorization:${MARKY_AUTH}"]
env = { "MARKY_AUTH" = "Bearer mk_live_THE_KEY" }
```

**Other clients** — most take this MCP config; otherwise export `MARKY_API_KEY` in the
user's shell profile and call the REST API per the `marky-api` skill:

```json
{
  "mcpServers": {
    "marky": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://api.mymarky.ai/api/mcp",
               "--header", "Authorization:${MARKY_AUTH}"],
      "env": { "MARKY_AUTH": "Bearer mk_live_THE_KEY" }
    }
  }
}
```

## 4. Verify

Call the `list_businesses` MCP tool (or `GET https://api.mymarky.ai/api/businesses` with
`Authorization: Bearer mk_live_...` on the key path). Seeing the user's workspaces =
installed correctly. Tell the user it worked and show them their business names.

If it fails: "needs authentication" means the user hasn't finished the OAuth sign-in
(`/mcp` -> marky -> Authenticate); a 401 on the key path means the key is wrong or
wasn't picked up (restart the client); anything else, read the `marky-api` skill's
troubleshooting notes.

## 5. Show the user what they can do now

Offer a few of these first prompts:

- "Plan a week of posts for my business. Ask me what's coming up first."
- "What were my top posts last month? Repurpose the best one."
- "Suggest 10 topics my audience would love."
- "Make a countdown series for my event on [date]."
- "Schedule my drafts across next week."

Before doing real work, read the `marky-api` skill — it is the contract every other
Marky skill builds on (auth, endpoints, the curated MCP tools, session-start checks).
