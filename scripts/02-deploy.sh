#!/usr/bin/env bash
# Deploy the reference-build metadata to the workshop org.
#
# 3-phase sequence (order matters — see KNOWN-GAPS T11, validated 2026-08-06):
#   1. Deploy all metadata EXCEPT the permission set. The agent ships as an
#      Agent Script authoring bundle (aiAuthoringBundles/); the compiled runtime
#      (Bot + GenAiPlannerBundle) is NOT in source — it's a build output that
#      `sf agent publish` generates. Shipping both collides on a fresh org
#      ("DeveloperName already in use by a Bot Definition").
#   2. `sf agent publish` the authoring bundle → compiles the Bot + planner at the
#      correct bare name; then `sf agent activate`.
#   3. Deploy the permission set LAST — its <agentAccesses> entry needs the Bot to
#      exist (created in step 2), and it grants the Order__c FLS the Apex tests need.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/scripts/lib/common.sh"
ORG="$(resolve_org "$@")"
[ -n "$ORG" ] || { fail "no org (pass --org <alias> or set ORG_ALIAS)"; exit 1; }
[ -d "$ROOT/sfdx/force-app" ] || { fail "sfdx/force-app not found"; exit 1; }
AGENT="Headless360_Order_Assistant"

cd "$ROOT/sfdx"

# 1) Everything except the permission set (deploy the whole dir minus permissionsets).
#    The ECA family (externalClientApps + extlClntApp* OAuth settings) is intentionally EXCLUDED:
#    the MCP External Client App is org-scoped (its <orgScopedExternalApp> needs the TARGET org's
#    own Id, which differs per participant), so it can't be a static committed artifact. It's a
#    per-org Module 3 step — create it via the guided card (04-mcp-connect-setup.sh), never in the
#    base capability deploy. (Validated 2026-08-15: including it fails a clean-org deploy.)
echo "→ 1/3 deploying metadata (excl. permission set + ECA)…"
DIRS=""
for d in classes objects tabs layouts lightningTypes lwc namedCredentials externalCredentials aiAuthoringBundles; do
  [ -d "force-app/main/default/$d" ] && DIRS="$DIRS force-app/main/default/$d"
done
sf project deploy start --source-dir $DIRS --target-org "$ORG" || { fail "metadata deploy failed"; exit 1; }

# 2) Publish + activate the agent (compiles Bot + planner from the authoring bundle).
echo "→ 2/3 publishing + activating the agent…"
sf agent publish authoring-bundle --api-name "$AGENT" --target-org "$ORG" --json >/dev/null \
  && pass "agent published (Bot + planner compiled)" \
  || { fail "agent publish failed — inspect: sf agent publish authoring-bundle --api-name $AGENT --target-org $ORG --json"; exit 1; }
sf agent activate --api-name "$AGENT" --target-org "$ORG" --json >/dev/null 2>&1 \
  && pass "agent activated" \
  || warn "agent activate failed/soft — confirm in Agent Builder (publish must land first)"

# 3) Base permission set LAST — <agentAccesses> now resolves (Bot exists) + grants Order__c FLS + Order tab.
#    Deploy ONLY Headless360_Workshop_Access — NOT the whole permissionsets/ dir. The React app's
#    Headless360_React_App permset references the Headless360_OrderStatus CustomApplication, which is
#    NOT in the base deploy (it ships via 07-deploy-react-bundle.sh); deploying the dir wholesale fails
#    that permset and, being atomic, takes the base permset down with it. (Cold-start regression, fixed 2026-08-16.)
echo "→ 3/3 deploying the permission set…"
sf project deploy start --source-dir force-app/main/default/permissionsets/Headless360_Workshop_Access.permissionset-meta.xml --target-org "$ORG" \
  && pass "permission set deployed" \
  || { fail "permset deploy failed — the Bot must be published (step 2) before <agentAccesses> resolves"; exit 1; }

# 4) Assign the permission set to the running user (deploying it does NOT assign it).
#    Grants Order__c FLS (the Apex tests + the Skill's USER_MODE query need it) + Order tab visibility.
echo "→ deploy done. Assign the permset:  ./scripts/03-assign-perms.sh --org $ORG"
echo "   (or assign to each participant/run-as user — deploying a permset never auto-assigns it.)"
