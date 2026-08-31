# React Agent-API Sample Client (Surface #2)

A minimal reference React client that embeds the reference Employee Agent's Skill in a partner's own web app via the
**headless Agentforce Agent API** — the truest "Headless 360" story for an ISV with their own front-end.

> **Reference, not a product.** This is deliberately dependency-light: it shows the Agent API loop (start → send → receive
> → end) and renders the structured order-status Response as a card. Swap in your own Skill + styling to reskin.

## HXL Mosaic side-by-side — "define once as a widget, render anywhere"

The page shows the **same Agent-API data two ways**:

- **Left — hand-built React card.** One surface, coded by hand (the classic per-surface build).
- **Right — HXL Mosaic widget.** The same data rendered by a small **React Mosaic renderer**
  (`src/mosaic/`) that interprets a **Mosaic widget JSON** — the *same shape* that deploys to the org
  as a `UiWidgetBundle` (see `reference/hxl-widget-sample/`). The interactive `OrderAssistant` widget's
  quick-pick buttons (`OR-1001…1005`) **re-drive the agent**; the response widget binds live data.

This is the partner-buildable proof of the HXL thesis: **you declare the surface once as a widget and
render it wherever you need it** — here, in your own React app, interactively, today.

**How it's wired** (`src/mosaic/`):
- `bind.js` — pure, unit-tested: `bindWidget(node, data)` resolves `{{order}}` / `{{status}}` /
  `{{summary}}` / `{{recordUrl}}` tokens in the widget tree from the live Agent-API response;
  `statusVariant(status)` picks the badge color. Run `npm test` (vitest).
- `MosaicTile.jsx` — recursive renderer for the tiles our widgets use (mirrors the in-org LWC
  `mosaicTile`, but interactive: buttons fire an `onAction` the App owns).
- `src/widgets/*.web.json` — the bindable widget definitions.

> 🚧 **Honest boundary.** This renderer is **partner-authored** — it is *not* the gated platform HXL
> runtime, and `*.web.json` is a **bindable twin** of the deployed bundle (it adds `{{token}}` bindings
> the strict server schema forbids). We demonstrate the *thesis* (render-from-one-definition), not the
> platform auto-render.

## How it works

The Agent API is a REST API (no bundled UI):
1. **Start session** → get a session id.
2. **Send message** ("order status for <id>") → the agent runs the Skill.
3. **Receive** the structured Response.
4. **Render** it in React (this is where *you* own the UI — the API returns data, not markup).
5. **End session.**

### Architecture — a backend proxy holds the token (the real partner pattern)

The browser does **not** call the Agent API directly. Two reasons: (1) `api.salesforce.com` sends no browser
CORS headers, and (2) an access token must never live in browser JS. So the React app calls a tiny **backend
proxy** (`proxy.mjs`) that holds the token server-side and forwards to the Agent API — exactly what a partner
does in production. The browser sends no token.

```
browser (React)  ──►  proxy.mjs :8787  ──►  api.salesforce.com/einstein/ai-agent/v1
                       (injects Bearer token from .env, server-side)
```

## Prerequisites

- The agent is a **non-"Agentforce (Default)"** type (Employee qualifies).
- A **separate External Client App** for the Agent API (client_credentials + Run-As user; scopes `api`, `chatbot_api`,
  `sfap_api`). Do **not** reuse the MCP ECA. (403 without the scopes.)
- 🔴 **`bypassUser: false`** on session start for an Employee agent — the session runs as the token's Run-As user.
  `bypassUser: true` → HTTP 400 "Invalid user ID provided on start session". (Handled in `src/agentApi.js`.)
- Note the **120-second Agent API timeout** — keep actions fast.
- ✅ Validated end-to-end 2026-07-23 against agent `Headless360_Order_Assistant` (start → send → receive → end).

## Full setup — step by step (end to end)

