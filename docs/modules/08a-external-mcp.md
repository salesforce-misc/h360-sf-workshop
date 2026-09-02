# Module 8a — Connect your own external MCP server 🟡

**Phase:** 3 · Apply to Partner POC · **Goal:** fold your own external MCP service into this org's agent as a governed tool · **Time:** take-home / optional · **Done when:** your tools register and the agent can call them

> 🟡 **Optional — for partners who already run an external MCP server.**

> **For partners who already run an external MCP server** — fold *your* service into this org's agent as a governed tool (ideation for "our product as an MCP-callable capability"). This is the **inbound/registry** path, distinct from the Salesforce-hosted `headless-360` ([Module 3](./03-connect-claude-mcp.md)) and the Setup-composed server ([Module 3a](./03a-custom-mcp-server.md)).

**Directional only — this is optional.**

## Steps

> **Where do I run this?** `sf package install` and `sf apex run --file scripts/…` run from the **repo root** (the `scripts/` path is repo-root-relative); raw `sf agent …` commands run from the **`sfdx/` project directory**.

1. **Add a Named Principal** to the existing **External Credential** (your external MCP server's auth).

2. **Grant External Credential Principal Access** on the permission set.

3. **Install MCP Workbench** — the in-org diagnostic, Postman-for-in-org-MCP-callouts. Source: [github.com/mvogelgesang/MCP-Workbench](https://github.com/mvogelgesang/MCP-Workbench).

   ```bash
   sf package install -p 04tHs000000iSjcIAE -o <alias> --wait 5
   ```

   Or browser-install by navigating to this path in your org:

   ```text
   /packaging/installPackage.apexp?p0=04tHs000000iSjcIAE
   ```

4. **Grant the Platform Integration User** — run this *after* Workbench is installed. The MCP-5 trap: the agent's runtime callout runs as the Platform Integration User (PIU), not as you, so a Workbench/curl test can pass while the wired agent returns "no data."

   ```bash
   sf apex run --file scripts/apex/assign-piu-mcp-permset.apex -o <alias>
   ```

5. **Register the MCP tools** so the agent can call them.

   ```bash
   sf agent mcp create --server-url <your-endpoint>
   ```

   ```bash
   sf agent mcp list
   ```

### 🔴 Checkpoint 8a

Your tools register (`sf agent mcp list` shows the server + tools) and the agent can call them. Remember the PIU trap: the agent's runtime callout runs as the Platform Integration User, so a passing curl or MCP Workbench test proves *your* access, not the *agent's* — the PIU permission-set grant in step 4 is what closes that gap.

When you're ready, wire this into a POV of your own capability.

---

[← Module 8](./08-package.md) · [Overview](../../OVERVIEW.md) · [Module 8b →](./08b-coworker.md)
