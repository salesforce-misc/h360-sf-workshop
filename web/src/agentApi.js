// Minimal Agentforce Agent API helper (reference — not production auth).
// Endpoints per developer.salesforce.com/docs/ai/agentforce/guide/agent-api.
// NOTE: the Agent API is not supported for "Agentforce (Default)" agents; 120s timeout applies.
//
// The Agent API host does not send browser CORS headers AND the token must not live in
// browser JS. So the browser calls a small BACKEND proxy (proxy.mjs) that holds the token
// server-side and injects the Bearer header — the same pattern a partner uses in production.
// Start it with `node proxy.mjs` (see web/README.md). The browser sends NO token.
const BASE = "http://localhost:8787/agent-api";

// myDomain: your org My Domain, e.g. https://<your-domain>.my.salesforce.com
export async function startSession({ agentId, myDomain }) {
  const res = await fetch(`${BASE}/agents/${agentId}/sessions`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      externalSessionKey: crypto.randomUUID?.() || String(Date.now()),
      instanceConfig: { endpoint: myDomain },
      streamingCapabilities: { chunkTypes: ["Text"] },
      // 🔴 Employee agents MUST use bypassUser:false — the session runs as the token's
      // Run-As user. bypassUser:true (the Service-agent pattern) → HTTP 400
      // "Invalid user ID provided on start session" because an employee agent has no
      // agent-assigned user to resolve. Validated 2026-07-23.
      bypassUser: false,
    }),
  });
  if (!res.ok) throw new Error(`startSession ${res.status}: ${(await res.text()).slice(0, 120)}`);
  return res.json(); // → { sessionId, ... }
}

let seq = 0;
export async function sendMessage({ sessionId, text }) {
  const res = await fetch(`${BASE}/sessions/${sessionId}/messages`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ message: { sequenceId: ++seq, type: "Text", text } }),
  });
  if (!res.ok) throw new Error(`sendMessage ${res.status}: ${(await res.text()).slice(0, 120)}`);
  return res.json(); // → structured agent response (render this)
}

export async function endSession({ sessionId }) {
  await fetch(`${BASE}/sessions/${sessionId}`, {
    method: "DELETE",
    headers: { "x-session-end-reason": "UserRequest" },
  });
}

// Resolve an order number → { recordId, recordUrl } via the proxy's /lookup endpoint,
// so the card can deep-link to the record (the Agent API response carries only prose).
// BASE ends in /agent-api; the lookup lives at the proxy root.
const PROXY_ROOT = BASE.replace(/\/agent-api$/, "");
export async function lookupOrder(orderNumber) {
  try {
    const res = await fetch(`${PROXY_ROOT}/lookup?order=${encodeURIComponent(orderNumber)}`);
    return res.ok ? res.json() : { recordId: null, recordUrl: null };
  } catch {
    return { recordId: null, recordUrl: null };
  }
}
