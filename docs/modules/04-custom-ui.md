# Module 4 — Custom UI on the agent: React apps & HXL widgets (in-org & external)

**Phase:** 2 · Reference Build · **Goal:** put a **custom UI** on the Module 2 capability two ways — **React you code** and **HXL widgets you declare** — each shown **in-org** and **headless (external)** · **Time:** ~60 min · **Done when:** the React card shows OR-1003 (in-org **and** external), and an HXL widget deploys + renders (in the org viewer **and** in the external side-by-side).

> **📎 New section order (reordered 2026-09-01).** Now that HXL is enabled up front, this module runs in a build-up order so nothing is referenced before it exists: **4a** in-org React (you *code*) → **4b** HXL widget (you *declare* + deploy + view in org) → **4c** external/headless via the Agent API (render your hand-coded card **and** the HXL widget side-by-side) → **4d** author your own widget. *(Mapping from the previous layout: old 4b → new 4c; old 4c.1/4c.2 → new 4b; old 4c.3 → folded into new 4c; old 4c.4 → new 4d.)*

There are two ways to give the agent a custom front-end, and this module builds both — **code** first, then **declare**:

- **React (you code the surface).** Two React surfaces reach the agent published in Module 2 (needs it **published + activated**): an **in-org** app (lowest-friction, no tokens) and an **external** Agent-API client (the fully-headless, off-platform story).
- **HXL widgets (you declare the surface).** Instead of coding a card per channel, you declare the UI **once as a Mosaic widget** and render it in multiple places. You'll deploy a functional reference widget, view it **in the org**, then see it rendered **externally** alongside the hand-coded card, and finally **extend** it.

