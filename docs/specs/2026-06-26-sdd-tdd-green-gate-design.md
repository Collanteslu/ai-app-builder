# Diseño — SDD + TDD doble bucle + gate "todo en verde"

**Fecha:** 2026-06-26
**Estado:** aprobado (pendiente de implementación)
**Ámbito:** mejora del proceso del `ai-app-builder` (skills `app-*`). No añade
artefactos ni skills nuevas; sube de nivel las fases 3, 5 y 6.

## Objetivo

Cerrar el bucle **diseño → test primero → implementación → "todo en verde"**:

1. La fase de diseño produce un **SDD** (documento de diseño de software) lo
   bastante detallado para guiar los tests.
2. La construcción sigue **TDD de verdad** en doble bucle (aceptación + unitario).
3. El proyecto no se cierra hasta que **toda la suite de tests pasa**, ejecutada
   y comprobada con evidencia.

## Decisiones tomadas (brainstorming)

- **SDD = `architecture.md` formalizado** (opción A). No se crea un documento
  nuevo ni se renombra: se amplía la Fase 3. Razón: evitar un cuarto doc de
  diseño con su propia trazabilidad y su propio drift; no romper el cableado
  existente (`Ver: architecture.md §4`, gates de discovery→audit, etc.).
- **TDD en doble bucle** (opción C): test de aceptación del RF por fuera (ATDD)
  + tests unitarios de contratos del SDD por dentro.
- **Gate "todo en verde" en dos puntos** (opción C): handoff del Scaffold (verde
  slice a slice y al entregar) + ejecución final completa en la Auditoría.

## Pieza 1 — El SDD (Fase 3, `app-architecture`)

A las secciones actuales (1 Stack, 2 ADRs, 3 Modelo de datos, 4 Contrato de API,
5 Threat model, 6 Trazabilidad) se añaden:

- **§7 Diseño de componentes/módulos** — tabla por módulo:
  `módulo | responsabilidad única | RF-XX que cubre | dependencias`.
- **§8 Contratos de interfaz interna** — por módulo, su interfaz pública:
  firma entrada→salida, invariantes y errores esperados. Es la **fuente de los
  tests unitarios** del bucle interno.
  - **Scope para no sobrediseñar:** contrato detallado solo para componentes con
    **comportamiento real** (lógica, validación, cambios de estado) o que **cruzan
    límites de módulo**. Un CRUD simple lleva un contrato mínimo. Evita el "big
    design up front" que hincharía la Fase 3.
  - **Mapeo legacy (CI3):** "componente" = controlador / modelo / librería;
    "contrato" = interfaz pública PHP de esa clase.
- **Trazabilidad ampliada**: la tabla §6 pasa a `RF → entidad → endpoint →
  componente(s) → contrato §8`.

**DoD añadido a la Fase 3:**
- [ ] Cada RF de prioridad alta tiene componente(s) asignado(s) en §7.
- [ ] Cada componente con comportamiento real o que cruza módulo tiene contrato
  detallado en §8 (firma, invariantes, errores); los CRUD simples, contrato mínimo.

## Pieza 2 — Doble bucle TDD (Fase 5, `app-scaffold`)

> Esto **formaliza y escala a doble bucle** la semilla de TDD que ya tiene el
> `app-scaffold` ("el test de aceptación se escribe ANTES del slice, estilo TDD").
> No introduce TDD desde cero.

Por cada slice de RF de prioridad alta:

1. **Bucle externo (ATDD):** escribir primero el **test de aceptación** desde el
   Dado/Cuando/Entonces del RF. Nace en rojo. Define el "hecho" del slice.
   - **Nivel por defecto: API/integración** (p. ej. vitest + supertest, o
     equivalente del stack). El **e2e (playwright)** se reserva para el **flujo
     principal del PRD**, no uno por cada RF: un e2e rojo por slice sobre un
     servidor que aún no levanta es poco realista y retrasa el primer verde.
2. **Bucle interno (unit TDD):** implementar guiado por los contratos del SDD §8.
   Por componente: test unitario desde el contrato (rojo) → código mínimo (verde)
   → refactor. Repetir hasta cubrir los componentes del slice.
