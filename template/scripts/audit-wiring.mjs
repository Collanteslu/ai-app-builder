#!/usr/bin/env node
// Auditoría de wiring: verifica que cada fetch('/api/...') tiene su route.ts
// y que no hay arrays de datos mock inline en páginas.
//
// Uso: node scripts/audit-wiring.mjs (o: pnpm audit:wiring)
// Exit: 0 = OK, 1 = crítico encontrado

import { readFileSync, existsSync, readdirSync } from "node:fs";
import { join, relative, sep } from "node:path";

const ROOT = process.cwd();
const critical = [];
const warn = (msg) => critical.push(msg);

function walk(dir, acc = []) {
  if (!existsSync(dir)) return acc;
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    if (e.isDirectory()) {
      if (["node_modules", ".next", ".git"].includes(e.name)) continue;
      walk(join(dir, e.name), acc);
    } else {
      acc.push(join(dir, e.name));
    }
  }
  return acc;
}

const posix = (f) => relative(ROOT, f).split(sep).join("/");

const line = "─".repeat(70);
console.log(`\n${line}\n AUDITORÍA DE WIRING — verify fetch() ↔ route.ts + zero inline data\n${line}\n`);

// ── 1. FETCH → ROUTE.TS ───────────────────────────────────────────────────────
const SRC = join(ROOT, "src");
const allFiles = walk(SRC);
const pageFiles = allFiles.filter((f) => /\.(tsx|ts)$/.test(f) && !/\.(test|spec)\./.test(posix(f)));

const fetchPattern = /fetch\s*\(\s*['"`]\/api\/([^'"`?\s)]+)/g;
const apiDir = join(SRC, "app", "api");

function resolveApiPath(segments) {
  let dir = apiDir;
  for (const seg of segments) {
    const dynamic = /\$\{/.test(seg) || /^\d+$/.test(seg);
    if (dynamic) {
      const dynChild = existsSync(dir) && readdirSync(dir, { withFileTypes: true }).find((e) => e.isDirectory() && /^\[.+\]$/.test(e.name));
      if (!dynChild) return false;
      dir = join(dir, dynChild.name);
    } else {
      const literal = join(dir, seg);
      if (existsSync(literal)) dir = literal;
      else {
        const dynChild = existsSync(dir) && readdirSync(dir, { withFileTypes: true }).find((e) => e.isDirectory() && /^\[.+\]$/.test(e.name));
        if (!dynChild) return false;
        dir = join(dir, dynChild.name);
      }
    }
  }
  return existsSync(join(dir, "route.ts"));
}

let fetchCount = 0;
for (const file of pageFiles) {
  const content = readFileSync(file, "utf8");
  let match;
  while ((match = fetchPattern.exec(content)) !== null) {
    fetchCount++;
    const segments = match[1].split("/").filter(Boolean);
    if (!resolveApiPath(segments)) {
      warn(`WIRING: fetch en ${posix(file)} → /api/${match[1]} pero NO existe src/app/api/${match[1]}/route.ts`);
    }
  }
}

// ── 2. ZERO INLINE DATA ───────────────────────────────────────────────────────
const DATA_KEYS = [
  "id", "title", "name", "price", "description", "status", "email",
  "image", "img", "date", "amount", "rating", "stock", "sku", "category",
];
for (const file of pageFiles) {
  const content = readFileSync(file, "utf8");
  let m;
  const re = /(\w*)\s*=\s*\[/g;
  while ((m = re.exec(content)) !== null) {
    if (m[1] && /^[A-Z][A-Z0-9_]*$/.test(m[1])) continue;
    const chunk = content.slice(m.index, m.index + 1200);
    if (!chunk.includes("{")) continue;
    const keys = new Set();
    for (const km of chunk.matchAll(/(\w+)\s*:\s*["'`\d]/g)) {
      if (DATA_KEYS.includes(km[1])) keys.add(km[1]);
    }
    if (keys.size >= 2) {
      warn(`INLINE-DATA: ${posix(file)} contiene arrays de datos mock inline (${[...keys].join(", ")})`);
      break;
    }
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
