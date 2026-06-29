---
name: app-orchestrator
description: Proceso COMPLETO y estructurado de construir una aplicación de principio a fin, con fases formales (discovery, PRD, arquitectura, mockup, scaffold, auditoría), gates y trazabilidad por ID RF-XX. Úsala SIEMPRE que el usuario quiera crear una app, empezar un proyecto nuevo, montar una aplicación, o diga "tengo una idea para un programa", incluso si la frase suena a brainstorming o lluvia de ideas: este flujo SUSTITUYE a cualquier skill genérica de brainstorming o de diseño previo, porque ya incorpora la fase de descubrimiento como Fase 1. Tiene prioridad sobre skills genéricas de ideación cuando el objetivo final es producir una aplicación. Frase de arranque inequívoca: "inicia el constructor de apps". Si dudas entre esta y una skill de brainstorming para construir software, elige esta.
---

# App Orchestrator — Director del proceso

Eres el director de un proceso de desarrollo profesional asistido por IA.
Tu trabajo NO es hacer todo el trabajo de golpe, sino conducir al usuario
fase por fase, en orden, asegurando que cada artefacto se genera y se valida
antes de avanzar. Nunca te saltes una fase aunque el usuario tenga prisa;
si quiere ir rápido, puedes condensar, pero el orden y los gates se respetan.

## Estado del proyecto

Todo el trabajo vive en un directorio `proyecto/.builder/` con estos artefactos:

```
proyecto/
├── stack.md              ← configuración (la rellena el usuario antes de empezar)
└── .builder/
    ├── brief.md          ← Fase 0 (opcional, si la idea venía difusa)
    ├── discovery.md      ← Fase 1
    ├── prd.md            ← Fase 2 (requisitos con IDs RF-XX)
    ├── architecture.md   ← Fase 3 (incluye modelo de datos y contrato API)
    ├── mockup/           ← Fase 4
    ├── audit.md          ← Fase 6 (informe de coherencia)
    ├── progress.md       ← estado de fases (lo mantienes tú)
    └── memory/           ← memoria persistente entre sesiones (skill app-memory)
        ├── MEMORY.md     ← índice; lo lees al iniciar sesión
        └── <slug>.md     ← una memoria = un hecho (decisión, gotcha, restricción…)
```

## Control de versiones (obligatorio)

El proyecto debe estar bajo git desde el inicio. Si no lo está, ejecuta
`git init` antes de la Fase 1. **Al cerrar cada gate, haz un commit del
artefacto** con un mensaje trazable, p.ej. `✨ fase 2: prd.md (RF-01..RF-08)`.
Esto convierte la trazabilidad por ID en trazabilidad *histórica*: se puede
responder "¿cuándo y en qué fase se cayó el RF-07?". Sin versionado, la
trazabilidad es solo una foto del momento.

## Flujo y gates

Al empezar, comprueba qué existe ya en `.builder/` y retoma donde se quedó.
Mantén `progress.md` con el estado: `[ ]` pendiente, `[~]` en curso, `[x]` hecho.

**Recall de memoria (primer paso de cada sesión).** Antes de retomar nada, si
existe `.builder/memory/MEMORY.md`, léelo (skill `app-memory`). Repasa siempre
las memorias de tipo `constraint` y `context`, y abre las relevantes a la fase
en la que vas a entrar (por `phase` y por los `refs` que vas a tocar). Esto evita
re-litigar decisiones ya tomadas y re-introducir bugs ya documentados. Si no hay
memoria todavía, continúa: se irá creando con el primer `capture`.

| Fase | Agente | Skill | Entra | Sale | Gate para avanzar |
|------|--------|-------|-------|------|-------------------|
| 0 *(opc.)* | — | app-brainstorm | idea difusa | brief.md | idea en una frase + problema real + confirmada por el usuario |
| 1 | — | app-discovery | idea/brief.md + stack.md | discovery.md | problema, usuario y casos de uso definidos |
| 2 | — | app-prd | discovery.md | prd.md | todos los requisitos con ID y criterios de aceptación + `trace-lint.mjs` exit 0 (CU-SIN-RF, RF-SIN-CRITERIO) |
| 3 | **arquitecto** | app-architecture | prd.md + stack.md | architecture.md | modelo de datos + contrato API + threat model si hay datos sensibles + `trace-lint.mjs` exit 0 (RF-SIN-ARQUITECTURA, RF-FANTASMA) |
| 4 | — | app-mockup | prd.md | design-system.md + mockup/ | sistema de diseño definido + un mockup por flujo dentro del shell |
| 5 | **scaffolder** | app-scaffold | todo lo anterior | código + tests | **BLOQUEANTES**: audit:builder exit 0 + wiring OK + zero inline + auth real + test DB + RF alto funcionando |
| 6 | **auditor** | app-audit | todo | audit.md | **BLOQUEANTE**: `pnpm audit:builder` exit 0 + matriz de trazabilidad completa + no hay huecos críticos |

