#!/usr/bin/env node
// Auditoría ejecutable — gate de la Fase 6 del AI App Builder.
//
// Comprueba de VERDAD (no de memoria) los huecos que las skills definen como
// bloqueantes y devuelve exit≠0 si encuentra alguno CRÍTICO. Así el cierre del
// proceso depende del código de salida, no de la narración del modelo.
//
// Uso:  node scripts/audit.mjs        (o:  pnpm audit:builder)
//
// Severidad:
//   CRÍTICO  → bloquea el cierre (exit 1): datos inline, fetch sin endpoint,
//              servicio huérfano (capa de lógica muerta), endpoint sin Zod,
//              entidad creable que no es editable (CREATE/EDIT symmetry).
//   AVISO    → no bloquea (exit 0), pero se reporta: e2e placeholder, test DB
//              no aislada, CRUD incompleto (creable sin listado/detalle).
//
// Opt-out puntual: añade `// audit-ignore` en la misma línea o la anterior.

import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join, relative, sep } from "node:path";

const ROOT = process.cwd();
const SRC = join(ROOT, "src");

const critical = [];
const warnings = [];
const crit = (rule, file, msg) => critical.push({ rule, file, msg });
const warn = (rule, file, msg) => warnings.push({ rule, file, msg });

const DATA_KEYS = [
  "id", "title", "name", "price", "description", "status", "email",
  "image", "img", "date", "amount", "rating", "stock", "sku", "category",
];

function walk(dir, acc = []) {
  if (!existsSync(dir)) return acc;
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    if (e.isDirectory()) {
      if (["node_modules", ".next", ".git", "generated"].includes(e.name)) continue;
      walk(join(dir, e.name), acc);
    } else {
      acc.push(join(dir, e.name));
    }
  }
  return acc;
}

const posix = (f) => relative(ROOT, f).split(sep).join("/");
const read = (f) => readFileSync(f, "utf8");

if (!existsSync(SRC)) {
  console.log("ℹ️  No hay src/ — nada que auditar todavía.");
  process.exit(0);
}

