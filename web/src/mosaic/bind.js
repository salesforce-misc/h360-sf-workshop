// Pure Mosaic data-binding — no React. Resolves {{token}} placeholders in a widget
// tree from a data object, so one widget definition renders with live data.
const BIND_ATTRS = ["text", "label", "title", "description", "href"];
const TOKEN = /\{\{\s*([\w.]+)\s*\}\}/g;

function subst(str, data) {
  return str.replace(TOKEN, (_, key) => {
    const v = data ? data[key] : undefined;
    return v == null ? "" : String(v);
  });
}

export function bindWidget(node, data) {
  if (!node || typeof node !== "object" || !node.definition) {
    return { definition: "unknown", attributes: { error: "malformed node" } };
  }
  const attributes = { ...(node.attributes || {}) };
  for (const k of BIND_ATTRS) {
    if (typeof attributes[k] === "string") attributes[k] = subst(attributes[k], data);
  }
  const out = { ...node, attributes };
  if (Array.isArray(node.children)) {
    out.children = node.children.map((c) => bindWidget(c, data));
  }
  return out;
}

export function statusVariant(status) {
  const v = (status || "").toLowerCase();
  if (v.includes("deliver")) return "success";
  if (v.includes("ship")) return "info";
  if (v.includes("exception")) return "error";
  if (v.includes("process")) return "warning";
  return "neutral";
}
