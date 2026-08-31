#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/scripts/lib/common.sh"
[ -f "$ROOT/.env" ] && pass ".env present" || warn "no .env (copy .env.example → .env, set ORG_ALIAS)"
[ -f "$ROOT/sfdx/sfdx-project.json" ] && pass "sfdx project present" || warn "sfdx/ not scaffolded yet"
