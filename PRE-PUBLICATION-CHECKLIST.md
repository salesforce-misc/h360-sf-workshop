# Pre-Publication Checklist — gaps to address before this repo goes public

**Status: PRIVATE — under review.** This repo holds the Headless 360 participant workshop content seeded onto the
Salesforce OSS starter template (baseline commit `54dd4af`, 2026-08-24). It is **not yet cleared for public release.**
This file tracks the open legal decisions, action items, and open questions. Delete it once the repo is published.

Owner: Brandon Stauber (bstauber@salesforce.com).

---

## 🔴 Blocking — legal / licensing decisions (must resolve before public)

- [ ] **Choose the LICENSE.** `LICENSE.txt` is currently **The Unlicense** — the *starter-template placeholder*, almost
  certainly **not** the intended license for a Salesforce sample. Decide the real license (Salesforce sample default is
  **BSD-3-Clause**; Apache-2.0 also used). **Everything below marked "(pending license)" depends on this.**
- [ ] **Confirm it's cleared to open-source at all** — content, screenshots, and any referenced product capabilities are
  OK to publish publicly (incl. the 🚧 SAFE HARBOR "honest boundary" language in the HXL sections).
- [ ] **ECCN / export classification** — fill the `#ECCN:` line in `CODEOWNERS` (template has `#ECCN:Open Source`) and the
  `#GUSINFO:` team/product tags. Confirm the correct ECCN with legal/trade.

## 🟡 Action items — repo hygiene before public

- [ ] **CODEOWNERS** — replace placeholder `* @github-org/my-team` with the real owning GUS team.
- [ ] **Per-file copyright headers** *(pending license)* — Apex (`.cls`) and JS/JSX source carry **no** headers today;
  add the standard header for the chosen license.
- [ ] **`web/package.json` `license` field** *(pending license)* — currently `null`; set to the chosen SPDX id and add
  an `author`.
- [ ] **Remove `how_to_license.md`** — it's Salesforce OSS *setup instructions*, not project content. Delete before publish.
- [ ] **`README.md` polish** — replaced with the workshop README; give it a final pass for a public/self-guided audience
  (currently still references a facilitator in places — see self-guided items below).
- [ ] **Final secret + link sweep** on the exact publish commit (baseline scan was clean; re-run at release).

## 🟢 Self-guided variant — content changes (the main functional delta)

This repo is a **self-guided** version of the facilitator-led participant lab. Content is ~identical; the largest
difference is **org provisioning** (no facilitator handing out an event code). Tracked on the `self-guided` branch.

- [ ] **Org provisioning rewrite** — `README.md` + `docs/setup.md`: replace "event code from your facilitator" /
  facilitator-led OrgFarm claim with a **self-serve** signup flow. Confirm the self-serve path + template availability.
- [ ] **Remove facilitator-dependent beats** — e.g. `docs/modules/08a-external-mcp.md` ("Grab a facilitator when you're
  ready…"); rewrite for a solo learner.
- [ ] **Facilitator-only assets** — decide what to omit (e.g. the HXL Widget Viewer is facilitator/demo-only via
  `scripts/08-deploy-hxl-widget-viewer.sh`, which is not in the participant path).

## ❓ Open questions

- [ ] **Repo name / description** — keep `h360-sf-workshop`? The GitHub description is currently empty.
- [ ] **Relationship to the facilitator-led repo** — is this a fork/variant or the single canonical public home?
- [ ] **Support model** — Issues/PRs enabled? Who triages? (ties to CODEOWNERS + CONTRIBUTING).
- [ ] **`UiWidgetBundle` / HXL beta framing** — the HXL content is honest-boundary/SAFE HARBOR; confirm the public wording
  is right for a beta capability.

---

## ✅ Already handled in the baseline (for reviewer context)

- Salesforce OSS governance preserved: `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CODEOWNERS`, `LICENSE.txt`.
- Dropped 3 `*-DEPRECATED.md` stubs from the source repo.
- Retargeted clone URLs `bstaubersalesforce` → `salesforce-misc`.
- Removed a broken internal-doc reference (`KNOWN-GAPS`) from `sfdx/README.md`.
- Verified: **no hardcoded secrets**; no `node_modules` / `dist` / `.env` committed; no residual internal-doc references.
