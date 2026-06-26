# SDD + TDD doble bucle + gate "todo en verde" — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) o superpowers:executing-plans para implementar tarea a tarea. Los pasos usan checkbox (`- [ ]`).

**Goal:** Subir de nivel las fases 3/5/6 del `ai-app-builder` para que el diseño produzca un SDD, la construcción siga TDD doble bucle y el cierre exija toda la suite en verde.

**Architecture:** Edición de 4 `SKILL.md` (`app-architecture`, `app-scaffold`, `app-audit`, `app-orchestrator`). No se crean artefactos ni skills nuevas; el SDD *es* `architecture.md` ampliado. Spec fuente: `docs/specs/2026-06-26-sdd-tdd-green-gate-design.md`.

**Tech Stack:** Markdown (skills de Claude Code). Verificación con `grep`/lectura, no con runner de tests.

## Global Constraints

- No añadir skills ni artefactos nuevos; `skills/INDEX.md` no cambia.
- Mantener la trazabilidad por ID existente (`RF-XX`) y el estilo de los SKILL.md.
- El gate "todo en verde" aplica solo a RF de **prioridad alta**; media/baja puede quedar `.skip` sin bloquear.
- Aceptación a nivel **API/integración** por defecto; e2e (playwright) solo flujo principal.
- "Suite" = unitarios + aceptación (+ e2e del flujo principal), todos ejecutados.
- Commits con Conventional Commits en español + emoji (convención de `config/stack.md`).
- Tras cada tarea: verificar que no quedan referencias rotas con el cross-check de la Tarea 5.

---

### Task 1: SDD — §7 Componentes y §8 Contratos en `app-architecture`

**Files:**
- Modify: `skills/app-architecture/SKILL.md`

**Interfaces:**
- Produces: convención de secciones `§7` (tabla de componentes) y `§8` (contratos pre/post/errores) que la Tarea 2 (scaffold) consume como fuente de los tests unitarios.

- [ ] **Step 1: Añadir las dos piezas a "## Qué produces"**

Localiza el final del bloque `### 4. Threat model ...` (justo antes de `## Salida: architecture.md`) e inserta:

```markdown
### 5. Diseño de componentes/módulos
Descompón cada flujo en componentes con responsabilidad única. Una tabla:
módulo · responsabilidad · qué RF cubre · dependencias. Es el mapa de piezas
que el scaffold construirá.

### 6. Contratos de interfaz interna
Por cada componente con comportamiento real (lógica, validación, cambios de
estado) o que cruza límites de módulo, define su interfaz pública: firma
entrada→salida, precondiciones, postcondiciones y errores esperados. Un CRUD
simple lleva contrato mínimo (no sobrediseñes). **Estos contratos son la fuente
de los tests unitarios** de la Fase 5.
Legacy (CI3): "componente" = controlador/modelo/librería; "contrato" = interfaz
pública PHP de esa clase.
```

- [ ] **Step 2: Ampliar el template "## Salida: architecture.md"**

Dentro del bloque ```markdown del Salida, sustituye la línea de la sección 6:

```markdown
## 6. Trazabilidad
Tabla RF-XX → entidad(es) → endpoint(s). Marca cualquier RF sin cubrir.
```

por:

```markdown
## 6. Trazabilidad
Tabla RF-XX → entidad(es) → endpoint(s) → componente(s) → contrato §8.
Marca cualquier RF sin cubrir.

## 7. Componentes
| Componente | Responsabilidad | Cubre | Depende de |
|-----------|-----------------|-------|------------|
| MovimientoService | Registrar salida/devolución y estado del arma | RF-01, RF-02 | ArmaRepo, SocioRepo |

## 8. Contratos
### Contrato — MovimientoService
- `registrarSalida(socioId, armaId): Movimiento`
  - Pre: socio con licencia vigente; arma DISPONIBLE.
  - Post: Movimiento estado="fuera"; arma → ENTREGADA.
  - Errores: LicenciaCaducada, ArmaNoDisponible.
```

- [ ] **Step 3: Añadir los DoD de la Fase 3**

En `## Definition of Done`, tras la línea `- [ ] Desviaciones del stack documentadas como ADR`, inserta:

```markdown
- [ ] §7: cada RF de prioridad alta tiene componente(s) asignado(s)
- [ ] §8: cada componente con comportamiento real o que cruza módulo tiene contrato (firma, pre/post, errores); los CRUD simples, contrato mínimo
```

- [ ] **Step 4: Verificar que quedó**

Run: `grep -n -E "## 7\. Componentes|## 8\. Contratos|contrato §8" "skills/app-architecture/SKILL.md"`
Expected: al menos 3 líneas (las dos cabeceras de sección + la traza ampliada).

