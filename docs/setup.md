# Setup — get your laptop and org ready

Setup is **two ordered parts**:

1. **[Pre-work](#part-1--pre-work-before-you-arrive)** — install the toolchain (do this **before** the workshop). Has a 🍎 **Mac** and a 🪟 **Windows** path.
2. **[Org provisioning](#part-2--make-your-org-yours)** — log in → change email → turn on Agentforce → onboard → smoke.

> When a command fails, don't re-read this page — flip to **[ISSUES.md](./ISSUES.md)**.

---

## Part 1 — Pre-work (before you arrive)

> ⚠️ **Do not configure on-site.** The tech day is compressed; if your laptop isn't ready you'll spend the morning installing instead of building. Complete this ~1 week ahead.

Install and verify four things: **Node.js**, the **Salesforce CLI (`sf`)**, **Claude Code**, and two Claude Code **plugins**.

### Choose your terminal

| Platform | Use | Note |
|---|---|---|
| 🍎 **Mac** | Terminal / iTerm | Everything below works as-is. |
| 🪟 **Windows** | **Git Bash** (ships with [Git for Windows](https://git-scm.com/download/win)) — **recommended** — or **WSL2 (Ubuntu)** | The kit's `./scripts/*.sh` are bash scripts. **PowerShell and CMD cannot run them.** Install Git for Windows and use the **Git Bash** prompt for every command in this kit. (If you only have PowerShell, see the [PowerShell fallback](#powershell-fallback-no-bash) at the end of Part 2.) |

### 🍎 Mac — install

```bash
brew install node
```
```bash
npm install --global @salesforce/cli @anthropic-ai/claude-code
```

### 🪟 Windows — install

1. Install **Node.js (≥18 LTS)** from the [nodejs.org installer](https://nodejs.org).
2. Install **Git for Windows** from [git-scm.com](https://git-scm.com/download/win) and open **Git Bash**.
3. In Git Bash:
   ```bash
   npm install --global @salesforce/cli @anthropic-ai/claude-code
   ```

### Verify (both platforms)

```bash
node --version
```
```bash
sf --version
```
```bash
claude --version
```

### Add the two Claude Code plugins

In Claude Code:

```
/plugin marketplace add mvogelgesang/sf-mcp-partner-toolkit
```
```
/plugin install sf-mcp-partner-toolkit@mvogelgesang-plugins
```

🔴 **Name gotcha:** `marketplace add` takes the **GitHub repo** path (`mvogelgesang/sf-mcp-partner-toolkit`), but `install` takes `<plugin>@<marketplace-name>`, where the marketplace is **`mvogelgesang-plugins`** — *not* the repo name. Also add **`agentforce-adlc`** from the marketplace. Confirm with `/plugin` (both listed).

> `curl` (used by later verify steps) ships on macOS, Windows 10+, and in Git Bash — nothing to install.

---

## Part 2 — Make your org yours

Your workshop org is pre-provisioned (OrgFarm). Claim it, make it yours, then onboard the kit. ~10 minutes.

### Step 1 — Log in

1. Claim your org with the **event code + sign-up form** your facilitator provides. Default org password: **`orgfarm1234`**.
2. Note your org's My Domain URL. This is the account you'll authenticate the CLI as in Step 4.

### Step 2 — Change the admin email to your address

Your org ships with a placeholder admin email — change it so verification/reset mail reaches you.

1. Setup → Quick Find **"My Personal Information"** → **Personal Information** → edit **Email** → your work email → **Save**.
2. **Confirm** the verification email Salesforce sends to that address.

### Step 3 — Turn on Agentforce (Einstein)

The kit's agent won't deploy until Agentforce is enabled (otherwise you get a cryptic "Not available for deploy").

1. Setup → Quick Find **"Agentforce"** (Agentforce / Einstein Setup) → **turn Agentforce ON**.
2. ⏳ **Wait ~1–2 minutes.** The `Bot` / agent metadata materializes **asynchronously** — deploy too fast and it won't be ready.

### Step 4 — Get the kit and onboard

Open your terminal (🪟 Windows: **Git Bash**), go to where you keep code, and clone (run one at a time):

```bash
git clone https://github.com/salesforce-misc/h360-sf-workshop.git
```
```bash
cd h360-sf-workshop
```
```bash
sf org login web --alias myorg
```
```bash
./scripts/06-org-onboard.sh --org myorg
```

`06-org-onboard.sh` runs the scriptable half in order and is safe to re-run: guards Agentforce-on → deploys the reference build (`02`) + publishes/activates the agent → assigns the permset (`03`) → seeds the 5 hero orders incl. **OR-1003** (`05`) → deploys the in-org React app (`07`) → smoke-tests.

> A `WARN: permset assign failed` line on a re-run just means it's already assigned — non-fatal; the final "onboarded" line confirms success.

### Step 5 — Smoke test: "am I ready to build?"

```bash
./scripts/smoke.sh --org myorg
```

Green **"MECHANICAL: all green"** = build-ready (org reachable · Agentforce on · 5 hero orders · permset assigned · agent deployed · the real `OrderStatusSkill` returns OR-1003). The command also prints a manual browser checklist. Re-run anytime.

✅ **Now start the modules → [Module 0](./modules/00-prereqs-and-comprehend.md)** (or jump to [Module 2](./modules/02-capability.md) if your org is already onboarded).

---

### PowerShell fallback (no bash)

If you're on Windows with **only PowerShell** (no Git Bash/WSL), you can't run `./scripts/*.sh`. Best fix: install [Git for Windows](https://git-scm.com/download/win) and use **Git Bash**. If you truly can't, run the underlying `sf` commands the onboarder wraps, from the repo root, after Steps 1–3 above:

```
sf org login web --alias myorg
```
```
sf project deploy start --source-dir sfdx/force-app --target-org myorg
```
```
sf agent publish authoring-bundle --api-name Headless360_Order_Assistant --target-org myorg
```
```
sf agent activate --api-name Headless360_Order_Assistant --target-org myorg
```
```
sf org assign permset --name Headless360_Workshop_Access --target-org myorg
```

Seed the 5 hero orders with the PowerShell port of the seeder:

```
.\scripts\05-seed-hero-data.ps1 -Org myorg
```

Then verify in the browser: the Orders list view shows 5 rows and Agent Builder answers "status of order OR-1003".

> The **in-org React app** (Module 4a, `07-deploy-react-bundle.sh`) needs an `npm` build and has no PowerShell port — run that one step in **Git Bash**, or skip it (it's a Module-4 surface, not core setup). Everything else above works in plain PowerShell. *(Exact command names may drift — confirm against `scripts/` if one errors.)*
