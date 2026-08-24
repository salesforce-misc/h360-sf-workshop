// Reference React client — one Skill on the web surface via the Agent API.
// LEFT column: the Response hand-built as an SLDS-style card (you own the UI).
// RIGHT column: the SAME data rendered through a partner-built React Mosaic renderer
// from a Mosaic widget JSON — the "define once as a widget, render anywhere" proof.
import { useState } from "react";
import { startSession, sendMessage, endSession, lookupOrder } from "./agentApi.js";
import { C, FONT } from "./mosaic/theme.js";
import MosaicTile from "./mosaic/MosaicTile.jsx";
import { bindWidget } from "./mosaic/bind.js";
import orderStatusWidget from "./widgets/orderStatus.web.json";
import orderAssistantWidget from "./widgets/orderAssistant.web.json";

const agentId = import.meta.env.VITE_AGENT_ID;
const myDomain = import.meta.env.VITE_SF_MYDOMAIN;
// The in-org render surface for these UiWidgetBundles: the HXL Widget Viewer custom app
// (App-Page tab backed by the hxlWidgetViewer LWC). Opt-in via VITE_HXL_VIEWER_URL — set it
// ONLY where the viewer is actually deployed (empty → the footer link is hidden, caption stays).
// Accepts a full URL, or a path like /lightning/n/HXL_Widget_Viewer (prefixed with VITE_SF_MYDOMAIN).
const rawViewer = import.meta.env.VITE_HXL_VIEWER_URL;
const hxlViewerUrl = rawViewer
  ? (rawViewer.startsWith("http") ? rawViewer : myDomain ? `${myDomain}${rawViewer}` : null)
  : null;

// Map an order status to an SLDS-style badge colour (left card).
function statusColor(s) {
  const v = (s || "").toLowerCase();
  if (v.includes("deliver")) return C.green;
  if (v.includes("ship")) return C.brand;
  if (v.includes("exception")) return C.red;
  if (v.includes("process")) return C.amber;
  return C.slate;
}

// Read the Skill's STRUCTURED output off the Agent API response — the reliable source of
// truth (the API returns data; you render the UI). Falls back to scraping prose.
function extractOrder(resp, query) {
  const value = resp?.messages?.[0]?.result?.[0]?.value;
  const c = value?.card || value;
  if (c && (c.status || c.orderNumber)) {
    return { order: c.orderNumber || null, status: c.status || null, summary: c.summary || null, recordId: c.recordId || null };
  }
  const msg = resp?.messages?.[0]?.message ?? "";
  const status = (msg.match(/\b(Processing|Shipped|Delivered|Exception)\b/i) || [])[0] || null;
  const order = (msg.match(/\bOR-\d+\b/) || [])[0] || (query.match(/\bOR-\d+\b/i) || [])[0] || null;
  return { order, status, summary: null, recordId: null };
}

const eyebrow = { fontSize: "0.68rem", letterSpacing: "0.1em", textTransform: "uppercase", color: C.slate, marginBottom: 6 };

// Layout chrome — a formal header panel over two clearly-divided render panels.
const panel = { background: C.white, border: `1px solid ${C.border}`, borderRadius: 10, boxShadow: "0 1px 3px rgba(0,0,0,0.08)", overflow: "hidden" };
const panelHead = { display: "flex", alignItems: "center", gap: 10, padding: "12px 16px", background: C.tint, borderBottom: `1px solid ${C.border}` };
const panelBody = { padding: 18 };
const tag = (bg) => ({ background: bg, color: C.white, fontSize: "0.66rem", fontWeight: 700, letterSpacing: "0.06em", textTransform: "uppercase", padding: "3px 9px", borderRadius: 4, whiteSpace: "nowrap" });
const inOrgLink = { background: C.white, color: C.brand, border: `1px solid ${C.brand}`, borderRadius: 4, padding: "5px 12px", fontSize: "0.82rem", fontWeight: 600, textDecoration: "none", whiteSpace: "nowrap" };

