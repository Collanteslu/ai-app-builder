---
name: app-audit
description: Fase 6 y final del proceso de crear una app. Audita la coherencia y trazabilidad de todos los artefactos (discovery, PRD, arquitectura, mockup, código) y reporta huecos. Úsala cuando quieras "verificar que no falta nada", "auditar el proyecto", "comprobar trazabilidad", "revisión final antes de cerrar". Genera audit.md.
---

# Fase 6 — Auditoría de coherencia

Objetivo: cazar lo que se haya colado. Esta es la red de seguridad del proceso:
recorre todos los artefactos y verifica que cada cosa enlaza con la siguiente.
Lo que no se mapea, se ha olvidado.

## Agente especializado

Esta fase es conducida por el agente **auditor** (especificado en opencode.json).
El auditor tiene permisos de lectura (no modifica código, solo genera `audit.md`
y captura en memoria). Antes de empezar a auditar:

**Recall de memoria.** Si existe `.builder/memory/MEMORY.md`, ejecuta recall con la
skill `app-memory`. Lee especialmente las memorias de tipo `gotcha`, `constraint` y
`decision` con `refs` a los RF-XX. Los gotchas indican dónde han fallado las pruebas
o han aparecido rareza del stack; la auditoría ha de verificar esos puntos específicos
con atención extra. Las restricciones (business, técnicas) te dicen qué verificar
que se respeta en el código final.

## Qué lees

Todos los artefactos de `.builder/`: `discovery.md`, `prd.md`,
`architecture.md`, `mockup/`, y el código generado (busca los comentarios de
trazabilidad `RF-XX`). Lee también `.builder/memory/MEMORY.md` para entender qué
gotchas han plagado el scaffold, de forma que los audites con especial rigor.

## Comprobaciones de trazabilidad

Recorre las cadenas en ambos sentidos y reporta cualquier rotura:

1. **Caso de uso → RF**: ¿cada CU-XX del discovery tiene al menos un RF en el PRD?
2. **RF → arquitectura**: ¿cada RF aparece en la tabla de trazabilidad de la
   arquitectura, con entidad y endpoint?
3. **RF → mockup**: ¿cada RF de prioridad alta tiene una pantalla que lo representa?
4. **RF → código**: ¿cada RF tiene un archivo con su comentario de trazabilidad?
5. **RF → test**: ¿cada RF de prioridad alta tiene al menos un test?
5b. **Suite en verde (gate de cierre duro):** ejecuta toda la suite (unit +
    aceptación + e2e del flujo principal) y observa la salida. Un solo test en
    rojo en prioridad alta → bloquea el cierre; indica al orquestador a qué fase
    volver. Media/baja en `.skip` no bloquea.
6. **WIRING: fetch → endpoint**: busca todos los `fetch('/api/` en el código de
   las páginas. Para cada uno, comprueba que existe el archivo `route.ts` en la
   ruta correspondiente. Reporta los fetch huérfanos (sin endpoint) como
   **hueco crítico**.
7. **WIRING: endpoint → fetch**: busca todos los `route.ts` en `src/app/api/`.
   Para cada endpoint POST/GET que devuelve datos, comprueba que al menos una
   página lo llama con fetch(). Reporta endpoints huérfanos (sin página que los
   consuma) como **hueco menor**.
8. **ZERO INLINE DATA**: busca páginas que contengan arrays de datos mock
   (patrón `const \w+ = [` seguido de objetos con propiedades de datos).
   Reporta cualquier hallazgo como **hueco crítico** — los datos nunca deben
   ir inline en las páginas.
 9. **SEED IDS**: busca IDs hardcodeados en el frontend (ej: `"seller-1"`, `"user-1"`)
     y verifica que existen con el mismo valor en el seed. Reporta cualquier ID
     que esté en el frontend pero no en el seed como **hueco crítico**.
10. **AUTH REAL**: verifica que existe `src/app/api/auth/[...nextauth]/route.ts`
     y que las páginas NO tienen userId hardcodeados (busca patrones como
     `userId: "..."` estático). Reporta login simulado como **hueco crítico**.
11. **TEST DB AISLADA**: verifica que existe `docker-compose.test.yml` y que los
     tests NO usan `DATABASE_URL` (deben usar `DATABASE_URL_TEST`). Reporta si
     los tests comparten DB de desarrollo como **hueco crítico**.
12. **COBERTURA MÍNIMA**: cuenta los tests por entidad (patrón `src/__tests__/api/*.test.ts`).
     Si alguna entidad tiene menos de 5 tests, reporta **hueco menor**.
13. **CREATE/EDIT SYMMETRY**: busca todas las páginas `*/new/page.tsx` (creación).
     Para cada una, verifica que existe su correspondiente `*/[id]/edit/page.tsx`
     (edición). También verifica que si existe `POST /api/[entidad]/route.ts`
     existe su correspondiente `PUT /api/[entidad]/[id]/route.ts`.
     Reporta cualquier entidad que se pueda crear pero no editar como **hueco crítico**.
     Este check se ejecuta en un bucle: por cada `new/` encontrado, busca su edit.
14. **CRUD COMPLETO**: para cada entidad con página de listado (ej: `*/products/page.tsx`),
     verifica que existe: detalle (`*/products/[id]/page.tsx`), creación (`*/products/new/page.tsx`),
     y edición (`*/products/[id]/edit/page.tsx`). Reporta cualquier falta como **hueco crítico**.
     Este check también es un bucle: itera sobre todas las entidades y verifica las 4 páginas.
15. **Huérfanos inversos**: ¿hay endpoints, entidades o archivos que NO se mapean
     a ningún RF? (señal de scope creep o de un requisito sin documentar)

