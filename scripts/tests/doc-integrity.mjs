#!/usr/bin/env node
/**
 * Workshop integrity checks — everything verifiable without clicking through the UI.
 *
 * Run:  node scripts/tests/doc-integrity.mjs
 * Exit: 0 = all green, 1 = one or more checks failed.
 *
 * Covers:
 *   A. Every scripts/**\/*.sh parses under `bash -n`.
 *   B. No broken INTERNAL markdown links in docs/ + README + OVERVIEW (file must exist;
 *      an #anchor must match a heading on the target page).
 *   C. The reference Skill (OrderStatusSkill) is `global` so a hosted MCP server can expose it.
 *   D. The reference object's tab is referred to as "H360 Orders", never the misleading bare "Orders".
 *   E. Documented-gotcha guards — the field-verified fixes stay in the docs (regression guards).
 */
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join, dirname, resolve, relative, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

const ROOT = resolve(fileURLToPath(new URL('../../', import.meta.url)));
let failures = 0;
let checks = 0;

const rel = (p) => relative(ROOT, p) || p;
function ok(msg) { checks++; console.log(`  ✓ ${msg}`); }
function bad(msg) { checks++; failures++; console.log(`  ✗ ${msg}`); }
function section(name) { console.log(`\n═══ ${name}`); }

/** Recursively collect files under dir whose name matches `test(name)`. */
function walk(dir, test, acc = []) {
  if (!existsSync(dir)) return acc;
  for (const entry of readdirSync(dir)) {
    if (entry === 'node_modules' || entry === '.git' || entry === '.sfdx') continue;
    const full = join(dir, entry);
    const st = statSync(full);
    if (st.isDirectory()) walk(full, test, acc);
    else if (test(entry, full)) acc.push(full);
  }
  return acc;
}

/** GitHub-flavored heading -> anchor slug. */
function slug(heading) {
  return heading
    .trim()
    .toLowerCase()
    .replace(/[^\w\- ]+/g, '') // drop punctuation, emoji, em dashes; keep word chars, hyphen, space
    .replace(/ /g, '-'); // GitHub maps each space to one hyphen and does NOT collapse runs
}

function headingSlugs(md) {
  const slugs = new Set();
  const counts = {};
  for (const line of md.split('\n')) {
    const m = /^#{1,6}\s+(.*)$/.exec(line.trim());
    if (!m) continue;
    let s = slug(m[1]);
    if (s in counts) { counts[s]++; s = `${s}-${counts[s]}`; }
    else counts[s] = 0;
    slugs.add(s);
  }
  return slugs;
}

// ── A. Shell scripts parse ──────────────────────────────────────────────
section('A. Shell scripts parse (bash -n)');
for (const sh of walk(join(ROOT, 'scripts'), (n) => n.endsWith('.sh')).sort()) {
  try {
    execFileSync('bash', ['-n', sh], { stdio: 'pipe' });
    ok(`bash -n ${rel(sh)}`);
  } catch (e) {
    bad(`bash -n ${rel(sh)} — ${String(e.stderr || e.message).trim().split('\n')[0]}`);
  }
}