- [ ] **Step 5: Commit**

```bash
git add "skills/app-architecture/SKILL.md"
git commit -m "✨ feat(architecture): SDD con §7 componentes y §8 contratos"
```

---

### Task 2: TDD doble bucle en `app-scaffold`

**Files:**
- Modify: `skills/app-scaffold/SKILL.md`

**Interfaces:**
- Consumes: §7/§8 de `app-architecture` (Tarea 1).
- Produces: tests de aceptación etiquetados `RF-XX` y unitarios por componente que la Auditoría (Tarea 3) audita.

- [ ] **Step 1: Reemplazar la sección "## Ritmo: por flujo, con checkpoint"**

Sustituye esa sección entera por:

```markdown
## Ritmo: TDD doble bucle por slice (formaliza la semilla previa)

Esto formaliza y escala a doble bucle el "test antes del slice" que ya hacías.
No renderices todo de golpe. Por cada slice de RF de **prioridad alta**:

1. **Bucle externo (ATDD):** escribe primero el **test de aceptación** desde el
   Dado/Cuando/Entonces del RF. Nace en rojo: define el "hecho" del slice.
   Nivel por defecto **API/integración** (vitest+supertest o equivalente del
   stack). El **e2e (playwright)** solo para el **flujo principal del PRD**, no
   uno por RF.
2. **Bucle interno (unit TDD):** implementa guiado por los **contratos del SDD
   §8**. Por componente: test unitario desde el contrato (rojo) → código mínimo
   (verde) → refactor. Repite hasta cubrir los componentes del slice.
3. Slice cerrado cuando el test de aceptación pasa a **verde** (y sus unitarios).
4. Etiqueta: aceptación con `RF-XX`; unitarios con el nombre del componente.
5. **Checkpoint:** ejecuta la suite, debe estar **verde**, y haz commit antes
   del siguiente slice. Si algo se queda rojo, aplica `debugging-strategies`.

### Reglas de contrato (§8 ↔ tests)
- **Drift:** si la implementación revela que un contrato §8 era incorrecto,
  actualiza §8 en `architecture.md` (cambio retroactivo + commit) y ajusta el
  test unitario al **contrato corregido** — nunca al revés.
- **Precedencia aceptación > contrato:** si seguir el contrato no hace pasar la
  aceptación, manda el RF: corrige §8 y, con él, el test unitario.
```

- [ ] **Step 2: Actualizar la sección "## Tests"**

Sustituye el párrafo que empieza por `Aplica las skills incluidas` por:

```markdown
Los tests nacen en dos niveles (ver "Ritmo: TDD doble bucle"): **aceptación**
por RF (API/integración; e2e solo flujo principal) y **unitarios** por contrato
§8. Skills de apoyo incluidas: `testing`, `javascript-testing-patterns`,
`e2e-testing-patterns`/`playwright`. El framework según `stack.md`.
```

- [ ] **Step 3: Actualizar el "## Definition of Done"**

Sustituye la línea `- [ ] Cada RF de prioridad alta tiene al menos un test ...` por estas tres:

```markdown
- [ ] Cada RF de prioridad alta tiene un test de aceptación (escrito primero) en verde, etiquetado con su RF-XX
- [ ] Cada componente implementado tiene tests unitarios derivados de su contrato §8
- [ ] La suite completa (unit + aceptación + e2e principal) se ejecuta y pasa en el handoff, con evidencia (comando + salida); cero rojos/skip en prioridad alta
```

- [ ] **Step 4: Verificar**

Run: `grep -n -E "Bucle externo|Bucle interno|Drift|Precedencia aceptación" "skills/app-scaffold/SKILL.md"`
Expected: 4 líneas.

- [ ] **Step 5: Commit**

```bash
git add "skills/app-scaffold/SKILL.md"
git commit -m "✨ feat(scaffold): TDD doble bucle (aceptación + contrato) y reglas de §8"
```

---

### Task 3: Gate verde en `app-audit`

**Files:**
- Modify: `skills/app-audit/SKILL.md`

**Interfaces:**
- Consumes: tests etiquetados de la Tarea 2.

- [ ] **Step 1: Añadir la ejecución de suite como comprobación**

En `## Comprobaciones de trazabilidad`, tras el punto `5. RF → test`, inserta:

```markdown
5b. **Suite en verde (gate de cierre duro):** ejecuta toda la suite (unit +
    aceptación + e2e del flujo principal) y observa la salida. Un solo test en
    rojo en prioridad alta → bloquea el cierre; indica al orquestador a qué fase
    volver. Media/baja en `.skip` no bloquea.
```

- [ ] **Step 2: Ampliar la matriz de la salida**

