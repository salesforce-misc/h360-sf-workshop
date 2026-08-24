# Module 6 — ChatGPT over MCP 🟡

**Phase:** 2 · Reference Build · **Goal:** reach the same org/Skill from ChatGPT exactly as Module 3 reached it from Claude · **Time:** ~30 min · **Done when:** ChatGPT returns real org data governed by your FLS

> 🟡 **Optional / time-permitting — skip if the clock is tight.**

This surface reuses the **same Hosted MCP surface as Module 3's Claude connection** — ChatGPT is simply a second **MCP client**, running as the signed-in user. This is a **CONNECT-level (text/data)** surface — it is **not** the (pre-release, gated) HXL rich-widget-in-ChatGPT render.

The point: reach the same org + Skill from **ChatGPT** exactly as Module 3 reached it from Claude — an external LLM calling a **Salesforce Hosted MCP server** over the MCP protocol (not REST, not a generic connector), governed by the signed-in user's FLS/sharing. This makes ChatGPT the 4th external surface and directly serves the Dreamforce goal ("expose Apex/Flows via a hosted MCP server, reach it from a surface — Slack, CLI, Web-React, **ChatGPT**").

**Why no bridge / no Ngrok:** the ChatGPT connector runs **server-to-server (OpenAI cloud → `api.salesforce.com`)**; only the OAuth login redirect touches the browser. So a constrained presenter network (e.g. CloudFlare blocking Slack) does **not** affect this path, and no tunnel is needed. *(A local MCP bridge over Ngrok is the fallback only if the direct OAuth handshake fails.)*

## Steps

1. **Pre-flight (do the day before — not live):**
   - ChatGPT account is **Plus / Pro / Business / Enterprise / Education** (developer mode is **not** on Free). Prefer a **personal Plus** account — Business/Enterprise workspaces can admin-gate connectors.
   - The org's **`sobject-reads`** standard MCP server is activated (Module 3 already does this). Read-only → its tools carry `readOnlyHint`, so ChatGPT won't prompt per-call write confirmations. Smoother live.

2. **Create an External Client App** for the ChatGPT connect (same recipe family as Module 3's ECA): OAuth ON; scopes **`mcp_api` + `refresh_token`**; **PKCE ON**; issue JWT-based tokens. Copy the **Consumer Key** (= OAuth Client ID). *(⚠️ confirm on your org whether ChatGPT's static-client path also needs the consumer **secret**, or just the key.)*

3. **In ChatGPT:** enable **developer mode** (Settings → Connectors/Apps), then **create a new app/connector**.

4. **Endpoint:** use `https://api.salesforce.com/platform/mcp/v1/sobject-reads` (sandbox/scratch: `.../v1/sandbox/sobject-reads`). *(⚠️ confirm the exact path on your org — Salesforce's ChatGPT setup page is authoritative over blog posts.)*

5. **Auth:** Advanced → Registration Method = **User-defined OAuth client** → paste the ECA **Consumer Key** as the OAuth Client ID. (Salesforce does **not** support Dynamic Client Registration; ChatGPT's user-defined static client is what makes the two compatible — PKCE lines up on both sides.)

6. **Wire the callback:** copy ChatGPT's generated callback URL (form `https://chatgpt.com/connector/oauth/{callback_id}`) into the ECA's **Callback URL**; save. **Allow ~30 min for propagation** — another reason to stage this the day before.

7. **Authorize:** enable the connector → ChatGPT redirects to the org login → sign in as the workshop user → approve.

8. **Demo the read:** in the composer, select the Salesforce connector under **+**, and ask a read prompt (e.g. *"what's the status of order OR-1003?"* or *"list my open high-value accounts"*). It returns **real org data, governed by that user's FLS/sharing** — the same Skill/data reachable from Claude in Module 3, now from ChatGPT.

### 🔴 Checkpoint 6

Confirm the connection returns real data. Things to confirm as you wire this up:

- **The OAuth handshake end-to-end**: does the static client need the consumer **secret** or just the key? Does ChatGPT's metadata discovery (`/.well-known/oauth-protected-resource`, `/.well-known/oauth-authorization-server`, `WWW-Authenticate` on 401, RFC 8707 `resource` echo) succeed against `api.salesforce.com`?
- **Account tier + workspace policy** (Free fails; managed workspaces may gate connectors).
- **The exact endpoint path** and **server naming** on the live org (the org shows `sobject-reads` activated — use that).

Salesforce's authoritative setup page: [developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/chatgpt.html](https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/chatgpt.html).

---

[← Module 5](./05-slack.md) · [Overview](../../OVERVIEW.md) · [Module 7 →](./07-fork.md)