const files = walk(SRC);
const apiRoutes = files.filter((f) => /\/app\/.*\/api\/|\/app\/api\//.test(posix(f)) && f.endsWith("route.ts"));
const pages = files.filter((f) => f.endsWith(".tsx") && posix(f).includes("/app/") && !posix(f).includes("/api/") && !/\.test\./.test(posix(f)));
const services = files.filter((f) => /\/services\/.*(service|validator)\.ts$/i.test(posix(f)) && !/\.test\./.test(posix(f)));

// ── 1. CRÍTICO — datos mock inline en páginas ────────────────────────────────
for (const f of pages) {
  const src = read(f);
  let m;
  const re = /(\w*)\s*=\s*\[/g;
  while ((m = re.exec(src)) !== null) {
    const before = src.slice(Math.max(0, m.index - 120), m.index);
    const lineStart = src.lastIndexOf("\n", m.index);
    const prevLine = src.slice(src.lastIndexOf("\n", lineStart - 1), lineStart);
    if (/audit-ignore/.test(before) || /audit-ignore/.test(prevLine)) continue;
    // Constante en UPPER_SNAKE_CASE = convención de config/enum, no datos mock.
    if (m[1] && /^[A-Z][A-Z0-9_]*$/.test(m[1])) continue;
    const chunk = src.slice(m.index, m.index + 1200);
    if (!chunk.includes("{")) continue;
    const keys = new Set();
    for (const km of chunk.matchAll(/(\w+)\s*:\s*["'`\d]/g)) {
      if (DATA_KEYS.includes(km[1])) keys.add(km[1]);
    }
    if (keys.size >= 2) {
      const lineNo = src.slice(0, m.index).split("\n").length;
      crit("INLINE-DATA", `${posix(f)}:${lineNo}`, `array de datos inline (${[...keys].join(", ")}). Los datos van detrás de un endpoint, no en la página.`);
      break; // un hallazgo por página basta
    }
  }
}

// ── 2. CRÍTICO — fetch a /api/... sin carpeta de endpoint ─────────────────────
// Recorre la ruta COMPLETA segmento a segmento (no solo el primero): un segmento
// estático debe existir como carpeta literal; un segmento dinámico (`${...}` o
// todo dígitos, p. ej. un id) casa con cualquier carpeta `[param]` existente. Así
// `fetch('/api/users/profile')` con users/ pero sin users/profile/ se detecta.
const apiDir = join(SRC, "app", "api");
const dynChild = (dir) => existsSync(dir) && readdirSync(dir, { withFileTypes: true }).find((e) => e.isDirectory() && /^\[.+\]$/.test(e.name));
function resolveApiPath(segments) {
  let dir = apiDir;
  for (const seg of segments) {
    const dynamic = /\$\{/.test(seg) || /^\d+$/.test(seg);
    if (dynamic) {
      const child = dynChild(dir);
      if (!child) return false;
      dir = join(dir, child.name);
    } else {
      const literal = join(dir, seg);
      if (existsSync(literal)) dir = literal;
      else {
        const child = dynChild(dir); // tolera que el segmento esté modelado como dinámico
        if (!child) return false;
        dir = join(dir, child.name);
      }
    }
  }
  return existsSync(join(dir, "route.ts"));
}
for (const f of [...pages, ...files.filter((x) => x.endsWith(".ts") && !x.endsWith("route.ts"))]) {
  const src = read(f);
  for (const fm of src.matchAll(/fetch\(\s*[`"']\/api\/([^`"'?\s)]+)/g)) {
    const segments = fm[1].split("/").filter(Boolean);
    if (!segments.length) continue;
    if (!resolveApiPath(segments)) {
      const lineNo = src.slice(0, fm.index).split("\n").length;
      crit("WIRING", `${posix(f)}:${lineNo}`, `fetch a /api/${fm[1]} pero no existe su route.ts (ningún src/app/api/${segments.join("/")}/route.ts ni equivalente dinámico).`);
    }
  }
}

// ── 3. CRÍTICO — servicio huérfano (no se importa en NINGÚN sitio de src) ──
// Escanea todo src/ (no solo /app/) y casa imports por nombre de fichero, tanto
// por alias (@/lib/services/x) como relativos (./x) — así no marca como muerto un
// servicio usado desde lib/ (p. ej. auth-service en lib/auth.ts, o un validator
// usado por otro servicio).
const nonTestSrc = files.filter((f) => /\.(ts|tsx)$/.test(f) && !/\.test\./.test(posix(f)));
// Clave de import por servicio. Un `index.ts` se importa por su CARPETA, no por
// "index" (`from '@/services/user'`). Si dos servicios comparten basename
// (services/auth/validator vs services/payment/validator), casar solo por base
// daría un falso negativo: exigimos también el directorio padre para desambiguar.
const baseCount = {};
const svcKey = (svc) => {
  const parts = posix(svc).replace(/\.ts$/, "").split("/");
  const base = parts.pop();
  const parent = parts.pop();
  return base === "index" ? { tail: parent, needParent: false } : { tail: base, needParent: true, parent };
};
for (const svc of services) baseCount[svcKey(svc).tail] = (baseCount[svcKey(svc).tail] || 0) + 1;
for (const svc of services) {
  const { tail, needParent, parent } = svcKey(svc);
  // Si el basename colisiona con otro servicio, exige la ruta padre/base completa.
  const ambiguous = needParent && parent && baseCount[tail] > 1;
  const pattern = ambiguous ? `[/]${parent}[/]${tail}` : `[/]${tail}`;
  const importRe = new RegExp(`(from\\s+|import\\(\\s*)["'\`][^"'\`]*${pattern}["'\`]`);
  const used = nonTestSrc.some((f) => f !== svc && importRe.test(read(f)));
  if (!used) {
    crit("ORPHAN-SERVICE", posix(svc), `el servicio no se usa en ningún endpoint ni componente (capa de lógica muerta). Cablea su uso en el route/página o elimínalo.`);
  }
}

// ── 4. CRÍTICO — endpoint que lee body sin validar con Zod ────────────────────
for (const r of apiRoutes) {
  const src = read(r);
  if (/\.json\(\)/.test(src) && /(req|request)\s*\.\s*json|await\s+\w*\.?json\(\)/.test(src)) {
    if (!/from\s+["']zod["']/.test(src)) {
      crit("NO-ZOD", posix(r), "lee el body de la petición sin validarlo con Zod (validación manual frágil).");
    }
  }
}

// ── 5. AVISO — e2e placeholder ────────────────────────────────────────────────
const e2eDir = join(ROOT, "e2e");
if (existsSync(e2eDir)) {
  const specs = readdirSync(e2eDir).filter((f) => f.endsWith(".spec.ts"));
  const real = specs.some((s) => {
    const c = read(join(e2eDir, s));
    return !/playwright\.dev|example\.com/.test(c) && c.length > 200;
  });
  if (!real) warn("E2E-PLACEHOLDER", "e2e/", "no hay un test e2e real del flujo principal (solo el ejemplo).");
}

// ── 6. AVISO — test DB no aislada (si hay tests y Prisma) ──────────────────────
const hasTests = files.some((f) => /\.test\.ts$/.test(posix(f)));
const usesPrisma = existsSync(join(ROOT, "prisma", "schema.prisma"));
if (hasTests && usesPrisma && !existsSync(join(ROOT, "docker-compose.test.yml"))) {
  warn("TEST-DB", "docker-compose.test.yml", "no existe la BD de test aislada; los tests comparten la BD de desarrollo.");
}

// ── 7. CRÍTICO — CREATE/EDIT symmetry (toda entidad creable es editable) ──────
const newPages = files.filter((f) => /\/new\/page\.tsx$/.test(posix(f)));
const fromRoot = (p) => join(ROOT, ...p.split("/"));
for (const np of newPages) {
  const entityDir = posix(np).replace(/\/new\/page\.tsx$/, "");
  if (!existsSync(fromRoot(`${entityDir}/[id]/edit/page.tsx`))) {
    crit("CREATE-EDIT", posix(np), `hay página de creación pero falta la de edición (${entityDir}/[id]/edit/page.tsx). Toda entidad creable debe ser editable.`);
  }
}

// ── 8. AVISO — CRUD completo (la entidad creable tiene listado y detalle) ─────
for (const np of newPages) {
  const entityDir = posix(np).replace(/\/new\/page\.tsx$/, "");
  for (const [label, rel] of [["listado", `${entityDir}/page.tsx`], ["detalle", `${entityDir}/[id]/page.tsx`]]) {
    if (!existsSync(fromRoot(rel))) {
      warn("CRUD", entityDir, `entidad creable sin página de ${label} (${rel}).`);
    }
  }
}

// ── Informe ───────────────────────────────────────────────────────────────────
const line = "─".repeat(70);
console.log(`\n${line}\n AUDITORÍA EJECUTABLE — gate de cierre\n${line}`);
console.log(` Páginas: ${pages.length}  ·  Endpoints: ${apiRoutes.length}  ·  Servicios: ${services.length}\n`);

if (critical.length === 0 && warnings.length === 0) {
  console.log(" ✅ Sin huecos. Trazabilidad y wiring correctos.\n");
  process.exit(0);
}

if (critical.length) {
  console.log(` ❌ CRÍTICOS (${critical.length}) — bloquean el cierre:`);
  for (const c of critical) console.log(`    • [${c.rule}] ${c.file}\n        ${c.msg}`);
  console.log("");
}
if (warnings.length) {
  console.log(` ⚠️  AVISOS (${warnings.length}) — no bloquean, pero conviene cerrarlos:`);
  for (const w of warnings) console.log(`    • [${w.rule}] ${w.file}\n        ${w.msg}`);
  console.log("");
}

console.log(line);
if (critical.length) {
  console.log(" Resultado: ❌ BLOQUEADO. Vuelve a la Fase 5 y cierra los críticos.\n");
  process.exit(1);
}
console.log(" Resultado: ✅ Sin críticos (hay avisos por revisar).\n");
process.exit(0);
