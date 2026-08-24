// Recursive React renderer for a (bound) Mosaic widget tree. Mirrors the in-org LWC
// mosaicTile, but interactive: buttons fire onAction, links navigate. Inline styles only.
import { C, FONT } from "./theme.js";
import { statusVariant } from "./bind.js";

const VARIANT_COLOR = { success: C.green, info: C.brand, error: C.red, warning: C.amber, neutral: C.slate };
const TEXT_STYLE = {
  h1: { fontSize: "1.5rem", fontWeight: 700, color: C.navy },
  h2: { fontSize: "1.15rem", fontWeight: 700, color: C.navy },
  h3: { fontSize: "1rem", fontWeight: 700, color: C.navy },
  body: { fontSize: "0.95rem", color: C.navy, lineHeight: 1.5 },
  caption: { fontSize: "0.8rem", color: C.greyText },
};
const CONTAINERS = ["tile/widget", "tile/container", "tile/card", "tile/row", "tile/column"];

export default function MosaicTile({ node, onAction }) {
  if (!node || !node.definition) return null;
  const a = node.attributes || {};
  const kids = Array.isArray(node.children) ? node.children : [];
  const def = node.definition;

  if (def === "tile/text") {
    return <p style={{ ...(TEXT_STYLE[a.variant] || TEXT_STYLE.body), margin: "4px 0", fontFamily: FONT }}>{a.text}</p>;
  }
  if (def === "tile/badge") {
    const color = VARIANT_COLOR[statusVariant(a.label)] || C.slate;
    return (
      <span style={{ background: color, color: C.white, fontSize: "0.72rem", fontWeight: 600, padding: "3px 10px", borderRadius: 999, textTransform: "uppercase", letterSpacing: "0.04em" }}>
        {a.label}
      </span>
    );
  }
  if (def === "tile/button") {
    const brand = a.variant === "primary";
    return (
      <button
        onClick={() => onAction?.(node, a.label)}
        style={{ background: brand ? C.brand : C.white, color: brand ? C.white : C.brand, border: `1px solid ${C.brand}`, borderRadius: 4, padding: "6px 14px", fontWeight: 600, fontSize: "0.85rem", cursor: "pointer", fontFamily: FONT }}
      >
        {a.label}
      </button>
    );
  }
  if (def === "tile/link") {
    return <a href={a.href || "#"} target="_blank" rel="noreferrer" style={{ color: C.brand, fontSize: "0.85rem", fontWeight: 600 }}>{a.text || a.href}</a>;
  }
  if (def === "tile/separator") {
    return <hr style={{ border: 0, borderTop: `1px solid ${C.border}`, margin: "10px 0" }} />;
  }
  if (def === "tile/callout") {
    return (
      <div style={{ background: C.tint, border: `1px solid ${C.border}`, borderRadius: 6, padding: "10px 12px", margin: "6px 0" }}>
        {a.title && <div style={{ fontWeight: 700, color: C.navy, fontSize: "0.9rem" }}>{a.title}</div>}
        {a.description && <div style={{ color: C.slate, fontSize: "0.82rem" }}>{a.description}</div>}
        {kids.map((c, i) => <MosaicTile key={i} node={c} onAction={onAction} />)}
      </div>
    );
  }
  if (CONTAINERS.includes(def)) {
    const isRow = def === "tile/row";
    const isCard = def === "tile/card";
    const style = {
      display: "flex",
      flexDirection: isRow ? "row" : "column",
      gap: isRow ? 10 : 6,
      alignItems: isRow ? "center" : "stretch",
      flexWrap: isRow ? "wrap" : "nowrap",
      ...(isCard ? { background: C.white, border: `1px solid ${C.border}`, borderRadius: 8, padding: 14, boxShadow: "0 2px 4px rgba(0,0,0,0.07)" } : {}),
    };
    return <div style={style}>{kids.map((c, i) => <MosaicTile key={i} node={c} onAction={onAction} />)}</div>;
  }
  // unknown tile → labeled placeholder (never crash)
  return (
    <div style={{ border: `1px dashed ${C.border}`, borderRadius: 4, padding: 8, margin: "4px 0", fontSize: "0.78rem", color: C.slate }}>
      Unsupported tile: {def}
      {kids.map((c, i) => <MosaicTile key={i} node={c} onAction={onAction} />)}
    </div>
  );
}
