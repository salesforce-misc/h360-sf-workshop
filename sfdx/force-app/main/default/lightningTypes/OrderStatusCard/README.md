# OrderStatusCard — Custom Lightning Type (Surface #3)

A `LightningTypeBundle` (API 64.0+) that renders the `OrderStatusSkill.Response` as a rich card INSIDE the agent
conversation. This lab uses **Employee-Agent-in-Lightning-Experience**, but per the 2026-07-15 re-verification Apex-based
CLTs are **no longer LEX-only** — they also render on Enhanced Chat v2 (Service), Mobile, and Experience Builder.

- `schema.json` — references the Apex inner class directly: `"lightning:type": "@apexClassType/c__OrderStatusSkill$Card"`
  (the `OrderStatusSkill.Card` display shape). This is the binding — no manual step needed.
- `lightningDesktopGenAi/renderer.json` — points at the renderer LWC `c/orderStatusCard`.
- The renderer LWC meta declares `<sourceType name="c__OrderStatusCard" />` under `lightning__AgentforceOutput`.
- The `.agent` action exposes a `card: object` output with `complex_data_type_name: "c__OrderStatusCard"` +
  `is_displayable: True`. That displayable object output is what the runtime renders as the card.

> **Why an object, not the flat fields?** A CLT binds to ONE object output referencing an Apex class — flat
> primitive outputs cannot be bound (silent text fallback). `OrderStatusSkill.Response` therefore carries both:
> the flat fields (for the agent's text reasoning) AND a `card` object (the CLT-displayable output). Pattern
> verified against Salesforce's `trailheadapps/agent-script-recipes` customLightningTypes example (2026-07-23).

⚠️ **Naming must line up** (bundle / schema / renderer / LWC) — on a mismatch the conversation **silently falls back to
plain text** (no error). That's the #1 CLT gotcha.

The renderer LWC (`c/orderStatusCard`) lives under `../../lwc/orderStatusCard/` — a styled card + one action button
(`orderStatusCard.js/.html/.js-meta.xml`, target `lightning__AgentforceOutput`). **It is committed to source and deploys
with the reference build** (added 2026-07-21; renderer + LWC + schema all deploy 10/10 clean).
