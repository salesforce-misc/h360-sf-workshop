import { describe, it, expect } from "vitest";
import { bindWidget, statusVariant } from "./bind.js";

const data = { order: "OR-1003", status: "Exception", summary: "Carrier exception.", recordUrl: "https://x/r/1" };

describe("bindWidget", () => {
  it("substitutes tokens in string attributes", () => {
    const node = { definition: "tile/text", attributes: { text: "Order {{order}}", variant: "h2" } };
    const out = bindWidget(node, data);
    expect(out.attributes.text).toBe("Order OR-1003");
    expect(out.attributes.variant).toBe("h2");
  });
  it("binds link text + href", () => {
    const node = { definition: "tile/link", attributes: { text: "{{status}}", href: "{{recordUrl}}" } };
    const out = bindWidget(node, data);
    expect(out.attributes.text).toBe("Exception");
    expect(out.attributes.href).toBe("https://x/r/1");
  });
  it("resolves a missing token to empty string", () => {
    const out = bindWidget({ definition: "tile/text", attributes: { text: "{{nope}}" } }, data);
    expect(out.attributes.text).toBe("");
  });
  it("recurses into children", () => {
    const node = { definition: "tile/row", children: [{ definition: "tile/text", attributes: { text: "{{order}}" } }] };
    expect(bindWidget(node, data).children[0].attributes.text).toBe("OR-1003");
  });
  it("does not mutate the input", () => {
    const node = { definition: "tile/text", attributes: { text: "{{order}}" } };
    const copy = JSON.parse(JSON.stringify(node));
    bindWidget(node, data);
    expect(node).toEqual(copy);
  });
  it("returns a placeholder for malformed input", () => {
    expect(bindWidget(null, data).definition).toBe("unknown");
  });
});

describe("statusVariant", () => {
  it("maps known statuses", () => {
    expect(statusVariant("Exception")).toBe("error");
    expect(statusVariant("Shipped")).toBe("info");
    expect(statusVariant("Delivered")).toBe("success");
    expect(statusVariant("Processing")).toBe("warning");
  });
  it("defaults to neutral", () => {
    expect(statusVariant("weird")).toBe("neutral");
    expect(statusVariant()).toBe("neutral");
  });
});
