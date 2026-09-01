# Module 8 — Package your solution 🟡

**Phase:** 3 · Apply to Partner POC · **Goal:** the shape to package + distribute your forked Skill · **Time:** take-home · **Done when:** you know the three-bucket split + the two package commands

> 🟡 **Optional / directional wrap-up — not a required lab step.**

This is a directional wrap-up so you can package *your own* forked Skill (Module 7) when you get home. We proved the reference build itself packages as a **2GP unlocked package** (the `.agent` bundle, all planner versions, and the CLT all made it in) — so the path is real. Here's the shape to take back.

## Steps

1. **Sort your metadata into three buckets:**
   - the packageable **capability** — Apex + object + CLT/LWC + perm set;
   - the **agent** — ships as an Agent Template + per-org activation (the `.agent` authoring layer has a managed-ISV gap);
   - the **not-packageable org config** — 🔑 **all credentials + connections (Slack token, the two External Client Apps, the MCP server definition) are post-install configuration**, never packaged.

2. **Deliver the org config as a post-install Skill** — package the capability, then wire the creds + agent activation *after* install. This is the software-plus-services motion.

3. **Generate the package.** Both commands require a **Dev Hub enabled** first. **[Terminal]** — run them from the `sfdx/` project directory (they need `sfdx-project.json`), one at a time:

   ```bash
   sf package create
   ```

   ```bash
   sf package version create
   ```

📦 That three-bucket split + these two commands are the whole shape: package the capability, deliver the org config as a post-install Skill, activate the agent per org.

### 🔴 Checkpoint 8
You can name the **three buckets** (capability / agent / not-packageable org config), you know the org config (Slack token, both ECAs, the MCP server definition) is **post-install configuration**, and you can run the **two package commands** (`sf package create`, `sf package version create`) against a **Dev Hub-enabled** org.

## Showcase

Demo your forked cross-surface capability: **one capability, reached from every surface** — Claude over MCP, a React app over the Agent API, Slack, and the in-conversation card (+ ChatGPT if built). This is the Dreamforce story — "build the capability once, meet the user on every surface."

## Appendix — Scratch org for local dev (what it can and can't validate)

You create your workshop org from the **template `0TTHo0000036iOl`** because it carries the
preview/beta features the full build needs. If you want a **throwaway org for local iteration**
(base capability + your React/LWC work) without spinning up another template org, the kit ships a scratch
definition at [`sfdx/config/project-scratch-def.json`](../../sfdx/config/project-scratch-def.json):

```bash
sf org create scratch --definition-file sfdx/config/project-scratch-def.json \
  --alias h360-scratch --set-default --duration-days 7 --target-dev-hub <your-devhub>
```

**What a standard scratch org validates (tested 2026-08-24, Developer edition, no add-on features):**
- ✅ The **base capability** — Apex (`OrderStatusSkill`, `SendSlackCardAction`), `Order__c` + tab, `lightningTypes`, LWC, named credentials (17/19 components of the `steps/deploy` base set).
- ✅ The **HXL Widget Viewer** package (`hxl-viewer/` — Apex + LWCs + FlexiPage + Tab + App + permset) deploys clean via `./scripts/deploy-hxl-viewer.sh`.
- ✅ Good for local Apex/LWC/React dev and for a cold-start sanity check of the base deploy ordering.

**What a standard scratch org can NOT host — you need the workshop template org (`0TTHo0000036iOl`):**
- ❌ **The Agentforce agent** — `AiAuthoringBundle` fails with *"Not available for deploy for this organization,"* so `steps/deploy`'s agent-publish step (Module 2) can't run.
- ❌ **HXL widgets** — `UiWidgetBundle` fails the same way, so the Module 4b reference-widget deploy (`--metadata-dir reference/hxl-widget-sample`) won't land.

Both are gated features that aren't exposed as scratch-definition `features`; enabling them requires an org
that ships them (the workshop template `0TTHo0000036iOl`). **Use a scratch org for base/dev iteration; use your
workshop template org for the full Agentforce + HXL path.** If a future scratch feature enables either, add it to the
`features` array in the definition file above.

---

[← Module 7](./07-fork.md) · [Overview](../../OVERVIEW.md) · [Module 8a →](./08a-external-mcp.md)
