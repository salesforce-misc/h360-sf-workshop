# HXL Mosaic widgets — deployable samples (mdapi format)

`UiWidgetBundle` samples. Used by [Module 4 (§4c — HXL widgets)](../../docs/modules/04-custom-ui.md).

**Widgets in this bundle:**
- `HelloWorld` — the minimal deploy proof (two `tile/text` nodes).
- `OrderStatusWidget` — **the response**: the OrderStatusSkill result (order #, status badge, summary,
  action + record link) as a surface-agnostic Mosaic card — the HXL-native twin of the Agentforce/Slack/React cards.
- `OrderAssistant` — **the interactive agent**: pick/enter an order and fire a semantic "Check status" action.
- `OrderAssistantApp` — the **combined mini-app**: `OrderAssistant` input + `OrderStatusWidget` card in one Mosaic.

Each widget's body carries a pithy `attributes.description` (a "code comment") that the
[HXL Widget Viewer](../../docs/modules/04-custom-ui.md) surfaces as a **Description** field.

🚧 **SAFE HARBOR — honest boundary.** These widgets **deploy and inspect** in-org today. `OrderAssistant` /
`OrderAssistantApp` are **interactive in the [public Playground](https://www.headlessexperiencelayer.com/playground/)**
(live input + state + conditional render); the in-org viewer renders them **structurally** (no state), and
cross-surface channel rendering is still gated. Build to learn the shape — don't promise a partner cross-surface
auto-render on a date.

**Deploy (mdapi format — NOT source format):**
```bash
sf project deploy start --metadata-dir reference/hxl-widget-sample --target-org <alias> --dry-run
sf project deploy start --metadata-dir reference/hxl-widget-sample --target-org <alias>
```

Kept under `reference/` (not `force-app/`) on purpose: the current CLI (2.143.6) has a source-format
round-trip bug for `UiWidgetBundle`, so a source-format deploy of `force-app` would trip it. mdapi format
sidesteps it. 🚧 SAFE HARBOR — proves the widget *deploys*, not that it *renders* in a channel.
