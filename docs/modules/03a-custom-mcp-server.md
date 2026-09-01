# Module 3a — Assemble a Custom MCP Server (Setup-composed) 🟡

**Phase:** 2 · Reference Build · **Goal:** compose your own MCP server in Setup from your org's building blocks, then reach it from Claude · **Time:** ~20 min · **Done when:** Claude `discover`/`dispatch_readonly` your custom server returns OR-1003 via your Apex

> 🟡 **Optional / time-permitting — skip if the clock is tight.**

Module 3 connected you to the Salesforce-provided **`headless-360`** server. This beat flips it around: you **compose your own** MCP server in Setup from your org's building blocks — no server code shipped. It's the **"admin assembles the server"** distribution path, sitting between *use the standard server* (M3) and *package a full solution* (M8).

This is the **Setup-composed** server (built from actions your org already has) — distinct from *registering an external* MCP server via `sf agent mcp create --server-url …` (Module 3, step 6). Different path, different purpose.

## Steps

1. **Create the server:** Setup → Quick Find `MCP Servers` (under **API Catalog**) → **Custom Servers** → **New** (this is an `McpServerDefinition`). Name it e.g. `Order_Concierge`. *(Custom MCP Servers are Beta — verify the exact tab/label in Setup at workshop time; UI drifts release-to-release.)*

2. **Add your Apex action:** include the **`OrderStatusSkill`** `@InvocableMethod` you deployed in Module 2 — the same code path the agent uses, now exposed as an MCP tool.

   🔴 **`OrderStatusSkill` must be `global`, or it won't appear in the action picker.** A Salesforce-hosted MCP server auto-exposes only **`global`** `@InvocableMethod` classes; a **`public`** class isn't selectable unless you register it in **Setup → API Catalog** first. The shipped class is already `global` (class + `getStatus` + the `Request` / `Response` / `Card` inner classes and their `@InvocableVariable` fields — Apex requires the whole chain to be `global` once the method is). If you reskinned it back to `public with sharing`, promote the chain to `global with sharing` (and re-deploy) before this step. Everything else the exposure needs — `static` method, `WITH USER_MODE`, a `label` + `description` on `@InvocableMethod`, a single `List<Request>` parameter — the class already satisfies.

3. **Add a Flow + standard tools:** include a simple autolaunched Flow (e.g. status-lookup / "approve rebooking") and a standard tool (e.g. `sobject-reads`) so the server genuinely mixes **Flow + Apex + standard tools** — the composed-server pattern.

4. **Activate** it. It's reachable over the **same ECA / `mcp_api` OAuth** you configured in Module 3 — **no new credential** and the same JWT toggle applies.

5. **Point Claude at your custom server (new URL → re-register → re-auth).** Your `Order_Concierge` server has its **own endpoint** — different from the hosted `headless-360` one you registered in Module 3 — so Claude needs a fresh registration; the OAuth (ECA, Consumer Key, JWT toggle, callback port `8765`) is unchanged.

   Copy the exact URL from the UI: on the **MCP Server Setup** page for `Order_Concierge`, click the **arrow (▸)** on the server row → **Copy Server URL**. Then re-register in Claude Code with a distinct name (so both servers can coexist):

   ```bash
   claude mcp remove order-concierge 2>/dev/null
   ```
   ```bash
   claude mcp add --transport http --client-id <YOUR_CONSUMER_KEY> --callback-port 8765 order-concierge <PASTE_COPIED_SERVER_URL>
   ```

   Then `/mcp` → `order-concierge` → **Authenticate**. Use the **same Consumer Key** from Module 3 (no new credential); paste the URL exactly (no trailing slash). If auth throws an SSO / `OAUTH_AUTHORIZATION_BLOCKED` error, use the **incognito workaround** from [Module 3](./03-connect-claude-mcp.md#4-connect-claude-and-confirm-with-a-real-read).

6. **Test from Claude** the same four-tool way as M3, but the tools are now **yours**: `discover` on `order-concierge` → `describe` → `dispatch_readonly` → `dispatch`.

### 🔴 Checkpoint 3a — your own server answers
From Claude, `discover` on your custom server should list your composed tools (the `OrderStatusSkill` / Flow); then `dispatch_readonly` **OR-1003** → returns the real record **via your Apex**, governed by your FLS/sharing. Same run-as / JWT rules as Module 3 — if calls fail `INVALID_AUTH_HEADER`, it's the JWT toggle (Checkpoint 3), not the server.

> ⚠️ **Not packageable (today).** A Setup-composed custom MCP server (`McpServerDefinition`) is created **per-org in Setup** and is **not** included in a managed/unlocked package — so this is an admin-assembly path, not a shippable artifact. If you need a distributable capability, that's the packaging take-home (Module 8). *(Re-verify at workshop time — Beta.)*

---

[← Module 3](./03-connect-claude-mcp.md) · [Overview](../../OVERVIEW.md) · [Module 4 →](./04-custom-ui.md)
