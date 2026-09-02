# Module 2 — The Capability: guided tour + one query

**Phase:** 2 · Reference Build · **Goal:** tour the one pre-built capability every surface will reach + run one query · **Time:** ~30 min · **Done when:** the OR-1003 query returns the real record and the rich card renders

You are about to **tour** the one reference capability every surface will reach — an Employee Agent + an Apex `@InvocableMethod` Skill over the custom `Order__c` object + its in-conversation rich card (CLT). This is "build the capability once" made concrete on screen, and it front-loads the one true ordering gate: the agent is **deployed + published + activated**, so Connect / React / Slack later just plug in.

> **You already ran `./scripts/onboard.sh`, so steps 1–3 are DONE FOR YOU.** The metadata + permset are deployed, the agent is published + activated, the 5 hero records (OR-1001..OR-1005) are seeded, and the CLT renders. **This module is a guided tour of what got deployed, plus the hands-on OR-1003 query (step 4).** The deploy / publish / activate commands in the Reference section below are **what `onboard.sh` did under the hood** — read them to understand the capability; you do **not** re-run them. (If you ever need to rebuild from scratch, re-running `./scripts/onboard.sh --org <alias>` from the repo root replays all of it.)

## Reference — what `onboard.sh` already did (steps 1–3)

*Read this to understand the capability. These are not to-dos — `onboard.sh` already ran the equivalent.*

1. **Deployed the metadata + assigned the permset.** `onboard.sh` runs `steps/deploy.sh` then `steps/assign-perms.sh` — the by-hand equivalents run from the repo root:

   **[Terminal, repo root]**
   ```bash
   ./scripts/steps/deploy.sh --org <alias>
   ./scripts/steps/assign-perms.sh --org <alias>
   ```

   `steps/deploy.sh` runs a **3-phase sequence** (metadata → `sf agent publish` + `activate` → permset last — see step 2 for why order matters) and deploys the custom **`Order__c`** object, its **tab + page layout** (all 5 fields — so the record is viewable in the UI, now captured in metadata), the `OrderStatusSkill` `@InvocableMethod` (queries `Order__c` `WITH USER_MODE` → real status + next action + record Id, CLT-eligible), the Slack action, and the permset (`Order__c` object + field FLS **and** the H360 Order tab visibility).

   ⚠️ **Deploying the permset does NOT assign it** — `steps/assign-perms.sh` assigns `Headless360_Workshop_Access` to the running user. The `Order__c` FLS lives in the permset, so an unassigned user sees no fields / no tab. (`onboard.sh` already assigned it to you.)

   The 5 hero records (OR-1001..OR-1005) were seeded by `steps/seed-hero-data.sh` — idempotent, and run **after** the permset so the FLS is in place (an unseeded org makes the agent answer "No order matches OR-1003"):

   **[Terminal, repo root]**
   ```bash
   ./scripts/steps/seed-hero-data.sh --org <alias>
   ```

   The `Order__c` object ships an **All Orders** list view, so the rows appear on the tab immediately.

2. **Deployed + published + activated the Employee Agent.** `steps/deploy.sh` already does this (it's the 3-phase script: deploy metadata incl. the `.agent` bundle → `sf agent publish` + `sf agent activate` → deploy the permset last). The agent ships as an **Agent Script bundle**, not UI-authored (`agentforce-adlc`). The by-hand sequence — for reference only — runs from the `sfdx/` project directory (that's where `sfdx-project.json` lives; running these from the repo root fails with `RequiresProjectError`), one at a time:

   **[Terminal, in `sfdx/`]**
   ```bash
   cd sfdx/
   sf project deploy start --metadata AiAuthoringBundle:Headless360_Order_Assistant --target-org <alias>
   sf agent publish authoring-bundle --api-name Headless360_Order_Assistant --target-org <alias>
   sf agent activate --api-name Headless360_Order_Assistant --target-org <alias>
   ```

   **The compiled Bot + planner are NOT in source** — `publish` generates them; a `.forceignore` keeps them out. Agent type = **Employee** (`AgentforceEmployeeAgent`) — required for Slack + CLT + Agent API; no `default_agent_user`.

   🔴 **This is the one ordering gate:** everything downstream (Slack, React/Agent-API, the CLT render) needs the agent **published + activated**, not just deployed. The Agent API errors against an unpublished/inactive agent.

3. **The in-conversation rich card (CLT) is part of the capability.** The `OrderStatusCard` **`LightningTypeBundle`** (in the same package) is bound to the Skill's Apex output so the agent renders a rich card *inside* the conversation (LEX) — the **native/in-platform surface**, and the on-ramp to the HXL "render everywhere" vision (shown as a demo, not built live). How the binding works + the silent-text-fallback gotcha are in the **Capability internals** below.

## Your hands-on steps

