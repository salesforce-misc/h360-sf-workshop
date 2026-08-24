# Module 1 — Educate: the Headless 360 mental model

**Phase:** 1 · Educate · **Goal:** a shared mental model and vocabulary before anyone builds · **Time:** ~45–60 min (instructor-led) · **Done when:** you've mapped 2–3 of your own workflows to a tier.

Shared language before you build. (Instructor-led; ~45–60 min.)

- **The architecture:** four layers — Data 360 (context) · Business Logic (Apex/Flows as MCP tools) · Orchestration
  (Agentforce/ReAct) · the **Engagement Layer (HXL/AXL)** that targets any surface. The five systems: Data 360, Customer
  360, Agentforce, Tableau, **Slack (System of Engagement)**.
- **The north star:** the Engagement Layer's "define once, render everywhere" vision — author a **Widget** in JSON
  (with **Mosaic**) and render it across Agentforce, ChatGPT, and Slackbot. Learn its vocabulary
  (**Widget / Mosaic / Block / rendition**) so you recognize it when it reaches you. This is a **forward-looking vision,
  not partner-buildable today** — which is *exactly why* this lab builds each surface by hand.
- **The canonical partner path:** **Connect** (AF action via MCP/API) → **Extend** (Topics + Actions as certified IP) →
  **Scale** (full agent / A2A). The consumption test: the one objective is to drive Agentforce consumption.
- **Agentforce Vibes** — the agentic dev experience that connects Claude Code to the full Headless 360 stack (MCP tools,
  Skills, CLI, platform governance). Describe a capability in natural language; Vibes plans + executes using your org's
  metadata. Frame it as "where this goes" for partners who want idea-to-production without leaving the terminal.
  Docs: https://developer.salesforce.com/docs/platform/agentforcevibes/overview
- **The [Three-Tier UX framework](../reference/three-tier-framework.md):** Conversational · Rich Conversational · Full Rich UI.
- **Honest buildability:** what's GA today vs. the HXL/AXL vision; the agent-type gates; the `@AuraEnabled` caveat.
- **Distribution:** how partner IP reaches a customer's org. **Headless is available today, at no packaging cost, and it
  puts the customer in control.** Your **take-home Skill (Module 7)** is distributed via the **AI-assisted (Skills)** path.
  The key reframe: because the **customer assembles** the server definition, it's **version-independent — a feature, not a
  limitation**. Two personas drive it — the **admin** (builds the definition using partner Skills from Agent Exchange) and
  the **end customer** (consumes via Claude/OpenAI through an External Client App). See a partner's timecard capability as
  a worked example.

**Interactive:** each partner maps **2–3 of their own workflows** to a tier (Tier 1/2/3) and notes the surface each would
live on. This mapping is the **Phase-3 ideation seed** — it becomes the spec for the capability you fork and take to Dreamforce.

> **Name the reframe here (so it's a feature, not a gap).** The reference agent is **pre-deployed** — you won't build it
> live. That's deliberate: the transferable skill is **reaching one governed capability from every surface** and
> **forking your own**, not rebuilding a throwaway sample. The build shifts (to surface-wiring + your fork), it doesn't
> vanish — and you leave with a cross-surface capability that's yours, not a demo you'll never reuse.

### 🔴 Checkpoint 1
Each partner has named **2–3 of their own workflows** and assigned each a tier (Tier 1/2/3) plus the surface it would
live on. This is the **Phase-3 ideation seed** — the spec for the capability you'll fork and take to Dreamforce.

---

[← Module 0](./00-prereqs-and-comprehend.md) · [Overview](../../OVERVIEW.md) · [Module 2 →](./02-capability.md)
