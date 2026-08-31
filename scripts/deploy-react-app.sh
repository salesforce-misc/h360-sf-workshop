#!/usr/bin/env bash
# Module 4b — deploy the native IN-ORG React app (Multi-Framework UI Bundle).
#
# This is a SUBSEQUENT/optional deploy step, deliberately NOT part of steps/deploy.sh
# (base capability): the UI Bundle needs an `npm` build first and pulls a large
# node_modules (the deploy footgun) — node_modules is .forceignore'd (repo root +
# bundle level) so the scoped deploy below stays clean.
#
# Usage:
#   ./scripts/deploy-react-app.sh --org <alias>              # npm install + build + deploy
#   ./scripts/deploy-react-app.sh --org <alias> --no-build   # deploy only (dist/ already built)
#
# Validated build + scoped deploy on a clean trial-EE org 2026-08-15.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/scripts/lib/common.sh"
ORG="$(resolve_org "$@")"
[ -n "$ORG" ] || { fail "no org (pass --org <alias> or set ORG_ALIAS)"; exit 1; }
BUNDLE="force-app/main/default/uiBundles/Headless360_OrderStatus"
APP="force-app/main/default/applications/Headless360_OrderStatus.app-meta.xml"
REACT_PERMSET="force-app/main/default/permissionsets/Headless360_React_App.permissionset-meta.xml"
AGENT_API="Headless360_Order_Assistant"   # BotDefinition DeveloperName → baked in as VITE_AGENT_ID
DO_BUILD=1
for a in "$@"; do [ "$a" = "--no-build" ] && DO_BUILD=0; done

cd "$ROOT/sfdx"
[ -d "$BUNDLE" ] || { fail "UI bundle not found: $BUNDLE"; exit 1; }

if [ "$DO_BUILD" -eq 1 ]; then
  echo "→ 1/4 baking THIS org's agent id into the build (VITE_AGENT_ID)…"
  #   The chat (Agentforce Conversation Client) binds to the agent by Id, which Vite INLINES at
  #   build time. Skip this and the chat shows "unavailable" (or binds to the wrong org's agent).
  AGENT_ID="$(sf data query --target-org "$ORG" -q "SELECT Id FROM BotDefinition WHERE DeveloperName='$AGENT_API'" --json 2>/dev/null | python3 -c 'import sys,json;r=json.load(sys.stdin)["result"]["records"];print(r[0]["Id"] if r else "")' 2>/dev/null)"
  [ -n "$AGENT_ID" ] || { fail "could not resolve agent id (DeveloperName=$AGENT_API) — publish the agent first (steps/deploy.sh / onboard.sh)"; exit 1; }
  echo "VITE_AGENT_ID=$AGENT_ID" > "$BUNDLE/.env.local"
  pass "VITE_AGENT_ID=$AGENT_ID → $BUNDLE/.env.local"
  echo "→ 2/4 building the React bundle (npm install + build)…"
  ( cd "$BUNDLE" && npm install && npm run build ) \
    && pass "React bundle built (dist/)" \
    || { fail "npm build failed — run 'npm install && npm run build' in sfdx/$BUNDLE"; exit 1; }
else
  echo "  (--no-build) skipping bake+build — ensure sfdx/$BUNDLE/.env.local has VITE_AGENT_ID for THIS org"
fi

echo "→ 3/4 deploying UI Bundle + surfacing app + permset → $ORG (node_modules .forceignore'd)…"
#   The CustomApplication (uiBundle-backed) is what puts the React app in the App Launcher — the
#   bundle alone is invisible. The app + permset deploy AFTER the bundle so the uiBundle reference resolves.
sf project deploy start -d "$BUNDLE" "$APP" "$REACT_PERMSET" --target-org "$ORG" \
  && pass "in-org React app deployed (UIBundle + CustomApplication + permset)" \
  || { fail "UIBundle/app deploy failed"; exit 1; }

echo "→ 4/4 assigning app-visibility permset…"
sf org assign permset --name Headless360_React_App --target-org "$ORG" >/dev/null 2>&1 \
  && pass "app visibility granted (Headless360_React_App assigned)" \
  || warn "permset assign failed (likely already assigned) — non-fatal"

echo "→ Open it: App Launcher → 'Headless360 Order Status' (the native React app)."
echo "   Details: sfdx/$BUNDLE/README.md"
