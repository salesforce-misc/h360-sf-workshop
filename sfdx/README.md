# Reference-Build Metadata

The deployable core of the reference build: **one Employee Agent** (built in Agentforce Studio — see below) + one
Apex `@InvocableMethod` Skill, surfaced across three surfaces.

Deploy: `../scripts/steps/deploy.sh --org <alias>` then `../scripts/steps/assign-perms.sh --org <alias>`.

## What's here (static metadata)
- `objects/Order__c/` — the reference demo object the Skill queries (fields: `Order_Number__c` ext-id, `Status__c` picklist,
  `Status_Summary__c`, `Owner_Name__c`, `Next_Action__c`). Seed 5 hero records (OR-1001..OR-1005) — see below.
- `classes/OrderStatusSkill.cls` — the Skill: `@InvocableMethod` with Apex Request/Response classes (CLT-eligible).
  Queries `Order__c` (`WITH USER_MODE`) and returns real status + summary + next action + the record Id.
- `classes/SendSlackCardAction.cls` — Slack surface: posts a Block Kit card via `callout:Slack_API/chat.postMessage`,
  with a `url` button linking to the real `Order__c` record. Parses the Slack response body (200 ≠ success).
- `classes/*Test.cls` — Apex tests. `OrderStatusSkillTest` seeds + exercises the Skill **inside `System.runAs` a
  permset-assigned user** (NOT `@testSetup`) — because Order__c field FLS comes only from the permset, not the profile, so
  the deploying user can't insert/query those fields on a fresh org. Both classes run for the 75% gate.
- `aiAuthoringBundles/Headless360_Order_Assistant/` — **the agent, as Agent Script** (`.agent` bundle) — the **source of
  truth**, built with the `agentforce-adlc` skill; NOT UI-authored. The **compiled runtime** (`Bot` + `GenAiPlannerBundle`)
  is a **build output of `sf agent publish`** and is **deliberately NOT in source** — shipping it alongside the bundle
  collides on a fresh deploy (Bot + AiAuthoringBundle share a DeveloperName namespace). `steps/deploy.sh` handles
  the deploy → publish → activate → permset sequence.
- `lightningTypes/OrderStatusCard/` — the CLT (`LightningTypeBundle`): schema + renderer LWC (rich in-conversation card, LEX).
- `namedCredentials/` + `externalCredentials/` — `Slack_API` wiring: a **Custom External Credential + bearer bot token**
  (NOT an OIDC Auth Provider). Principal `Slack_Bot_Principal`, secret param `BotToken`. NC needs `allowMergeFieldsInHeader=true`
  + `generateAuthorizationHeader=false`. Secrets are org-config, NOT committed.
- `tabs/Order__c` + `layouts/Order__c-H360 Order Layout` — the **Order tab + page layout** (all 5 custom fields placed) so
  the record is viewable in the UI for the Module-2 tour. These were **manual clicks in the source org** — now in
  metadata so a fresh org shows the object+fields without hand-config. Tab visibility is granted by the permset (`tabSettings`).
- `permissionsets/Headless360_Workshop_Access` — Apex + Order__c object/FLS + Order-tab visibility + External Credential principal access.

## Deploy + seed
1. **One command (recommended):** `../scripts/onboard.sh --org <alias>` — guards Agentforce-enabled, then runs 02 → 03 → 05 → smoke. (Prereq: enable Agentforce on the org first — see [../docs/setup.md](../docs/setup.md).) Or run the steps by hand: `../scripts/steps/deploy.sh --org <alias>` → `../scripts/steps/assign-perms.sh --org <alias>` → `../scripts/steps/seed-hero-data.sh --org <alias>` (02 creates `Order__c` but does **not** seed data — 05 is a separate required step).
   (Or just the agent bundle: `sf project deploy start --metadata AiAuthoringBundle:Headless360_Order_Assistant`.)
2. Seed hero records (5 orders): `../scripts/steps/seed-hero-data.sh --org <alias>` (idempotent upsert of OR-1001..OR-1005, incl. the OR-1003 exception; run AFTER 03 so the permset FLS is in place). The object ships an **All Orders** list view, so the seeded rows show on the tab immediately.
3. Publish + activate the agent: `sf agent publish authoring-bundle --api-name Headless360_Order_Assistant` → `sf agent activate --api-name Headless360_Order_Assistant`.

## Built/configured in the org (not deployable secrets) — GUIDE Modules 2–6
- **External Client Apps:** the MCP ECA (`mcp_api`) for Module 3, and a **separate** Agent API ECA
  (`api`/`chatbot_api`/`sfap_api`, client_credentials + Run-As user) for Module 4. Created in Setup; not committed.
- **Slack bot token** pasted into the `Slack_API` External Credential's `BotToken` principal param (Module 5).
- The agent's **Topic + action wiring** and Slack connection can be finished in Agentforce Studio; the agent itself is
  the committed `.agent` bundle above (re-deploy + publish rather than re-author).
