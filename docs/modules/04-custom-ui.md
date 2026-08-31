# Module 4 — Custom UI on the agent: React apps & HXL widgets (in-org & external)

**Phase:** 2 · Reference Build · **Goal:** put a **custom UI** on the Module 2 capability two ways — **React you code** and **HXL widgets you declare** — each shown **in-org** and **headless (external)** · **Time:** ~60 min · **Done when:** the React card shows OR-1003 (in-org **and** external), and an HXL widget deploys + renders (in the org viewer **and** in the external side-by-side).

There are two ways to give the agent a custom front-end, and this module builds both:

- **React (you code the surface).** Two React surfaces reach the agent published in Module 2 (needs it **published + activated**): an **in-org** app (lowest-friction, no tokens) and an **external** Agent-API client (the fully-headless, off-platform story).
- **HXL widgets (you declare the surface).** Instead of coding a card per channel, you declare the UI **once as a Mosaic widget** and render it in multiple places. You'll deploy a functional reference widget, view it **in the org**, see it rendered **externally**, then **extend** it.

> **React is GA on-platform (Multi-Framework).** Native React runs on Hyperforce orgs; each app gets a dedicated **`salesforce.app`** origin; Data SDK (GraphQL) is GA. The two React surfaces render the same agent differently: (a) the **in-org app** embeds the **Agentforce Conversation Client** (Lightning Out over `my.salesforce.com`) — no tokens; (b) the **external `web/` app** calls the raw **Agent API** and renders the Response as **your own card**. Docs: [Multi-Framework guide](https://developer.salesforce.com/docs/platform/multiframework/guide/).

---

## 4a — In-org React app (native Multi-Framework)

The kit ships the **`Headless360_OrderStatus` UI Bundle** — a native React app running *on* the platform, embedding the Order Assistant chat. It's a subsequent deploy step (not in base onboarding — it needs an `npm` build + a large `node_modules`, which is `.forceignore`d). Run it **after** the agent is published:

```bash
./scripts/deploy-react-app.sh --org <alias>
```

It queries the org's `BotDefinition` Id → bakes **`VITE_AGENT_ID`** at build time → `npm run build` → scoped-deploys the UI Bundle + its surfacing **CustomApplication** + the **`Headless360_React_App`** permset (and assigns it). Then **App Launcher → "Headless360 Order Status"** → the React app renders with the embedded **Order Assistant** chat; ask "status of order OR-1003" → the same Exception / "Approve rebooking" from Module 2, now in a custom React shell in the org.

### 🔴 Checkpoint 4a
The app appears in App Launcher and the embedded chat answers on OR-1003. ⏳ Expect a **cold start** — the first load *and* the agent's first reply can take several seconds; wait, it's not a failure, and later calls are fast. A **persistent blank chat / "Order Assistant unavailable"** (not just slow) → `VITE_AGENT_ID` was built for a different org (or not set) — re-run `deploy-react-app.sh` against **this** org (it re-bakes the id). No tokens involved — the in-org client runs as you.

---

## 4b — External React via the Agent API — "fully headless"

The `web/` app calls the raw Agent API and renders the structured Response as **your own card** — the true off-platform "your product, headless" surface.

### Set up the Agent-API ECA (a SEPARATE app from the MCP one)

Setup → **External Client App Manager** → **New External Client App**.

- **Name / API Name:** `Headless360 Agent API` / `Headless360_Agent_API`
- **Enable OAuth: ON.**
- **Callback URL** (required even though client_credentials never uses it):
  ```
  https://<your-org>.my.salesforce.com/services/oauth2/callback
  ```
- **OAuth Scopes — add EXACTLY these** (different from the MCP ECA): `Manage user data via APIs (api)`, `Access chatbot services (chatbot_api)`, `Access the Salesforce API Platform (sfap_api)`, `Perform requests at any time (refresh_token, offline_access)`. 🔴 **NOT `mcp_api`**, and do not add `openid`.
- **UNcheck** "Require secret for Web Server Flow" and "Require secret for Refresh Token Flow".
- **CHECK "Issue JWT-based access tokens for named users."**
- **PKCE is locked ON — leave it** (client_credentials ignores it).

Then set the flow + Run-As user. 🔴 **This is on the finished app's Policies tab — NOT the creation wizard.** Open the app → **Policies** → **OAuth Policies** → **Edit**:
- **Enable Client Credentials Flow: ON.**
- **Run As:** a user who can call the API **and** run the Agentforce agent. 🔴 **A bare API-Only integration user may lack Agentforce agent-use** — use a user whose license supports **both** (API Integration PSL + "Access Agentforce Default Agent"), not a pure API-Only user. Using an admin works but can hit MFA on a stale session.

**Copy the Consumer Key + Consumer Secret** (client_credentials **needs the secret**).

> 🔒 **If revealing the Key/Secret loops on identity-verification or "insufficient privileges"** (common on trial orgs) — **open the org in an incognito/private window and reveal from there.** A clean session resolves it; or complete the emailed code / retry from a fresh `sf org open --target-org <alias>` session.

### Verify the token mint (local terminal — keeps the secret off any transcript)

```bash
curl -s -X POST "https://<your-org>.my.salesforce.com/services/oauth2/token" -d "grant_type=client_credentials" -d "client_id=<CONSUMER_KEY>" -d "client_secret=<CONSUMER_SECRET>" | python3 -m json.tool
```
Expect `access_token`, `token_type: Bearer`, `scope: sfap_api chatbot_api api`. `invalid_client` → key/secret wrong or app not propagated (wait 2–5 min). `invalid_grant` → Client Credentials Flow not enabled or Run-As not set.

### Run the client

1. The agent must be a **non-"Agentforce (Default)"** type (Employee qualifies) — the Agent API doesn't support Default.
2. **Save your creds into `web/.env`.** You'll have the ECA **Consumer Key + a fresh Consumer Secret**. Put them in `web/.env`, then run **two processes** (the browser can't call `api.salesforce.com` directly — no CORS, and the token must never live in browser JS — so `proxy.mjs` holds the token and forwards):
   ```bash
   cd web && cp .env.example .env
   ```
   Set `VITE_SF_MYDOMAIN`, `VITE_AGENT_ID`, `VITE_CLIENT_ID`, `SF_CLIENT_SECRET`, and `VITE_ACCESS_TOKEN` (a fresh access token) in `web/.env`, then:
   ```bash
   npm install
   ```
   ```bash
   node proxy.mjs
   ```
   ```bash
   npm run dev
   ```
   `proxy.mjs` (Terminal 1, → :8787) holds the token and forwards to the Agent API; `npm run dev` (Terminal 2, → :5173) serves the React app → "Ask the agent". `web/.env` is **gitignored** — keep creds off git. Full walk-through: [`web/README.md`](../../web/README.md).

