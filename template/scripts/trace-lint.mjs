#!/usr/bin/env node
// Lint de trazabilidad ejecutable — gate de las fases TEMPRANAS (2 y 3) del AI App Builder.
//
// Filosofía idéntica a audit.mjs, pero adelantada: en lugar de esperar a la
// Fase 6 para descubrir que un RF del PRD nunca llegó a la arquitectura, lo caza
// en cuanto el artefacto existe. El cierre de las fases de criterio (PRD,
// arquitectura) deja de depender de la narración del modelo y pasa a depender del
// código de salida.
//
// Opera sobre los artefactos markdown de .builder/ (no sobre el código):
//   .builder/discovery.md   (Fase 1)  — casos de uso CU-XX
//   .builder/prd.md         (Fase 2)  — requisitos RF-XX / RNF-XX
//   .builder/architecture.md(Fase 3)  — tabla de trazabilidad RF → entidad/endpoint
//
// Uso:  node scripts/trace-lint.mjs        (o:  pnpm trace:builder)
//
// Severidad:
//   CRÍTICO → bloquea (exit 1): RF sin criterio de aceptación, CU sin RF,
//             RF del PRD ausente en la arquitectura, RF en arquitectura sin PRD.
//   AVISO   → no bloquea (exit 0): RF sin prioridad, RNF de seguridad ausente.
//
// Es tolerante: si un artefacto aún no existe, no audita sus reglas (no penaliza
// trabajar fase a fase). Solo exige coherencia entre los que SÍ existen.

import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";

const ROOT = process.cwd();
const BUILDER = join(ROOT, ".builder");

const critical = [];
const warnings = [];
const crit = (rule, where, msg) => critical.push({ rule, where, msg });
const warn = (rule, where, msg) => warnings.push({ rule, where, msg });

const read = (f) => (existsSync(f) ? readFileSync(f, "utf8") : null);
const uniq = (arr) => [...new Set(arr)];
const idsOf = (txt, prefix) =>
  txt ? uniq([...txt.matchAll(new RegExp(`\\b${prefix}-(\\d+)`, "g"))].map((m) => `${prefix}-${m[1]}`)) : [];

if (!existsSync(BUILDER)) {
  console.log("ℹ️  No hay .builder/ — aún no hay artefactos que cotejar.");
  process.exit(0);
}

const discovery = read(join(BUILDER, "discovery.md"));
const prd = read(join(BUILDER, "prd.md"));
const architecture = read(join(BUILDER, "architecture.md"));

// IDs declarados en cada artefacto (la fuente de verdad es el PRD para RF/RNF).
const cuIds = idsOf(discovery, "CU");
const rfIds = idsOf(prd, "RF");
const rnfIds = idsOf(prd, "RNF");

// ── 1. CRÍTICO — cada CU del discovery tiene al menos un RF en el PRD ─────────
// La cadena empieza en el discovery: un caso de uso sin requisito es alcance
// que se evaporó entre la Fase 1 y la 2.
if (discovery && prd) {
  for (const cu of cuIds) {
    // Buscamos que el PRD mencione el CU (trazabilidad explícita) o, si el PRD no
    // referencia CUs, no penalizamos por número pero sí avisamos si hay menos RF que CU.
    const referenced = new RegExp(`\\b${cu}\\b`).test(prd);
    if (!referenced && prd.includes("CU-")) {
      crit("CU-SIN-RF", "prd.md", `${cu} del discovery no se referencia en ningún RF del PRD (caso de uso sin requisito).`);
    }
  }
  if (!prd.includes("CU-") && cuIds.length > rfIds.length) {
    warn("CU-RF-RATIO", "prd.md", `el discovery define ${cuIds.length} CU pero el PRD solo ${rfIds.length} RF y no referencia CUs: revisa que ningún caso de uso se haya perdido.`);
  }
}

// ── 2. CRÍTICO — cada RF del PRD tiene criterio de aceptación Given/When/Then ─
// Sin criterio testeable, el RF no es verificable y el test de la Fase 5 no
// puede nacer de un contrato. Buscamos el bloque de cada RF hasta el siguiente.
if (prd) {
  const ACCEPT = /(dado|cuando|entonces|given|when|then)\b/i;
  const PRIORITY = /(prioridad|priority)\s*[:=]?\s*(alta|media|baja|high|medium|low)/i;
  // Particiona el PRD por encabezados de RF (acepta "### RF-01", "RF-01:", "- RF-01").
  const blocks = splitByIds(prd, "RF");
  for (const { id, body } of blocks) {
    if (!ACCEPT.test(body)) {
      crit("RF-SIN-CRITERIO", "prd.md", `${id} no tiene criterios de aceptación (Dado/Cuando/Entonces). Sin esto no es testeable.`);
    }
    if (!PRIORITY.test(body)) {
      warn("RF-SIN-PRIORIDAD", "prd.md", `${id} no declara prioridad (alta/media/baja); la Fase 5 prioriza por ella.`);
    }
  }
}

