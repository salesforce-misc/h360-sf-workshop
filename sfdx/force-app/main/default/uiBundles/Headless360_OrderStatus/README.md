# Headless360 Order Status — React UI Bundle (in-org, Multi-Framework)

The **in-org React surface** for the Headless 360 workshop (GUIDE **Module 4a**). A React app
(Vite + TypeScript + Tailwind + shadcn/ui + the Salesforce UI Bundle SDK) deployed *inside* the
org on its `salesforce.app` origin, surfaced via the **Headless360 Order Status** CustomApplication.
It embeds the **Agentforce Conversation Client** (Lightning Out over `my.salesforce.com`) — Agentforce's
own chat UI, running as the logged-in user, **no tokens** — alongside an `Order__c` view via the Data SDK (GraphQL).

> This is *not* the external Agent-API client — that's `web/` at the repo root (Module 4b). Both reach
> the same agent; this one renders the embedded chat, the `web/` one renders a custom card.

## Deploy (the supported path)

**Use the kit script — it handles the per-org agent-id bake, build, and scoped deploy in one step:**

```bash
# from the repo root, AFTER the agent is published (scripts/steps/deploy.sh):
./scripts/deploy-react-app.sh --org <alias>
```

It: (1) queries the org's `BotDefinition` Id → writes `VITE_AGENT_ID` into `.env.local`;
(2) `npm run build` (Vite **inlines `VITE_AGENT_ID` at build time** — so a bundle built for one org
will NOT work in another; always rebuild per org); (3) scoped-deploys **only** `uiBundles/` +
`applications/` (a full `force-app` deploy would sweep this bundle's ~590 MB `node_modules` past the
Metadata API limits — `.forceignore` guards it; `dist/` ships).

Then **activate/tour**: App Launcher → **Headless360 Order Status** → ask the embedded chat
"status of order OR-1003". A blank chat means `VITE_AGENT_ID` was built for a different org (the app
renders a visible error saying so) — rerun `deploy-react-app.sh` against *this* org.

### Manual equivalent (if you're not using the script)

From this bundle directory:

```bash
# STEP 0 — bake the per-org agent id (Vite inlines it at build):
sf data query -o <alias> -q "SELECT Id FROM BotDefinition WHERE DeveloperName='Headless360_Order_Assistant'" --json \
  | python3 -c 'import sys,json;print("VITE_AGENT_ID="+json.load(sys.stdin)["result"]["records"][0]["Id"])' >> .env.local
npm install       # first time
npm run build     # → dist/  (tsc -b && vite build)
```

Then, from the **SFDX project root** (`sfdx/`):

```bash
sf project deploy start --source-dir force-app/main/default/uiBundles force-app/main/default/applications --target-org <alias>
```

## Run (local dev preview)

```bash
npm install
npm run dev            # Vite dev server (localhost)
```

Localhost has no Salesforce session, so the embedded chat needs a dev-only `VITE_SF_FRONTDOOR_URL`
in `.env.local` (see `.env.local.example`) — that branch is stripped from production builds
(`import.meta.env.DEV`), so a stray frontdoor URL can never bake into a deployed bundle.

## Test

```bash
npm run test          # Vitest (config in vitest.config.ts)
```
