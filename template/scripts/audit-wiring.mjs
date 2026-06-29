#!/usr/bin/env node
// Auditoría de wiring: verifica que cada fetch('/api/...') tiene su route.ts
// y que no hay arrays de datos mock inline en páginas.
//
// Uso: node scripts/audit-wiring.mjs (o: pnpm audit:wiring)
// Exit: 0 = OK, 1 = crítico encontrado

import { readFileSync, existsSync } from "node:fs";
import { globSync } from "glob";
import { join, relative } from "node:path";

const ROOT = process.cwd();
const critical = [];
const warn = (msg) => critical.push(msg);

const line = "─".repeat(70);
console.log(`\n${line}\n AUDITORÍA DE WIRING — verify fetch() ↔ route.ts + zero inline data\n${line}\n`);

// ── 1. FETCH → ROUTE.TS ───────────────────────────────────────────────────────
// Busca todos los fetch() en archivos .tsx/.ts de src/app y src/components
const pageFiles = globSync(join(ROOT, "src/**/*.{tsx,ts}"), {
  ignore: [join(ROOT, "src/**/*.test.{ts,tsx}"), join(ROOT, "src/**/*.spec.{ts,tsx}")],
});

const fetchPattern = /fetch\s*\(\s*['"`]\/api\/([^/'"`]+)\/([^/'"`]*)/g;
const foundFetches = new Map(); // path → [fetch calls]

for (const file of pageFiles) {
  const content = readFileSync(file, "utf8");
  let match;
  const fetches = [];
  while ((match = fetchPattern.exec(content)) !== null) {
    const segment1 = match[1];
    fetches.push({ segment1, full: match[0] });
  }
  if (fetches.length > 0) {
    foundFetches.set(file, fetches);
  }
}

// Para cada fetch, verifica que existe route.ts
const routeFiles = globSync(join(ROOT, "src/app/api/**/route.{ts,tsx}"));
const routePaths = routeFiles.map((f) => {
  // De src/app/api/users/route.ts, extrae "users"
  const rel = relative(join(ROOT, "src/app/api"), f);
  const dir = rel.split(/[/\\]/)[0];
  return dir;
});

let fetchCount = 0;
for (const [file, fetches] of foundFetches) {
  for (const { segment1, full } of fetches) {
    fetchCount++;
    const rel = relative(ROOT, file);
    if (!routePaths.includes(segment1)) {
      warn(`WIRING: fetch en ${rel} → /api/${segment1}/... pero NO existe src/app/api/${segment1}/route.ts`);
    }
  }
}

// ── 2. ZERO INLINE DATA ───────────────────────────────────────────────────────
// Busca arrays de datos mock en páginas: const XXX = [ { ...objeto... } ]
const inlineDataPattern = /const\s+\w+\s*=\s*\[\s*\{[\s\S]*?\}\s*\]/;
let inlineCount = 0;

for (const file of pageFiles) {
  const content = readFileSync(file, "utf8");
  if (inlineDataPattern.test(content)) {
    const rel = relative(ROOT, file);
    warn(`INLINE-DATA: ${rel} contiene arrays de datos mock inline`);
    inlineCount++;
  }
}

// ── Reporte ───────────────────────────────────────────────────────────────────
if (critical.length === 0) {
  console.log(` ✅ Wiring OK: ${fetchCount} fetch() verificados, ninguno huérfano.`);
  console.log(` ✅ Zero inline data: ninguna página con arrays mock inline.\n`);
  console.log(line);
  console.log(" Resultado: ✅ WIRING VERIFICADO\n");
  process.exit(0);
}

console.log(` ❌ CRÍTICOS (${critical.length}):`);
for (const msg of critical) {
  console.log(`    • ${msg}`);
}
console.log("");
console.log(line);
console.log(" Resultado: ❌ WIRING FALLIDO\n");
process.exit(1);
