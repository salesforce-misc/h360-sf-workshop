# Module 7 — Fork your own capability

**Phase:** 3 · Apply to Partner POC · **Goal:** reskin the reference Skill to your own product capability · **Time:** take-home · **Done when:** your capability answers on your own data

> **This phase is where the workshop pays off** — it's the third act every partner drives toward. Ideate first (which capability, which tier, which surfaces, which distribution path — from your Phase-1 tier mapping), then fork, then package. Modules 7–8 are labeled *optional/take-home* — the ideation and the fork carry the work forward.

Reskin the reference Skill to **your own capability**: swap `OrderStatusSkill` for your product's equivalent (a status + one action), retarget the surfaces, and swap `config/kit.json` `partner_overlay`. **This is the Dreamforce payoff** — your own cross-surface capability, ready for the showcase. (Do this *before* Package — you package what you've forked.)

## Steps

1. **Ideate first — pick the capability.** From your Phase-1 tier mapping, choose one workflow: which capability, which tier, which surfaces, which distribution path. Keep it to a **status + one action** (the same shape as the reference `OrderStatusSkill`) so it stays forkable in take-home time.

2. **Reskin the Skill.** Swap `OrderStatusSkill` for your product's equivalent — your object, your query, your "real status + next action + record Id" output. Keep the same structure: an Apex `@InvocableMethod` that queries `WITH USER_MODE` and returns a single displayable object output bound to your card. The binding pattern, the CLT `schema.json` / `renderer.json` wiring, and the silent-text-fallback gotcha are all in the capability internals — see [Module 2](./02-capability.md).

3. **Retarget the surfaces.** Point the surfaces you wired in Phase 2 at your new Skill — Claude over MCP, the React app over the Agent API, Slack, the in-conversation card, ChatGPT. The wiring is identical; only the capability behind it changes.

4. **Swap the kit overlay.** Update `config/kit.json` `partner_overlay` so the kit reflects your product's naming and capability instead of the reference order-status one. **[Terminal]** — run from the `sfdx/` project directory:
   ```bash
   sf project deploy start --source-dir force-app --org <alias>
   ```

5. **Verify against your own data.** Run the agent and ask for one of your records — it should invoke your forked Skill, return your product's real status + next action, and render your card. **[Terminal]** — run from the `sfdx/` project directory:
   ```bash
   sf agent preview --use-live-actions --authoring-bundle <your-authoring-bundle> --target-org <alias>
   ```

### 🔴 Checkpoint 7
Your **forked Skill returns your product's status + one action** — the agent invokes *your* `@InvocableMethod` against *your* object, returns the real record (status + next action), and renders your card. That's your own cross-surface capability, ready for the Dreamforce showcase — and the thing you package in Module 8.

---

[← Module 6](./06-chatgpt.md) · [Overview](../../OVERVIEW.md) · [Module 8 →](./08-package.md)
