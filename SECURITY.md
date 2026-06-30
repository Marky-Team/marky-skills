# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in these skills, please report it
responsibly.

**Do not open a public GitHub issue for security vulnerabilities.**

Instead, either:

- Open a [GitHub Security Advisory](https://github.com/Marky-Team/marky-skills/security/advisories/new), or
- Email support@mymarky.ai with `SECURITY` in the subject.

Please include:

- A description of the vulnerability
- Steps to reproduce
- Potential impact
- A suggested fix (if any)

We will acknowledge receipt within 48 hours and aim to provide a fix or
mitigation plan within 7 days.

## A note on API keys

These skills authenticate to Marky with an `mk_live_...` API key. Treat that key
like a password:

- Never commit a real key to a repository, paste it into an issue, or share it in
  a screenshot.
- A key grants access to your Marky businesses and connected social accounts.
- If a key is exposed, rotate it immediately in **Organization Settings -> API
  Keys** in the [Marky app](https://app.mymarky.ai).

Vulnerabilities in the Marky API or app itself (not these skills) should also be
reported to support@mymarky.ai.

## Scope

This policy covers the skills and scripts in this repository.
