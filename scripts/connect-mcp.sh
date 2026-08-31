#!/usr/bin/env bash
# Per-org MCP / Connect (Module 3) setup helper — run ONCE per participant org.
#
# Automates the deterministic parts of getting an org ready for the Connect module
# (reachability, edition/LEX sanity, deploy, permset) and gives an exact-values,
# copy-paste guided walk for the ONE step no org type auto-provisions: the
# External Client App (mcp_api + PKCE + JWT tokens). Use --verify after the manual
# ECA step to confirm it landed. No deletes; safe to re-run (idempotent).
#
# Usage:
#   ./scripts/connect-mcp.sh --org <alias>            # run the setup + print the guided ECA card
#   ./scripts/connect-mcp.sh --org <alias> --verify   # verify the org is Connect-ready (post-ECA)
#   ./scripts/connect-mcp.sh --org <alias> --no-deploy # skip the metadata deploy (already deployed)
#
# See PARTICIPANT-SETUP.md and GUIDE.md Module 3 for the why.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/scripts/lib/common.sh"

# --- Connect-module constants (single source of truth for the guided values) ---
# Two callback paths — register BOTH (one per line in the ECA):
#   • claude.ai web / desktop app  → https://claude.ai/api/mcp/auth_callback
#   • Claude Code CLI (loopback)   → http://localhost:8765/callback  (from oauth.callbackPort in ~/.claude.json)
# The CLI does exact-match on localhost:<port>/callback; omitting it → redirect_uri_mismatch.
MCP_CALLBACK_URL_WEB="https://claude.ai/api/mcp/auth_callback"
MCP_CALLBACK_URL_CLI="http://localhost:8765/callback"
MCP_OAUTH_SCOPES="mcp_api, refresh_token, offline_access"
MCP_SERVERS="headless-360 (Beta) sobject-reads sobject-all salesforce-api-context metadata-experts"
ECA_LABEL="Headless360 MCP Client"      # suggested label; participants may rename
PERMSET="Headless360_Workshop_Access"

# --- flags (resolve_org handles --org; parse the rest) ---
ORG="$(resolve_org "$@")"
VERIFY=0; DO_DEPLOY=1
while [ $# -gt 0 ]; do
  case "$1" in
    --verify) VERIFY=1; shift;;
    --no-deploy) DO_DEPLOY=0; shift;;
    --org) shift 2;;
    *) shift;;
  esac
done
[ -n "$ORG" ] || { fail "no org (pass --org <alias> or set ORG_ALIAS in .env)"; exit 1; }
command -v sf >/dev/null 2>&1 || { fail "sf CLI not found — https://developer.salesforce.com/tools/salesforcecli"; exit 1; }

# --- reachability (shared gate for both modes) ---
sf org display --target-org "$ORG" >/dev/null 2>&1 \
  || { fail "org '$ORG' not reachable — run: sf org login web --alias $ORG"; exit 1; }
pass "org '$ORG' reachable"

# --- edition / LEX sanity (best-effort; warn-only, never blocks) ---
EDITION="$(sf org display --target-org "$ORG" --json 2>/dev/null | grep -o '"edition"[^,]*' | head -1)"
# Trial / OrgFarm orgs often omit "edition" from `org display` → fall back to Organization.OrganizationType.
[ -n "$EDITION" ] || EDITION="$(sf data query --target-org "$ORG" -q 'SELECT OrganizationType FROM Organization LIMIT 1' --json 2>/dev/null | grep -o '"OrganizationType"[^,}]*' | head -1)"
[ -n "$EDITION" ] && echo "  org $EDITION"
case "$EDITION" in
  *Developer*|*Enterprise*|*Partner*) pass "edition supports Agentforce/Einstein (Einstein1AIPlatform-eligible)";;
  "") warn "edition not reported — confirm Developer/Enterprise (Agentforce requires it)";;
  *) warn "edition '$EDITION' may not support Agentforce — see PARTICIPANT-SETUP.md";;
esac

# ============================ VERIFY MODE ============================
if [ "$VERIFY" -eq 1 ]; then
  echo "--- Verify: is '$ORG' Connect-ready? ---"
  RC=0
  # External Client App present? (the ECA is the load-bearing MCP artifact)
  if sf org list metadata --metadata-type ExternalClientApplication --target-org "$ORG" >/dev/null 2>&1; then
    ECAS="$(sf org list metadata --metadata-type ExternalClientApplication --target-org "$ORG" --json 2>/dev/null | grep -c '"fullName"')"
    if [ "${ECAS:-0}" -ge 1 ]; then pass "External Client App present (count: $ECAS)"
    else fail "no External Client App found — create it (re-run without --verify for the guided card)"; RC=1; fi
  else
    warn "could not query ExternalClientApplication metadata — confirm the ECA in Setup → External Client App Manager"
  fi
  # Permset assigned? (read-only query — do NOT re-assign here: an already-assigned
  # permset makes `sf org assign permset` exit non-zero with "Duplicate
  # PermissionSetAssignment", which would misreport a correctly-configured org.)
  ASSIGNED="$(sf data query --target-org "$ORG" \
    --query "SELECT COUNT() FROM PermissionSetAssignment WHERE PermissionSet.Name='$PERMSET'" \
    --json 2>/dev/null | grep -o '"totalSize"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$')"
  if [ "${ASSIGNED:-0}" -ge 1 ]; then
    pass "permset '$PERMSET' assigned (assignments: $ASSIGNED)"
  else
    warn "permset '$PERMSET' not assigned yet — deploy the reference build + assign (steps/deploy.sh / steps/assign-perms.sh)"
  fi
  echo "  ⓘ MCP server activation + the JWT-token toggle can't be read via CLI — confirm in the UI:"
  echo "    • Setup → API Catalog → MCP Servers → Salesforce Servers: $MCP_SERVERS active"
  echo "    • ECA → OAuth: 'Issue JWT-based access tokens for named users' is CHECKED (the INVALID_JWT_FORMAT gotcha)"
  echo "    • Smoke-test: ask Claude to read a record via sobject-reads (don't trust the green dot — run the flow)"
  exit $RC
