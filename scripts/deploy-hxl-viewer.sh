#!/usr/bin/env bash
# Deploy the HXL Widget Viewer — an LWC "view kit" to browse + inspect the org's HXL
# Mosaic widgets (UiWidgetBundle / lightning__agentforceWidget content) and see each
# one's structure + raw Mosaic JSON.
#
# This is a STANDALONE step (independent of steps/deploy / deploy-react-app). It is LWC — no npm
# build, no launch-point wiring — chosen deliberately for the HXL viewer.
#
# Steps (stops on first hard failure):
#   1. Provision a per-org RemoteSiteSetting for the org My Domain. The controller reads a
#      widget's body via a self-callout to the Connect authoring REST API (draft widgets are
#      invisible to ConnectApi channel reads), which needs the org domain allow-listed.
#   2. Scoped deploy of the viewer metadata (Apex + 2 LWCs + FlexiPage + Tab + App + permset).
#   3. Assign the HXL_Widget_Viewer_Access permset to the running user.
#
# After it lands: App Launcher → "HXL Widget Viewer".
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/scripts/lib/common.sh"
ORG="$(resolve_org "$@")"
[ -n "$ORG" ] || { fail "no org (pass --org <alias> or set ORG_ALIAS)"; exit 1; }

PERMSET="HXL_Widget_Viewer_Access"
APP_DIR="$ROOT/sfdx"

# 1) RemoteSiteSetting for the org My Domain (self-callout allow-list) ----------------
echo "→ 1/3 provisioning RemoteSiteSetting for the org My Domain…"
INSTANCE_URL="$(sf org display -o "$ORG" --json 2>/dev/null \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["result"]["instanceUrl"])' 2>/dev/null)"
[ -n "$INSTANCE_URL" ] || { fail "could not resolve instanceUrl for $ORG"; exit 1; }
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/remoteSiteSettings"
cat > "$TMP/remoteSiteSettings/HXL_Self_Callout.remoteSite-meta.xml" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<RemoteSiteSetting xmlns="http://soap.sforce.com/2006/04/metadata">
    <disableProtocolSecurity>false</disableProtocolSecurity>
    <isActive>true</isActive>
    <description>HXL Widget Viewer self-callout to the Connect authoring REST API.</description>
    <url>$INSTANCE_URL</url>
</RemoteSiteSetting>
XML
cat > "$TMP/package.xml" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types><members>HXL_Self_Callout</members><name>RemoteSiteSetting</name></types>
    <version>67.0</version>
</Package>
XML
if sf project deploy start --metadata-dir "$TMP" --target-org "$ORG" >/dev/null 2>&1; then
  pass "RemoteSiteSetting HXL_Self_Callout → $INSTANCE_URL"
else
  fail "RemoteSiteSetting deploy failed (viewer may still work if self-callouts are already allowed)"
fi

# 2) Scoped deploy of the viewer metadata --------------------------------------------
echo "→ 2/3 deploying viewer metadata (Apex + LWCs + FlexiPage + Tab + App + permset)…"
# Run from the sfdx project dir so --metadata resolves against its package directories
# (--metadata and --source-dir are mutually exclusive; component-scoped is what we want).
if ( cd "$APP_DIR" && sf project deploy start \
    --metadata ApexClass:HxlWidgetViewerController ApexClass:HxlWidgetViewerControllerTest \
      ApexPage:HxlApiSession \
      "LightningComponentBundle:hxlWidgetViewer" "LightningComponentBundle:mosaicTile" \
      FlexiPage:HXL_Widget_Viewer CustomTab:HXL_Widget_Viewer CustomApplication:HXL_Widget_Viewer \
      PermissionSet:HXL_Widget_Viewer_Access \
    --target-org "$ORG" ); then
  pass "viewer metadata deployed"
else
  fail "viewer metadata deploy failed"; exit 1
fi

# 3) Assign the permset --------------------------------------------------------------
echo "→ 3/3 assigning ${PERMSET}…"
if sf org assign permset --name "$PERMSET" --target-org "$ORG" >/dev/null 2>&1; then
  pass "$PERMSET assigned"
else
  warn "$PERMSET assign skipped (already assigned?) — check manually if the app is missing"
fi

echo
pass "HXL Widget Viewer deployed. Open: App Launcher → \"HXL Widget Viewer\" (org: $ORG)."