## Comprobaciones de calidad

- ¿RNF de RGPD/seguridad presentes y reflejados en el threat model y el código,
  si el discovery marcó datos sensibles?
- ¿Métricas de éxito del discovery siguen reflejadas en el PRD?
- ¿Alguna sección quedó como TODO o vacía en algún artefacto?

## Auditoría ejecutable (gate duro)

Las comprobaciones no se declaran "pasadas" de memoria: se **ejecutan**. El
template incluye un auditor real, cross-platform (Node), en
`scripts/audit.mjs`, disponible como script de npm:

```bash
pnpm audit:builder      # = node scripts/audit.mjs
```

**Esta es la regla de oro de la fase:** el cierre depende del **código de salida**,
no de la narración del modelo. Si `audit:builder` devuelve **exit≠0**, hay un
hueco **CRÍTICO** y el orquestador **NO puede cerrar la Fase 6** — vuelve a la
Fase 5 a corregirlo. Pégale la salida real (no la resumas inventando).

### Rúbrica de severidad (fija, no la degrades)

El auditor clasifica con criterio FIJO. No bajes un crítico a menor para "poder
cerrar":

| Severidad | Regla | Qué detecta |
|-----------|-------|-------------|
| **CRÍTICO** (exit 1) | `INLINE-DATA` | arrays de datos mock dentro de una página |
| **CRÍTICO** (exit 1) | `WIRING` | `fetch('/api/X')` sin su carpeta `src/app/api/X/` |
| **CRÍTICO** (exit 1) | `ORPHAN-SERVICE` | servicio que no se usa en ningún endpoint ni componente (capa de lógica muerta) |
| **CRÍTICO** (exit 1) | `NO-ZOD` | endpoint que lee el body sin validarlo con Zod |
| **CRÍTICO** (exit 1) | `CREATE-EDIT` | hay `*/new/page.tsx` (creación) pero falta `*/[id]/edit/page.tsx` (edición) |
| **AVISO** | `CRUD` | entidad creable sin su página de listado o detalle |
| **AVISO** | `E2E-PLACEHOLDER` | sin e2e real del flujo principal |
| **AVISO** | `TEST-DB` | sin BD de test aislada (`docker-compose.test.yml`) |

Los AVISOS no bloquean, pero se reportan en `audit.md` y conviene cerrarlos. Si
tu juicio (leyendo el código) detecta un crítico que el script aún no cubre
—p. ej. login simulado, IDs de seed inconsistentes, una entidad creable que no
se puede editar— **decláralo crítico igualmente** y bloquea: el script es el
suelo, no el techo.

Las comprobaciones manuales de las secciones anteriores (CREATE/EDIT symmetry,
seed IDs, auth real, CRUD completo) complementan al script con tu lectura.

## Skills incluidas (úsalas)

La auditoría de trazabilidad es lo propio de esta fase, pero apóyate en estas
skills incluidas para las comprobaciones de calidad:

- **`security-review`**: escáner real de vulnerabilidades sobre el código (no te
  fíes solo de "¿hay threat model?"; pásalo si el PRD tenía datos sensibles).
- **`code-review-excellence`**: revisión de calidad del código más allá de la
  trazabilidad.
- **`accessibility-a11y`**: si había RNF de accesibilidad, audítalo de verdad.
- **`testing`**: cobertura y solidez de los tests por RF.

## Salida: audit.md

```markdown
# Auditoría — [Nombre del proyecto]

## Resumen
Estado: ✅ sin huecos críticos / ⚠️ con huecos / ❌ bloqueante
[Conteo: X RF totales, Y completamente trazados, Z con hueco]

## Matriz de trazabilidad
| RF | Discovery | PRD | Arquitectura | Mockup | Código | Test acept. (verde/rojo) | Test contrato (sí/no) | Estado |
|----|-----------|-----|--------------|--------|--------|--------------------------|------------------------|--------|
| RF-01 | CU-01 | ✅ | ✅ | ✅ | ✅ | verde | sí | OK |
| RF-02 | CU-02 | ✅ | ✅ | ❌ | ⚠️ | rojo | no | hueco |

## Huecos detectados
### Críticos (bloquean cierre)
- [...]
### Menores
- [...]

## Huérfanos (sin requisito)
- [...]

## Recomendaciones
- [Acciones concretas para cerrar cada hueco]
```

## Definition of Done

- [ ] **`pnpm audit:builder` ejecutado** y con **exit 0** (cero CRÍTICOS); la salida real se pega en `audit.md`. Exit≠0 → vuelve a la Fase 5
- [ ] Matriz de trazabilidad completa, un RF por fila
- [ ] Cada hueco clasificado como crítico o menor con recomendación concreta
- [ ] Huérfanos listados
- [ ] Veredicto claro: se puede cerrar o no
- [ ] Los hallazgos se basan en evidencia comprobada, no en suposición
- [ ] La suite completa se ha ejecutado contra la **test DB** y está en verde (evidencia: comando + salida); cero rojos en prioridad alta
- [ ] `pnpm audit:builder` corre en el CI (`.github/workflows/ci.yml`) — ya viene del template
- [ ] **CREATE/EDIT SYMMETRY**: bucle ejecutado y verificado — toda entidad creable es editable
- [ ] Seed IDs verificados: todos los IDs del frontend existen en el seed
- [ ] NextAuth real verificado: no hay login simulado
- [ ] Test DB aislada: docker-compose.test.yml existe y los tests la usan
- [ ] Cobertura >= 5 tests por entidad

Si hay huecos críticos, indica al orquestador a qué fase volver para cerrarlos.
