# Program Overview — Headless 360 Workshop (tech track)

This is the **map** for the hands-on technical build. Work top to bottom.

- **New here?** Read the [README](./README.md) for what this is and why.
- **Getting your laptop + org ready?** → **[docs/setup.md](./docs/setup.md)** (pre-work, then org provisioning). Do this first.
- **Something broke?** → **[docs/ISSUES.md](./docs/ISSUES.md)** — the one place for symptoms → fixes (copy-paste, incognito, OS, per-surface gotchas).
- **Reference:** [Three-Tier framework](./docs/reference/three-tier-framework.md) · [Tool reference](./docs/reference/tool-reference.md) · [Credential checklist card](./docs/reference/credential-checklist-card.md).

> **How to use this kit.** Each module is its own page with a fixed header (**Goal · Prereqs · Time · Done-when**), numbered steps, a 🔴 checkpoint, and prev/next links. 🟡 = optional/time-permitting — skip if the clock is tight. When stuck, flip to [ISSUES](./docs/ISSUES.md) rather than re-reading the module.

## The arc: Educate → Reference Build → Apply-to-POC

The thesis, made literal by the flow: **build the capability once, reach it from every surface.**

## Table of contents

### Phase 1 · Educate — build the shared language *(joint)*
| Module | Goal | ~Time | Done when |
|---|---|---|---|
| [0 — Prereqs & Comprehend](./docs/modules/00-prereqs-and-comprehend.md) | Org reachable, tooling installed, repo cloned | 15 min | `00-preflight.sh` passes |
| [1 — Educate: the mental model](./docs/modules/01-educate.md) | Shared language before you build | 45–60 min | You've mapped 2–3 of your workflows to a tier |

### Phase 2 · Reference Build — prove the pattern *(guided, on pre-provisioned orgs)*
| Module | Goal | ~Time | Done when |
|---|---|---|---|
| [2 — The Capability: deploy + tour](./docs/modules/02-capability.md) | Tour the one pre-built capability; run one query | 30 min | OR-1003 query returns the real record + card |
| [3 — Connect: Claude over Hosted MCP 🔴](./docs/modules/03-connect-claude-mcp.md) | Reach the org from Claude over MCP | 45 min | A real read returns your FLS-governed data |
| [3a — Assemble a custom MCP server](./docs/modules/03a-custom-mcp-server.md) 🟡 | Compose your own MCP server in Setup | 20 min | Claude reaches your custom server, returns OR-1003 |
| [4 — Custom UI: React & HXL](./docs/modules/04-custom-ui.md) | Custom UI on the agent — React apps + HXL widgets, in-org & external | 60 min | React card shows OR-1003 (in-org + external) and an HXL widget deploys + renders |
| [5 — Slack (Block Kit card) 🔴](./docs/modules/05-slack.md) 🟡 | Same Skill rendered as a Slack Block Kit card | 30 min | A card posts to the channel |
| [6 — ChatGPT over MCP](./docs/modules/06-chatgpt.md) 🟡 | Reach the same org/Skill from ChatGPT | 30 min | ChatGPT returns real org data |

### Phase 3 · Apply to Partner POC — the partner's own capability *(joint, late Day-1 → Day-2)*
| Module | Goal | ~Time | Done when |
|---|---|---|---|
| [7 — Fork your own capability](./docs/modules/07-fork.md) | Reskin the reference Skill to your product | take-home | Your capability answers on your own data |
| [8 — Package your solution](./docs/modules/08-package.md) 🟡 | The shape to package + distribute your fork | take-home | You know the three-bucket split |
| [8a — Connect your own external MCP server](./docs/modules/08a-external-mcp.md) 🟡 | Fold your MCP service into the agent | take-home | Your tools register + the agent calls them |
| [8b — Explore Agentforce Co-Worker](./docs/modules/08b-coworker.md) 🟡 | Ideation: your Skill through Co-Worker | topic | — |

### [Showcase](./docs/modules/08-package.md#showcase)
Each partner demos their forked cross-surface capability — one capability, reached from every surface.
