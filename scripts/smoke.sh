#!/usr/bin/env bash
# Participant smoke test — is my org ready to build?
# Two parts:
#   MECHANICAL (auto, CLI-only): org reachable · Agentforce enabled · kit deployed ·
#     permset assigned · hero data · the REAL Skill returns OR-1003 · (opt) Apex tests.
#   MANUAL (printed checklist): the browser/MCP/Slack steps the CLI can't verify.
#
# Run anytime after ./scripts/onboard.sh. Read-only except a transient
# Order__c query — safe to re-run. Exits non-zero if any mechanical check fails.
#
# Usage: ./scripts/smoke.sh --org <alias> [--with-tests]
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/scripts/lib/common.sh"
ORG="$(resolve_org "$@")"
[ -n "$ORG" ] || { fail "no org (pass --org <alias> or set ORG_ALIAS)"; exit 1; }
FAILED=0

echo "═══ MECHANICAL checks (org: $ORG) ═══"

# 1. reachable
sf org display --target-org "$ORG" >/dev/null 2>&1 \
  && pass "org reachable" || { fail "org not reachable — sf org login web --alias $ORG"; exit 1; }

# 2. Agentforce enabled (Bot/AiAuthoringBundle metadata types present)
AF="$(sf org list metadata-types --target-org "$ORG" --json 2>/dev/null \
  | python3 -c "import sys,json;t=set(m['xmlName'] for m in json.load(sys.stdin)['result']['metadataObjects']);print('yes' if 'Bot' in t and 'AiAuthoringBundle' in t else 'no')" 2>/dev/null)"
[ "$AF" = "yes" ] && pass "Agentforce enabled" || { fail "Agentforce NOT enabled — Setup → Agentforce → ON (see PARTICIPANT-SETUP.md step 2)"; FAILED=1; }

# 3. Order__c object + hero data
ROWS="$(sf data query --target-org "$ORG" \
  --query "SELECT Order_Number__c FROM Order__c WHERE Order_Number__c LIKE 'OR-100%'" --json 2>/dev/null \
  | grep -o '"Order_Number__c"' | wc -l | tr -d ' ')"
[ "${ROWS:-0}" -ge 5 ] && pass "hero data: $ROWS orders (OR-1001..OR-1005)" \
  || { fail "hero data missing (${ROWS:-0} rows) — ./scripts/steps/seed-hero-data.sh --org $ORG"; FAILED=1; }

# 4. permset assigned (any assignee — each participant owns their org)
PSA="$(sf data query --target-org "$ORG" \
  --query "SELECT Assignee.Username FROM PermissionSetAssignment WHERE PermissionSet.Name='Headless360_Workshop_Access'" --json 2>/dev/null \
  | grep -o '"Username"' | wc -l | tr -d ' ')"
[ "${PSA:-0}" -ge 1 ] && pass "permset 'Headless360_Workshop_Access' assigned ($PSA user/s)" \
  || { fail "permset not assigned — ./scripts/steps/assign-perms.sh --org $ORG"; FAILED=1; }

# 5. agent deployed
BOTS="$(sf data query --target-org "$ORG" \
  --query "SELECT DeveloperName FROM BotDefinition WHERE DeveloperName='Headless360_Order_Assistant'" --json 2>/dev/null \
  | grep -o '"DeveloperName"' | wc -l | tr -d ' ')"
[ "${BOTS:-0}" -ge 1 ] && pass "agent 'Headless360_Order_Assistant' deployed" \
  || { warn "agent not found via BotDefinition — confirm publish/activate in Agent Builder"; }

# 6. THE key check — invoke the real Skill the agent runs (WITH USER_MODE path)
SK="$(mktemp -t skill_smoke.XXXX.apex)"; trap 'rm -f "$SK"' EXIT
cat > "$SK" <<'AEOF'
OrderStatusSkill.Request hit = new OrderStatusSkill.Request(); hit.orderNumber = 'OR-1003';
OrderStatusSkill.Request miss = new OrderStatusSkill.Request(); miss.orderNumber = 'OR-9999';
List<OrderStatusSkill.Response> r = OrderStatusSkill.getStatus(new List<OrderStatusSkill.Request>{ hit, miss });
OrderStatusSkill.Response a = r[0];
Boolean ok = a.found==true && a.status=='Exception' && a.availableAction=='Approve rebooking'
             && a.card!=null && a.recordId!=null && r[1].found==false;
System.debug('SKILLSMOKE=' + (ok ? 'PASS' : 'FAIL'));
AEOF
SK_OUT="$(sf apex run --target-org "$ORG" --file "$SK" 2>/dev/null | grep -oE 'SKILLSMOKE=(PASS|FAIL)' | tail -1)"
[ "$SK_OUT" = "SKILLSMOKE=PASS" ] \
  && pass "Skill invocation: OR-1003 → Exception / 'Approve rebooking' + card; not-found path OK" \
  || { fail "Skill invocation FAILED (${SK_OUT:-no result}) — agent code path broken (check FLS + hero data)"; FAILED=1; }

# 7. optional: Apex test suite
if printf '%s\n' "$@" | grep -q -- '--with-tests'; then
  if sf apex run test --target-org "$ORG" \
       --class-names OrderStatusSkillTest --class-names SendSlackCardActionTest \
       --result-format human --wait 10 2>/dev/null | grep -qiE "Pass Rate +100%"; then
    pass "Apex tests: 4/4 pass"
  else
    warn "Apex tests not all passing — sf apex run test -o $ORG --class-names OrderStatusSkillTest --class-names SendSlackCardActionTest -r human"
  fi
fi

echo
echo "═══ MANUAL checks (CLI can't verify — tick these in the browser) ═══"
cat <<EOF
  [ ] App Launcher → "H360 Orders" (NOT the standard "Orders" tab) → the All Orders list view shows 5 rows (OR-1003 = Exception)
        (seeded by onboard.sh / Module 2 — if the mechanical 'hero data' check above is green they exist even if the UI looks empty)
  [ ] Agent Builder → 'Headless360 Order Assistant' opens; ask "status of order OR-1003"
        → returns the real record (carrier exception, Approve rebooking)
  [ ] Module 3 — Hosted MCP + ECA (run ./scripts/connect-mcp.sh --org $ORG):
        [ ] MCP servers activated (Setup → API Catalog → MCP Servers)
        [ ] ECA created with JWT-token toggle ON + PKCE (the INVALID_JWT_FORMAT gotcha)
        [ ] in Claude: "read order OR-1003 from Salesforce" → real data (not just a green dot)
  [ ] Module 5 (if using Slack) — Slack bot token set on the Slack_API external credential;
        SendSlackCardAction posts a Block Kit card for OR-1003
EOF

echo
if [ "$FAILED" -eq 0 ]; then
  pass "MECHANICAL: all green — org is build-ready (finish the manual checks above)."
else
  fail "MECHANICAL: one or more checks failed (see above) — fix, then re-run ./scripts/smoke.sh --org $ORG"
fi
exit $FAILED
