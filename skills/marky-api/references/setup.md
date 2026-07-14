# Setup: get an API key and connect the MCP

Part of the `marky-api` skill. Read this when the user needs to CREATE an API key,
PERSIST it, or CONNECT Marky's MCP server to a client (Claude Code, Cowork, Codex,
Cursor, custom agents). For day-to-day calls you don't need this file — the base URL,
auth header, and endpoints are in the main SKILL.md.

## Get your API key

1. Sign in at [app.mymarky.ai](https://app.mymarky.ai).
2. Open **Organization Settings -> API Keys** (left sidebar -> Settings, then scroll to
   API Keys).
3. Click **Create API Key**, name it, and copy the `mk_live_...` value. It is only shown
   once, so save it somewhere safe.
4. **If you use this plugin in Claude Code**, put the key in the `MARKY_API_KEY`
   environment variable (the bundled MCP server reads it). Persist it — a bare
   `export` lasts only until the terminal closes. Pick one:

   - **Recommended:** add it to Claude Code's own settings so it works no matter how
     Claude Code is launched (terminal, desktop app, IDE). In `~/.claude/settings.json`:

     ```json
     { "env": { "MARKY_API_KEY": "mk_live_YOUR_KEY" } }
     ```

     (Merge into the existing file if it already has other keys.)

   - Or add the export to your shell profile (`~/.zshrc` for zsh, `~/.bashrc` for bash):

     ```bash
     echo 'export MARKY_API_KEY="mk_live_YOUR_KEY"' >> ~/.zshrc
     ```

     Note: GUI-launched apps do not read your shell profile, so prefer the
     settings.json option if you use the Claude desktop app or an IDE.

Notes:
- You must be an **org admin** to create keys.
- A key has access to every workspace (business) in your organization.
- Keep the key in an environment variable or `.env` file, never in source control.
- Each org can have up to 10 active keys. Revoke a leaked key from the same page.

## Connect the MCP

The Marky MCP server lets an agent call Marky's tools directly instead of you pasting REST
instructions.

```
MCP endpoint:  https://api.mymarky.ai/api/mcp
Transport:     streamable HTTP
Auth:          OAuth (sign in with your Marky account) OR Authorization: Bearer mk_live_YOUR_KEY
```

**Which auth?** Two credentials, split by who holds them — both work on the MCP and the
REST API:

- **Sign in (OAuth)** — the default when a person is present. Claude Code, claude.ai,
  Claude Desktop/mobile, and Cowork all walk you through it: click connect/authenticate,
  approve in the browser, pick your organization, done. No key to copy. Revoke any time
  from **Settings → API Keys → Connected agents**.
- **API key (`mk_live_`)** — for automation: CI, scripts, cron/headless agents,
  server-to-server. No browser available, or the credential belongs to a system rather
  than a person? Use a key.

### Claude Code CLI

**If you installed this plugin, the MCP server is already bundled** (in the plugin's
`.mcp.json`) — you only need your key in the `MARKY_API_KEY` environment variable.
Persist it in `~/.claude/settings.json` (or your shell profile) — see "Get your API
key" above for both options; a one-off `export` disappears when the terminal closes:

```json
{ "env": { "MARKY_API_KEY": "mk_live_YOUR_KEY" } }
```

Then ask: *"List my Marky businesses."* Claude calls `list_businesses` and shows your
workspaces. Each has an `id` you use as `business_id` for everything else.

**Prefer OAuth sign-in, or not using the plugin?** Register the server yourself and
authenticate — no key needed:

```bash
claude mcp add --transport http marky https://api.mymarky.ai/api/mcp
```

Then run `/mcp` → **marky** → **Authenticate**: your browser opens Marky's consent
page; approve and you're connected. Prefer a static key instead (e.g. for headless
use)? Pass it as a header:

```bash
claude mcp add --transport http marky https://api.mymarky.ai/api/mcp \
  --header "Authorization: Bearer mk_live_YOUR_KEY"
```

### Cowork / claude.ai custom connector

Cowork and claude.ai add remote MCP servers as **custom connectors** — even with the
Marky plugin installed, the connector is a separate manual step (the plugin carries
skills, hooks, and the `/marky` command; Cowork does not read the plugin's `.mcp.json`).
Custom connectors are OAuth-only (there is no API-key field), and Marky supports that
natively:

1. **Settings → Connectors → Add → Add custom connector**
2. Name: `Marky`; URL: `https://api.mymarky.ai/api/mcp`
3. Leave the OAuth Client ID/Secret fields blank and click **Add**.
4. Click **Connect** — your browser opens Marky's consent page. Sign in if needed,
   pick the organization to connect (multi-org accounts get a picker), and click
   **Allow**.

Marky's tools then appear in the tools menu for every Cowork session. Disconnect any
time from Marky's **Settings → API Keys → Connected agents**.

### Codex CLI

Codex talks to local (stdio) MCP servers, so bridge to Marky's remote HTTP server with the
open-source `mcp-remote` package (run on demand via `npx`, no install). It signs in with
OAuth — the browser opens, the user clicks Allow and picks their organization. Add to
`~/.codex/config.toml`:

```toml
[mcp_servers.marky]
command = "npx"
args = ["-y", "mcp-remote", "https://api.mymarky.ai/api/mcp"]
```

### Any other MCP client (Cursor, custom agents)

Most clients take a config like this — clients that speak OAuth natively sign the user
in; stdio-only clients go through `mcp-remote` (which handles the sign-in itself):

```json
{
  "mcpServers": {
    "marky": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://api.mymarky.ai/api/mcp"]
    }
  }
}
```
