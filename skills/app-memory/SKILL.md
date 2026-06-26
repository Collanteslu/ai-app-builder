---
name: app-memory
description: Memoria persistente del proyecto en .builder/memory/. Captura y recuerda el conocimiento aprendido durante el build que NO vive en los artefactos formales — decisiones no obvias, bugs y su fix, restricciones descubiertas, rarezas del stack y cambios retroactivos — enlazado a la trazabilidad por ID (RF-XX). Úsala cuando el orquestador inicie sesión (recall), al entrar en cada fase (recall dirigido), y cuando aparezca una decisión, un bug resuelto, una restricción o un gotcha que merezca recordarse (capture). Es la red que evita repetir errores y re-litigar decisiones ya tomadas entre sesiones.
---

# App Memory — Memoria persistente del proyecto

Los artefactos de `.builder/` (discovery, prd, architecture, mockup, audit)
capturan **el qué**: el estado formal del proyecto. Pero durante un build se
aprende mucho que no cabe ahí: *por qué* se eligió una opción y no otra, qué bug
costó una hora y cómo se arregló, qué restricción apareció a mitad de camino, qué
rareza tiene el stack en este proyecto. Eso es **conocimiento volátil**: vive en
la conversación y se pierde al cerrar la sesión.

Esta skill lo persiste en `.builder/memory/` y lo devuelve en el momento justo.
Es la memoria de trabajo del constructor entre sesiones.

## Principio: enlazada a la trazabilidad

Cada memoria puede referenciar los IDs con los que se relaciona (`RF-01`,
`RNF-02`, `ADR-03`, `CU-01`). Eso es lo que la diferencia de un cuaderno de notas
suelto: una decisión sobre `RF-07` se recupera automáticamente cuando una fase
vuelve a tocar `RF-07`. **Lo que no se enlaza, no se recuerda en contexto.**

## Estructura

```
proyecto/.builder/memory/
├── MEMORY.md          ← índice: una línea por memoria. Se lee al iniciar sesión.
└── <slug>.md          ← una memoria = un hecho. Frontmatter + cuerpo.
```

Si `.builder/memory/` no existe, créalo con un `MEMORY.md` vacío (solo la
cabecera de abajo) la primera vez que captures algo.

## Formato de una memoria (`<slug>.md`)

```markdown
  ---
  name: <slug-kebab-case>
  description: <una línea — se usa para decidir relevancia al recordar>
  type: decision | gotcha | constraint | context | retro
  phase: 0 | 1 | 2 | 3 | 4 | 5 | 6
  refs: [RF-01, ADR-02]      # IDs relacionados (lista vacía [] si no aplica)
  status: active | superseded
  created: <YYYY-MM-DD>
  ---

<El hecho, conciso. Para `decision` y `gotcha` añade dos líneas:>

**Por qué:** <la razón / la causa raíz>
**Cómo aplicarlo:** <qué hacer la próxima vez>

<Enlaza memorias relacionadas con [[otro-slug]].>
```

### Tipos

| `type` | Qué captura | Ejemplo |
|--------|-------------|---------|
| `decision` | Una elección no obvia entre alternativas (ADR ligero) | "Usamos borrado lógico, no físico, por RNF-01" |
| `gotcha` | Un bug/trampa y su causa raíz + fix, para no repetirlo | "Prisma `findUnique` devuelve null si el campo no es @unique" |
| `constraint` | Una restricción descubierta a mitad de build, no en `stack.md` | "El cliente exige que ningún registro se borre nunca" |
| `context` | Trasfondo del proyecto no derivable del código | "El club ya tiene un Excel que migrar en v2" |
| `retro` | Resumen del cambio retroactivo (complementa el de `progress.md`) | "Se añadió RF-09 al detectar hueco en arquitectura" |

### Línea de índice (`MEMORY.md`)

```markdown
- [<Título>](<slug>.md) — <gancho de una línea> · `<type>` · <refs>
```

`MEMORY.md` arranca así y solo crece con líneas de una memoria cada una (nunca
contenido de memoria dentro del índice):