fi

# ============================ SETUP MODE ============================
# 1) Deploy the reference build (idempotent) unless told to skip.
#    Delegates to steps/deploy.sh — the 3-phase sequence (metadata → agent publish+activate →
#    permset last). A wholesale `sf project deploy start --source-dir force-app` would FAIL here:
#    the permset's <agentAccesses> only resolves after the agent is published (KNOWN-GAPS T11),
#    and this helper doesn't publish. Always go through steps/deploy.sh so the order is correct.
if [ "$DO_DEPLOY" -eq 1 ]; then
  if [ -d "$ROOT/sfdx/force-app" ]; then
    echo "--- Deploy reference build (3-phase via steps/deploy.sh) → $ORG ---"
    "$ROOT/scripts/steps/deploy.sh" --org "$ORG" \
      && pass "reference build deployed" \
      || warn "deploy failed — check output; if a prior deploy was interrupted, run: sf org list metadata -m AiAuthoringBundle (orphan-bundle gotcha)"
  else
    warn "sfdx/force-app not found — skipping deploy"
  fi
else
  echo "  (--no-deploy) skipping metadata deploy"
fi

# 2) Assign the workshop permset (idempotent).
sf org assign permset --name "$PERMSET" --target-org "$ORG" >/dev/null 2>&1 \
  && pass "permset '$PERMSET' assigned" \
  || warn "permset '$PERMSET' not newly assigned — already assigned (fine), or deploy the reference build first (steps/deploy.sh)"

# 3) Guided External Client App card — the WORKSHOP PATH (manual, per org).
#    The ECA is a per-org Module 3 step: create it from the card below. It is NOT in the base
#    deploy (steps/deploy.sh) because it's org-scoped — <orgScopedExternalApp> needs the TARGET
#    org's own Id, so it can't be a static committed artifact.
#    On the metadata-deploy path (externalClientApps/ + extlClntApp*/): it exists and once
#    deployed cross-org in testing, BUT the committed file carries a SCRUBBED placeholder org Id
#    (00D-XXXXXXXXXXXXXX) that FAILS validation on a clean org (confirmed 2026-08-15). To use it
#    you must first set orgScopedExternalApp to a valid Id (or inject the target org's Id per
#    deploy). For the workshop, use this manual card — it always works. See the ECA README.
#    STILL MANUAL regardless: MCP-server activation (API Catalog — not metadata) + the consumer
#    SECRET for the Agent-API client-credentials flow + the e2e smoke-test.
#    This guided card is also the Module 3 teaching moment.
cat <<EOF

──────────────────────────────────────────────────────────────────────────────
 Connect module (M3) — External Client App  ·  org: $ORG
──────────────────────────────────────────────────────────────────────────────
 First, activate the Hosted MCP servers:
   Setup → Quick Find "MCP Servers" (under API Catalog) → Salesforce Servers →
   activate:  $MCP_SERVERS

 Then create the External Client App:
   Setup → External Client App Manager → New
   • Label / API name:  $ECA_LABEL   ·   Contact email: yours (REQUIRED)
   • Enable OAuth:      ON
   • Flow Enablement:  CHECK "Enable Authorization Code and Credentials Flow"  🔴 NONE on by default (MCP = auth-code + PKCE)
   • Callback URLs:     $MCP_CALLBACK_URL_WEB   (claude.ai web / desktop)
                        $MCP_CALLBACK_URL_CLI        (Claude Code CLI — loopback; one per line)
   • OAuth scopes (add these two — exact UI labels):
       - "Access Salesforce hosted MCP Servers (mcp_api)"
       - "Perform requests at any time (refresh_token, offline_access)"     [do NOT add api / openid]
   • "Require secret for Web Server Flow": confirm UNchecked (usually already is)
   • PKCE: "Require Proof Key for Code Exchange (PKCE)…" is ON and CAN'T be unchecked — leave it (PKCE is wanted)
   • CHECK  "Issue JSON Web Token (JWT)-based access tokens for named users"   ← the #1 gotcha
   Save (the button may say "Create"), then copy the Consumer Key (Settings → OAuth Settings) = OAuth Client ID.

 🔴 If MCP calls fail INVALID_AUTH_HEADER / INVALID_JWT_FORMAT → the JWT-token
    box is unchecked. If invalid_client_id → the app hasn't propagated; wait.
    If OAuth fails redirect_uri_mismatch → the callback you connected from isn't
    in the app's list; add BOTH URLs above (CLI needs the localhost:8765 one).

 Then connect Claude Code (no DCR → pass the Consumer Key as a STATIC client_id; no secret):
   cd <your cloned repo dir>     # MCP servers are project-scoped in ~/.claude.json
   claude mcp add --transport http --client-id <Consumer Key> --callback-port 8765 h360 https://api.salesforce.com/platform/mcp/v1/platform/headless-360
   → restart Claude, then /mcp → h360 → Authenticate → approve the tool prompts → ask "read order OR-1003"
   (sandbox/scratch org: insert /sandbox/ before platform/headless-360)

 Verify when done:  ./scripts/connect-mcp.sh --org $ORG --verify
──────────────────────────────────────────────────────────────────────────────
EOF
