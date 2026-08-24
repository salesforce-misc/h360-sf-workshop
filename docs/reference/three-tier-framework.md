# The Three-Tier UX Decision Framework (Phase 1 · Educate core)

The reusable intellectual IP partners take home. **The ISV decision is not "rich UI vs. conversational."** That framing is
a false choice. The reality: some task types genuinely need a full interface; others create needless friction for users who
never needed a browser. **The ISV's job is to know the difference — and to build clean, context-preserving hand-offs
between tiers.** That judgment is an ISV value no generic LLM can replicate.

## The three questions

Map any workflow to a tier by asking:
1. **Where does this user live day-to-day?** (Slack? A mobile device in the field? The Salesforce app itself?)
2. **How many data points do they need at once?** (One record? A short comparison? A dense grid?)
3. **Is the action high-stakes or irreversible?**

## The tiers

| Tier | Pattern | Personas | When to use | Build with |
|------|---------|----------|-------------|-----------|
| **1 — Conversational** | Agent text response | Field technician, sales rep on the go, warehouse worker, driver | Status checks, summaries, alerts, single-record lookups — users in motion who need a fast answer + one action | MCP → Agentforce → any LLM surface |
| **2 — Rich Conversational** | Agent response **+ Block Kit card / carousel / alert** (Slack), card (ChatGPT), adaptive card (Teams) | CSR, account exec, ops manager, frontline supervisor | Record previews, approvals, action prompts, short comparisons — users in flow of work who need context before acting, but not the full app | The agent action returns structured data + an explicit rich render per surface (Slack Apex Block Kit action; CLT in LEX) |
| **3 — Full Rich UI** | Conversational **front door → hand-off to LEX** (deep link / inline panel) | Admin, RevOps analyst, PM, compliance officer, business analyst | Data viz, complex config, bulk grid management, drag-and-drop authoring — users whose job *is* the application | LWC / LEX — the agent surfaces a deep link or opens an inline panel |

## Where rich UI is still a moat (Tier 3)

Certain tasks require a full interface regardless of how good conversation gets — because the cognitive load of *recall*
(conversation) is far higher than *recognition* (seeing options on screen):
- **Data visualization** — dashboards, capacity planning, scheduling boards (spatial + simultaneous comparison).
- **Multi-step configuration** — setup wizards, compliance onboarding (branching logic, persistent state).
- **Dense record management** — order queues, service backlogs (a data grid; text doesn't scale past a handful).
- **Drag-and-drop authoring** — Kanban, journey builders (no conversational equivalent today).

For these, **the agent's job is to get the user to the right page efficiently — not to replace the page.** Start with a
natural-language prompt, resolve to the right filtered view in LEX with context intact. For ISVs whose value *is* the
visual layer, that UI is a differentiator worth protecting.

## Conversational UX is no longer just text (Tier 2)

New inline rich primitives (cards, carousels, alerts embeddable in agent responses) let conversational surfaces render
structured, interactive UI. A workflow that used to require "open the app → navigate to a queue → find the record → click
approve" can now happen entirely inside a Slack message. The full page still exists for complex review; the agent handles
the routine action in-flow. **This is where most ISVs find their highest-leverage opportunity: don't replace your core UI —
eliminate unnecessary navigation for high-frequency, narrow tasks.**

## Design for modality constraints

Agentforce supports **one modality at a time**; in voice mode, rich components strip to plain text. So:
- **Design plain text as the base layer of every agent response.** Rich components (cards, interactive actions) are
  **progressive enhancement**, not the foundation.
- Field/frontline personas can't assume a visual surface — the response must be coherent and complete as text first.
- Architect MCP actions to **return structured data** that each surface renders appropriately, rather than hardcoding a
  format optimized for one modality.

## How the workshop applies it

This framework runs across all three phases of the technical arc (**Educate → Reference Build → Apply-to-POC**, the
phases in [OVERVIEW.md](../../OVERVIEW.md)):
- **Educate (Phase 1)** teaches the framework — and each partner maps **2–3 of their own workflows** to a tier (the
  ideation seed that feeds Phase 3).
- **Reference Build (Phase 2)** *applies* it — the same Skill is rendered as Tier-2 (Slack Block Kit card), Tier-1/2
  (React via Agent API), and Tier-3 (a rich CLT card / LEX hand-off), so partners see the tier decision made concretely.
- **Apply-to-POC (Phase 3)** *transfers* it — partners fork the reference Skill to their own capability, choosing the tier
  and surfaces from their Phase-1 mapping. That mapping stops being a take-home and becomes the spec for their DF POC.