// ── B. Internal markdown links resolve ─────────────────────────────────
section('B. Internal markdown links resolve');
const mdFiles = [
  ...walk(join(ROOT, 'docs'), (n) => n.endsWith('.md')),
  ...['README.md', 'OVERVIEW.md'].map((f) => join(ROOT, f)).filter(existsSync),
].sort();
const linkRe = /\[[^\]]*\]\(([^)]+)\)/g;
for (const md of mdFiles) {
  const text = readFileSync(md, 'utf8');
  let m;
  while ((m = linkRe.exec(text))) {
    let target = m[1].trim();
    if (/^(https?:|mailto:|#)/.test(target)) continue; // external or same-page anchor (skip)
    const [pathPart, anchor] = target.split('#');
    const resolved = resolve(dirname(md), pathPart);
    if (!existsSync(resolved)) {
      bad(`${rel(md)} → missing target ${target}`);
      continue;
    }
    if (anchor && extname(resolved) === '.md') {
      const slugs = headingSlugs(readFileSync(resolved, 'utf8'));
      if (!slugs.has(anchor.toLowerCase())) {
        bad(`${rel(md)} → ${target} (no heading anchor "#${anchor}")`);
        continue;
      }
    }
    ok(`${rel(md)} → ${target}`);
  }
}

// ── C. Reference Skill is global (MCP-exposable) ───────────────────────
section('C. OrderStatusSkill is global (hosted-MCP exposable)');
const skillPath = join(ROOT, 'sfdx/force-app/main/default/classes/OrderStatusSkill.cls');
const skill = readFileSync(skillPath, 'utf8');
if (/\bglobal\s+(with|without|inherited)\s+sharing\s+class\s+OrderStatusSkill\b/.test(skill))
  ok('class declared `global ... sharing class OrderStatusSkill`');
else bad('OrderStatusSkill class is not `global` (a `public` class is not auto-exposed to a hosted MCP server)');
if (/\bglobal\s+static\s+List<Response>\s+getStatus\b/.test(skill))
  ok('getStatus is `global static`');
else bad('getStatus is not `global static`');

// ── D. Tab naming: "H360 Orders", never the misleading bare "Orders" ───
section('D. Tab naming ("H360 Orders", not the standard "Orders")');
const tabFiles = {
  'docs/modules/02-capability.md': ['**Order tab**', 'the **Order tab**'],
  'scripts/smoke.sh': ['→ Orders →'],
  'docs/ISSUES.md': ['no Orders tab'],
  'sfdx/README.md': ['**Order tab', 'Order-tab visibility'],
  'scripts/steps/deploy.sh': ['+ Order tab', 'Order tab visibility'],
  'sfdx/force-app/main/default/permissionsets/Headless360_Workshop_Access.permissionset-meta.xml': ['<!-- Order tab', 'open the Order tab'],
};
for (const [f, banned] of Object.entries(tabFiles)) {
  const text = readFileSync(join(ROOT, f), 'utf8');
  // "H360 Order" is a substring of both the object name ("H360 Order") and the tab label ("H360 Orders").
  if (!text.includes('H360 Order')) bad(`${f} does not mention the correct tab name "H360 Order(s)"`);
  else ok(`${f} names "H360 Order(s)"`);
  for (const b of banned) {
    if (text.includes(b)) bad(`${f} still contains misleading tab reference: ${JSON.stringify(b)}`);
    else ok(`${f} free of ${JSON.stringify(b)}`);
  }
}
if (readFileSync(join(ROOT, 'docs/setup.md'), 'utf8').includes('H360 Orders')) ok('docs/setup.md names "H360 Orders"');
else bad('docs/setup.md does not mention "H360 Orders"');

// ── E. Documented-gotcha regression guards ─────────────────────────────
section('E. Documented-gotcha guards (field-verified fixes stay in the docs)');
const guards = [
  ['docs/modules/02-capability.md', /cd sfdx/, 'Module 2 runs by-hand sf commands from sfdx/'],
  ['docs/modules/02-capability.md', /Conversation Preview/, 'Module 2 uses Agent Builder Conversation Preview as the primary OR-1003 path'],
  ['docs/modules/02-capability.md', /sf agent preview --use-live-actions/, 'Module 2 CLI alternative uses bare interactive `sf agent preview`'],
  ['docs/modules/02-capability.md', /sf agent preview send/, 'Module 2 documents `preview send` (scripted) mode'],
  ['docs/modules/03-connect-claude-mcp.md', /OAUTH_AUTHORIZATION_BLOCKED/, 'Module 3 documents the SSO block error'],
  ['docs/modules/03-connect-claude-mcp.md', /--no-browser/, 'Module 3 gives the --no-browser recipe'],
  ['docs/modules/03-connect-claude-mcp.md', /incognito/i, 'Module 3 gives the incognito workaround'],
  ['docs/modules/03a-custom-mcp-server.md', /must be `global`/, 'Module 3a explains the global requirement'],
  ['docs/modules/03a-custom-mcp-server.md', /Copy Server URL/, 'Module 3a says to copy the custom server URL'],
  ['docs/modules/03a-custom-mcp-server.md', /order-concierge/, 'Module 3a re-registers the custom server in Claude'],
  ['docs/setup.md', /trust the mechanical line/i, 'setup.md clarifies the premature-orders manual check'],
];
for (const [f, re, desc] of guards) {
  if (re.test(readFileSync(join(ROOT, f), 'utf8'))) ok(desc);
  else bad(`${desc} — not found in ${f}`);
}

// ── F. `sf agent preview start` never presented as an interactive chat ──
section('F. `sf agent preview start` not presented as interactive');
for (const f of ['docs/build-and-deploy.md', 'docs/modules/07-fork.md']) {
  const text = readFileSync(join(ROOT, f), 'utf8');
  if (/agent preview start/.test(text)) bad(`${f} still runs \`sf agent preview start\` (programmatic, exits) as a chat command`);
  else ok(`${f} free of \`agent preview start\``);
}

// ── Summary ─────────────────────────────────────────────────────────────
console.log(`\n${failures === 0 ? '✅' : '❌'} ${checks - failures}/${checks} checks passed` +
  (failures ? ` (${failures} FAILED)` : ''));
process.exit(failures === 0 ? 0 : 1);