### 🔴 Checkpoint 4b — it's the token, not the network
The web card shows the same OR-1003 status.
- `401` / empty → **expired/wrong token**: mint a fresh one into `web/.env` and **restart `node proxy.mjs`** (it reads `.env` at startup).
- session-start **412** → assign the **agent-access permset** to the Run-As user (an Employee agent is invisible to a user without agent access); confirm the agent is **published + activated**.
- **400 "Invalid user ID"** → `bypassUser` wrong for an Employee agent.
- First call may show a timeout-style delay (session start + the 120s Agent-API ceiling) — wait for the card; check the **proxy log** (Terminal 1) for the real status, not just the browser. More → [ISSUES.md](../ISSUES.md).

---

## 4c — HXL widgets: define once, render anywhere

Everything above builds the UI **explicitly, per surface** — you hand-code the React card. **HXL (the Headless Experience Layer)** is the platform's answer to that: **declare the UI once as a Mosaic widget**, deploy it as a `UiWidgetBundle`, and render it in more than one place. This section gives you a **functional widget first** (deploy the reference build, view it in the org and externally), then shows you how to **author your own** so you can extend it.

> 🚧 **Safe harbor — what's real today vs. the gated frontier.** Two things are concrete and current: (1) the **`UiWidgetBundle` metadata type deploys to a workshop org** and can be inspected in the in-org **HXL Widget Viewer**; (2) the **external `web/` app renders the same widget definition** through a partner-built React Mosaic renderer (§4c.3). What is **not** yet a promise is a platform **auto-render of that widget live in a channel** (ChatGPT / Slack / Agentforce) — that path is still gated. Build this to understand the shape and to render it where you control the surface; don't promise a partner cross-surface channel auto-render on a date.

