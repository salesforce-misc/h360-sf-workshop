# Credential Checklist Card — one page, tick as you go

Print one per participant / per table. This is the **verify-only** companion to the
[the module pages (3/4/5)](../modules/) — do the setup there, tick the ✅ checks here.
Replace `<alias>`, `<org>` (My Domain host), `<xoxb>`, `<KEY>`/`<SECRET>` with your values.

**Participant / org: ______________________**

---

### ☐ 0. Org reachable + hero data
```bash
sf org display --target-org <alias>          # opens? edition Enterprise?
sf data query -o <alias> -q "SELECT Order_Number__c, Status__c FROM Order__c ORDER BY Order_Number__c"
```
✅ **5 rows** OR-1001..OR-1005.  ☐ pass

---

### ☐ A. MCP ECA (Module 3)
Setup → External Client App Manager → `Headless360_MCP_Client` created, then:
- ☐ both callbacks (`claude.ai/api/mcp/auth_callback` **and** `http://localhost:8765/callback`)
- ☐ scopes = `mcp_api` ("Access Salesforce hosted MCP Servers") + `refresh_token,offline_access` **only** (no `openid`)
- ☐ JWT-tokens **on** (🔴 the real gotcha) · PKCE **on** · both "Require secret" **off** *(PKCE/secret may already be set — confirm)*

**Verify** (Claude Code launched from the project dir):
```bash
./scripts/04-mcp-connect-setup.sh --org <alias> --verify
# then in Claude:  read order OR-1003 from Salesforce   → returns real data
```
✅ real read returns (not just a green dot).  ☐ pass

---

### ☐ B. Agent API ECA (Module 4) — a SEPARATE app
Setup → External Client App Manager → `Headless360_Agent_API` created, then:
- ☐ scopes = `api` + `chatbot_api` + `sfap_api` + `refresh_token,offline_access` (NOT `mcp_api`)
- ☐ PKCE **off** (Cancel the Confirm-and-Lock dialog *if* it appears/defaults on) · JWT-tokens **on**
- ☐ **Policies tab** (on the finished app, not the wizard) → **Client Credentials Flow on** + **Run As** user with **Salesforce API Integration PSL** + **"Access Agentforce Default Agent"** *(🔴 a bare API-Only integration user may NOT support agent-use — confirm license on the target org; labels drift across releases)*

**Verify** (mint a token — local terminal):
```bash
curl -s -X POST "https://<org>.my.salesforce.com/services/oauth2/token" \
  -d grant_type=client_credentials -d client_id=<KEY> -d client_secret=<SECRET> | python3 -m json.tool
```
✅ `access_token` + `scope: sfap_api chatbot_api api`.  ☐ pass

---

### ☐ C. Slack app + bot token (Module 5)
api.slack.com/apps → app created + installed; bot scopes `chat:write`, `channels:read`, `chat:write.public`.

**Verify 1 — token direct (bisector):**
```bash
curl -s -H "Authorization: Bearer <xoxb>" https://slack.com/api/auth.test
```
✅ `{"ok":true, team:<your workspace>}`. (If `invalid_auth` → clear the app's "Restrict API Token Usage" allowlist.)  ☐ pass

**Then** paste `<xoxb>` into org: External Credentials → Slack API → Principals → `Slack_Bot_Principal` → param **`BotToken`**.

**Verify 2 — through the org:**
```bash
sf apex run --target-org <alias> --file /dev/stdin <<'APEX'
HttpRequest h=new HttpRequest(); h.setEndpoint('callout:Slack_API/auth.test'); h.setMethod('POST');
h.setHeader('Content-Type','application/x-www-form-urlencoded');
Map<String,Object> b=(Map<String,Object>)JSON.deserializeUntyped(new Http().send(h).getBody());
System.debug('ok='+b.get('ok')+' team='+b.get('team'));
APEX
```
✅ `ok=true team=<your workspace>`.  ☐ pass

---

### ☐ D. Agent visible in the UI (not just preview)
- ☐ permset `Headless360_Workshop_Access` assigned (grants `agentAccesses`)
- ☐ `Headless360_Workshop_Access` permset assigned  ·  ☐ **latest agent version Active** (a fresh build = v1; re-publishing bumps the number — activate whichever is newest)
```bash
sf org assign permset --name Headless360_Workshop_Access --target-org <alias>   # if missing
```
✅ Agentforce panel (sparkle icon) shows **Headless 360 Order Assistant**; ask "status of order OR-1003".  ☐ pass

---

### ☐ E. React app (Stop 6 / Module 4)
```bash
cd web && node proxy.mjs &   # terminal 1 :8787   (restart after refreshing the token in .env)
npm run dev                  # terminal 2 :5173 → "Ask the agent"
```
✅ card renders real OR-1003 data + "View in Salesforce ↗" link.  ☐ pass

---

**All ticked → participant is fully set up.** Gotcha detail + fixes: [ISSUES.md](../ISSUES.md).