// ── 3. CRÍTICO — cada RF del PRD aparece en la arquitectura ───────────────────
// El hueco RF→arquitectura es el que hoy no se ve hasta la Fase 6. Aquí salta ya.
if (prd && architecture) {
  const archRf = idsOf(architecture, "RF");
  for (const rf of rfIds) {
    if (!archRf.includes(rf)) {
      crit("RF-SIN-ARQUITECTURA", "architecture.md", `${rf} está en el PRD pero no aparece en la arquitectura (sin entidad/endpoint que lo soporte).`);
    }
  }
  // ── 4. CRÍTICO — huérfano inverso: RF en arquitectura que no existe en el PRD ─
  for (const rf of archRf) {
    if (!rfIds.includes(rf)) {
      crit("RF-FANTASMA", "architecture.md", `${rf} aparece en la arquitectura pero no existe en el PRD (scope creep o RF sin documentar).`);
    }
  }
}

// ── 5. AVISO — RNF de seguridad ausente si el discovery marcó datos sensibles ─
if (discovery && prd) {
  const sensitive = /(rgpd|gdpr|datos sensibles|datos personales|sensible|fiscal|financier|salud|biom[eé]tric)/i.test(discovery);
  const hasSecRnf = rnfIds.length > 0 && /(seguridad|security|rgpd|gdpr|cifrad|encrypt|autenticaci|authoriz|autorizaci)/i.test(prd);
  if (sensitive && !hasSecRnf) {
    warn("RNF-SEGURIDAD", "prd.md", "el discovery menciona datos sensibles/RGPD pero el PRD no tiene un RNF de seguridad que lo cubra.");
  }
}

// ── 6. AVISO — secciones TODO/vacías en los artefactos existentes ─────────────
for (const [name, txt] of [["discovery.md", discovery], ["prd.md", prd], ["architecture.md", architecture]]) {
  if (txt && /(^|\n)\s*(TODO|TBD|\(definir\)|pendiente de definir)\b/i.test(txt)) {
    warn("TODO-ABIERTO", name, "el artefacto tiene marcadores TODO/TBD/(definir) sin resolver.");
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
// Parte un texto en bloques, uno por cada RF DEFINIDO (no meramente mencionado).
// Un RF se considera definido solo si su ID abre una línea como encabezado o
// ítem de lista (`## RF-01`, `### RF-01 —`, `- RF-01:`, `RF-01.`), no si aparece
// citado a mitad de frase ("…también cubre RF-02…"). Así un RF mencionado dentro
// del bloque de otro no genera un falso bloque sin criterios. El body de cada
// bloque va hasta el siguiente RF definido, para comprobar criterios/prioridad.
function splitByIds(txt, prefix) {
  // Ancla: inicio de línea + posibles marcadores markdown (#, -, *, dígitos) y el ID.
  const re = new RegExp(`^[ \\t]*(?:#{1,6}\\s*|[-*]\\s*|\\d+[.)]\\s*)?(${prefix}-\\d+)\\b`, "gm");
  const marks = [];
  let m;
  while ((m = re.exec(txt)) !== null) marks.push({ id: m[1], index: m.index });
  // Deduplica por id quedándonos con la PRIMERA aparición (el encabezado del RF).
  const seen = new Set();
  const heads = marks.filter((k) => (seen.has(k.id) ? false : seen.add(k.id)));
  return heads.map((h, i) => ({
    id: h.id,
    body: txt.slice(h.index, i + 1 < heads.length ? heads[i + 1].index : txt.length),
  }));
}

// ── Informe ───────────────────────────────────────────────────────────────────
const line = "─".repeat(70);
console.log(`\n${line}\n LINT DE TRAZABILIDAD — gate de fases tempranas (PRD / arquitectura)\n${line}`);
console.log(` CU: ${cuIds.length}  ·  RF: ${rfIds.length}  ·  RNF: ${rnfIds.length}` +
  `   [discovery ${discovery ? "✓" : "—"} · prd ${prd ? "✓" : "—"} · arch ${architecture ? "✓" : "—"}]\n`);

if (critical.length === 0 && warnings.length === 0) {
  console.log(" ✅ Trazabilidad coherente entre los artefactos existentes.\n");
  process.exit(0);
}

if (critical.length) {
  console.log(` ❌ CRÍTICOS (${critical.length}) — bloquean el avance de fase:`);
  for (const c of critical) console.log(`    • [${c.rule}] ${c.where}\n        ${c.msg}`);
  console.log("");
}
if (warnings.length) {
  console.log(` ⚠️  AVISOS (${warnings.length}) — no bloquean, pero conviene cerrarlos:`);
  for (const w of warnings) console.log(`    • [${w.rule}] ${w.where}\n        ${w.msg}`);
  console.log("");
}

console.log(line);
if (critical.length) {
  console.log(" Resultado: ❌ BLOQUEADO. Cierra el hueco de trazabilidad antes de avanzar.\n");
  process.exit(1);
}
console.log(" Resultado: ✅ Sin críticos (hay avisos por revisar).\n");
process.exit(0);
