# Tool reference — install once, verify before the lab

Every tool the lab uses, in one place. Install steps live in [setup.md](../setup.md); this is the reference table + the MCP Workbench install note. `preflight.sh` checks `sf` + org reachability; verify the rest yourself.

macOS "easy buttons" (Homebrew / npm) below; the link is the cross-platform fallback. **Install Node first** — the `npm -g` installs depend on it. 🪟 Windows: run these in **Git Bash** (see [setup.md](../setup.md#choose-your-terminal)).

| Tool | Min version | Install (easy button) | Verify | Used in |
|------|-------------|-----------------------|--------|---------|
| **Node.js + npm** | Node ≥18 LTS | `brew install node` — or [nodejs.org](https://nodejs.org) installer | `node --version` | M4 (React `web/` client); prereq for the npm installs below |
| **Salesforce CLI** (`sf`) | latest | `npm install --global @salesforce/cli` — [docs](https://developer.salesforce.com/tools/salesforcecli) | `sf --version` | all modules |
| **Claude Code** | latest | `npm install --global @anthropic-ai/claude-code` — or [claude.com/claude-code](https://claude.com/claude-code) | `claude --version` | M2 (capability tour) + M3 (Connect) + take-homes |
| ↳ plugin **`agentforce-adlc`** | latest | `/plugin` in Claude Code → install from marketplace | `/plugin` list | M2 (deploy/publish/activate the agent) + M7 fork |
| ↳ plugin **`sf-mcp-partner-toolkit`** | latest (`create-sf-mcp-client-metadata` ≥1.1.0) | `/plugin marketplace add mvogelgesang/sf-mcp-partner-toolkit` → `/plugin install sf-mcp-partner-toolkit@mvogelgesang-plugins` (⚠️ marketplace name ≠ repo name — see [setup.md](../setup.md#add-the-two-claude-code-plugins)) | `/plugin` list | M3 (scaffold/deploy/diagnose MCP) |
| **MCP Workbench** | latest | **not on AppExchange / not publicly listed** — install from the repo (see below) | open `/lightning/n/MCP_Workbench` | M3 (connection **troubleshooting**) |
| **`sf agent mcp`** (CLI, **preview**) | ships with `sf` | included in the Salesforce CLI — no extra install | `sf agent mcp list` | M3 (optional CLI-native retrieval/verify) |
| **`sf-flex-estimator`** (skill) | — | already available as a Claude Code skill — invoke `/sf-flex-estimator` | `/sf-flex-estimator` runs | M2 (profile action Flex-credit cost) |

- **Org side** isn't a CLI install — the org you create from template `0TTHo0000036iOl` carries Agentforce + Employee Agent, Hosted MCP + External Client App, Agent API, and LEX for the CLT (activate Agentforce per setup; Slack connection optional — bring your own Slack app).
- **Platform capability versions** (API 64.0+ for CLTs, etc.) move release-to-release — re-check them at workshop time.

## Installing MCP Workbench (not publicly discoverable)

MCP Workbench is a Salesforce Lightning app that tests MCP connections from *inside* the org (like Postman for in-org MCP callouts). It's **not on AppExchange and not publicly listed** — it ships from [github.com/mvogelgesang/MCP-Workbench](https://github.com/mvogelgesang/MCP-Workbench). The `sf-mcp-partner-toolkit` plugin's **`diagnose-connection`** skill installs it for you; to do it by hand:

1. Package version ID: `04tHs000000iSjcIAE` (re-verify at workshop time — community tool). Install:
   ```bash
   sf package install -p 04tHs000000iSjcIAE -o <org-alias> --wait 5
   ```
   Namespaced org where package install fails? Source-deploy instead:
   ```bash
   git clone https://github.com/mvogelgesang/MCP-Workbench.git
   ```
   ```bash
   sf project deploy start --source-dir force-app/main/default -o <org-alias>
   ```
2. Assign the permset:
   ```bash
   sf org assign permset --name MCP_Workbench -o <org-alias>
   ```
3. Open it:
   ```bash
   sf org open -o <org-alias> --path "/lightning/n/MCP_Workbench"
   ```

> *(Verify the repo + version ID are current at workshop time — it's a community tool, not a Salesforce product.)*
