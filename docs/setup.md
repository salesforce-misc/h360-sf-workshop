# Setup — get your laptop and org ready

Setup is **two ordered parts**:

1. **[Pre-work](#part-1--pre-work-before-you-start)** — install the toolchain (do this **before** you start building). Has a 🍎 **Mac** and a 🪟 **Windows** path.
2. **[Org provisioning](#part-2--make-your-org-yours)** — create your org → activate Agentforce → onboard → smoke.

> When a command fails, don't re-read this page — flip to **[ISSUES.md](./ISSUES.md)**.

---

## Part 1 — Pre-work (before you start)

> ⚠️ **Do the pre-work before you start building.** Getting the toolchain in place first keeps the build modules smooth. It's a one-time setup.

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

You'll **create your own workshop org** from the Headless 360 org template, activate Agentforce, then onboard the kit. ~15 minutes.

### Step 1 — Create your workshop org

This kit needs an **Agentforce-capable** org. Create your own from the Headless 360 **org template `0TTHo0000036iOl`** using your partner tooling — no OrgFarm, no event code.

Use whichever your partner account supports (the one constant is the template ID):

- **Environment Hub** (from your Partner Business Org) — the usual home for partner org templates: create a new org from template **`0TTHo0000036iOl`**.
- **Dev Hub (CLI)** — create the org from template `0TTHo0000036iOl` via your Dev Hub, then it appears in `sf org list`.

> ℹ️ The exact menu path / flags depend on your partner setup; the constant is the template ID **`0TTHo0000036iOl`** — it carries the Headless 360 configuration. Use whichever org-provisioning tool your team already uses.

Then authenticate the CLI to your new org:

```bash
sf org login web --alias myorg
```

### Step 2 — Activate Agentforce (Einstein)

Agentforce is **installed** on the template org but must be **activated** — the kit's agent won't deploy until it is (otherwise you get a cryptic "Not available for deploy").

1. Setup → Quick Find **"Agentforce"** (Agentforce / Einstein Setup) → **turn Agentforce ON**.
2. ⏳ **Wait ~1–2 minutes.** The `Bot` / agent metadata materializes **asynchronously** — deploy too fast and it won't be ready.

> This build does **not** require Data 360 — no extra data-cloud enablement needed.

### Step 3 — Get the kit and onboard

Open your terminal (🪟 Windows: **Git Bash**), go to where you keep code, and clone (run one at a time):

```bash
git clone https://github.com/salesforce-misc/h360-sf-workshop.git
```
```bash
cd h360-sf-workshop
```
```bash
./scripts/onboard.sh --org myorg
```

`onboard.sh` runs the scriptable half in order and is safe to re-run: guards Agentforce-on → deploys the reference build (`steps/deploy`) + publishes/activates the agent → assigns the permset (`steps/assign-perms`) → seeds the 5 hero orders incl. **OR-1003** (`steps/seed-hero-data`) → smoke-tests. (The in-org React app is **not** part of onboarding — you deploy it hands-on in [Module 4](./modules/04-custom-ui.md).)

> A `WARN: permset assign failed` line on a re-run just means it's already assigned — non-fatal; the final "onboarded" line confirms success.

### Step 4 — Smoke test: "am I ready to build?"

```bash
./scripts/smoke.sh --org myorg
```

Green **"MECHANICAL: all green"** = build-ready (org reachable · Agentforce on · 5 hero orders · permset assigned · agent deployed · the real `OrderStatusSkill` returns OR-1003). The command also prints a manual browser checklist. Re-run anytime.

✅ **Now start the modules → [Module 0](./modules/00-prereqs-and-comprehend.md)** (or jump to [Module 2](./modules/02-capability.md) if your org is already onboarded).

---

### PowerShell fallback (no bash)

If you're on Windows with **only PowerShell** (no Git Bash/WSL), you can't run `./scripts/*.sh`. Best fix: install [Git for Windows](https://git-scm.com/download/win) and use **Git Bash**. If you truly can't, run the underlying `sf` commands the onboarder wraps, from the repo root, after Steps 1–2 above (org created + Agentforce activated):

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
.\scripts\steps\seed-hero-data.ps1 -Org myorg
```

Then verify in the browser: the Orders list view shows 5 rows and Agent Builder answers "status of order OR-1003".

> The **in-org React app** (Module 4a, `deploy-react-app.sh`) needs an `npm` build and has no PowerShell port — run that one step in **Git Bash**, or skip it (it's a Module-4 surface, not core setup). Everything else above works in plain PowerShell. *(Exact command names may drift — confirm against `scripts/` if one errors.)*
