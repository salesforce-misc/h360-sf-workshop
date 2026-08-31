#!/usr/bin/env bash
# Preflight: verify tooling + org connectivity before the workshop build.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/scripts/lib/common.sh"
ORG="$(resolve_org "$@")"
FAILED=0
command -v sf >/dev/null 2>&1 && pass "sf CLI present" || { fail "sf CLI not found — https://developer.salesforce.com/tools/salesforcecli"; FAILED=1; }
if [ -n "$ORG" ]; then
  sf org display --target-org "$ORG" >/dev/null 2>&1 && pass "org '$ORG' reachable" || { fail "org '$ORG' not reachable — run: sf org login web --alias $ORG"; FAILED=1; }
else
  warn "no org alias (pass --org <alias> or set ORG_ALIAS in .env)"
fi
echo "--- Reminders (see docs/setup.md) ---"
echo "  • Employee Agent built in Agentforce Studio"
echo "  • MCP servers activated + External Client App (mcp_api, PKCE, JWT tokens)"
echo "  • Slack workspace connected (optional — on request); Slack app scopes chat:write/channels:read/canvases:write"
echo "  • Agent (non-'Agentforce (Default)') + External Client App for Agent API"
exit $FAILED
