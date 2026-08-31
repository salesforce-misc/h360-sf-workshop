# Module 3 — Connect: Claude over Hosted MCP 🔴

**Phase:** 2 · Reference Build · **Goal:** reach the capability's org from an external LLM (Claude) over Hosted MCP, running as the signed-in user (FLS/sharing enforced) · **Time:** ~45 min · **Done when:** a real read returns your org data, governed by your FLS.

> **Standalone:** this reaches the object/Apex directly over MCP and does **not** require the agent — MCP and the agent are parallel paths to the same Skill.

**Helper** — this does the deterministic prep (deploy + permset + edition/LEX check) and prints an **exact-values card** for the External Client App below. The ECA itself stays a guided manual step — the Connect teaching moment.

```bash
./scripts/connect-mcp.sh --org <alias>
```

After you create the ECA, re-run with `--verify` to confirm the org is Connect-ready.

## Steps

### 1. Activate the MCP servers
Setup → Quick Find **`MCP Servers`** (under **API Catalog**) → **Salesforce Servers** → activate **`headless-360`**. Also activate: `sobject-reads`, `sobject-all`, `salesforce-api-context`, `metadata-experts`.

The Headless 360 MCP Server (`platform/headless-360`, Beta) exposes **four tools — Discover → Describe → Dispatch / Dispatch-Read-Only** over one stable connection. Requires **API v67.0+**, an External Client App with the `mcp_api` scope, and per-user OAuth.

### 2. Create the MCP External Client App
Setup → **External Client App Manager** → **New External Client App**. Each setting prevents a specific failure — do all of them.

- **Name / API Name:** `Headless360 MCP Client` / `Headless360_MCP_Client`
- **Enable OAuth: ON.**
- **Flow Enablement — CHECK "Enable Authorization Code and Credentials Flow."** 🔴 None are enabled by default; miss this and Claude can't complete auth. MCP uses **authorization_code + PKCE** (per-user). Do **not** enable JWT Bearer / Device / Token Exchange.
- **Callback URLs — enter BOTH, one per line, no leading spaces, no trailing slash:**
  ```
  https://claude.ai/api/mcp/auth_callback
  http://localhost:8765/callback
  ```
  🔴 Miss the second line → the Claude Code CLI fails `redirect_uri_mismatch`. Exact match — `http` (not `https`) on the loopback, lowercase `localhost` (not `127.0.0.1`).
- **OAuth Scopes — add EXACTLY these two:** `Access Salesforce hosted MCP Servers (mcp_api)` and `Perform requests at any time (refresh_token, offline_access)`. 🔴 Do **not** add `api`, `openid`, or extras — they can break the connection.
- **PKCE is ON** (locked in current UI — leave it).
- **Confirm "Require secret for Web Server Flow" is UNchecked** (usually already is).
- 🔴 **CHECK "Issue JSON Web Token (JWT)-based access tokens for named users."** THE #1 SILENT GOTCHA. With this OFF, OAuth *succeeds* (green connection) but **every MCP call fails** `INVALID_AUTH_HEADER` / `INVALID_JWT_FORMAT`. It's frequently off by default. *(This is NOT "JWT Bearer Flow" — a different grant type you do not enable.)*

**Create/Save.** The new-app flow may show only a "Create" button — same action. If a "Confirm and Lock Security Controls" dialog appears with PKCE ON, confirm it (PKCE is wanted for MCP).

### 3. Copy the Consumer Key
Settings → OAuth Settings → **Consumer Key** (= the OAuth Client ID Claude uses). 🔴 For MCP you need **only the Key — not the secret** (public PKCE client).

> 🔒 **If revealing the Consumer Key loops on identity-verification, "insufficient privileges," or a stale MFA prompt** (seen on trial orgs) — **open the org in an incognito/private browser window and reveal from there.** A clean session (no cached SSO / other-org login) resolves most reveal failures. You can also complete the emailed verification code, or retry from a fresh `sf org open --target-org <alias>` session.