3. Slice cerrado cuando el test de aceptación pasa a verde (y sus unitarios).
4. Etiquetado: aceptación con `RF-XX`; unitarios con el nombre del componente.
5. **Checkpoint por slice:** suite verde + commit antes del siguiente.

### Reglas de contrato (gobiernan §8 ↔ tests)

- **Drift del contrato:** si la implementación revela que un contrato §8 era
  incorrecto, se **actualiza §8** (cambio retroactivo, con commit) y el test
  unitario se ajusta al **contrato corregido** — nunca al revés. El test unitario
  prueba el diseño, no "lo que salió"; sin esta regla el SDD pierde su sentido.
- **Precedencia aceptación > contrato:** si seguir el contrato al pie de la letra
  no hace pasar el test de aceptación, manda el RF (aceptación): se corrige el
  contrato §8 y, con él, el test unitario.

Apoyo (skills ya incluidas): `testing`, `javascript-testing-patterns`,
`e2e-testing-patterns`/`playwright` (aceptación), `debugging-strategies` (rojo
persistente → causa raíz). Framework según `stack.md` (vitest/playwright por
defecto; PHPUnit en CI3 legacy).

**DoD añadido a la Fase 5:**
- [ ] Cada RF de prioridad alta tiene un test de aceptación (escrito primero) en verde.
- [ ] Cada componente implementado tiene tests unitarios derivados de su contrato.
- [ ] La suite completa se ejecuta y pasa en el handoff (evidencia: comando + salida).

## Pieza 3 — Gate "todo en verde" (Fase 5 handoff + Fase 6 cierre)

> **"Suite" =** tests unitarios + tests de aceptación (+ el e2e del flujo
> principal), **todos ejecutados**. El gate verde no es solo unitarios.

- **Handoff del Scaffold:** no entrega hasta que la suite completa pasa, con
  evidencia. Cero rojos y cero `skip` en RF de prioridad alta.
- **Auditoría (Fase 6):** ejecución final de toda la suite como **gate de cierre
  duro**. Un solo test en rojo → el orquestador devuelve a la fase responsable.
  La matriz de auditoría gana columnas: `test de aceptación (RF) verde/rojo` y
  `test de contrato por componente (sí/no)` — **presencia, no porcentaje de
  cobertura** (evita política de umbrales).
- **DoD global del orquestador:** añade "suite completa en verde, ejecutada con
  evidencia" como condición de cierre del proceso.

## Pieza 4 — Trazabilidad e impacto

Cadena completa resultante:

```
CU → RF → (entidad, endpoint, componente) → contrato §8 → test unitario → verde
                                          → test de aceptación (RF) → verde
```

El nodo **contrato §8** es explícito a propósito: el test unitario nace del
contrato, no del componente directo. Si no se pinta, el SDD queda invisible en la
traza siendo el centro de todo.

- **Sin skills nuevas** ni artefactos nuevos. El repo sigue lean (32 de
  conocimiento intactas). El SDD *es* `architecture.md`.
- **Ficheros a editar:** `skills/app-architecture/SKILL.md`,
  `skills/app-scaffold/SKILL.md`, `skills/app-audit/SKILL.md`,
  `skills/app-orchestrator/SKILL.md`. Nota menor en `README.md` si procede.
  `skills/INDEX.md` no cambia (no hay skills nuevas; el cableado de fases se
  mantiene).

## Fuera de alcance (YAGNI)

- No se crea un documento SDD separado.
- No se añaden librerías de test nuevas ni stacks nuevos.
- No se automatiza CI (el "todo en verde" se ejecuta localmente con evidencia;
  enganchar GitHub Actions queda para otra iteración).

## Criterio de éxito

- Un proyecto construido con el proceso llega a la Auditoría con `architecture.md`
  que incluye §7 y §8, tests de aceptación por RF escritos antes del código, y la
  suite completa en verde verificada por ejecución.

**Coste asumido:** el primer slice tarda más en verse "funcionando" (aceptación
roja + N unitarios antes del primer verde). Es el precio del gate verde y de que
el código nazca del diseño; se apunta para que no sorprenda en la Fase 5.
