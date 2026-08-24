# Module 5 — Slack (Block Kit card) 🔴

**Phase:** 2 · Reference Build · **Goal:** the same Skill rendered as a Block Kit card in Slack · **Time:** ~30 min · **Done when:** a Block Kit card posts to the channel with the right status + a working "view record" button.

> 🟡 **Optional / time-permitting — skip if the clock is tight.** Uses the agent published in Module 2 + the `SendSlackCardAction` (both already deployed). The org side (`Slack_API` Custom External Credential + Named Credential) ships deployed; you create the Slack app and paste its bot token into the credential.

## Steps

### 1. Create + install the Slack app
1. [api.slack.com/apps](https://api.slack.com/apps) → **Create New App → From scratch** → name it and pick **your** workshop workspace.
2. **OAuth & Permissions → Bot Token Scopes** → add: `chat:write`, `channels:read`, and `chat:write.public` (lets the bot post to any public channel without an invite — recommended).
3. **Install to Workspace** → Allow. Copy the **Bot User OAuth Token** (starts `xoxb-`).
   - 🔴 It must be the **Bot User OAuth Token** (`xoxb-`), not the App-Level token (`xapp-`), Client Secret, or a config token (`xoxe-`). Use the **Copy** button (avoids trailing-newline corruption).

### 2. 🔴 Validate the token BEFORE touching Salesforce (the fast bisector)
```bash
curl -s -H "Authorization: Bearer <xoxb-...>" https://slack.com/api/auth.test
```
- **`{"ok":true, …}`** → good; the `team`/`url` should match your workspace. Proceed.
- **`{"ok":false,"error":"invalid_auth"}`** → two documented causes:
  1. **Disallowed source IP** — the app's **OAuth & Permissions → "Restrict API Token Usage"** allowlist. If it has entries, they block other IPs. **Clear the list** (leave it empty for the workshop). 🔴 Even after clearing it for your laptop, the **org's callout egresses from Salesforce IPs, not yours** — an allowlist scoped to your IP still blocks the org.
  2. **Bad/stale token** — reinstall the app, re-copy. A phone-hotspot test isolates IP-block vs. token (bypasses a corporate proxy like Zscaler).

### 3. Store the token in the org
Setup → **Named Credentials → External Credentials → Slack API → Principals** → edit **`Slack_Bot_Principal`** → **Authentication Parameters** → add:
- **Name:** `BotToken` *(exact, case-sensitive)*
- **Value:** the `xoxb-…` token — **no `Bearer` prefix, no quotes, no trailing space** (paste with the Copy button)
- **Save.**

🔴 **Naming rule (cost us an hour):** the **principal** is `Slack_Bot_Principal` and the **secret parameter** is `BotToken` — they must be **different names**, or the merge field `{!$Credential.Slack_API.BotToken}` resolves to empty → `invalid_auth`.

The reference build ships a **Custom** External Credential + bearer AuthHeader — **not** an OAuth/OIDC Auth Provider (Slack's v2 bot flow has no `id_token`, so OIDC fails "We can't log you in").

### 4. Wire the action
The `SendSlackCardAction` (deployed in Module 2) is already on the agent's Topic — an Apex `@InvocableMethod` that posts a Block Kit card of the order status via `callout:Slack_API/chat.postMessage`, with a `url` button linking to the real `Order__c` record. (Block Kit is built explicitly by the action — not auto-rendered.)

### Verify through the org (proves the whole chain)
Run the `callout:Slack_API/auth.test` Apex snippet in **[ISSUES.md → Slack org-side verify snippet](../ISSUES.md#slack-org-side-verify-snippet)**. Expect `ok=true … team=<your workspace>`. If `ok=false invalid_auth` here but the curl in step 2 was fine → the org's stored value is wrong (re-paste cleanly), or the org egress IP is blocked (step 2 cause #1).

### 🔴 Checkpoint 5 — the Slack callout
Run the agent (or fire the action) with a seeded order (`OR-1003`) → a Block Kit card posts to the channel with the correct status + a working "view record" button.
- `not_in_channel` → `/invite` the bot (or use `chat:write.public`).
- The **record-link button gacks** "Looks like there's a problem" → your browser is logged into a **different org** (the button uses the browser's active Salesforce session). Fix: log into the demo org first, or open the link in an **incognito window** signed into the demo org. More → [ISSUES.md](../ISSUES.md).

---

[← Module 4](./04-custom-ui.md) · [Overview](../../OVERVIEW.md) · [Module 6 →](./06-chatgpt.md)