4. **Tour it + run one query (the hands-on beat).** Walk the pieces on screen, then run one query against the live agent.

   **Tour the pieces:**
   - **The sample data is the custom object `Order__c`** (external-id field `Order_Number__c`) — **not** the standard Salesforce `Order` object. In your org, open **App Launcher → search "H360 Order"** (custom object `Order__c`) → the **All Orders** list view shows **OR-1001..OR-1005**, with **OR-1003 = Exception**. (Do *not* search "Orders" — that collides with the standard Order object and lands you on an empty one. Also make sure you're in **Lightning Experience**, not Classic.) Open OR-1003 to see all fields on the record page — status, summary, next action.
   - The `OrderStatusSkill` Apex class, the agent's Topic/action wiring, and the CLT.

   **Run the OR-1003 query — PRIMARY path: Agent Builder UI Conversation Preview.** In your org, open **Setup → Agentforce (Agent) Builder → the `Headless360_Order_Assistant` agent → Conversation Preview**, and ask:

   > *"what's the status of order OR-1003?"*

   The agent invokes Get Order Status, returns the **real** record ("carrier exception… Approve rebooking"), and renders the **rich card** in the preview. This is the reliable, low-friction way to run the hero query.

   **Optional CLI alternative — `sf agent preview` (with caveats):** you can run the same query from the terminal instead. Run it from the **`sfdx/`** project directory (it fails with `RequiresProjectError` from the repo root) and pass your org:

   **[Terminal, in `sfdx/`]**
   ```bash
   cd sfdx/
   sf agent preview --use-live-actions --authoring-bundle Headless360_Order_Assistant --target-org <alias>
   ```

   ⚠️ **`sf agent preview` (no `start`) is an in-terminal interactive REPL that needs a real TTY.** It does **not** open a separate window — it drops you into an interactive prompt in the **same terminal**, where you type your query (*"what's the status of order OR-1003?"*) to get the same real record + card. If you run it inside a wrapper / IDE task-runner / non-interactive shell, no prompt appears and it looks like nothing happened — use the UI Conversation Preview above. (Note: `sf agent preview **start**` is a *different, programmatic* command — it prints a session ID and **exits**, for scripted use with `sf agent preview send --utterance …`; use bare `sf agent preview` for an interactive chat.)

   Either way, once OR-1003 returns the real record and card, you've touched the capability before wiring surfaces to it.

5. **Profile the cost** with `sf-flex-estimator` — estimate the Flex-credit weight of the action before scaling (shift-left consumption discipline).

   **What this costs at scale:** the base invocation (1 Standard prompt + the `OrderStatusSkill` action) runs ~**24 Flex Credits**, and the **action is ~83% of that (20 of 24 FC)**. The prompt tier is already at the sensible floor (Standard), so **action consolidation is the main lever** — each extra custom action adds roughly +20 FC. Agentforce pricing is **linear (no volume discount)**, so per-invocation weight is exactly what scales.

### 🔴 Checkpoint 2 — activate + smoke-test + the card renders

- **Agent fires:** the OR-1003 query returns the real record. If the action doesn't fire, check the Topic/action wiring; if it returns "not found," the hero records aren't seeded. Full commands: [docs/build-and-deploy.md](../build-and-deploy.md) §3.
- **Card renders (not plain text):** two things must BOTH be true — the CLT is **bound** (single displayable object output typed to `c__OrderStatusCard`; renderer LWC meta declares `<sourceType>`; `schema.json` references the Apex inner class) **AND** the agent calls **`show_command`** on that output (not "compose as text"). After any `.agent` change: deploy → publish → activate → **fresh conversation**. (Verified 2026-07-23.)

### Capability internals (for the tour narrative + reskin)

- The CLT `schema.json` references the Skill's Apex inner class (`@apexClassType/c__OrderStatusSkill$Card`) + a `renderer.json` + renderer LWC (styled card + action button, meta declaring `<sourceType name="c__OrderStatusCard" />`).
- **The binding is metadata, not a manual click.** The action exposes a single displayable object output (`card: object`, `complex_data_type_name: "c__OrderStatusCard"`, `is_displayable: True`) — a CLT binds to ONE typed object output, never to flat primitive fields. (Reskin pattern: Salesforce's `trailheadapps/agent-script-recipes`.)
- **Reach:** as of the 2026-07-15 re-verification, Apex-based CLTs render across **four** channels — LEX desktop, Enhanced Chat v2 (Service agents), Mobile, Experience Builder. This lab uses Employee-Agent-in-LEX; the same bundle carries to Service/Mobile. Still not the HXL "one widget auto-renders on Slack/ChatGPT" vision — those stay per-surface builds.

---

[← Module 1](./01-educate.md) · [Overview](../../OVERVIEW.md) · [Module 3 →](./03-connect-claude-mcp.md)