**Two terminals + a two-part ECA.** Full ECA click-by-click is in
[Module 4 — Custom UI §4b](../docs/modules/04-custom-ui.md#set-up-the-agent-api-eca-a-separate-app-from-the-mcp-one);
the essential path:

### 1. Create the Agent-API External Client App (SEPARATE from the MCP one)
Setup → **External Client App Manager → New External Client App**.
- **Basic Info:** Name `Headless360 Agent API`; **Contact email** (required).
- **API (Enable OAuth Settings) → ON:**
  - **Callback URL:** `https://<your-domain>.my.salesforce.com/services/oauth2/callback` (required field even though
    client_credentials never uses it)
  - **OAuth scopes** (exact UI labels — **NOT** `mcp_api`):
    - Manage user data via APIs **(api)**
    - Access chatbot services **(chatbot_api)**
    - Access the Salesforce API Platform **(sfap_api)**
    - Perform requests at any time **(refresh_token, offline_access)**
  - **CHECK** "Issue JSON Web Token (JWT)-based access tokens for named users"
  - PKCE is locked ON — **leave it** (it only affects the browser auth-code flow, not client_credentials)
- **Create.**

### 2. 🔴 Enable the flow + set Run-As — ONLY after the app is created (Policies tab)
The **Run As** field doesn't exist in the creation wizard — it appears only after the app is saved. Open the finished
app → **Policies → OAuth Policies → Edit**:
- **Enable Client Credentials Flow:** ON
- **Run As (Username):** a user that can call the API **and** run the agent — your admin user works (it holds
  `Headless360_Workshop_Access` → agent access). **Save.**

### 3. Copy the Consumer Key + Secret (🔴 you'll likely have to re-login)
App → **Settings → OAuth Settings**. Revealing the Key/Secret usually forces a **re-login / identity verification**
(on trial orgs it can surface as "insufficient privileges") — complete the emailed code, or reopen fresh with
`sf org open --target-org <alias>`. **Client_credentials needs the secret.**

### 4. Mint a short-lived access token (client_credentials)
Run as **one line** (a `\` continuation breaks on paste), and **pipe through the extractor so you get ONLY the token**,
not the whole JSON:
```bash
curl -s -X POST "https://<your-domain>.my.salesforce.com/services/oauth2/token" -d grant_type=client_credentials -d client_id=<CONSUMER_KEY> -d client_secret=<CONSUMER_SECRET> | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])'
```
🔴 **Paste ONLY that `access_token` value into `VITE_ACCESS_TOKEN`** — not the whole `{...}` JSON. Pasting the JSON blob
makes `proxy.mjs` send `Bearer {…}` → `startSession 401 "Invalid token"`.

### 5. Configure `web/.env`
```bash
cp .env.example .env      # then set:
#   VITE_SF_MYDOMAIN=https://<your-domain>.my.salesforce.com
#   VITE_AGENT_ID=<Employee Agent BotDefinition Id, 0Xx…>
#   VITE_CLIENT_ID=<CONSUMER_KEY>
#   VITE_ACCESS_TOKEN=<access_token from step 4>
#   SF_CLIENT_SECRET=<CONSUMER_SECRET>
#   VITE_HXL_VIEWER_URL=/lightning/n/HXL_Widget_Viewer   # OPTIONAL — only if the in-org
#     HXL Widget Viewer is deployed (scripts/deploy-hxl-viewer.sh). Empty → the
#     HXL panel's "Open HXL Widget Viewer" footer link is hidden.
```

### 6. Run — TWO terminals (both from `web/`)
```bash
npm install               # first time only

# Terminal 1 — backend proxy (holds the token, forwards to the Agent API). LEAVE RUNNING.
node proxy.mjs            # → http://localhost:8787

# Terminal 2 — the React app
npm run dev               # → http://localhost:5173
```
Open **http://localhost:5173** → ask for **OR-1003** → the status card renders.

🔴 **Token expires** (client_credentials tokens are short-lived). On a `401`/empty response, **re-mint** (step 4) into
`web/.env` and **restart `node proxy.mjs`** (it reads `.env` at startup). `412` on session start → the Run-As user lacks
agent access; `400 "Invalid user ID"` → `bypassUser` (handled in `src/agentApi.js`).
- `node proxy.mjs` errors **`EADDRINUSE :8787`** → a previous proxy is still running; kill it and re-run:
  `lsof -ti tcp:8787 | xargs kill`.
- **Stop / free both ports** — Ctrl-C each terminal, or force-release (proxy 8787 + Vite 5173–5175):
  `lsof -ti tcp:8787,5173,5174,5175 | xargs kill` (add `-9` if a port won't release).

## Files

- `proxy.mjs` — dependency-free backend proxy; holds the token, forwards to the Agent API, handles CORS.
- `src/agentApi.js` — the Agent API helper (start/send/receive/end); calls the proxy, sends no token.
- `src/App.jsx` — the page: a formal top ask panel over two clearly-divided render panels — the hand-built
  React card (left) and the HXL Mosaic render (right, with an in-org HXL Widget Viewer link).
- `src/mosaic/` — the render-anywhere kit: `bind.js` (pure token binding, unit-tested), `MosaicTile.jsx`
  (recursive renderer), `theme.js` (shared palette/font).
- `src/widgets/*.web.json` — the bindable widget definitions (twins of the deployed `UiWidgetBundle`s).
- `vite.config.js` / `index.html` / `src/main.jsx` — standard Vite React scaffolding.

⚠️ **Auth/licensing + Flex-credit cost** for the Agent API in a partner app is a workshop budget item — confirm from the
Headless 360 Success Guide with your Salesforce contact.
