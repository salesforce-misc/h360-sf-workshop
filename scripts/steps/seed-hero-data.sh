#!/usr/bin/env bash
# Seed the 5 hero Order__c records (OR-1001..OR-1005) the demo/agent depends on.
#
# Why this exists: the metadata deploy (02) creates the Order__c object but NOT its
# data. Without these rows the agent answers "No order matches OR-1003" and
# smoke.sh fails its hero-data check. This is the per-org pre-stage step
# GUIDE Module 2 describes — scripted here so it's one command across ~20 orgs.
#
# Idempotent: upserts on the Order_Number__c external id, so re-running is safe.
# Requires the Headless360_Workshop_Access permset assigned to the running user
# (Order__c field FLS comes from the permset, not the profile — KNOWN-GAPS T12),
# so run AFTER steps/assign-perms.sh.
#
# Usage: ./scripts/steps/seed-hero-data.sh --org <alias>
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$ROOT/scripts/lib/common.sh"
ORG="$(resolve_org "$@")"
[ -n "$ORG" ] || { fail "no org (pass --org <alias> or set ORG_ALIAS)"; exit 1; }

APEX="$(mktemp -t seed_orders.XXXX.apex)"
trap 'rm -f "$APEX"' EXIT
cat > "$APEX" <<'AEOF'
List<Order__c> os = new List<Order__c>{
  new Order__c(Name='Order OR-1001', Order_Number__c='OR-1001', Status__c='Shipped',
    Owner_Name__c='Jordan Rivera', Status_Summary__c='Order OR-1001 shipped.', Next_Action__c='None'),
  new Order__c(Name='Order OR-1002', Order_Number__c='OR-1002', Status__c='Processing',
    Owner_Name__c='Priya Shah', Status_Summary__c='Order OR-1002 is being processed.', Next_Action__c='None'),
  new Order__c(Name='Order OR-1003', Order_Number__c='OR-1003', Status__c='Exception',
    Owner_Name__c='Initech', Status_Summary__c='Order OR-1003 hit a carrier exception - address needs confirmation.',
    Next_Action__c='Approve rebooking'),
  new Order__c(Name='Order OR-1004', Order_Number__c='OR-1004', Status__c='Delivered',
    Owner_Name__c='Sam Nguyen', Status_Summary__c='Order OR-1004 was delivered.', Next_Action__c='None'),
  new Order__c(Name='Order OR-1005', Order_Number__c='OR-1005', Status__c='Processing',
    Owner_Name__c='Alex Kim', Status_Summary__c='Order OR-1005 is being processed.', Next_Action__c='None')
};
upsert os Order_Number__c;
System.debug('Seeded/updated ' + os.size() + ' hero orders');
AEOF

sf apex run --file "$APEX" --target-org "$ORG" >/dev/null 2>&1 || { fail "seed apex failed — is the permset assigned? run steps/assign-perms.sh first"; exit 1; }

ROWS="$(sf data query --target-org "$ORG" \
  --query "SELECT Order_Number__c FROM Order__c WHERE Order_Number__c LIKE 'OR-100%'" --json 2>/dev/null \
  | grep -o '"Order_Number__c"' | wc -l | tr -d ' ')"
if [ "${ROWS:-0}" -ge 5 ]; then
  pass "hero data seeded ($ROWS Order__c rows, incl. OR-1003 exception)"
else
  fail "expected 5 hero orders, found ${ROWS:-0} after seed"; exit 1
fi
