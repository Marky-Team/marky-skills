/**
 * Catch API drift before it breaks a shipped skill.
 *
 * These skills tell agents to call specific Marky API tools (`get_business`,
 * `create_post`, ...) and send specific request fields (`caption`,
 * `restrict_publish_to`, ...). The public API is a LIVE, hosted contract — if a
 * field or tool is renamed or removed on the API side (it has happened twice:
 * `publish_to` -> `restrict_publish_to`, and `get_business` being cut from the
 * MCP), the skills silently start telling agents to do something that now 422s or
 * doesn't exist. Nobody notices until a user's automation breaks.
 *
 * This script is the backstop. It reads the LIVE public API surface and fails if a
 * skill references a field or tool the API no longer has. It runs on every PR and
 * nightly (see .github/workflows/ci.yml), so drift surfaces on its own — it does
 * not depend on whoever changed the API remembering that this repo consumes it.
 *
 * Zero dependencies on purpose (like lint-skills.mjs): a skills collection should
 * validate itself without an install step.
 *
 * Three checks:
 *   A. Request FIELDS  — every JSON key a skill puts in a request example must be a
 *      real property somewhere in the API's OpenAPI schemas. [no key needed]
 *   B. Tool/OP NAMES   — every verb_noun token a skill references in backticks must
 *      be a real API operationId. [no key needed]
 *   C. MCP EXPOSURE    — tools the skills call over MCP must actually be exposed as
 *      MCP tools (not just REST). Catches "removed from the MCP but kept on REST"
 *      drift. Runs ONLY when MARKY_API_KEY is set (the MCP tools/list needs auth).
 *
 * If the API is unreachable we WARN and pass — a transient API/network blip must
 * not red every PR in this repo. Real drift is persistent; the nightly run catches it.
 */

import { readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";

const ROOT = join(import.meta.dirname, "..");
const OPENAPI_URL = "https://api.mymarky.ai/api/openapi.json";
const OPENAPI_FALLBACK_URL = "https://docs.mymarky.ai/public-openapi.json";
const MCP_URL = "https://api.mymarky.ai/api/mcp";

// Keys that legitimately appear in skill JSON blocks but are NOT API request
// fields — MCP client-config keys and cross-session state (user.toml). Extend this
// when a new non-API key shows up; a genuinely-removed API field is never here.
const FIELD_ALLOWLIST = new Set([
  "mcpServers", "command", "args", "url", "headers", "type", "env", "transport",
  "Authorization", "MARKY_AUTH", "MARKY_API_KEY", "marky", "marky-api",
  "current_business_id", "current_business_name", "file_system", // user.toml [workspace]
  "mode", "decisions", "comments", "overall", "context", "items", "feedback", // review-board feedback-log
  "date", "preferred", "ratings", "edits",
]);

// Operations the skills invoke as MCP tools (not just mention as REST). Check C
// asserts each is still exposed on the live MCP. Keep this to what the skills
// actually drive an agent to call over MCP.
const REQUIRED_MCP_TOOLS = [
  "list_businesses", "get_business",
  "list_posts", "get_post", "create_post", "update_post",
  "schedule_post", "queue_post", "publish_post_now", "get_post_analytics",
  "list_topics", "create_topic", "list_categories",
  "create_media_upload", "upload_media_from_url", "list_connected_social_accounts", "list_google_reviews",
  "get_posting_schedule", "submit_feedback",
];

// An op token looks like a Marky operation: a known verb prefix + snake_case.
const OP_TOKEN = /^(list|get|create|update|delete|schedule|queue|publish|search|upload|revise|generate|submit)_[a-z0-9_]+$/;

async function fetchJson(url, init) {
  const res = await fetch(url, init);
  if (!res.ok) throw new Error(`${url} -> HTTP ${res.status}`);
  return res.json();
}

async function loadApiSurface() {
  let spec;
  try {
    spec = await fetchJson(OPENAPI_URL);
  } catch {
    spec = await fetchJson(OPENAPI_FALLBACK_URL); // let this throw if it also fails
  }

  const fields = new Set();
  for (const schema of Object.values(spec.components?.schemas ?? {})) {
    for (const key of Object.keys(schema.properties ?? {})) fields.add(key);
  }
  const ops = new Set();
  for (const item of Object.values(spec.paths ?? {})) {
    for (const op of Object.values(item)) {
      if (op && typeof op === "object" && op.operationId) ops.add(op.operationId);
    }
  }
  return { fields, ops };
}

// Live MCP tool names (check C). Stateless streamable-HTTP: initialize, then
// tools/list. Returns null if MARKY_API_KEY is unset so the caller can skip.
async function loadMcpToolNames() {
  const key = process.env.MARKY_API_KEY;
  if (!key) return null;

  const headers = {
    "Authorization": `Bearer ${key}`,
    "Content-Type": "application/json",
    "Accept": "application/json, text/event-stream",
  };
  const rpc = (id, method, params) => ({ jsonrpc: "2.0", id, method, params });

  await fetch(MCP_URL, {
    method: "POST", headers,
    body: JSON.stringify(rpc(1, "initialize", {
      protocolVersion: "2025-06-18", capabilities: {},
      clientInfo: { name: "drift-check", version: "1" },
    })),
  });
  const res = await fetch(MCP_URL, {
    method: "POST", headers, body: JSON.stringify(rpc(2, "tools/list", {})),
  });
  // Defensive: only a genuine tool list (200 + parseable + has tools) is usable.
  // Any auth/transport/parse hiccup returns null so check C SKIPS rather than
  // false-alarming that every tool vanished. A stale/expired secret shouldn't red
  // the whole repo — that's a secret problem, not skill drift.
  if (!res.ok) {
    console.warn(`⚠️  MCP tools/list returned HTTP ${res.status}; skipping the MCP exposure check.`);
    return null;
  }
  const text = await res.text();
  let json;
  try {
    // Branch on content-type, NOT a string match: tool descriptions mention
    // "data:" URIs, which would falsely trip an includes("data:") SSE check.
    const isSse = (res.headers.get("content-type") || "").includes("text/event-stream");
    const payload = isSse
      ? text.split("\n").filter((l) => l.startsWith("data:")).pop()?.slice(5).trim()
      : text;
    json = JSON.parse(payload);
  } catch {
    console.warn("⚠️  Could not parse MCP tools/list; skipping the MCP exposure check.");
    return null;
  }
  const tools = json.result?.tools;
  if (!Array.isArray(tools) || tools.length === 0) {
    console.warn("⚠️  MCP tools/list had no tools; skipping the MCP exposure check.");
    return null;
  }
  return new Set(tools.map((t) => t.name));
}

function skillMarkdownFiles() {
  const dirs = ["skills", "commands"];
  const files = [];
  for (const dir of dirs) {
    const abs = join(ROOT, dir);
    let entries;
    try { entries = readdirSync(abs); } catch { continue; }
    for (const entry of entries) {
      const p = join(abs, entry);
      if (statSync(p).isDirectory()) {
        for (const f of readdirSync(p)) if (f.endsWith(".md")) files.push(join(p, f));
      } else if (entry.endsWith(".md")) {
        files.push(p);
      }
    }
  }
  return files;
}

function referencedFieldsAndOps(text) {
  const fields = new Set();
  for (const block of text.matchAll(/```json\s*([\s\S]*?)```/g)) {
    for (const m of block[1].matchAll(/"([A-Za-z_][A-Za-z0-9_]*)"\s*:/g)) fields.add(m[1]);
  }
  const ops = new Set();
  for (const m of text.matchAll(/`([a-z][a-z0-9_]*)`/g)) {
    if (OP_TOKEN.test(m[1])) ops.add(m[1]);
  }
  return { fields, ops };
}

async function main() {
  let surface;
  try {
    surface = await loadApiSurface();
  } catch (err) {
    console.warn(`⚠️  Could not reach the Marky API to check for drift (${err.message}).`);
    console.warn("   Skipping — a transient outage should not block this repo. Nightly run will retry.");
    return; // pass
  }

  let mcpTools = null;
  try {
    mcpTools = await loadMcpToolNames();
  } catch (err) {
    console.warn(`⚠️  MCP tools/list check skipped (${err.message}).`);
  }

  const problems = [];
  for (const file of skillMarkdownFiles()) {
    const rel = file.slice(ROOT.length + 1);
    const { fields, ops } = referencedFieldsAndOps(readFileSync(file, "utf8"));

    for (const f of fields) {
      if (!surface.fields.has(f) && !FIELD_ALLOWLIST.has(f)) {
        problems.push(`${rel}: request field \`${f}\` is not in the live API (renamed/removed?).`);
      }
    }
    for (const op of ops) {
      // A verb_noun token is fine if it's an operation OR a field name (some
      // fields read like ops, e.g. `publish_results`, `scheduled_publish_time`).
      // Only flag a name that exists NOWHERE on the API surface.
      if (!surface.ops.has(op) && !surface.fields.has(op)) {
        problems.push(`${rel}: references \`${op}\` but no such API operation exists (renamed/removed?).`);
      }
    }
  }

  // Check C: required MCP tools must be exposed on the live MCP (needs a key).
  if (mcpTools) {
    for (const tool of REQUIRED_MCP_TOOLS) {
      if (!mcpTools.has(tool)) {
        problems.push(`MCP: \`${tool}\` is used by the skills but is NOT exposed as an MCP tool (curation drift).`);
      }
    }
  } else if (!process.env.MARKY_API_KEY) {
    console.log("ℹ️  MCP exposure check skipped (set MARKY_API_KEY to enable it).");
  }

  if (problems.length) {
    console.error(`\n❌ API drift detected — the skills reference names the live API no longer has:\n`);
    for (const p of problems) console.error(`   - ${p}`);
    console.error(`\nFix: update the affected skill(s) to the current API, or update the API.`);
    console.error(`(If a flagged name is a false positive, add it to the allowlist in this script.)\n`);
    process.exit(1);
  }

  console.log(`✅ No API drift — every field/tool the skills reference exists on the live API.`);
}

main().catch((err) => {
  console.error("check-api-drift crashed:", err);
  process.exit(1);
});