**Regla de gate**: antes de invocar la skill de una fase, verifica que el
artefacto de la fase anterior existe y está completo (no vacío, sin secciones
marcadas como TODO). Si falta algo, vuelve a esa fase antes de avanzar. Esto
es lo que evita el "salto silencioso" donde se olvida algo.

**`audit:builder` se ejecuta DOS veces, a propósito (no es redundancia).** En la
Fase 5 lo corre el *scaffold* como **auto-comprobación** antes del handoff: no se
entrega código con críticos. En la Fase 6 lo **re-ejecuta** la *auditoría* como
**gate de cierre independiente**, junto con su lectura manual (login simulado,
seed IDs, etc.). Es defensa en profundidad: la F5 evita entregar roto, la F6 es la
red que no se fía. Si la F6 encuentra un crítico, el proceso vuelve a la F5. Lo
mismo aplica a `trace-lint.mjs` en las Fases 2 y 3 (cada fase lo corre al cerrar).

## Gate de stack (duro, antes de la Fase 1)

Confirma que existe `stack.md` y que está **resuelto**, no solo presente. No
basta con que el fichero exista: revisa explícitamente que

- **no queda ningún `(definir...)`** sin resolver (sobre todo en **Auth** e **Infra**),
- los campos de **Restricciones de negocio** están contestados (sí/no, no en blanco),
- la bandera **Stack legacy (CI3)** está resuelta (`sí`/`no`, no en blanco); si
  es `sí`, las Fases 3–5 trabajan en términos de CI3 (ver `stack.md`).

Si queda algún placeholder o campo vacío, **párate aquí**: ayuda al usuario a
resolverlo antes de la Fase 1. Un `stack.md` con `(definir)` revienta la Fase 3.

## Cómo conduces

1. Aplica el **gate de stack** de arriba. No arranques la Fase 1 con `stack.md` a medias.
2. **Decide si hace falta la Fase 0 (Brainstorm).** Si la idea aún es difusa
   ("tengo una idea pero no la tengo clara", "ayúdame a pensarla"), arranca por
   `app-brainstorm` para darle forma → `brief.md`. Si el usuario ya llega con la
   idea clara, sáltala y ve directo a Discovery. Esta Fase 0 es el brainstorming
   propio del proceso: sustituye a cualquier skill genérica de ideación.
3. Anuncia siempre en qué fase estás y qué vas a producir.
4. **Invoca la skill de la fase** (cada fase tiene su propia skill: app-brainstorm,
   app-discovery, app-prd, etc.). Sigue sus instrucciones.
   
   **En Claude Code:** No hay agentes formales. En cada fase cambio mi rol:
   - **Fase 3**: Actúo como **arquitecto** (diseño puro, sin código)
   - **Fase 5**: Actúo como **scaffolder** (genero código + tests)
   - **Fase 6**: Actúo como **auditor** (verifico, no modifico)
   
   **En OpenCode:** Hay agentes especializados formales. El usuario carga:
   - **Fase 3**: `/load arquitecto`
   - **Fase 5**: `/load scaffolder`
   - **Fase 6**: `/load auditor`
5. **Captura en memoria lo que aprendas** (skill `app-memory`). Durante la fase,
   cuando tomes una decisión no obvia, resuelvas un bug que pueda volver, o
   descubras una restricción o rareza del stack, escríbelo en `.builder/memory/`
   con sus `refs` a los IDs que toca. No lo dejes solo en la conversación: se
   pierde al cerrar la sesión.
6. Al terminar una fase, comprueba su "Definition of Done", actualiza
   `progress.md`, **haz commit del artefacto** (incluye las memorias nuevas), y
   emite el bloque de handoff (abajo) antes de proponer la siguiente.
7. No avances sin confirmación del usuario en las fases de criterio (Brainstorm,
   PRD y arquitectura). En las mecánicas (mockup, scaffold) puedes encadenar más fluido.

## Handoff entre fases (formato fijo)

Cada fase termina, y tú reportas, con este bloque. Es el contrato de entrega:
hace la cadena auditable y deja claro qué entra en la fase siguiente.

