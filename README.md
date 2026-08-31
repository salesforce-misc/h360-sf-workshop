# Headless 360 Partner Activation Workshop

A clone-able, in-person workshop kit that activates priority ISV partners on the **Headless 360**
initiative — the TDX 2026 architecture that opens the full platform (data, logic, workflows, governance) to every human,
agent, and surface.

This kit follows a **three-phase technical arc** — **Educate → Reference Build → Apply-to-POC** 
— so each participant leaves with the mental model, a proven cross-surface pattern, and a working 
reference **Skill forked into a POV of their own capability**.

## 👉 Start here: [**OVERVIEW.md**](./OVERVIEW.md)

The tech track is a navigable, page-per-module kit. Everything below is orientation.

- **The map / table of contents:** **[OVERVIEW.md](./OVERVIEW.md)** — the phase→module list; start here.
- **Get your laptop + org ready:** **[docs/setup.md](./docs/setup.md)** — pre-work (🍎 Mac / 🪟 Windows) then org provisioning. Do this first.
- **When something breaks:** **[docs/ISSUES.md](./docs/ISSUES.md)** — the single troubleshooting page (copy-paste, incognito, OS, per-surface gotchas; the credential setup for the two ECAs + Slack token now lives inline in Modules 3/4/5).
- **Per-module build:** **[docs/modules/](./docs/modules/)** — one page each, Module 0 → 8b + Showcase.
- **Hands-on build/deploy for the four surfaces** (concrete commands, per-surface): **[docs/build-and-deploy.md](./docs/build-and-deploy.md)**.


## What you're building

A partner-neutral reference **Employee Agent** with a single `@InvocableMethod` Skill
(order/case status + one action), rendered in-conversation and available via the Agent API —
the **hands-on build every partner completes**, then tailors into a POV of their own capability.

**HXL "render everywhere."** The aspirational headline — one experience rendering natively
across Slack, Agentforce, Claude, mobile. Module 4c has participants **build it as far as it
goes today**: deploy a real `UiWidgetBundle`, inspect it in the in-org HXL Widget Viewer, and
render the same definition in the external React side-by-side — no gated dependency. What stays
**vision** is a platform **auto-render of that widget live in a channel** (ChatGPT/Slack/Agentforce).

Prescribed AI tool: **Claude Code** (Agentforce Vibes = documented alternative + "what's next" demo).

## Prerequisites

Your workshop org — created from the Headless 360 **org template `0TTHo0000036iOl`** — carries: Agentforce + Employee Agent; Hosted MCP + External Client App; 
Agent API; Lightning Experience for the in-conversation card. **Agentforce is installed but must be activated** (see setup). A **Slack workspace connection is optional** — provide your own Slack app if you want to build the Slack surface. The setup process is documented in 
**[setup.md](./docs/setup.md)**.

