// Minimal standalone Agent API proxy — the pattern a partner uses in production:
// the BACKEND holds the token and calls the Agent API; the browser never sees the token
// and never hits CORS. Dependency-free (Node built-ins only) — run: `node proxy.mjs`.
//
// Reads config from web/.env (same file the React app uses). The browser calls
// http://localhost:8787/agent-api/... ; this server injects the Bearer token and forwards
// to https://api.salesforce.com/einstein/ai-agent/v1/... , streaming the body correctly.
import http from "node:http";
import https from "node:https";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// tiny .env reader (no dotenv dependency)
const env = {};
for (const line of fs.readFileSync(path.join(__dirname, ".env"), "utf8").split("\n")) {
  const m = line.match(/^([A-Z0-9_]+)=(.*)$/);
  if (m) env[m[1]] = m[2].trim();
}
const TOKEN = env.VITE_ACCESS_TOKEN;
const MY_DOMAIN = (env.VITE_SF_MYDOMAIN || "").replace(/^https?:\/\//, ""); // host only
const API_HOST = "api.salesforce.com";
const API_BASE = "/einstein/ai-agent/v1";
const PORT = 8787;

// Resolve an order number → record Id via SOQL (the client_credentials token has the `api`
// scope). Lets the web app build a "view in Salesforce" deep link — the Agent API response
// itself carries only the agent's prose, not the record Id.
function lookupOrderId(orderNumber, cb) {
  const q = encodeURIComponent(`SELECT Id FROM Order__c WHERE Order_Number__c='${orderNumber.replace(/'/g, "")}' LIMIT 1`);
  const r = https.request(
    { host: MY_DOMAIN, path: `/services/data/v62.0/query/?q=${q}`, method: "GET",
      headers: { Authorization: `Bearer ${TOKEN}` } },
    (up) => { const c = []; up.on("data", (d) => c.push(d)); up.on("end", () => {
      try { const j = JSON.parse(Buffer.concat(c)); cb(j.records && j.records[0] ? j.records[0].Id : null); }
      catch { cb(null); }
    }); }
  );
  r.on("error", () => cb(null));
  r.end();
}

if (!TOKEN) { console.error("No VITE_ACCESS_TOKEN in web/.env"); process.exit(1); }

http.createServer((req, res) => {
  // CORS for the local Vite origin
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS");
  if (req.method === "OPTIONS") { res.writeHead(204); return res.end(); }

  // /lookup?order=OR-1003 → { recordId, recordUrl } (for the "view in Salesforce" link)
  if (req.url.startsWith("/lookup")) {
    const order = new URL(req.url, "http://x").searchParams.get("order") || "";
    return lookupOrderId(order, (id) => {
      console.log(`[proxy] lookup ${order} → ${id || "(none)"}`);
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({
        recordId: id,
        recordUrl: id ? `https://${MY_DOMAIN}/lightning/r/Order__c/${id}/view` : null,
      }));
    });
  }

  const upstreamPath = API_BASE + req.url.replace(/^\/agent-api/, "");
  const chunks = [];
  req.on("data", (c) => chunks.push(c));
  req.on("end", () => {
    const body = Buffer.concat(chunks);
    const up = https.request(
      { host: API_HOST, path: upstreamPath, method: req.method,
        headers: {
          Authorization: `Bearer ${TOKEN}`,
          "Content-Type": "application/json",
          ...(req.headers["x-session-end-reason"] ? { "x-session-end-reason": req.headers["x-session-end-reason"] } : {}),
          ...(body.length ? { "Content-Length": body.length } : {}),
        } },
      (upRes) => {
        console.log(`[proxy] ${req.method} ${req.url} → ${upRes.statusCode}`);
        res.writeHead(upRes.statusCode, { "Content-Type": upRes.headers["content-type"] || "application/json" });
        upRes.pipe(res);
      }
    );
    up.on("error", (e) => { console.error("[proxy ✗]", e.message); res.writeHead(502); res.end(JSON.stringify({ error: e.message })); });
    if (body.length) up.write(body);
    up.end();
  });
}).listen(PORT, () => console.log(`Agent API proxy on http://localhost:${PORT} (token from web/.env, held server-side)`));
