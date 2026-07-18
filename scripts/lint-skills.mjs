/**
 * Lint the skills in this repo so a broken skill never ships.
 *
 * This runs in CI (see .github/workflows/ci.yml) and locally via `npm run lint`.
 * It is plain Node with zero dependencies on purpose: a skills collection should
 * not need a build step or an install just to validate itself.
 *
 * It checks three things:
 *
 *  1. Frontmatter is valid. Every skills/<name>/SKILL.md needs a `---` block with
 *     a `name` and a `description`, and `name` must match the directory. One bad
 *     SKILL.md aborts `npx skills add` for the WHOLE repo, so this is the gate
 *     that keeps the collection installable.
 *
 *  2. No shell-trap characters in inline backticks. Claude Code scans skill text
 *     for shell-like patterns; an inline backtick containing `!` (history
 *     expansion) or `>` followed by a word (redirection) trips the bash
 *     permission checker and stops the skill from loading. Use fenced code
 *     blocks for commands instead.
 *
 *  3. The manifests are in sync. Every skill directory must be registered in both
 *     skills-manifest.json and .claude-plugin/marketplace.json, with no missing
 *     or stray entries. This is what makes `npx skills add marky-team/marky-skills`
 *     resolve every skill.
 */

import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, relative } from "node:path";

const ROOT = join(import.meta.dirname, "..");
const SKILLS_DIR = join(ROOT, "skills");

// Inline-backtick patterns that trip Claude Code's bash permission checker.
const DANGEROUS_INLINE_PATTERNS = [
  {
    pattern: /`[^`]*![^`]*`/,
    message:
      'Inline backtick contains "!" — Claude Code reads this as bash history expansion. Move the command into a fenced code block.',
  },
  {
    pattern: /`[^`]*>\w[^`]*`/,
    message:
      'Inline backtick contains ">" followed by a word character — Claude Code may read this as output redirection. Rephrase (e.g. "150ms+" not the redirection form) or use a fenced code block.',
  },
];

function listSkillDirs() {
  return readdirSync(SKILLS_DIR, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();
}

/** Strip fenced code blocks so we only lint prose + inline code. */
function stripFencedBlocks(content) {
  return content.replace(/^```[\s\S]*?^```/gm, (block) =>
    block
      .split("\n")
      .map(() => "")
      .join("\n"),
  );
}

function parseFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) {
    return null;
  }

  const fields = {};
  for (const line of match[1].split("\n")) {
    const m = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (m) {
      fields[m[1]] = m[2].trim();
    }
  }
  return fields;
}

function lintSkillFile(dirName, filePath, violations) {
  const raw = readFileSync(filePath, "utf-8");
  const rel = relative(ROOT, filePath);

  const frontmatter = parseFrontmatter(raw);
  if (!frontmatter) {
    violations.push(`${rel}: missing YAML frontmatter (the leading "---" block).`);
    return;
  }

  if (!frontmatter.name) {
    violations.push(`${rel}: frontmatter is missing a "name" field.`);
  } else if (frontmatter.name !== dirName) {
    violations.push(
      `${rel}: frontmatter name "${frontmatter.name}" does not match its directory "${dirName}".`,
    );
  }

  // description can be a block scalar (">"), in which case the value is on the
  // following lines; treat the ">" marker as present-and-valid.
  const hasDescription =
    frontmatter.description !== undefined && frontmatter.description !== "";
  if (!hasDescription) {
    violations.push(`${rel}: frontmatter is missing a "description" field.`);
  }

  const lines = stripFencedBlocks(raw).split("\n");
  for (let i = 0; i < lines.length; i++) {
    for (const { pattern, message } of DANGEROUS_INLINE_PATTERNS) {
      if (pattern.test(lines[i])) {
        violations.push(`${rel}:${i + 1}: ${message}`);
      }
    }
  }
}

function lintManifests(skillDirs, violations) {
  const manifest = JSON.parse(
    readFileSync(join(ROOT, "skills-manifest.json"), "utf-8"),
  );
  const marketplace = JSON.parse(
    readFileSync(join(ROOT, ".claude-plugin", "marketplace.json"), "utf-8"),
  );

  const manifestSkills = Object.keys(manifest.skills ?? {});
  const marketplaceSkills = (marketplace.plugins?.[0]?.skills ?? []).map((p) =>
    p.replace(/^\.\/skills\//, ""),
  );

  for (const dir of skillDirs) {
    if (!manifestSkills.includes(dir)) {
      violations.push(
        `skills-manifest.json: skill "${dir}" exists on disk but is not registered.`,
      );
    }
    if (!marketplaceSkills.includes(dir)) {
      violations.push(
        `.claude-plugin/marketplace.json: skill "${dir}" exists on disk but is not registered.`,
      );
    }
  }

  for (const name of manifestSkills) {
    if (!skillDirs.includes(name)) {
      violations.push(
        `skills-manifest.json: registers "${name}" but skills/${name}/ does not exist.`,
      );
    }
  }
  for (const name of marketplaceSkills) {
    if (!skillDirs.includes(name)) {
      violations.push(
        `.claude-plugin/marketplace.json: registers "${name}" but skills/${name}/ does not exist.`,
      );
    }
  }
}

// The version is hand-maintained in three files (one per vendor manifest plus
// package.json). Nothing generates them from a single source, so they drift
// silently — a stale version in a vendor manifest ships the wrong number to
// that vendor's plugin UI. Cheapest guard is to fail the lint when they differ.
function lintVersions(violations) {
  const VERSIONED_FILES = [
    "package.json",
    join(".claude-plugin", "plugin.json"),
    join(".codex-plugin", "plugin.json"),
  ];

  const versions = VERSIONED_FILES.map((rel) => ({
    rel,
    version: JSON.parse(readFileSync(join(ROOT, rel), "utf-8")).version,
  }));

  const expected = versions[0].version;
  for (const { rel, version } of versions) {
    if (version !== expected) {
      violations.push(
        `${rel}: version "${version}" does not match ${versions[0].rel} "${expected}".`,
      );
    }
  }
}

function main() {
  if (!statSync(SKILLS_DIR, { throwIfNoEntry: false })?.isDirectory()) {
    console.error("No skills/ directory found.");
    process.exit(1);
  }

  const skillDirs = listSkillDirs();
  const violations = [];

  for (const dir of skillDirs) {
    const filePath = join(SKILLS_DIR, dir, "SKILL.md");
    if (!statSync(filePath, { throwIfNoEntry: false })?.isFile()) {
      violations.push(`skills/${dir}/: missing SKILL.md.`);
      continue;
    }
    lintSkillFile(dir, filePath, violations);
  }

  lintManifests(skillDirs, violations);
  lintVersions(violations);

  if (violations.length > 0) {
    for (const v of violations) {
      console.error(v);
    }
    console.error(`\n${violations.length} skill lint error(s) found.`);
    process.exit(1);
  }

  console.log(`Checked ${skillDirs.length} skill(s) — no issues found.`);
}

main();
