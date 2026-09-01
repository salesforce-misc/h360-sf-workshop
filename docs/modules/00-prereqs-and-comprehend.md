# Module 0 — Prereqs & Comprehend

**Phase:** 1 · Educate · **Goal:** your org is reachable, tooling is installed, the repo is cloned · **Time:** ~15 min · **Done when:** `preflight.sh` reports `sf` present + your org reachable (once you've claimed it in [setup](../setup.md)).

> **Setup lives in [docs/setup.md](../setup.md).** Do **Part 1** (install: Mac/Windows) and **Part 2** — [create org → switch to Lightning → verify email → enable Agentforce → onboard → smoke](../setup.md#part-2--make-your-org-yours) — there **first**. This module is a quick environment check + the pre-read; it does not repeat the setup steps.

## Steps

1. **Confirm your org is reachable** (run **from the cloned repo root**). If you haven't done org setup yet, do it now → **[setup.md Part 2](../setup.md#part-2--make-your-org-yours)**.
   ```bash
   ./scripts/preflight.sh --org <your-alias>
   ```
   Expected: `sf` present, org reachable, prereq reminders printed.
   > `--org <your-alias>` is the primary form (`--alias` also works). If you prefer, `cp .env.example .env` and set `ORG_ALIAS=<your-alias>` once, then you can omit the flag — but don't do both.

2. **Confirm the two Claude Code plugins are installed** (from [setup.md](../setup.md#add-the-two-claude-code-plugins)): `/plugin` lists **`agentforce-adlc`** and **`sf-mcp-partner-toolkit`**.

3. **Skim the tool reference** — every CLI, plugin, and skill the lab uses, with version and verify step: **[docs/reference/tool-reference.md](../reference/tool-reference.md)**.

> **Install before you start.** Claude Code is the prescribed AI tool; **Agentforce Vibes** is the supported alternative + the "what's next" showcase. **If you can't get the Claude Code happy path working, use Agentforce Vibes (GA)** — same stack (MCP tools, Skills, CLI, governance), a different driver.

## Pre-read (complete before you start the build)

| Resource | Why |
|----------|-----|
| [Introduction to Salesforce Headless 360](https://trailhead.salesforce.com/content/learn/modules/salesforce-headless-360-quick-look) | Trailhead quick-look — shared vocabulary before you start |
| [Headless 360 MCP Server Guide](https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/headless-360-mcp.html) | The `headless-360` server you activate in Module 3 — the four-tool interface |
| [Headless 360 Decoded Ep. 1](https://www.youtube.com/watch?v=a3sD9YUsk9c&list=PLgIMQe2PKPSLvBYUfZpg5M0eO0jiAKpAu&index=1) | Parker Harris's "why should you ever log in again?" — the executive narrative |

### 🔴 Checkpoint 0
`./scripts/preflight.sh --org <alias>` passes (sf present, org reachable) and `/plugin` lists both plugins. If preflight can't reach the org, revisit [setup.md Part 2](../setup.md#part-2--make-your-org-yours).

---

[Overview](../../OVERVIEW.md) · [Module 1 — Educate →](./01-educate.md)
