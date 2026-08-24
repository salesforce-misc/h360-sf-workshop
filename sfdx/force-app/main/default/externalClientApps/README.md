# External Client Apps (ECA) — deployable MCP + Agent-API OAuth config

**What this is:** the External Client App metadata for the two Headless 360 OAuth clients —
`Headless360_MCP_Client` (Claude / Hosted-MCP) and `Headless360_Agent_API` (React sample client) — retrieved
from a validated workshop org on **2026-08-06**.

> ⚠️ **Workshop path = the manual guided card (Module 3), NOT this metadata deploy.** The committed
> `Headless360_MCP_Client` file carries a **scrubbed placeholder** `orgScopedExternalApp` Id
> (`00D-XXXXXXXXXXXXXX`), which **fails validation on a clean org** (confirmed 2026-08-15) — which is why the
> ECA is **excluded from the base deploy** (`02-deploy.sh`). The cross-org proof below used a *real* source-org
> Id that auto-re-resolves; to use the metadata path, first set a valid `orgScopedExternalApp` Id (or inject the
> target org's Id per deploy). For the workshop, run `04-mcp-connect-setup.sh` and follow the card.

## Why it matters (the Option-1 finding, 2026-08-06)

The kit long treated ECA creation as a **UI-only manual step** (the Module-2/3 teaching moment) and flagged
"automate the ECA via metadata" as a **gated TODO**. That TODO is now **closed**: the full ECA family — including
the two hard bits — **is deployable metadata**:

- `isNamedUserJwtEnabled = true` — the **JWT-token toggle** (the `INVALID_JWT_FORMAT` gotcha)
- `isPkceRequired = true` — **PKCE**
- `isConsumerSecretOptional = true` — the "uncheck require secret" step
- `commaSeparatedOauthScopes = RefreshToken, MCP` — the **MCP scope** (UI label "Access Salesforce hosted MCP Servers")
- RT rotation, 30-day inactivity TTL, IP-enforce policy — all captured

**Verified:** `sf project deploy start … --dry-run` returns **4/4 components validated** against the source org.

## The four component types (one bundle per client)

| Dir | Type | Holds |
|---|---|---|
| `externalClientApps/` | `ExternalClientApplication` | the app shell (label, contact, `orgScopedExternalApp`) |
| `extlClntAppGlobalOauthSets/` | `ExtlClntAppGlobalOauthSettings` | callbacks, PKCE, JWT toggle, secret-optional, RTR |
| `extlClntAppOauthSettings/` | `ExtlClntAppOauthSettings` | the OAuth **scopes** (`RefreshToken, MCP`) |
| `extlClntAppOauthPolicies/` | `ExtlClntAppOauthConfigurablePolicies` | IP relaxation, RT validity, session level |

## ✅ Cross-org deploy — PROVEN (2026-08-06)

Deployed this bundle into a **second, different-lineage org** (a Health Cloud dev-ed, a different
org template). Result: **4/4 components `created: True`**, and a retrieve-back confirmed everything portable:

- ✅ `isNamedUserJwtEnabled=true` **survived** — the JWT toggle deploys as metadata (no more manual checkbox)
- ✅ `isPkceRequired=true`, `isConsumerSecretOptional=true`, scope `RefreshToken, MCP` — all intact
- ✅ **fresh consumer key auto-minted** per org (the target org mints its own key ≠ the source key) — no key leakage
- ✅ `orgScopedExternalApp` **auto-re-resolved** to the new org's ID (`00D…:…`) — no manual edit needed

### The one portability fix (already applied to these files)
The **`ExtlClntAppOauthSettings` must NOT carry `<oauthLink>`** — it's an org-scoped, platform-generated ID
(`00D…:888…`). A verbatim retrieve includes it and the cross-org deploy **fails** with *"couldn't update your OAuth
link … doesn't have distribution state PACKAGED."* **Stripping `<oauthLink>` fixes it** (the platform generates the
link per org). The `consumerKey` is likewise stripped from `*_glbloauth` (each org mints its own). Both strips are
baked into the committed files here — retrieve-then-deploy is clean as-is.

### Bulk provisioning path (the ~20–30 summit orgs)
```
sf project deploy start \
  -d force-app/main/default/externalClientApps \
     force-app/main/default/extlClntAppGlobalOauthSets \
     force-app/main/default/extlClntAppOauthSettings \
     force-app/main/default/extlClntAppOauthPolicies \
  --target-org <ORG>          # loop over the org list
```

### Still manual regardless (not blockers, by design)
- **MCP-server activation** (Setup → API Catalog → MCP Servers) is **not metadata** — per-org manual/CLI step.
- **Consumer *secret*** (if a flow needs it) isn't retrievable; secret-optional is on, so the MCP/PKCE flow doesn't
  need it, but the React Agent-API client-credentials flow does → still set per org.
- **End-to-end smoke-test** (connect Claude → read a record) still required per org — a green ECA ≠ a working MCP
  connection (needs the server activated too).

Only the `Headless360_MCP_Client` bundle was cross-org-verified. The `Headless360_Agent_API` bundle was retrieved the
same way — **apply the same `oauthLink` strip + dry-run it** before relying on it (it uses client-credentials, which
also needs the consumer secret set per org).
