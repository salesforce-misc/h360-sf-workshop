#!/usr/bin/env bash
# One-command per-participant org onboarding — runs the SCRIPTABLE half of setup
# after the two manual Setup-UI steps are done (see PARTICIPANT-SETUP.md):
#   Manual step 1: change the admin user's email to your own (+ verify).
#   Manual step 2: enable Agentforce in Setup.
# Then this script (step 3+):
#   • guard: confirm Agentforce is actually enabled (fail fast, not the cryptic
#     "Not available for deploy for this organization" — KNOWN-GAPS T13)
#   • deploy the kit (02) → assign the permset to you (03) → seed hero data (05)
#   • basic smoke test: 5 hero rows present, bot deployed
#
# Idempotent: safe to re-run. Does NOT do the per-org MCP activation / ECA
# (Module 3 — the manual teaching step) or the Slack token (Module 5).
#
# Usage: ./scripts/onboard.sh --org <alias>
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/scripts/lib/common.sh"
ORG="$(resolve_org "$@")"
[ -n "$ORG" ] || { fail "no org (pass --org <alias> or set ORG_ALIAS)"; exit 1; }

# --- step 3a: org reachable ----------------------------------------------------
sf org display --target-org "$ORG" >/dev/null 2>&1 \
  || { fail "org '$ORG' not reachable — run: sf org login web --alias $ORG"; exit 1; }
pass "org '$ORG' reachable"

# --- step 3b: GUARD — is Agentforce enabled? (Bot metadata type => enabled) ----
# On a fresh org WITHOUT Agentforce, Bot/AiAuthoringBundle aren't even queryable
# and the agent-bundle deploy dies with "Not available for deploy for this
# organization". Detect that here and point back to the manual toggle.
AF="$(sf org list metadata-types --target-org "$ORG" --json 2>/dev/null \
  | python3 -c "import sys,json;t=set(m['xmlName'] for m in json.load(sys.stdin)['result']['metadataObjects']);print('yes' if 'Bot' in t and 'AiAuthoringBundle' in t else 'no')" 2>/dev/null)"
if [ "$AF" != "yes" ]; then
  fail "Agentforce not enabled on '$ORG' (Bot/AiAuthoringBundle metadata types absent)."
  echo "     → Do manual step 2 first: Setup → Quick Find 'Agentforce' → turn Agentforce ON,"
  echo "       wait ~1-2 min for it to finish provisioning, then re-run this script."
  echo "       (See PARTICIPANT-SETUP.md.)"
  exit 1
fi
pass "Agentforce enabled (Bot + AiAuthoringBundle present)"

# --- step 3c: deploy + perms + seed -------------------------------------------
"$ROOT/scripts/steps/deploy.sh"       --org "$ORG" || { fail "deploy (02) failed"; exit 1; }
"$ROOT/scripts/steps/assign-perms.sh" --org "$ORG" || { fail "permset assign (03) failed"; exit 1; }
"$ROOT/scripts/steps/seed-hero-data.sh" --org "$ORG" || { fail "hero-data seed (05) failed"; exit 1; }

# --- step 4: basic smoke test --------------------------------------------------
echo "--- smoke test ---"
ROWS="$(sf data query --target-org "$ORG" \
  --query "SELECT Order_Number__c FROM Order__c WHERE Order_Number__c LIKE 'OR-100%'" --json 2>/dev/null \
  | grep -o '"Order_Number__c"' | wc -l | tr -d ' ')"
[ "${ROWS:-0}" -ge 5 ] && pass "hero data: $ROWS orders (incl. OR-1003)" || { fail "hero data missing ($ROWS rows)"; exit 1; }

BOTS="$(sf data query --target-org "$ORG" \
  --query "SELECT DeveloperName FROM BotDefinition WHERE DeveloperName='Headless360_Order_Assistant'" --json 2>/dev/null \
  | grep -o '"DeveloperName"' | wc -l | tr -d ' ')"
[ "${BOTS:-0}" -ge 1 ] && pass "agent 'Headless360_Order_Assistant' deployed" \
  || warn "agent not found via BotDefinition — confirm publish/activate in Agent Builder (02 runs sf agent publish+activate)"

# --- step 4b: invoke the REAL Skill the agent runs (no MCP/ECA needed) ---------
# This is the highest-value async check: if OrderStatusSkill returns OR-1003
# correctly here, the agent will work the moment MCP/ECA is wired in Module 3.
# Exercises the same WITH USER_MODE path (so it also proves the T12 permset-FLS
# grant is effective for the running user).
SKILL_APEX="$(mktemp -t skill_smoke.XXXX.apex)"
trap 'rm -f "$SKILL_APEX"' EXIT
cat > "$SKILL_APEX" <<'AEOF'
OrderStatusSkill.Request hit = new OrderStatusSkill.Request(); hit.orderNumber = 'OR-1003';
OrderStatusSkill.Request miss = new OrderStatusSkill.Request(); miss.orderNumber = 'OR-9999';
List<OrderStatusSkill.Response> r = OrderStatusSkill.getStatus(new List<OrderStatusSkill.Request>{ hit, miss });
OrderStatusSkill.Response a = r[0];
Boolean ok = a.found==true && a.status=='Exception' && a.availableAction=='Approve rebooking'
             && a.card!=null && a.recordId!=null && r[1].found==false;
System.debug('SKILLSMOKE=' + (ok ? 'PASS' : 'FAIL') + ' status=' + a.status + ' action=' + a.availableAction);
AEOF
# grep for PASS|FAIL only (the anon-apex source is echoed back, so a bare
# 'SKILLSMOKE=' also appears on the source line) and take the last match.
SKILL_OUT="$(sf apex run --target-org "$ORG" --file "$SKILL_APEX" 2>/dev/null | grep -oE 'SKILLSMOKE=(PASS|FAIL)' | tail -1)"
if [ "$SKILL_OUT" = "SKILLSMOKE=PASS" ]; then
  pass "Skill invocation: OrderStatusSkill returns OR-1003 (Exception / 'Approve rebooking') + card; not-found path OK"
else
  fail "Skill invocation FAILED (${SKILL_OUT:-no result}) — the agent's code path is broken; check permset FLS + hero data"; exit 1
fi

# --- step 4c (optional): Apex test suite (75% gate + T12 runAs-FLS fix) --------
# Skipped by default (adds ~30-60s); run with --with-tests for a full validation.
if printf '%s\n' "$@" | grep -q -- '--with-tests'; then
  echo "--- running Apex tests (--with-tests) ---"
  if sf apex run test --target-org "$ORG" \
       --class-names OrderStatusSkillTest --class-names SendSlackCardActionTest \
       --result-format human --wait 10 2>/dev/null | grep -qiE "Pass Rate +100%"; then
    pass "Apex tests: 4/4 pass (OrderStatusSkill + SendSlackCardAction)"
  else
    warn "Apex tests did not all pass — run manually: sf apex run test -o $ORG --class-names OrderStatusSkillTest --class-names SendSlackCardActionTest -r human"
  fi
fi

echo "──────────────────────────────────────────────────────────────────────"
pass "org '$ORG' onboarded: kit deployed, permset assigned, hero data seeded."
echo "  Next (manual, Module 3 teaching steps — not scripted):"
echo "   • Activate Hosted MCP servers + create the MCP ECA:  ./scripts/connect-mcp.sh --org $ORG"
echo "   • Then smoke-test the agent: in Agent Builder / Slack, ask \"status of order OR-1003\""
echo "──────────────────────────────────────────────────────────────────────"