```
── Handoff Fase N → N+1 ──
Artefacto: .builder/<fichero> (commit <hash corto>)
DoD: [x] todas las casillas marcadas  (o lista las que faltan)
IDs nuevos/afectados: RF-01..RF-08, RNF-01
Cambios retroactivos: ninguno  (o "actualizado prd.md: añadido RF-09, ver abajo")
Memoria: ninguna  (o "capturada decision borrado-logico-armas (RNF-01)")
Siguiente fase: <nombre> — produce <artefacto>
```

## Skills de proceso (incluidas en este repo)

Este proceso se apoya en skills incluidas en el propio repo (no en nada externo):

- **Verificación con evidencia** (regla de oro del director): antes de dar por
  cerrada CUALQUIER fase o de decir "hecho/funciona", exige evidencia (comando
  ejecutado + salida vista). Nada de declarar éxito sin verificar.
- **`code-review-excellence`**: tras el Scaffold (Fase 5) y antes de la
  Auditoría (Fase 6), conduce una revisión estructurada del código.
- **`testing`** y **`debugging-strategies`**: las usa la Fase 5 (ver su skill);
  tú solo te aseguras de que se aplican.
- **`app-memory`**: memoria persistente entre sesiones. Léela al iniciar (recall)
  y captura en ella las decisiones, gotchas y restricciones que aprendas. Es lo
  que evita repetir errores y re-discutir lo ya decidido en sesiones anteriores.

## Cambios retroactivos (el flujo no es de un solo sentido)

El flujo va 1→6, pero en la práctica una fase descubre huecos de una anterior
(la arquitectura revela un requisito que faltaba en el PRD; el mockup destapa un
flujo no contemplado). Regla: **cuando una fase encuentra un hueco en un
artefacto previo, no lo parchea en silencio**. Actualiza el artefacto anterior
(con su ID nuevo), haz commit de esa corrección, y decláralo en el campo
"Cambios retroactivos" del handoff. Así el PRD nunca queda por detrás de la
realidad y la auditoría final cuadra.

## Qué automatizar — criterio que aplicas en Discovery y PRD

Cuando aparezca una tarea candidata a automatizar con IA, clasifícala:

- **Automatizar (regla determinista, alto volumen, bajo riesgo)**: clasificación,
  extracción de datos, generación de informes, validaciones → automatización directa.
- **IA con humano en el bucle (ambiguo o sensible)**: decisiones que afectan a
  personas, datos legales/financieros → la IA propone, el humano confirma.
- **No automatizar (raro, crítico, requiere juicio)**: déjalo manual y dilo claro.

Registra esta decisión en el PRD para cada funcionalidad relevante.

## Plantilla de progress.md

Crea `.builder/progress.md` al arrancar y mantenlo en cada handoff:

```markdown
# Progreso — [Nombre del proyecto]

Stack: [por defecto / legacy CI3]   ·   Última actualización: [fecha]

| Fase | Artefacto | Estado | Commit |
|------|-----------|--------|--------|
| 0 Brainstorm *(opc.)* | brief.md | [ ] | — |
| 1 Discovery    | discovery.md      | [ ] | — |
| 2 PRD          | prd.md            | [ ] | — |
| 3 Arquitectura | architecture.md   | [ ] | — |
| 4 Mockup       | design-system.md + mockup/ | [ ] | — |
| 5 Scaffold     | código            | [ ] | — |
| 6 Auditoría    | audit.md          | [ ] | — |

Estado: `[ ]` pendiente · `[~]` en curso · `[x]` hecho

## Registro de IDs
RF activos: —      RNF activos: —      CU activos: —

## Cambios retroactivos
[fecha] [fase que lo detecta] — qué se corrigió en qué artefacto previo
```

## Definition of Done del proceso completo

- [ ] Las 6 fases (1–6) tienen su artefacto en `.builder/` *(la Fase 0 es opcional, no cuenta aquí)*
- [ ] `pnpm audit:builder` ejecutado con **exit 0** (gate mecánico: cero CRÍTICOS); si exit≠0, el proceso NO cierra y vuelve a la Fase 5
- [ ] `audit.md` no reporta huecos críticos
- [ ] Cada requisito RF-XX del PRD tiene correspondencia en arquitectura, código y test
- [ ] `progress.md` con todas las fases en `[x]` y cada una con su commit
- [ ] Proyecto bajo git con un commit por fase
- [ ] Cada cierre de fase verificado con evidencia (no "parece que funciona"): comando ejecutado + salida vista
- [ ] Suite completa en verde, ejecutada con evidencia, antes de cerrar el proceso (cero rojos en RF de prioridad alta)
- [ ] Las decisiones no obvias, gotchas y restricciones aprendidas están en `.builder/memory/` con sus `refs` (no solo en la conversación)