**The vocabulary.** Think **MVC**: your **Type** (a Custom Lightning Type / schema) is the *Model*, the **Widget** (a surface-agnostic composition written in **Mosaic**, the declarative JSON format) is the *View*, and **Actions** (semantic, fire-and-forget buttons) are the *Controller*. A widget is built from **Components** — primitives like `text`, `button`, `container`, `badge`, `card`, `list`, `table`.

### 4c.1 — Start with the reference build (functional immediately)

The kit ships a ready-to-deploy widget bundle at [`reference/hxl-widget-sample/`](../../reference/hxl-widget-sample/) — a `HelloWorld` widget plus three Order-demo widgets that mirror the rest of the build: **`OrderStatusWidget`** (the *response* card — the HXL-native twin of the Agentforce/Slack/React cards), **`OrderAssistant`** (the *interactive agent* — pick/enter an order → semantic "Check status" action), and **`OrderAssistantApp`** (the two composed into one mini-app).

**a. Deploy the HXL Widget Viewer (once per org).** A small LWC "view kit" to browse the org's widgets and inspect each one's structure + raw Mosaic JSON:

```bash
./scripts/deploy-hxl-viewer.sh --org <alias>
```

It provisions a per-org `RemoteSiteSetting` (the viewer reads a draft widget's body via an Apex self-callout to the Connect authoring REST API), deploys the viewer metadata (Apex + 2 LWCs + FlexiPage/Tab/App), and assigns the `HXL_Widget_Viewer_Access` permset.

**b. Deploy the widget bundle** in **metadata (mdapi) format**:

```bash
sf project deploy start --metadata-dir reference/hxl-widget-sample --target-org <alias> --dry-run
sf project deploy start --metadata-dir reference/hxl-widget-sample --target-org <alias>
```

🔴 **Deploy in mdapi format (`--metadata-dir`), NOT source format.** The current CLI has a source-format round-trip bug for this new type — it writes the bundle's meta file into the payload and the server rejects it (*"Unexpected file in bundle"*). This is also why the sample lives under `reference/` and not `force-app/`.

### 4c.2 — View it in the org (HXL Widget Viewer)

Open **App Launcher → "HXL Widget Viewer"** → **Refresh** → pick a widget → read its **Description** (the pithy caption from the body), then the **Preview** (structural render) and **JSON** (raw `contentBody`) tabs.

> **In-org view only — the honest boundary.** The viewer shows a widget's *structure* and *raw Mosaic JSON* inside your org. The Assistant widgets are **interactive in the authoring Playground**, but the in-org viewer renders them **structurally** (no live state) — the same gated-channel boundary as the safe-harbor note above. Rendering a widget live *in a channel* is still the frontier.

### 4c.3 — View it external (the React Mosaic side-by-side)

You already have this running from §4b. The `web/` app renders the same Agent-API response **two ways, side by side**: the **hand-built React card** (left) and — from the **same Mosaic widget shape** you just deployed — a **React Mosaic renderer** (right). The interactive `OrderAssistant` quick-pick buttons re-drive the agent; the response widget binds live data.

This is the partner-buildable proof of *"define once as a widget, render anywhere"* with **no gated dependency**: it's a **partner-authored renderer** (not the platform HXL runtime), and the web widget JSON (`web/src/widgets/*.web.json`) is a **bindable twin** of the deployed bundle (it adds `{{token}}` bindings the strict server schema forbids). Details + the honesty boundary: [`web/README.md`](../../web/README.md).

> **Link the two:** once you've deployed the viewer (§4c.1a), set `VITE_HXL_VIEWER_URL=/lightning/n/HXL_Widget_Viewer` in `web/.env` — the HXL panel's **"Open HXL Widget Viewer"** footer link then jumps straight to the in-org viewer. Leave it empty to hide the link.

### 4c.4 — Extend it (author your own widget)

**Author in the public Playground (no Salesforce login required):** **https://www.headlessexperiencelayer.com/playground/** — a standalone SPA with a 14-step tutorial ladder (each tutorial is itself a widget; open the code view to see the JSON). It's the fastest way to internalize Mosaic; reference it directly.

**Export → assemble → deploy.** Use the Playground's **Copy → "Reusable widget"** export — it wraps your widget as `{ "type": "lightning__agentforceWidget", "contentBody": { "widgetBody": { … } } }`, exactly what a `UiWidgetBundle` expects. A bundle is a folder of **three files** under `uiWidgets/<Name>/`:

```
uiWidgets/MyWidget/
├── MyWidget.uiwidget-meta.xml    # bundle descriptor (lowercase "uiwidget", name-prefixed)
├── MyWidget.json                 # the exported widget definition
└── schema.json                   # the widget's input schema (must declare properties.attributes)
```

Drop it beside the samples in `reference/hxl-widget-sample/uiWidgets/`, add it to that folder's `package.xml`, and deploy with the same `--metadata-dir` command. Then **Refresh** the Widget Viewer to see it.

**Three gotchas that will bite you:**
1. **Root `type` must be `lightning__agentforceWidget`** — a raw `"type": "mosaic"` fails (*"bad value for restricted picklist: mosaic"*). The "Reusable widget" export sets this correctly.
2. **`widgetBody` root block must be `tile/widget`** — the Playground uses `tile/mosaic` as its editor root, but the org's v67 server schema accepts only `tile/widget` at the root; everything else nests inside it.
3. **`schema.json` must declare `properties.attributes`** — keep it minimal (a `title` / `type` root is fine; the samples show the shape).

**Verified v67 body-schema constraints** (a widget that previews fine in the Playground can still fail deploy — the server validates the whole body with `additionalProperties: false`):
- **`tile/badge`** uses **`label`** (not `text`).
- **`tile/button`** `variant` ∈ `[primary, secondary, destructive]`.
- **`gap`** (rows/columns) ∈ `[none, xs, sm, md, lg, xl]`.
- **`justify`** — `spaceBetween` is rejected; omit unless you know a valid enum value.
- **`tile/link`** `href` must be a **valid absolute URL** (`"#"` and relative paths fail).
- **`tile/card`** **cannot be a direct child of `tile/widget`** — wrap it in a `tile/container`.
- **Node `id`** must be a **UUID** — the server assigns one on deploy; don't hand-author `id`.
- **No custom keys** in `attributes` (e.g. `attributes.description` is rejected). The samples carry their description as a **leading `tile/text` node with `variant: "caption"`**; the Widget Viewer lifts that into the Description field.

### 🚧 Checkpoint 4c
`sf project deploy start --metadata-dir reference/hxl-widget-sample --target-org <alias>` returns **Succeeded** (0 errors) and `sf org list metadata --metadata-type UiWidgetBundle --target-org <alias>` lists the widgets; the **HXL Widget Viewer** shows them (Preview + JSON); and the `web/` app's right panel renders the same widget shape. If you get *"Unexpected file in bundle"* → you deployed source-format; use `--metadata-dir`. If *"block … isn't allowed at $.widgetBody"* → swap the root to `tile/widget`. More symptoms → [ISSUES.md](../ISSUES.md).

> **Reminder:** a clean deploy + in-org view + external side-by-side proves the widget **lands and renders where you control the surface** — it does **not** prove a platform **channel auto-render** (ChatGPT/Slack/Agentforce). That path is still gated. Frame accordingly.

---

[← Module 3a](./03a-custom-mcp-server.md) · [Overview](../../OVERVIEW.md) · [Module 5 →](./05-slack.md)