The app takes a few minutes to propagate — an `invalid_client_id` on the next step is propagation, not a mistake: wait and retry.

### 4. Connect Claude and confirm with a real read

Pick your client path (both work because step 2 registered both callbacks):
- **Claude Code CLI** (loopback `localhost:8765/callback`) — no Claude-side admin toggle. Use this local MCP path if your Claude instance blocks web connectors.
  🔴 **Launch Claude Code from the cloned repo directory** (`h360-sf-workshop/`), not a parent folder — the MCP servers you add are **project-scoped** in `~/.claude.json`; from the wrong directory `/mcp` shows no Salesforce server at all. `cd` into the repo first.
- **claude.ai web / desktop** (`.../auth_callback`) — for an unmanaged instance that allows connectors.

Add the server. Salesforce Hosted MCP does **not** support dynamic client registration, so pass the Consumer Key as a **static `--client-id`**, match `--callback-port` to the ECA loopback (**8765**), and use the exact endpoint. First drop any prior registration:

```bash
claude mcp remove h360 2>/dev/null
```

Then add it (single line — do not let it wrap or add a trailing slash):

```bash
claude mcp add --transport http --client-id <YOUR_CONSUMER_KEY> --callback-port 8765 h360 https://api.salesforce.com/platform/mcp/v1/platform/headless-360
```

⚠️ **Endpoint gotcha:** note the **second `/platform/` segment**, and **no trailing slash**. A **sandbox/scratch** org inserts `/sandbox/` before `platform/headless-360`. **No secret** (public PKCE). *(Validated key-only on a fresh trial org, 2026-08-16.)*

Then `/mcp` → `h360` → **Authenticate**. If auth doesn't complete first try, re-run after a short wait (propagation lag).

**Run one real read** — e.g. `getUserInfo`, or ask Claude to read a record via `sobject-reads`. It should return your identity/data governed by your FLS/sharing. A "connected" indicator alone does **not** prove the flow. ⚠️ Claude prompts you to approve each MCP tool call — approve them (or "always allow" for the session). Expected, not an error.

### 5. Try the `headless-360` four-tool workflow — the payoff
- **`discover`** — semantic search: "what can I do with accounts?" → matching operations
- **`describe`** → pick one → full spec (APIs, params, dependencies, steps)
- **`dispatch_readonly`** → run it → org data, governed by your FLS/sharing
- **`dispatch`** → take an action (e.g. create a record); use sandbox — every action is attributed to you in the audit trail

This four-step sequence is the same pattern your agent uses at runtime.

### 6. (Optional) CLI-native verification — `sf agent mcp` (preview)
🔴 **Expect an EMPTY result here — that is NOT a failure.** `sf agent mcp list` shows only **externally-registered** servers (added via `sf agent mcp create --server-url …`). It does **not** list the Salesforce-Hosted `headless-360` server you activated in Setup (different path). Don't chase the empty table — your connection is already proven by the read above.

```bash
sf agent mcp list
```
```bash
sf agent mcp fetch --mcp-server-id <id>
```
```bash
sf agent mcp create --server-url <endpoint>
```
⚠️ Preview (label/behavior may change). Use this group only if you're exploring the external MCP-registration path.

### 🔴 Checkpoint 3 — the JWT gotcha
If MCP calls fail `INVALID_AUTH_HEADER` / `INVALID_JWT_FORMAT`, the ECA is missing **"Issue JWT-based access tokens for named users."** OAuth appears to succeed but calls fail — fix and re-auth with a fresh token. If `invalid_client_id`, the app hasn't propagated — wait and retry. **Verify:** `discover` on `headless-360`, then `dispatch_readonly` an operation → returns FLS-governed data. Fallback: read a record via `sobject-reads` if `headless-360` hasn't propagated yet. More symptoms → [ISSUES.md](../ISSUES.md).

---

[← Module 2](./02-capability.md) · [Overview](../../OVERVIEW.md) · [Module 3a →](./03a-custom-mcp-server.md)