export default function App() {
  const [q, setQ] = useState("What is the status of order OR-1003?");
  const [resp, setResp] = useState(null);
  const [recordUrl, setRecordUrl] = useState(null);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState(null);
  const [lastAction, setLastAction] = useState(null);

  // ask() takes an explicit query so a quick-pick button can set + ask in one click
  // without racing React state (the closure's `q` would otherwise be stale).
  async function ask(queryText) {
    const text = queryText ?? q;
    setBusy(true); setErr(null); setResp(null); setRecordUrl(null); setLastAction(null);
    let sessionId;
    try {
      ({ sessionId } = await startSession({ agentId, myDomain }));
      const r = await sendMessage({ sessionId, text });
      setResp(r);
      const { order: orderNum, recordId } = extractOrder(r, text);
      if (recordId) {
        setRecordUrl(`${myDomain}/lightning/r/Order__c/${recordId}/view`);
      } else if (orderNum) {
        lookupOrder(orderNum).then((x) => setRecordUrl(x.recordUrl));
      }
    } catch (e) {
      setErr(e.message);
    } finally {
      if (sessionId) await endSession({ sessionId }).catch(() => {});
      setBusy(false);
    }
  }

  // The widget is declarative; the App owns behavior. Order-labeled buttons re-drive the
  // agent; "Check status" submits the input; anything else is a fire-and-forget ack.
  function onAction(_node, label) {
    if (/^OR-\d+$/.test(label)) { setQ(`What is the status of order ${label}?`); ask(`What is the status of order ${label}?`); }
    else if (label === "Check status") { ask(); }
    else { setLastAction(label); }
  }

  const prose = resp?.messages?.[0]?.message ?? "";
  const { status, order, summary } = resp ? extractOrder(resp, q) : {};
  const message = summary || prose;
  const data = { order: order || "", status: status || "", summary: message || "", recordUrl: recordUrl || "" };

  return (
    <div style={{ fontFamily: FONT, background: C.panel, minHeight: "100vh", padding: "2rem 1rem" }}>
      <main style={{ maxWidth: 1040, margin: "0 auto" }}>

        {/* ── Top section: the agent ask ─────────────────────────────────── */}
        <header style={{ ...panel, marginBottom: 22 }}>
          <div style={panelHead}>
            <span style={tag(C.navy)}>Headless 360</span>
            <div style={{ ...eyebrow, margin: 0 }}>Web surface · Agent API</div>
          </div>
          <div style={panelBody}>
            <h1 style={{ color: C.navy, fontSize: "1.5rem", fontWeight: 700, margin: "0 0 4px" }}>Order Assistant</h1>
            <p style={{ color: C.slate, fontSize: "0.9rem", lineHeight: 1.5, margin: "0 0 16px", maxWidth: 620 }}>
              Ask the agent once — the identical Agent API response is rendered two ways below:
              a hand-built React card and an HXL Mosaic widget definition.
            </p>
            <div style={{ display: "flex", gap: 8, maxWidth: 620 }}>
              <input
                value={q}
                onChange={(e) => setQ(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && !busy && ask()}
                placeholder="Ask about an order, e.g. OR-1003"
                style={{ flex: 1, padding: "8px 12px", border: `1px solid ${C.border}`, borderRadius: 4, fontSize: "0.95rem", fontFamily: FONT }}
              />
              <button
                onClick={() => ask()}
                disabled={busy}
                style={{ background: busy ? C.brandDark : C.brand, color: C.white, border: 0, padding: "8px 18px", borderRadius: 4, fontWeight: 600, cursor: busy ? "default" : "pointer", fontFamily: FONT }}
              >
                {busy ? "Asking…" : "Ask the agent"}
              </button>
            </div>
            {err && (
              <div style={{ marginTop: 16, background: "#fef1f1", border: `1px solid ${C.red}`, borderRadius: 6, padding: 12, color: C.red, fontSize: "0.9rem" }}>
                {err}
              </div>
            )}
          </div>
        </header>

        {/* ── Lower half: two clearly-divided render panels ──────────────── */}
        <div className="h360-cols" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 22 }}>

          {/* LEFT — hand-built React, one surface coded by hand */}
          <section style={panel}>
            <div style={panelHead}>
              <span style={tag(C.brand)}>React</span>
              <div style={{ ...eyebrow, margin: 0 }}>Hand-built card · one surface, coded by hand</div>
            </div>
            <div style={panelBody}>
              {resp ? (
                <>
                  <div style={{ background: C.white, border: `1px solid ${C.border}`, borderRadius: 8, boxShadow: "0 2px 4px rgba(0,0,0,0.07)", overflow: "hidden" }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "12px 16px", borderBottom: `1px solid ${C.border}` }}>
                      <div style={{ width: 30, height: 30, borderRadius: 6, background: C.brand, color: C.white, display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 700, fontSize: "0.9rem" }}>◱</div>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontSize: "0.7rem", letterSpacing: "0.06em", textTransform: "uppercase", color: C.greyText }}>Order</div>
                        <div style={{ color: C.navy, fontWeight: 700, fontSize: "1rem", lineHeight: 1.1 }}>{order || "Order status"}</div>
                      </div>
                      {status && (
                        <span style={{ background: statusColor(status), color: C.white, fontSize: "0.72rem", fontWeight: 600, padding: "3px 10px", borderRadius: 999, textTransform: "uppercase", letterSpacing: "0.04em" }}>
                          {status}
                        </span>
                      )}
                    </div>
                    <div style={{ padding: "16px" }}>
                      <div style={eyebrow}>Agent response</div>
                      <div style={{ color: C.navy, fontSize: "0.98rem", lineHeight: 1.5 }}>{message || "(no message in response)"}</div>
                    </div>
                    <div style={{ padding: "10px 16px", background: C.tint, borderTop: `1px solid ${C.border}`, display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12 }}>
                      <span style={{ fontSize: "0.75rem", color: C.slate }}>Rendered from the headless Agent API — no Salesforce UI.</span>
                      {recordUrl && (
                        <a href={recordUrl} target="_blank" rel="noreferrer" style={inOrgLink}>
                          View in Salesforce ↗
                        </a>
                      )}
                    </div>
                  </div>
                  <details style={{ marginTop: 12 }}>
                    <summary style={{ cursor: "pointer", color: C.slate, fontSize: "0.85rem" }}>Raw Agent API response (JSON)</summary>
                    <pre style={{ background: "#f8fafc", border: `1px solid ${C.border}`, borderRadius: 6, padding: 12, marginTop: 8, whiteSpace: "pre-wrap", fontSize: "0.78rem", color: "#181818" }}>
                      {JSON.stringify(resp, null, 2)}
                    </pre>
                  </details>
                </>
              ) : (
                <div style={{ color: C.greyText, fontSize: "0.9rem" }}>Ask the agent to see the hand-built card.</div>
              )}
            </div>
          </section>

          {/* RIGHT — the SAME Mosaic widget JSON, interpreted by a React renderer */}
          <section style={panel}>
            <div style={panelHead}>
              <span style={tag(C.brandDark)}>HXL Mosaic</span>
              <div style={{ ...eyebrow, margin: 0 }}>One definition · rendered anywhere</div>
            </div>
            <div style={panelBody}>
              <MosaicTile node={orderAssistantWidget} onAction={onAction} />
              {lastAction && (
                <div style={{ margin: "8px 0", fontSize: "0.8rem", color: C.slate }}>⚡ “{lastAction}” action fired (fire-and-forget).</div>
              )}
              {resp && (
                <div style={{ marginTop: 12 }}>
                  <MosaicTile node={bindWidget(orderStatusWidget, data)} onAction={onAction} />
                  <div style={{ marginTop: 6, fontSize: "0.72rem", color: C.greyText }}>
                    Rendered from <code>orderStatus.web.json</code> — the same Mosaic shape that deploys as a <code>UiWidgetBundle</code>.
                  </div>
                </div>
              )}
              {/* Informational: the same definition renders in-platform via the HXL Widget Viewer app */}
              <div style={{ marginTop: 14, paddingTop: 12, borderTop: `1px solid ${C.border}`, display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12, flexWrap: "wrap" }}>
                <span style={{ fontSize: "0.75rem", color: C.slate, flex: 1, minWidth: 200 }}>
                  This definition deploys as a <code>UiWidgetBundle</code> and renders inside Salesforce via a custom Lightning type.
                </span>
                {hxlViewerUrl && (
                  <a href={hxlViewerUrl} target="_blank" rel="noreferrer" style={inOrgLink}>
                    Open HXL Widget Viewer ↗
                  </a>
                )}
              </div>
            </div>
          </section>
        </div>
      </main>
    </div>
  );
}
