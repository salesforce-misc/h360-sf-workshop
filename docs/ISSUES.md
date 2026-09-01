# Issues & Challenges — the one place to look when something breaks

When a step fails, come here rather than re-reading the module. Grouped by area, plus three cross-cutting callouts (copy-paste, incognito, OS) for the friction we hit live.

---

## Cross-cutting callouts

### 📋 Copy-paste safety
Pasted commands sometimes carry an **extra `/` or a stray line break**, silently breaking them.
- Copy **one command per fenced block** — don't select across blocks.
- Watch the MCP endpoint: `https://api.salesforce.com/platform/mcp/v1/platform/headless-360` has **two `/platform/` segments** and **no trailing slash**. An extra `/` is the classic failure.
- For any value you paste into Setup (Consumer Key, `xoxb-` token): **no leading/trailing space, no quotes, no `Bearer` prefix.** Use the source's **Copy button**, not a manual drag-select (avoids trailing-newline corruption).

### 🔒 Incognito for key/secret reveal
Revealing a Consumer Key/Secret can loop on **identity-verification**, fail **"insufficient privileges,"** or hit a **stale MFA prompt** — especially on trial orgs.
- **Fix: open the org in an incognito/private browser window and reveal from there.** A clean session (no cached SSO / other-org login) resolves most reveal failures.
- Same tactic fixes the Slack **record-link button** "Looks like there's a problem" — that means your browser is on a **different org**; open the link incognito, signed into the demo org.
- Alternatives: complete the emailed verification code, or retry from a fresh `sf org open --target-org <alias>` session.

### 🖥️ OS differences (Mac vs. Windows)
- The kit's `./scripts/*.sh` are **bash** scripts. **PowerShell and CMD can't run them.** On Windows use **Git Bash** (recommended) or **WSL2**. See [setup.md](./setup.md#choose-your-terminal) and the [PowerShell fallback](./setup.md#powershell-fallback-no-bash).
- Installs differ: 🍎 Mac = Homebrew; 🪟 Windows = nodejs.org installer + `npm i -g`. `curl` ships on both (and in Git Bash).
- The repo enforces LF on `.sh` via `.gitattributes` so a Windows checkout doesn't CRLF-corrupt the scripts.

---

## Setup / onboarding
| Symptom | Cause → fix |
|---|---|
| `onboard.sh` prints `WARN: permset assign failed` | The permset is **already assigned** (a re-run) — non-fatal; the final "onboarded" line confirms success. |
| Agent won't deploy — "Not available for deploy" | Agentforce isn't fully on. Enable it (Setup → Agentforce) and **wait ~1–2 min** — `Bot`/agent metadata materializes async. |
| Agent answers "No order matches OR-1003" | Hero data not seeded — run `./scripts/steps/seed-hero-data.sh --org <alias>` (after the permset is assigned, so FLS is in place). |
| No fields / no H360 Orders tab (App Launcher → "H360 Orders", not the standard "Orders" tab) | The permset isn't assigned to **this** user — `./scripts/steps/assign-perms.sh` (Order__c FLS + tab visibility live in the permset). |

## MCP / Claude (Module 3 · 3a)
| Symptom | Cause → fix |
|---|---|
| `redirect_uri_mismatch` | Missing the `http://localhost:8765/callback` line — register **both** callbacks, one per line, no trailing slash. |
| `/mcp` shows **no** Salesforce server | Launched Claude Code from the wrong dir — the MCP servers are **project-scoped**; `cd` into the cloned `h360-sf-workshop/` and relaunch. |
| `INVALID_JWT_FORMAT` / `INVALID_AUTH_HEADER` | The ECA is missing **"Issue JWT-based access tokens for named users"** — check it, then re-authenticate with a fresh token. (This is NOT "JWT Bearer Flow.") |
| `invalid_client_id` | The app hasn't propagated — wait a few minutes and retry the same steps. |
| "does not support dynamic client registration" | Pass the Consumer Key as a **static `--client-id`** on `claude mcp add` (Salesforce Hosted MCP has no DCR). |
| Connection breaks after adding a scope | Use ONLY `mcp_api` + `refresh_token`/`offline_access`; drop `openid`/`api`/extras. |
| `sf agent mcp list` is empty | **By design** — it lists only externally-registered servers, not the Salesforce-Hosted `headless-360`. Don't chase it; your read already proved the connection. |

## Agent API / React (Module 4)
| Symptom | Cause → fix |
|---|---|
| Blank chat / "Order Assistant unavailable" (4a) | `VITE_AGENT_ID` built for a different org — re-run `deploy-react-app.sh` against **this** org. Cold start (first load/reply) is slow, not broken — wait. |
| `401` / empty from the web card (4b) | **Expired/wrong token** — mint a fresh one into `web/.env` and **restart `node proxy.mjs`** (it reads `.env` at startup). |
| Session-start **412** | Assign the **agent-access permset** to the Run-As user; confirm the agent is published + activated. |
| **400 "Invalid user ID"** | `bypassUser` wrong for an Employee agent → set **`bypassUser:false`**. |
| Token mint `invalid_client` / `invalid_grant` | `invalid_client` = key/secret wrong or app not propagated; `invalid_grant` = Client Credentials Flow off or Run-As not set (Policies tab). |
| Consumer Secret reveal "verification timed out" | Stale session — reveal via **incognito** (see callout) or a fresh `sf org open`. |

## Slack (Module 5)
| Symptom | Cause → fix |
|---|---|
| `invalid_auth` from `curl` | Bad/stale token, OR the app's "Restrict API Token Usage" **IP allowlist** — clear it (leave empty). |
| `invalid_auth` from the org but curl was OK | Stored `BotToken` wrong/mistyped, OR the org's egress IP is blocked by the allowlist (org egresses from **Salesforce** IPs). |
| Empty merge field `{!$Credential.Slack_API.BotToken}` | Principal and secret-parameter share a name — principal must be `Slack_Bot_Principal`, parameter `BotToken` (different names). |
| `not_in_channel` | `/invite` the bot, or add `chat:write.public` (reinstall for a fresh token). |
| Record-link button gacks "Looks like there's a problem" | Browser logged into a **different org** — open the link incognito signed into the demo org. |

### Slack org-side verify snippet
Proves the whole chain (org → Named Credential → Slack). Expect `ok=true … team=<your workspace>`:
```bash
sf apex run --target-org <alias> --file /dev/stdin <<'APEX'
HttpRequest h = new HttpRequest();
h.setEndpoint('callout:Slack_API/auth.test'); h.setMethod('POST');
h.setHeader('Content-Type','application/x-www-form-urlencoded');
Map<String,Object> b = (Map<String,Object>) JSON.deserializeUntyped(new Http().send(h).getBody());
System.debug('ok=' + b.get('ok') + ' err=' + b.get('error') + ' team=' + b.get('team'));
APEX
```
If `ok=false invalid_auth` here but the curl was fine → the org's stored value is wrong (re-paste cleanly), or the org egress IP is blocked by the allowlist.

## General
| Symptom | Cause → fix |
|---|---|
| Any record-link button gacks across surfaces | Browser is logged into a different org — log into (or incognito into) the demo org first. |
| A "connected" green dot but nothing works | The green dot is not proof — run a **real read/query**; async half-states are invisible to status checks. |

---

**Printable tick-off card:** [reference/credential-checklist-card.md](./reference/credential-checklist-card.md) — one page of the ✅ verify commands, per participant/table.
