# Build & Deploy Guide — the four surfaces

> 🔑 **The credential setups (two ECAs + the Slack token) are gotcha-dense — follow the step-by-step
> [ISSUES.md](./ISSUES.md) for those.** This guide covers the surrounding build.

Attendee-facing, hands-on build/deploy for the Headless 360 reference apps. Assumes a **pre-configured participant
org** (Agentforce + Hosted MCP + reference build deployed). A **Slack workspace connection is optional (on request)** —
5–7 shared Slack orgs will be available for teams that want the Slack surface. Pairs with [OVERVIEW.md](../OVERVIEW.md) (module narrative).

> **Note on ordering:** this is a **deploy-dependency** guide (Skill/agent foundation first, then surfaces) — it does
> **not** match the GUIDE's participant *teaching* order (capability-first, reordered 2026-07-29). In the GUIDE the
> agent+Skill+CLT are **pre-deployed + toured as "The Capability" (Module 2)**; §1/§3/§6 below are that pre-stage. Module
> tags in the headings are updated to the new numbering. Validated end-to-end on the reference org.

> **Provisioning status (read first):**
> - **Participant orgs** — pre-configured by Partner Solutions: reference build deployed, permset assigned, hero
>   `Order__c` records seeded, MCP servers activatable. You log in and build.
> - **Slack workspaces — optional, on request.** Slack (Module 5) is opt-in; **5–7 shared Slack orgs** will be available
>   for teams that want it (a single workspace caps at 5 connected Salesforce orgs). Use a **standard (non-Enterprise-Grid) workspace** where
>   you're admin — Grid orgs gate custom-app tokens and pre-seed IP allowlists (see the Module 5 gotchas).

---

## 0. One-time setup

```bash
sf org login web --alias <your-alias>       # your workshop org (from template 0TTHo0000036iOl)
cd sfdx && sf config set target-org <your-alias>   # agent CLI runs from the DX project dir
```
Confirm the reference build is present: `sf data query -q "SELECT Order_Number__c, Status__c FROM Order__c ORDER BY Order_Number__c"` → 5 rows (OR-1001..OR-1005). If empty, deploy + seed per [sfdx/README.md](../sfdx/README.md).

---

## 1. The Skill + hero data (foundation for everything)

The whole workshop rides on **one Skill** — `OrderStatusSkill`, an `@InvocableMethod` that queries `Order__c` and
returns status + summary + next action + the record Id. It's already deployed. To verify it returns real data:

```bash
sf apex run --file /dev/stdin <<'APEX'
OrderStatusSkill.Request q = new OrderStatusSkill.Request(); q.orderNumber='OR-1003';
OrderStatusSkill.Response r = OrderStatusSkill.getStatus(new List<OrderStatusSkill.Request>{q})[0];
System.debug('found='+r.found+' status='+r.status+' action='+r.availableAction+' id='+r.recordId);
APEX
```
Expect `found=true status=Exception action=Approve rebooking id=<18-char>`. Reskin note: point the SOQL at your own
object; the Request/Response contract stays the same.

---

## 2. Connect — reach the org from Claude over MCP (GUIDE Module 3)

**No code.** Activate the Hosted MCP servers + create the MCP External Client App, then connect Claude.

- **MCP ECA scopes:** `mcp_api` + `refresh_token` (+ `offline_access`). **Do NOT add `api` or `openid`** — extra scopes
  can break the connection. MCP supports **Auth Code + Client Credentials only** (not JWT Bearer). Enable PKCE.
- **Both callback URLs** on the ECA (one per line):
  - `https://claude.ai/api/mcp/auth_callback` (claude.ai web/desktop)
  - `http://localhost:8765/callback` (Claude Code CLI loopback — else `redirect_uri_mismatch`)
- **CHECK** "Issue JWT-based access tokens for named users" (else `INVALID_JWT_FORMAT`).
- 🔴 **Launch Claude Code from the project directory** — the h360 MCP servers are project-scoped in `~/.claude.json`;
  from a parent dir `/mcp` shows no server.
- Helper: `./scripts/connect-mcp.sh --org <alias>` prints an exact-values ECA card; `--verify` confirms.
- **Test:** in Claude, `read order OR-1003 from Salesforce` → real data, running as the signed-in user (FLS/sharing enforced).

---

## 3. The Employee Agent (part of the pre-built Capability — GUIDE Module 2)

The agent ships as an **Agent Script bundle** (`aiAuthoringBundles/Headless360_Order_Assistant`) — don't hand-author it.

```bash
# from sfdx/
sf project deploy start --metadata AiAuthoringBundle:Headless360_Order_Assistant
sf agent publish authoring-bundle --api-name Headless360_Order_Assistant
sf agent activate --api-name Headless360_Order_Assistant
# smoke test in conversation:
sf agent preview start --use-live-actions --authoring-bundle Headless360_Order_Assistant
```
Agent type MUST be **Employee** (`AgentforceEmployeeAgent`) — the one type that works for Slack, the Agent API, and CLT.
No `default_agent_user` on an employee agent (causes "Internal Error" on publish).

---

## 4. Surface — Slack (Block Kit card) (GUIDE Module 5)

**Slack side (you, as workspace admin):**
1. api.slack.com/apps → **Create New App** → your workspace. **Bot Token Scopes:** `chat:write`, `channels:read`
   (+ `chat:write.public` to post without inviting the bot to each channel).
2. **Install to Workspace** → copy the **Bot User OAuth Token** (`xoxb-…`).
3. 🔴 **Validate the token before touching Salesforce:**
   `curl -s -H "Authorization: Bearer <xoxb-…>" https://slack.com/api/auth.test` → must be `{"ok":true}`.
   - `invalid_auth` = bad token **OR disallowed source IP**. Check the app's **OAuth & Permissions → "Restrict API Token
     Usage"** allowlist — clear it (the org callout egresses from Salesforce IPs, not yours). A phone hotspot isolates IP
     vs. token. This is **not** a Grid admin gate.