- **Salesforce CLI** (`sf`) — https://developer.salesforce.com/tools/salesforcecli
- **Your own workshop org**, created from the Headless 360 **org template `0TTHo0000036iOl`** via your Partner Business Org (Environment Hub) or Dev Hub — see [setup.md](./docs/setup.md) — then `sf org login web --alias <your-alias>`. **Activate Agentforce** before deploying the kit (it's installed but not active on a fresh template org).
- **Claude Code**, with the **`agentforce-adlc`** and **`sf-mcp-partner-toolkit`** plugins (installed in [setup.md](./docs/setup.md#add-the-two-claude-code-plugins)).
- (Agent API surface) **Node.js** to run the `web/` sample client.

The full tool list — every CLI, plugin, and skill with version, install command, verify step, and which module uses it —
is the **[tool reference](./docs/reference/tool-reference.md)**.

## Quick start

1. **Create your org** from template `0TTHo0000036iOl` (Environment Hub / Dev Hub) — see **[docs/setup.md](./docs/setup.md)** — then sign in the CLI:
   ```bash
   sf org login web --alias <your-alias>
   ```
2. **Clone + onboard** (run one at a time):
   ```bash
   git clone https://github.com/salesforce-misc/h360-sf-workshop.git
   cd h360-sf-workshop
   ./scripts/onboard.sh --org <your-alias>    # deploy + publish agent + permset + seed hero data
   ./scripts/smoke.sh --org <your-alias>             # confirm you're build-ready
   ```
3. Follow **[OVERVIEW.md](./OVERVIEW.md)** module by module — this repo is your authoritative guide.

## Workshop flow

The workshop follows a three-phase arc:

1. **Educate** — concept fluency + shared language (Headless 360 architecture, [Three-Tier framework](./docs/reference/three-tier-framework.md), surface portfolio).
2. **Reference Build** — hands-on modules building one Employee Agent + one Skill across four surfaces 
   (MCP/Claude, Agentforce, Slack, React/Agent API). Guided, step-by-step in **[the module pages](./docs/modules/)**.
3. **Apply to POC** — fork the reference Skill into your own capability, package it, and plan your next steps.

All modules are documented in **[the module pages](./docs/modules/)** with 🔴 checkpoints where silent failures happen.

## Kit contents

- **[OVERVIEW.md](./OVERVIEW.md)** — the tech-track map / table of contents.
- **[docs/setup.md](./docs/setup.md)** — pre-work (Mac/Windows) + org provisioning runbook.
- **[docs/modules/](./docs/modules/)** — one page per module (0 → 8b + Showcase), each with 🔴 checkpoints; credential setup for the two ECAs + Slack token is inline in Modules 3/4/5.
- **[docs/ISSUES.md](./docs/ISSUES.md)** — the single troubleshooting page (copy-paste, incognito, OS, per-surface symptom→fix).
- **[docs/](./docs/)** — the hands-on **[build & deploy guide](./docs/build-and-deploy.md)**, the printable
  **[checklist card](./docs/reference/credential-checklist-card.md)**, and the
  **[Three-Tier framework](./docs/reference/three-tier-framework.md)**.
- **`sfdx/`** — the reference build: the **`Order__c`** demo object (+ 5 hero records), the `@InvocableMethod` Skill
  (queries `Order__c`), the Employee Agent as an **Agent Script bundle** (deploy/publish, not UI-authored), the Slack
  custom action + Custom External Credential wiring, the `LightningTypeBundle` CLT, permission set.
- **`web/`** — a runnable React Agent-API sample client (`node proxy.mjs` backend proxy holds the token + `npm run dev`).
- **`scripts/`** — `onboard.sh` (one-command per-org onboarder) + `smoke.sh` (readiness check); the `00`–`05` bootstrap steps it wraps (preflight/deploy/assign/`steps/seed-hero-data.sh`), the `connect-mcp.sh` Connect helper, + `check.sh` validation harness.
- **`config/kit.json`** — mode + partner overlay + surface toggles.

## Resources (pre-reading)

Shared with participants before Day 1 (also listed in Module 0):

- [Headless 360 MCP Server Guide](https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/headless-360-mcp.html) — the four-tool interface (**Discover → Describe → Dispatch / Dispatch-Read-Only**); requires **API v67.0+**, an External Client App with the `mcp_api` scope ("Access Salesforce hosted MCP Servers"), per-user OAuth.
- [Introduction to Salesforce Headless 360](https://trailhead.salesforce.com/content/learn/modules/salesforce-headless-360-quick-look) — Trailhead quick-look module (GA)
- [Headless 360 Decoded Ep. 1](https://www.youtube.com/watch?v=a3sD9YUsk9c&list=PLgIMQe2PKPSLvBYUfZpg5M0eO0jiAKpAu&index=1) — Parker Harris's "why should you ever log in again?" framing
- [Agentforce Vibes](https://developer.salesforce.com/docs/platform/agentforcevibes/overview) — natural-language agentic dev experience; connects Claude Code to the full Headless 360 stack (MCP, Skills, CLI)
- [Build with React on Salesforce — Multi-Framework (GA)](https://developer.salesforce.com/blogs/2026/07/build-with-react-on-salesforce-multi-framework-is-now-ga) — native React is **fully GA** (Jul 2026), auto-enabled on all Hyperforce orgs (Product/Sandbox/Scratch/DE); new `salesforce.app` hosting domain; Data SDK (GraphQL) GA. Strengthens the React/web (Agent API) surface. *(Note: the May-2026 dev blog below called multi-framework "open beta" — it reached GA in July; cite the GA state.)*
- [Headless 360 — What It Means for Developers](https://developer.salesforce.com/blogs/2026/05/headless-360-what-it-means-for-developers) (dev blog, May 21 2026) — the public developer framing: **60+ MCP tools · 30+ coding skills · 4,000+ APIs · 220+ CLI commands**; MCP tools for *coding* vs *business* agents; four governance items enforced on every call; **HXL = "a new runtime that decouples capability definitions from their rendering surface"**; **Agentforce Vibes 2.0**; names **Claude / Claude Code** as rendering surface + coding agent.
- [Agentic Experience Layer (HXL/AXL) — marketing page](https://www.salesforce.com/headless/agentic-experience-layer/) — *"the control plane for how AI shows up across your business"*; a **core capability of the Agentforce 360 Platform**, included in the platform license (no per-user fees), 30-day free trial. The public north-star framing for the workshop.
- [Agentforce Vibes — Enterprise Vibe Coding](https://www.salesforce.com/agentforce/developers/vibe-coding/) — natural-language build/test/deploy inside the **Agentforce Trust Boundary** (code/schema/metadata never exposed to public LLMs); uses the **Salesforce DX MCP Server** + open-source MCP servers (GitHub, Figma).

_A full "Explore Salesforce Headless 360" Trailhead trail is in progress targeting Dreamforce 2026 (Sept 15–17); watch Trailhead for the full release._

## Honesty notes (taught, not hidden)

- **`@AuraEnabled` is not an open headless path** — only Agentforce can invoke it; external/third-party agents cannot. The
  taught path is **`@InvocableMethod` + MCP tools + Agent API**.
- **HXL / AXL cross-surface auto-rendering is the vision, not a button today.** Each surface's rich UI is built
  explicitly. The reusable IP is the **Three-Tier design discipline** applied per surface — which survives protocol churn.
  **Now publicly announced (2026-07-21):** HXL/AXL has a public marketing page + a May-2026 dev blog calling it *"a new
  runtime that decouples capability definitions from their rendering surface"* — a **core capability of the Agentforce 360
  Platform** (in the platform license). **Cross-surface auto-render is vision** — the lab builds each surface by hand. 
  HXL/AXL targets the **open MCP Apps standard**, so it's Salesforce joining an emerging standard, not a walled garden.
- All platform status is time-sensitive — **re-check against current release notes** before building.
