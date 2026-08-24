# Module 2 — The Capability: deploy + guided tour

**Phase:** 2 · Reference Build · **Goal:** tour the one pre-built capability every surface will reach + run one query · **Time:** ~30 min · **Done when:** the OR-1003 query returns the real record and the rich card renders

You are about to **tour** the one reference capability every surface will reach — an Employee Agent + an Apex `@InvocableMethod` Skill over `Order__c` + its in-conversation rich card (CLT). This is "build the capability once" made concrete on screen, and it front-loads the one true ordering gate: the agent is **deployed + published + activated** here, so Connect / React / Slack later just plug in.

> **Your org ships pre-deployed.** The metadata + permset are deployed, the agent is published + activated, the 5 hero records are seeded, and the CLT renders. Steps 1–3 below are that pre-deployment (reference detail); if you self-provision, run `./scripts/06-org-onboard.sh`. In-room, this module is a **guided tour + one hands-on query** (step 4), not a live build.

## Steps

1. **Deploy the metadata.** Run these two, one at a time — first the deploy:

   ```bash
   ./scripts/02-deploy.sh --org <alias>
   ```

   Then assign the permset:

   ```bash
   ./scripts/03-assign-perms.sh --org <alias>
   ```

   `02-deploy.sh` runs a **3-phase sequence** (metadata → `sf agent publish` + `activate` → permset last — see step 2 for why order matters) and deploys the `Order__c` object, the **Order tab + page layout** (all 5 fields — so the record is viewable in the UI; these were manual clicks in the reference org, now in metadata), the `OrderStatusSkill` `@InvocableMethod` (queries `Order__c` `WITH USER_MODE` → real status + next action + record Id, CLT-eligible), the Slack action, and the permset (Order__c object + field FLS **and** Order-tab visibility).

   ⚠️ **Deploying the permset does NOT assign it** — `03-assign-perms.sh` assigns it to the running user (assign it to each participant / Run-As user too). The Order__c FLS lives in the permset, so an unassigned user sees no fields / no tab.

   **Seed the 5 hero records** (OR-1001..OR-1005) — idempotent; run after `03-assign-perms.sh` so the permset FLS is in place (an unseeded org makes the agent answer "No order matches OR-1003"):

   ```bash
   ./scripts/05-seed-hero-data.sh --org <alias>
   ```

   The `Order__c` object ships an **All Orders** list view, so the rows appear on the tab immediately.

2. **Deploy + publish + activate the Employee Agent.** **`02-deploy.sh` already does this** (it's a 3-phase script: deploy metadata incl. the `.agent` bundle → `sf agent publish` + `sf agent activate` → deploy the permset last). The commands below are **what the script runs under the hood / how to do it by hand**. The agent ships as an **Agent Script bundle**, not UI-authored (`agentforce-adlc`) — the by-hand sequence, run one at a time.

   Deploy the authoring bundle:

   ```bash
   sf project deploy start --metadata AiAuthoringBundle:Headless360_Order_Assistant
   ```

   Publish it:

   ```bash
   sf agent publish authoring-bundle --api-name Headless360_Order_Assistant
   ```

   Activate it:

   ```bash
   sf agent activate --api-name Headless360_Order_Assistant
   ```

   **The compiled Bot + planner are NOT in source** — `publish` generates them; a `.forceignore` keeps them out. Agent type = **Employee** (`AgentforceEmployeeAgent`) — required for Slack + CLT + Agent API; no `default_agent_user`.

   🔴 **This is the one ordering gate:** everything downstream (Slack, React/Agent-API, the CLT render) needs the agent **published + activated**, not just deployed. The Agent API errors against an unpublished/inactive agent.

3. **The in-conversation rich card (CLT) is part of the capability.** The `OrderStatusCard` **`LightningTypeBundle`** (in the same package) is bound to the Skill's Apex output so the agent renders a rich card *inside* the conversation (LEX) — the **native/in-platform surface**, and the on-ramp to the HXL "render everywhere" vision (shown as a demo, not built live). How the binding works + the silent-text-fallback gotcha are in the **Capability internals** below.

4. **Tour it + run one query (the hands-on beat).** Walk the pieces on screen — the **Order tab** (list view + a record with all fields on the page — status, summary, next action), the `OrderStatusSkill` class, the agent's Topic/action wiring, the CLT — then **each participant runs one query** against the live agent:

   ```bash
   sf agent preview start --use-live-actions --authoring-bundle Headless360_Order_Assistant
   ```

   Ask *"what's the status of order OR-1003?"* → the agent invokes Get Order Status, returns the **real** record ("carrier exception… Approve rebooking"), and renders the **rich card** in LEX. Now everyone has touched the capability before wiring surfaces to it.

5. **Profile the cost** with `sf-flex-estimator` — estimate the Flex-credit weight of the action before scaling (shift-left consumption discipline).

### 🔴 Checkpoint 2 — activate + smoke-test + the card renders

- **Agent fires:** the OR-1003 query returns the real record. If the action doesn't fire, check the Topic/action wiring; if it returns "not found," the hero records aren't seeded. Full commands: [docs/build-and-deploy.md](../build-and-deploy.md) §3.
- **Card renders (not plain text):** two things must BOTH be true — the CLT is **bound** (single displayable object output typed to `c__OrderStatusCard`; renderer LWC meta declares `<sourceType>`; `schema.json` references the Apex inner class) **AND** the agent calls **`show_command`** on that output (not "compose as text"). After any `.agent` change: deploy → publish → activate → **fresh conversation**. (Verified 2026-07-23.)

### Capability internals (for the tour narrative + reskin)

- The CLT `schema.json` references the Skill's Apex inner class (`@apexClassType/c__OrderStatusSkill$Card`) + a `renderer.json` + renderer LWC (styled card + action button, meta declaring `<sourceType name="c__OrderStatusCard" />`).
- **The binding is metadata, not a manual click.** The action exposes a single displayable object output (`card: object`, `complex_data_type_name: "c__OrderStatusCard"`, `is_displayable: True`) — a CLT binds to ONE typed object output, never to flat primitive fields. (Reskin pattern: Salesforce's `trailheadapps/agent-script-recipes`.)
- **Reach:** as of the 2026-07-15 re-verification, Apex-based CLTs render across **four** channels — LEX desktop, Enhanced Chat v2 (Service agents), Mobile, Experience Builder. This lab uses Employee-Agent-in-LEX; the same bundle carries to Service/Mobile. Still not the HXL "one widget auto-renders on Slack/ChatGPT" vision — those stay per-surface builds.

---

[← Module 1](./01-educate.md) · [Overview](../../OVERVIEW.md) · [Module 3 →](./03-connect-claude-mcp.md)