```markdown
# Memoria — [Nombre del proyecto]

Índice de la memoria persistente. Una línea por memoria; el detalle está en su
archivo. Se lee al iniciar sesión y al entrar en cada fase.

## Decisiones
## Gotchas
## Restricciones
## Contexto
## Retroactivos
```

## Operación 1 — Recall (leer)

**Cuándo:** al iniciar sesión (lo hace el orquestador) y al entrar en cada fase.

1. Lee `MEMORY.md`. Si no existe, no hay memoria todavía: continúa.
2. Selecciona las memorias **relevantes al momento**:
   - por `phase` (las de la fase en la que entras),
   - por `refs` (las que tocan un RF/RNF/ADR que vas a trabajar ahora),
   - por `type` (al arrancar una sesión, siempre repasa `constraint` y `context`;
     antes de tocar código, repasa los `gotcha`).
3. Abre solo esos archivos (no todos) y **tenlos presentes antes de actuar**. No
   re-litigues una `decision` con `status: active` ni re-introduzcas un `gotcha`
   ya documentado.
4. Ignora las `status: superseded` salvo que busques el histórico.

## Operación 2 — Capture (escribir)

**Cuándo capturar** (gatillos — si dudas, captura, es barato):

- Tomas una **decisión no obvia** entre alternativas (por qué A y no B).
- Resuelves un **bug que costó tiempo** o que es fácil de re-introducir.
- Descubres una **restricción** que no estaba en `stack.md` ni en el discovery.
- Cierras un **cambio retroactivo** (deja también el `retro` aquí).
- Tropiezas con una **rareza del stack** específica de este proyecto.

**Qué NO capturar** (ruido): lo que ya está en un artefacto formal (un RF va al
PRD, no a memoria), lo trivial, lo derivable del código, o detalles que solo
importan en esta sesión.

**Cómo capturar:**

1. **Comprueba duplicados:** ¿hay ya un archivo que cubra esto? Si sí, **actualízalo**
   en vez de crear otro. Si una decisión vieja queda obsoleta, marca la anterior
   `status: superseded` y enlaza la nueva con `[[slug]]`.
2. Crea/edita `<slug>.md` con el frontmatter completo. `slug` en kebab-case,
   corto y único.
3. Rellena `refs` con los IDs que toca. Es lo que la hará recuperable.
4. Añade **una** línea en la sección correspondiente de `MEMORY.md`.
5. Si el proyecto está bajo git (lo está desde la Fase 1), incluye el archivo en
   el commit de la fase, o haz un commit propio: `🧠 memoria: <slug>`.

## Definition of Done (de una captura)

- [ ] El archivo `<slug>.md` existe con frontmatter completo y válido
- [ ] `refs` apunta a los IDs reales con los que se relaciona (o `[]` justificado)
- [ ] `description` resume en una línea (es lo que se lee al recordar)
- [ ] Hay exactamente una línea nueva en `MEMORY.md`, en su sección
- [ ] No duplica una memoria existente (se actualizó la que había, si la había)
- [ ] Las `decision`/`gotcha` incluyen **Por qué** y **Cómo aplicarlo**

## Ejemplo

`.builder/memory/borrado-logico-armas.md`:

```markdown
  ---
  name: borrado-logico-armas
  description: Ningún movimiento ni arma se borra físicamente; solo se anula (borrado lógico).
  type: decision
  phase: 3
  refs: [RNF-01, RF-02]
  status: active
  created: 2026-06-26
  ---

Toda baja es lógica (campo `deletedAt`/`anulado`), nunca un DELETE real.

**Por qué:** RNF-01 exige trazabilidad legal para inspecciones; un registro
borrado es un registro perdido ante una auditoría.
**Cómo aplicarlo:** ningún endpoint expone DELETE duro. La devolución y la
anulación cambian estado, no eliminan filas. El seed y los tests asumen que las
filas persisten. Relacionado con [[auditoria-consultas-rgpd]].
```

Línea en `MEMORY.md`:

```markdown
## Decisiones
- [Borrado lógico de armas](borrado-logico-armas.md) — nunca DELETE duro, solo anular · `decision` · RNF-01, RF-02
```
