# Module 3 — Connect: Claude over Hosted MCP 🔴

**Phase:** 2 · Reference Build · **Goal:** reach the capability's org from an external LLM (Claude) over Hosted MCP, running as the signed-in user (FLS/sharing enforced) · **Time:** ~45 min · **Done when:** a real read returns your org data, governed by your FLS.

> **Standalone:** this reaches the object/Apex directly over MCP and does **not** require the agent — MCP and the agent are parallel paths to the same Skill.

**Helper** — this does the deterministic prep (deploy + permset + edition/LEX check) and prints an **exact-values card** for the External Client App below. The ECA itself stays a guided manual step — the Connect teaching moment.

**[Terminal]** — run from the **cloned repo root**:

```bash
./scripts/connect-mcp.sh --org <alias>
```

> 💡 **Self-guided, and you already ran `./scripts/onboard.sh`?** Add `--no-deploy` to skip the redundant full 3-phase re-deploy (onboard already did it — it's idempotent, just slow and noisy to repeat):
> ```bash
> ./scripts/connect-mcp.sh --org <alias> --no-deploy
> ```
> On a re-run you'll see `WARN: permset ... already assigned` — that's **expected and non-fatal** (onboard assigned it), not an error.

After you create the ECA, re-run with `--verify` to confirm the org is Connect-ready.

## Steps

### 1. Activate the MCP servers
Setup → Quick Find **`MCP Servers`** (under **API Catalog**) → **Salesforce Servers** → activate all five (order matches primary-first):

- [ ] `headless-360` (primary — the 4-tool server)
- [ ] `sobject-reads`
- [ ] `sobject-all`
- [ ] `salesforce-api-context`
- [ ] `metadata-experts`

The Headless 360 MCP Server (`platform/headless-360`, Beta) exposes **four tools — Discover → Describe → Dispatch / Dispatch-Read-Only** over one stable connection. Requires **API v67.0+**, an External Client App with the `mcp_api` scope, and per-user OAuth.

### 2. Create the MCP External Client App
**[Setup UI]** Setup → **External Client App Manager** → **New External Client App**. Walk the page **top to bottom** — the sub-steps below are in the order the screen presents them, so you never jump around. Each setting prevents a specific failure — do all of them.

1. **Basic Information**
   - **Name:** `Headless360 MCP Client`
   - **API Name:** `Headless360_MCP_Client`
   - 🔴 **Contact Email:** `<your email>` — a **required** field the older doc left out; you can't save the app without it. Use the verified email on your user.

2. **API (Enable OAuth Settings)** section → turn **Enable OAuth ON.** This is *where OAuth lives* — flip it on here and the OAuth fields (Callback URL, Scopes, Flow Enablement, Security) appear below it.

3. **Callback URL** — the **first OAuth field** on the page. Enter BOTH, one per line, no leading spaces, no trailing slash:
   ```
   https://claude.ai/api/mcp/auth_callback
   http://localhost:8765/callback
   ```
   🔴 Miss the second line → the Claude Code CLI fails `redirect_uri_mismatch`. Exact match — `http` (not `https`) on the loopback, lowercase `localhost` (not `127.0.0.1`).

4. **OAuth Scopes** — add EXACTLY these two (nothing else):
   - [ ] `Access Salesforce hosted MCP Servers (mcp_api)`
   - [ ] `Perform requests at any time (refresh_token, offline_access)`
   - 🔴 Do **NOT** add `api`, `openid`, or any extras — they can break the connection.

5. **Flow Enablement** — CHECK **"Enable Authorization Code and Credentials Flow."** 🔴 None are on by default; miss this and Claude can't complete auth. MCP uses **authorization_code + PKCE** (per-user). Do **not** enable JWT Bearer / Device / Token Exchange.

6. **Security** (states as they appear on the page):
   - **"Require secret for Web Server Flow"** — confirm it's **UNchecked** (public PKCE client; usually already unchecked).
   - **PKCE** — locked **ON** in the current UI; leave it.
   - 🔴 **CHECK "Issue JSON Web Token (JWT)-based access tokens for named users" — this is DEFAULT OFF and is the #1 silent gotcha.** With it off, OAuth *succeeds* (green connection) but **every MCP call fails** `INVALID_AUTH_HEADER` / `INVALID_JWT_FORMAT`. *(This is NOT "JWT Bearer Flow" — a different grant type you do not enable.)*

7. **Save/Create the app.** The new-app flow may show only a "Create" button — same action. If a "Confirm and Lock Security Controls" dialog appears with PKCE ON, confirm it (PKCE is wanted for MCP).

> This same screen-ordered structure (Basic Info + Contact Email → Enable OAuth → Callback URL first → Scopes → Flow Enablement → Security → Save) is reused for the **Agent-API ECA in Module 4c** — once you've done it here, the second one reads the same way.

### 3. Copy the Consumer Key
Settings → OAuth Settings → **Consumer Key** (= the OAuth Client ID Claude uses). 🔴 For MCP you need **only the Key — not the secret** (public PKCE client).

**Where it goes:** you paste this Key directly into the `claude mcp add --client-id <Consumer Key> …` command in Step 4. If you want to stash it first, put it in a **local, untracked scratch file** — one that's already `.gitignore`'d (e.g. a repo-local `secrets.local`), never a tracked file. 🔴 **Never commit the Key and never paste it into a public doc / canvas / repo.** MCP needs the **Key only — no secret**. Delete the scratch file when you're done (the org is throwaway).

> 🔒 **Incognito reveal — a standing rule for every trial-org Key/Secret reveal.** If revealing the Consumer Key loops on identity-verification, "insufficient privileges," or a stale MFA prompt (common on trial orgs) — **open the org in an incognito/private browser window and reveal from there.** A clean session (no cached SSO / other-org login) resolves most reveal failures. You can also complete the emailed verification code, or retry from a fresh `sf org open --target-org <alias>` session. This applies to **every** Key/Secret reveal on a trial org, including the Agent-API ECA Key **and** Secret in Module 4.

The app takes a few minutes to propagate — an `invalid_client_id` on the next step is propagation, not a mistake: wait and retry.

### 4. Connect Claude Code

**[Terminal] — run from the cloned repo ROOT** (`h360-sf-workshop/`). 🔴 The MCP servers you add are **project-scoped in `~/.claude.json`**; from a parent folder or anywhere else, `/mcp` shows **no** Salesforce server at all. `cd` into the repo first:

```bash
cd <your cloned repo>        # the repo root, e.g. .../h360-sf-workshop
```

Pick your client path (both work because Step 2 registered both callbacks):
- **Claude Code CLI** (loopback `localhost:8765/callback`) — no Claude-side admin toggle. Use this local MCP path if your Claude instance blocks web connectors.
- **claude.ai web / desktop** (`.../auth_callback`) — for an unmanaged instance that allows connectors.

Salesforce Hosted MCP does **not** support dynamic client registration, so pass the Consumer Key as a **static `--client-id`**, match `--callback-port` to the ECA loopback (**8765**), and use the exact endpoint. First drop any prior registration, then add it — both **[Terminal]** commands:

```bash
claude mcp remove h360 2>/dev/null
```

```bash
claude mcp add --transport http --client-id <YOUR_CONSUMER_KEY> --callback-port 8765 h360 https://api.salesforce.com/platform/mcp/v1/platform/headless-360
```

⚠️ **Endpoint gotcha:** note the **second `/platform/` segment**, and **no trailing slash** (single line — don't let it wrap). A **sandbox/scratch** org inserts `/sandbox/` before `platform/headless-360`. **No secret** (public PKCE). *(Validated key-only on a fresh trial org, 2026-08-16.)*

Now **launch Claude Code by running `claude` from the repo root** (or restart it if it's already open) so it picks up the server you just added — still in the **[Terminal]**:

```bash
claude
```

Then, **[inside Claude Code]** — `/mcp` is an in-session slash command, **not** a shell command:

```
/mcp
```

→ select `h360` → **Authenticate**. If auth doesn't complete first try, re-run after a short wait (propagation lag). ⚠️ Claude prompts you to approve each MCP tool call — approve them (or "always allow" for the session). Expected, not an error.

> 🔒 **SSO / `OAUTH_AUTHORIZATION_BLOCKED` on Authenticate?** If the auth step throws `OAUTH_AUTHORIZATION_BLOCKED: Cross-org OAuth flows are not supported for this external client app`, your default browser is carrying a cached Salesforce session for the **wrong org**. Force a clean login through incognito — **[Terminal]**:
>
> ```bash
> claude mcp login h360 --no-browser
> ```
>
> That **prints the authorization URL** instead of auto-opening it in your logged-in profile. Copy the URL, open it in a **fresh incognito window**, and sign into the **correct** org:
>
> ```bash
> open -na "Google Chrome" --args --incognito "<PASTE_URL_HERE>"
> ```
>
> (macOS/Chrome shown — on any OS, paste the URL into a new incognito/private window.) Incognito carries no Salesforce session, so you get a real login prompt; the callback still returns to `http://localhost:8765/callback` on the same machine and the CLI completes automatically. Same standing incognito rule as the Consumer-Key reveal in Step 3.

### 5. Confirm with a real read — the payoff

**[inside Claude Code]** type exactly:

```
read order OR-1003 from Salesforce
```

✅ **Success** = the agent returns the **real, FLS-governed order data** (OR-1003 — the Exception order) fetched via the `headless-360` tools, running as *you* with your FLS/sharing enforced. A "connected" green indicator alone does **not** prove the flow — a real record coming back does.

### 6. Try the `headless-360` four-tool workflow
- **`discover`** — semantic search: "what can I do with accounts?" → matching operations
- **`describe`** → pick one → full spec (APIs, params, dependencies, steps)
- **`dispatch_readonly`** → run it → org data, governed by your FLS/sharing
- **`dispatch`** → take an action (e.g. create a record); use sandbox — every action is attributed to you in the audit trail

This four-step sequence is the same pattern your agent uses at runtime.

### 7. (Optional) CLI-native verification — `sf agent mcp` (preview)
🔴 **Expect an EMPTY result here — that is NOT a failure.** `sf agent mcp list` shows only **externally-registered** servers (added via `sf agent mcp create --server-url …`). It does **not** list the Salesforce-Hosted `headless-360` server you activated in Setup (different path). Don't chase the empty table — your connection is already proven by the read above.

**[Terminal]** (from the repo root):

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