**Salesforce side:**
4. Setup → Named Credentials → External Credentials → **Slack API** → Principals → edit **`Slack_Bot_Principal`** →
   Authentication Parameters → add **Name=`BotToken`, Value=`xoxb-…`** (no `Bearer` prefix). The reference build uses a
   **Custom External Credential + bearer bot token**, NOT an OIDC Auth Provider (Slack's OAuth v2 bot flow has no
   `id_token` → OIDC fails "We can't log you in").
5. **Test** (anonymous Apex, or via the agent Topic):
   ```bash
   sf apex run --file /dev/stdin <<'APEX'
   SendSlackCardAction.Request r = new SendSlackCardAction.Request();
   r.channel='<CHANNEL_ID>'; r.orderNumber='OR-1003'; r.status='Exception';
   r.summary='Order OR-1003 hit a carrier exception - address needs confirmation.';
   r.availableAction='Approve rebooking';
   r.recordId=[SELECT Id FROM Order__c WHERE Order_Number__c='OR-1003'].Id;
   System.debug(SendSlackCardAction.send(new List<SendSlackCardAction.Request>{r})[0].detail);
   APEX
   ```
   Expect `posted (HTTP 200, ok:true)` and a card in the channel. `/invite` the bot if `not_in_channel`.
   The card's "view record" button uses the browser's **active Salesforce session** — be logged into the demo org.

---

## 5. Surface — React web app (Agent API) (GUIDE Module 4)

The partner's own web app driving the agent over the headless Agent API. Architecture: the **browser calls a backend
proxy** (`web/proxy.mjs`) that holds the token server-side and forwards to the Agent API — the real partner pattern
(the token must never live in browser JS; the Agent API sends no browser CORS headers).

**Create the Agent API ECA (separate from the MCP one):**
- **Scopes:** `api`, `chatbot_api`, `sfap_api` (+ `refresh_token`, `offline_access`) — NOT `mcp_api`.
- **Flow:** Client Credentials. **Run As** a user with **Salesforce API Integration** (PSL, = the old "API Enabled")
  **+ "Access Agentforce Default Agent"** (formerly "Use Agentforce Default Agent"), authorized to run the agent.
  🔴 **License caveat:** a bare **API-Only integration user may NOT support the Agentforce agent-use permission** — use a
  license that supports both API integration and Agentforce agent use, and confirm on the target org. (Old "Access
  Service Einstein" reference = unconfirmed/possibly obsolete.) Full detail: [credential-setup-cookbook.md §B step 4](./modules/04-custom-ui.md#set-up-the-agent-api-eca-a-separate-app-from-the-mcp-one).
  Enable "Issue JWT-based access tokens for named users". Deselect the "Require secret for Web Server/Refresh Token
  Flow" boxes + PKCE. (If a "Confirm and Lock" dialog appears, turn PKCE OFF before locking.)
- Callback URL is required even for client_credentials: `https://<your-org>.my.salesforce.com/services/oauth2/callback`.

**Run it (two terminals):**
```bash
cd web && cp .env.example .env      # set MYDOMAIN, AGENT_ID (0Xx…), CLIENT_ID, and a fresh ACCESS_TOKEN
npm install
# mint a token into .env:  curl -s -X POST "$MYDOMAIN/services/oauth2/token" \
#   -d grant_type=client_credentials -d client_id=<key> -d client_secret=<secret>
node proxy.mjs        # terminal 1 → http://localhost:8787 (holds token server-side)
npm run dev           # terminal 2 → http://localhost:5173 → "Ask the agent"
```
- 🔴 **Session start needs `bypassUser: false`** for an employee agent (`true` → HTTP 400 "Invalid user ID"). Handled in
  `agentApi.js`.
- Token is short-lived — on a `401`/empty response, mint a fresh one into `.env` and **restart `node proxy.mjs`**.
- The card shows the agent's response + a "View in Salesforce ↗" record link + collapsible raw JSON. Full detail:
  [web/README.md](../web/README.md).

---

## 6. Custom Lightning Type — rich card in-conversation (part of the Capability — GUIDE Module 2)

Deploy the `LightningTypeBundle` and bind it to the Skill's Apex output so the agent renders a rich card in LEX instead
of plain text. `sf project deploy start --metadata LightningTypeBundle:OrderStatusCard`. (Apex-based CLTs also render on
Enhanced Chat v2 + Mobile — no longer LEX-only.) This is the partner-buildable on-ramp to the HXL "render everywhere"
vision (shown as a demo, not built live).

---

## Architecture context (why Salesforce-hosted MCP + agent orchestration)

Three ways an external agent reaches Salesforce, per the *MCP & Agent Orchestration Technical Guide*:

| | Salesforce-hosted MCP | Agent orchestration (Agent API / A2A) | Externally hosted MCP |
|---|---|---|---|
| **Security** | tool execution inside the trust boundary | reasoning inside the boundary | expanded attack surface |
| **API efficiency** | 1 call per tool | 1 call per user prompt | many calls |
| **Deploy** | zero-code (Setup) | low-code | build/maintain the full server tier |
| **Best for** | most use cases | PII masking; reuse an existing agent | heavy compute / data handling |

The externally-hosted path carries real risks the guide calls out — **tokens leaking into logs, cross-user data
bleeding, dependency supply-chain, SSRF exposing the client secret**. Our web sample's **backend proxy holding the token
server-side** is the mitigation pattern. Use this table as the Module 1 "why headless / why Salesforce-hosted" talking point.
