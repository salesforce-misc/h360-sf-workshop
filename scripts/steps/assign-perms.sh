#!/usr/bin/env bash
# Assign the workshop permission set to the running user.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$ROOT/scripts/lib/common.sh"
ORG="$(resolve_org "$@")"
[ -n "$ORG" ] || { fail "no org (pass --org <alias> or set ORG_ALIAS)"; exit 1; }
sf org assign permset --name Headless360_Workshop_Access --target-org "$ORG" || \
  warn "permset assign failed — confirm the permset name after Task 4 scaffolds it"