> **React is GA on-platform (Multi-Framework).** Native React runs on Hyperforce orgs; each app gets a dedicated **`salesforce.app`** origin; Data SDK (GraphQL) is GA. The two React surfaces render the same agent differently: (a) the **in-org app** embeds the **Agentforce Conversation Client** (Lightning Out over `my.salesforce.com`) — no tokens; (b) the **external `web/` app** calls the raw **Agent API** and renders the Response as **your own card**. Docs: [Multi-Framework guide](https://developer.salesforce.com/docs/platform/multiframework/guide/).

---

## 4a — In-org React app (native Multi-Framework) — *you code the surface*

The kit ships the **`Headless360_OrderStatus` UI Bundle** — a native React app running *on* the platform, embedding the Order Assistant chat. It's a subsequent deploy step (not in base onboarding — it needs an `npm` build + a large `node_modules`, which is `.forceignore`d). Run it **after** the agent is published, **[Terminal — from the repo root]**:

```bash
./scripts/deploy-react-app.sh --org <alias>
```

It queries the org's `BotDefinition` Id → bakes **`VITE_AGENT_ID`** at build time → `npm run build` → scoped-deploys the UI Bundle + its surfacing **CustomApplication** + the **`Headless360_React_App`** permset (and assigns it). Then **App Launcher → "Headless360 Order Status"** → the React app renders with the embedded **Order Assistant** chat; ask "status of order OR-1003" → the same Exception / "Approve rebooking" from Module 2, now in a custom React shell in the org.

### 🔴 Checkpoint 4a
The app appears in App Launcher and the embedded chat answers on OR-1003. ⏳ Expect a **cold start** — the first load *and* the agent's first reply can take several seconds; wait, it's not a failure, and later calls are fast. A **persistent blank chat / "Order Assistant unavailable"** (not just slow) → `VITE_AGENT_ID` was built for a different org (or not set) — re-run `deploy-react-app.sh` against **this** org (it re-bakes the id). No tokens involved — the in-org client runs as you.

---

## 4b — HXL widgets: declare once, then view in the org — *you declare the surface*

4a builds the UI **explicitly, per surface** — you hand-code the React card. **HXL (the Headless Experience Layer)** is the platform's answer to that: **declare the UI once as a Mosaic widget**, deploy it as a `UiWidgetBundle`, and render it in more than one place. Here you deploy a **functional reference widget** and view it **in the org**; in **4c** you'll see the same widget rendered **externally** next to your hand-coded card; in **4d** you author your own.

> 🚧 **Safe harbor — what's real today vs. the gated frontier.** Two things are concrete and current: (1) the **`UiWidgetBundle` metadata type deploys to a workshop org** and can be inspected in the in-org **HXL Widget Viewer**; (2) the **external `web/` app renders the same widget definition** through a partner-built React Mosaic renderer (4c). What is **not** yet a promise is a platform **auto-render of that widget live in a channel** (ChatGPT / Slack / Agentforce) — that path is still gated. Build this to understand the shape and to render it where you control the surface; don't promise a partner cross-surface channel auto-render on a date.

**The vocabulary.** Think **MVC**: your **Type** (a Custom Lightning Type / schema) is the *Model*, the **Widget** (a surface-agnostic composition written in **Mosaic**, the declarative JSON format) is the *View*, and **Actions** (semantic, fire-and-forget buttons) are the *Controller*. A widget is built from **Components** — primitives like `text`, `button`, `container`, `badge`, `card`, `list`, `table`.

### 4b.0 — Enable Headless/HXL in Setup (do this FIRST)

🔴 **HXL is a Setup toggle you must turn on — like Agentforce.** Without it, deploying a `UiWidgetBundle` fails with **"Not available for deploy for this organization"** (all components).

1. Setup → Quick Find **"Headless"** (Headless / HXL setup) → **turn it ON**.
2. Give it a moment to provision, then continue.

> If the widget deploy below returns *"Not available for deploy for this organization,"* Headless/HXL isn't enabled yet — come back to this step.

### 4b.1 — Deploy the reference build

The kit ships a ready-to-deploy widget bundle at [`reference/hxl-widget-sample/`](../../reference/hxl-widget-sample/) — a `HelloWorld` widget plus three Order-demo widgets that mirror the rest of the build: **`OrderStatusWidget`** (the *response* card — the HXL-native twin of the Agentforce/Slack/React cards), **`OrderAssistant`** (the *interactive agent* — pick/enter an order → semantic "Check status" action), and **`OrderAssistantApp`** (the two composed into one mini-app).

⚠️ **These are TWO separate deploys — the viewer app and the widgets themselves.** Step A ships the *viewer*; Step B ships the *widgets*. If you open the viewer after Step A and it's empty, that's expected — you haven't done Step B yet.

**Step A — Deploy the HXL Widget Viewer (once per org).** A small LWC "view kit" to browse the org's widgets and inspect each one's structure + raw Mosaic JSON, **[Terminal — from the repo root]**:

```bash
./scripts/deploy-hxl-viewer.sh --org <alias>
```

It provisions a per-org `RemoteSiteSetting` (the viewer reads a draft widget's body via an Apex self-callout to the Connect authoring REST API), deploys the viewer metadata (Apex + 2 LWCs + FlexiPage/Tab/App), and assigns the `HXL_Widget_Viewer_Access` permset.

**Step B — Deploy the widget bundle** in **metadata (mdapi) format** — dry-run first, then the real deploy, **[Terminal — from the repo root]**:

```bash
sf project deploy start --metadata-dir reference/hxl-widget-sample --target-org <alias> --dry-run
sf project deploy start --metadata-dir reference/hxl-widget-sample --target-org <alias>
```

🔴 **Deploy in mdapi format (`--metadata-dir`), NOT source format.** The current CLI has a source-format round-trip bug for this new type — it writes the bundle's meta file into the payload and the server rejects it (*"Unexpected file in bundle"*). This is also why the sample lives under `reference/` and not `force-app/`.

### 4b.2 — View it in the org (HXL Widget Viewer)

Open **App Launcher → "HXL Widget Viewer"** → **Refresh** → pick a widget → read its **Description** (the pithy caption from the body), then the **Preview** (structural render) and **JSON** (raw `contentBody`) tabs.

> **Empty viewer?** You haven't deployed the widget bundle yet — do **Step B** above (4b.1). Step A only ships the viewer app; the widgets are a separate deploy.

> **In-org view only — the honest boundary.** The viewer shows a widget's *structure* and *raw Mosaic JSON* inside your org. The Assistant widgets are **interactive in the authoring Playground**, but the in-org viewer renders them **structurally** (no live state) — the same gated-channel boundary as the safe-harbor note above. Rendering a widget live *in a channel* is still the frontier.

### 🔴 Checkpoint 4b
`sf project deploy start --metadata-dir reference/hxl-widget-sample --target-org <alias>` returns **Succeeded** (0 errors) and `sf org list metadata --metadata-type UiWidgetBundle --target-org <alias>` lists the widgets; the **HXL Widget Viewer** shows them (Preview + JSON). If deploy fails *"Not available for deploy for this organization"* → enable Headless/HXL (4b.0). If *"Unexpected file in bundle"* → you deployed source-format; use `--metadata-dir`.

---

## 4c — External React via the Agent API — "fully headless" (your card + the HXL widget, side by side)

The `web/` app calls the raw Agent API and renders the structured Response as **your own card** — the true off-platform "your product, headless" surface — **and**, in the same view, renders the **HXL widget you deployed in 4b** through a partner-built React Mosaic renderer. This is the "define once, render anywhere" payoff.

### Set up the Agent-API ECA (a SEPARATE app from the MCP one)

Setup → **External Client App Manager** → **New External Client App**. Fill the fields **in the order the page presents them**:

- **Basic Information:**
  - **Name:** `Headless360 Agent API` · **API Name:** `Headless360_Agent_API`
  - **Contact Email:** your email (this field is **required** — easy to miss).
- **API (Enable OAuth Settings) section → turn *Enable OAuth* ON.** (This is the section where OAuth lives; enabling it reveals the OAuth fields below.)
- **Callback URL** (first OAuth field; required even though client_credentials never uses it):
  ```
  https://<your-org>.my.salesforce.com/services/oauth2/callback
  ```
- **OAuth Scopes — add EXACTLY these** (bullets; different from the MCP ECA):
  - [ ] `Manage user data via APIs (api)`
  - [ ] `Access chatbot services (chatbot_api)`
  - [ ] `Access the Salesforce API Platform (sfap_api)`
  - [ ] `Perform requests at any time (refresh_token, offline_access)`
  - 🔴 **NOT `mcp_api`**, and do not add `openid`.
- **Flow Enablement — CHECK "Enable Client Credentials Flow"** here on the settings page. *(You will enable it again on the Policies tab after saving — it's required in both places; see below.)*
- **Security (states as they appear):**
  - Confirm **"Require secret for Web Server Flow"** and **"Require secret for Refresh Token Flow"** are **UNchecked** (they're off by default).
  - **PKCE** is locked **ON** — leave it (client_credentials ignores it).
  - 🔴 **CHECK "Issue JSON Web Token (JWT)-based access tokens for named users"** — this is **DEFAULT OFF** and is a common silent gotcha.
- **Save / Create the app.** (The button may say "Create.") 🔴 **You must save before the Policies tab exists** — the flow + Run-As settings below live only on the *finished* app.

**Then, on the SAVED app, set the flow + Run-As user.** 🔴 **This is on the finished app's Policies tab — NOT the creation wizard.** Open the app → **Policies** → **OAuth Policies** → **Edit**:
- **Enable Client Credentials Flow: ON** (yes — again here; it must be on in both the settings page *and* the Policies tab).
- **Run As:** your **username** — the Salesforce login (Setup → Users → your row → **Username**), e.g. `something@salesforce.com`. 🔴 This is the **username**, *not* the email you set earlier — they look alike but are different fields. The Run-As user must be able to call the API **and** run the Agentforce agent: a bare API-Only integration user may lack Agentforce agent-use — use a user with **both** (API Integration PSL + agent access). An admin works but can hit MFA on a stale session.

**Reveal the Consumer Key + Consumer Secret** (client_credentials **needs the secret**; the MCP ECA needed only the key).

> 🔒 **Standing rule — reveal via incognito.** On trial/template orgs, revealing a Key/Secret often loops on identity-verification or "insufficient privileges." **Open the org in an incognito/private window and reveal from there** — a clean session (no cached SSO) resolves it. (Alternatively complete the emailed code, or retry from a fresh `sf org open --target-org <alias>`.) This applies to *every* Key/Secret reveal in this kit.

> 🔴 **Handle these secrets safely.** Never commit them or paste them into any public doc/canvas. If you want a scratch place to hold the values while you work, use a **local file that git ignores** (e.g. `web/.env`, already gitignored) and delete it when you decommission the org.

### Verify the token mint (local terminal — keeps the secret off any transcript)

**[Terminal — run from anywhere.]** Tip: it's easiest to paste the `curl` template into a text editor, fill in the URL / key / secret there, then paste the completed command — editing a long one-liner inline is error-prone.

```bash
curl -s -X POST "https://<your-org>.my.salesforce.com/services/oauth2/token" -d "grant_type=client_credentials" -d "client_id=<CONSUMER_KEY>" -d "client_secret=<CONSUMER_SECRET>" | python3 -m json.tool
```
Expect `access_token`, `token_type: Bearer`, `scope: sfap_api chatbot_api api`. `invalid_client` → key/secret wrong or app not propagated (wait 2–5 min). `invalid_grant` → Client Credentials Flow not enabled (check **both** places) or Run-As not set.

### Fill in `web/.env` — precisely

The `web/.env` is the **#1 source of failures** in this section. Every value must be exact.

**[Terminal — from `<repo>/web`]:**
```bash
cd <repo>/web && cp .env.example .env
```

Then set each value. 🔴 **Paste RAW values — no quotes.** 🔴 **`VITE_SF_MYDOMAIN` must have exactly ONE `https://`** (pasting a full URL over a pre-filled `https://` gives `https://https://…`, which fails with a generic Agent-API `400 "mode":"unknown"`).

| `web/.env` variable | What to paste | Shape hint |
|---|---|---|
| `VITE_SF_MYDOMAIN` | your org My Domain URL | `https://<domain>.my.salesforce.com` (one `https://`) |
| `VITE_AGENT_ID` | the agent's **BotDefinition Id** | starts `0Xx…` |
| `VITE_CLIENT_ID` | the Agent-API ECA **Consumer Key** | starts `3MVG9F…` |
| `VITE_ACCESS_TOKEN` | the minted **access_token** | the long `eyJ…` blob |
| `SF_CLIENT_SECRET` | the Agent-API ECA **Consumer Secret** | server-only (no `VITE_` prefix) |

> 💡 **Mnemonic so you don't swap them:** `VITE_CLIENT_ID` is the short key that starts **`3MVG9F…`**; `VITE_ACCESS_TOKEN` is the long **`eyJ…`** blob. The token appears **in quotes** in the `curl` JSON output — strip the quotes when you paste.
>
> Get `VITE_AGENT_ID` with: `sf data query --target-org <alias> -q "SELECT Id FROM BotDefinition WHERE DeveloperName='Headless360_Order_Assistant'"`.

### Run the client — two terminals + a browser

The agent must be a **non-"Agentforce (Default)"** type (Employee qualifies) — the Agent API doesn't support Default. The browser can't call `api.salesforce.com` directly (no CORS) and the token must never live in browser JS, so **`proxy.mjs` holds the token server-side and forwards**. You run **two long-lived processes** in **two separate terminals**, plus the browser. Each terminal starts fresh — `cd <repo>/web` in **both**.

- **[Terminal A — `<repo>/web`]** (once): `npm install`
- **[Terminal A — `<repo>/web`]**: `node proxy.mjs`  — **leave running** (holds the token, forwards to the Agent API, → `:8787`)
- **[Terminal B — `<repo>/web`]** (new window): `npm run dev`  — **leave running** (serves the React app, → `:5173`)
- **[Browser]**: open **http://localhost:5173** → "Ask the agent" → **status of order OR-1003**

Success: the web card shows the same OR-1003 status (Exception / "Approve rebooking"), and the **HXL panel** renders the widget shape you deployed in 4b — the hand-built React card (left) and the **React Mosaic renderer** (right), side by side. The interactive `OrderAssistant` quick-pick buttons re-drive the agent; the response widget binds live data.

> 🔄 **Restart after any `.env` edit.** Both `proxy.mjs` and Vite read `web/.env` **only at startup** — editing `.env` while they run changes nothing. After any edit (or a fresh token): **Ctrl-C both, re-run `node proxy.mjs` and `npm run dev`, then hard-refresh the browser.** If a port is stuck: `lsof -ti tcp:8787 | xargs kill -9` (and `:5173`).

> **Link the two surfaces:** set `VITE_HXL_VIEWER_URL=/lightning/n/HXL_Widget_Viewer` in `web/.env` — the HXL panel's **"Open HXL Widget Viewer"** footer link then jumps straight to the in-org viewer (from 4b). Leave it empty to hide the link.

The web widget JSON (`web/src/widgets/*.web.json`) is a **bindable twin** of the deployed bundle (it adds `{{token}}` bindings the strict server schema forbids); the renderer is **partner-authored** (not the platform HXL runtime) — the honest "no gated dependency" proof. Details: [`web/README.md`](../../web/README.md).

### 🔴 Checkpoint 4c — it's the token, not the network
The web card shows the same OR-1003 status, and the HXL side-by-side renders.
- **`400 "mode":"unknown"`** → check `web/.env`: doubled `https://` in `VITE_SF_MYDOMAIN`, token pasted with quotes, or the token in the wrong field — then **restart both processes + hard-refresh**.
- `401` / empty → **expired/wrong token**: mint a fresh one into `web/.env` and **restart `node proxy.mjs`** (it reads `.env` at startup).
- session-start **412** → assign the **agent-access permset** to the Run-As user (an Employee agent is invisible to a user without agent access); confirm the agent is **published + activated**.
- **400 "Invalid user ID"** → `bypassUser` wrong for an Employee agent.
- First call may show a timeout-style delay (session start + the 120s Agent-API ceiling) — wait for the card; check the **proxy log** (Terminal A) for the real status, not just the truncated browser error. More → [ISSUES.md](../ISSUES.md).

---

## 4d — Extend it (author your own widget)

**Author in the public Playground (no Salesforce login required):** **https://www.headlessexperiencelayer.com/playground/** — a standalone SPA with a 14-step tutorial ladder (each tutorial is itself a widget; open the code view to see the JSON). It's the fastest way to internalize Mosaic; reference it directly.

**Export → assemble → deploy.** Use the Playground's **Copy → "Reusable widget"** export — it wraps your widget as `{ "type": "lightning__agentforceWidget", "contentBody": { "widgetBody": { … } } }`, exactly what a `UiWidgetBundle` expects. A bundle is a folder of **three files** under `uiWidgets/<Name>/`:

```
uiWidgets/MyWidget/
├── MyWidget.uiwidget-meta.xml    # bundle descriptor (lowercase "uiwidget", name-prefixed)
├── MyWidget.json                 # the exported widget definition
└── schema.json                   # the widget's input schema (must declare properties.attributes)
```

Drop it beside the samples in `reference/hxl-widget-sample/uiWidgets/`, add it to that folder's `package.xml`, and deploy with the same `--metadata-dir` command (from the repo root). Then **Refresh** the Widget Viewer to see it.

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

### 🚧 Checkpoint 4d
A widget you authored deploys clean (`--metadata-dir`, **Succeeded**, 0 errors) and appears in the **HXL Widget Viewer** after **Refresh**. If *"block … isn't allowed at $.widgetBody"* → swap the root to `tile/widget`. More symptoms → [ISSUES.md](../ISSUES.md).

> **Reminder:** a clean deploy + in-org view + external side-by-side proves the widget **lands and renders where you control the surface** — it does **not** prove a platform **channel auto-render** (ChatGPT/Slack/Agentforce). That path is still gated. Frame accordingly.

---

[← Module 3a](./03a-custom-mcp-server.md) · [Overview](../../OVERVIEW.md) · [Module 5 →](./05-slack.md)