En el bloque de `## Salida: audit.md`, sustituye la cabecera de la matriz:

```markdown
| RF | Discovery | PRD | Arquitectura | Mockup | Código | Test | Estado |
```

por:

```markdown
| RF | Discovery | PRD | Arquitectura | Mockup | Código | Test acept. (verde/rojo) | Contrato/comp. (sí/no) | Estado |
```

- [ ] **Step 3: Añadir DoD**

En `## Definition of Done`, tras `- [ ] Los hallazgos se basan en evidencia comprobada, no en suposición`, inserta:

```markdown
- [ ] La suite completa se ha ejecutado y está en verde (evidencia: comando + salida); cero rojos en prioridad alta
```

- [ ] **Step 4: Verificar**

Run: `grep -n -E "Suite en verde|Test acept\.|suite completa se ha ejecutado" "skills/app-audit/SKILL.md"`
Expected: 3 líneas.

- [ ] **Step 5: Commit**

```bash
git add "skills/app-audit/SKILL.md"
git commit -m "✨ feat(audit): gate de suite en verde y matriz con test de aceptación/contrato"
```

---

### Task 4: Cierre global en `app-orchestrator`

**Files:**
- Modify: `skills/app-orchestrator/SKILL.md`

- [ ] **Step 1: Añadir el gate verde al DoD global**

En `## Definition of Done del proceso completo`, tras la línea `- [ ] Cada cierre de fase verificado con evidencia ...`, inserta:

```markdown
- [ ] Suite completa en verde, ejecutada con evidencia, antes de cerrar el proceso (cero rojos en RF de prioridad alta)
```

- [ ] **Step 2: Reflejar el gate en la tabla de fases**

En la tabla `## Flujo y gates`, sustituye la celda del gate de la fila `| 5 | app-scaffold ...`:

```markdown
| 5 | app-scaffold | todo lo anterior | código | estructura + entidades + endpoints base generados |
```

por:

```markdown
| 5 | app-scaffold | todo lo anterior | código + tests | slices de prioridad alta en verde (aceptación + unit) y suite verde en el handoff |
```

- [ ] **Step 3: Verificar**

Run: `grep -n -E "Suite completa en verde|suite verde en el handoff" "skills/app-orchestrator/SKILL.md"`
Expected: 2 líneas.

- [ ] **Step 4: Commit**

```bash
git add "skills/app-orchestrator/SKILL.md"
git commit -m "✨ feat(orchestrator): gate de suite en verde como cierre del proceso"
```

---

### Task 5: Verificación final de coherencia

**Files:**
- Read-only: todos los `skills/app-*/SKILL.md`

- [ ] **Step 1: Cero referencias a skills inexistentes**

Run:
```bash
cd skills && for ref in $(grep -rhoE '`[a-z0-9-]+`' app-*/SKILL.md | tr -d '`' | sort -u); do [ -d "$ref" ] || case "$ref" in app-*|stack|.builder|*.md) ;; *) echo "⚠ $ref";; esac; done; echo fin
```
Expected: solo `fin` (sin `⚠`).

- [ ] **Step 2: Las referencias a §8/§7 y "verde" están presentes en las 4 fases**

Run: `grep -rl -E "§8|suite|verde" skills/app-architecture/SKILL.md skills/app-scaffold/SKILL.md skills/app-audit/SKILL.md skills/app-orchestrator/SKILL.md`
Expected: las 4 rutas.

- [ ] **Step 3: Marcar el spec como implementado**

En `docs/specs/2026-06-26-sdd-tdd-green-gate-design.md`, cambia `**Estado:** aprobado (pendiente de implementación)` por `**Estado:** implementado`.

- [ ] **Step 4: Commit**

```bash
git add docs/specs/2026-06-26-sdd-tdd-green-gate-design.md
git commit -m "📝 docs(spec): marcar SDD/TDD/gate verde como implementado"
```

---

## Self-Review

- **Cobertura del spec:** Pieza 1 → Task 1; Pieza 2 (doble bucle + reglas de contrato) → Task 2; Pieza 3 (gate handoff + auditoría + DoD orquestador) → Tasks 3 y 4; Pieza 4 (trazabilidad) → Task 1 (traza §6 ampliada) y Task 3 (matriz). Formato canónico §7/§8 → Task 1 Step 2. Alcance del gate (alta vs media/baja) → Global Constraints + Tasks 2/3.
- **Placeholders:** ninguno; cada paso lleva el contenido literal a insertar y un grep de verificación.
- **Consistencia de nombres:** secciones `§7`/`§8` y término "suite" usados igual en las 4 tareas; etiquetado `RF-XX` (aceptación) y nombre de componente (unit) coherente entre Task 2 y Task 3.
