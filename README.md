# AI App Builder — Sistema de skills encadenadas

Conjunto de skills para Claude Code que conducen la creación de una app de
principio a fin, fase por fase, con checklists, gates entre fases y trazabilidad
por ID. Diseñado para que no se te cuele nada.

**Autosuficiente:** el repo incluye TODAS las skills que necesita. Lo clonas y
construyes una app desde cero sin instalar ni depender de nada externo. Son dos
capas:

1. **9 skills de orquestación** (`app-*`): conducen el proceso fase por fase
   (8 de fase + `app-memory`, transversal).
2. **32 skills de conocimiento**, solo las que las fases realmente invocan para el
   stack por defecto (Next.js, NestJS, Prisma/PostgreSQL, auth, testing, seguridad,
   diseño/UI, a11y…). Sin duplicados ni stacks que no usas. Vienen **dentro del
   repo**, no se referencian de fuera. Si cambias de stack (p. ej. Supabase o
   Drizzle), añades esa skill concreta y listo.

## Quick Start — Master Installer (un comando)

Estando **dentro de la carpeta de tu nuevo proyecto** (vacía), ejecuta una línea
que te **pregunta qué plataforma quieres** (Claude Code, OpenCode, Reasonix, o todas)
y luego instala lo necesario:

**macOS / Linux**
```bash
mkdir mi-app && cd mi-app
bash <(curl -fsSL https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/ai-builder-init.sh)
```

**Windows / PowerShell**
```powershell
mkdir mi-app; cd mi-app
irm https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/ai-builder-init.ps1 | iex
```

El instalador **pregunta interactivamente**: ¿Claude Code, OpenCode, Reasonix, o Múltiples?
Según tu respuesta, instala solo lo que necesitas. Luego: edita `stack.md` y abre tu plataforma.

> **Nota:** Requiere `git`. Si quieres instalar **sin preguntas**, ve a
> [Instaladores específicos](#instaladores-elige-tu-plataforma) abajo.

---

## Instaladores — Elige tu plataforma

¿Prefieres **no que te pregunte** y instalar directo? Elige la opción que necesites:

### Claude Code (solo)
**macOS / Linux:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/install.sh) --project
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/bootstrap.ps1 | iex
```

Instala: `.claude/skills/` + `.claude/template/` + `CLAUDE.md` + `stack.md` + `git init`.

### OpenCode (solo)
**macOS / Linux:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/install.sh) --project
# Selecciona opción 2 cuando pregunte
```

Instala: `.opencode/agents/` + `.opencode/skills/` + `OPENCODE.md` + `opencode.json` + `stack.md`.

### Reasonix (DeepSeek-native)
**macOS / Linux:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/reasonix-init.sh)
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/reasonix-init.ps1 | iex
```

Instala: `.reasonix/agents/` + `.reasonix/skills/` + `.reasonix/template/` + `REASONIX.md` +
`reasonix.toml` + `stack.md`. [Lee la guía rápida](REASONIX_QUICK_START.md).

### Múltiples plataformas (todas en uno)
Si quieres trabajar con **Claude Code + OpenCode + Reasonix** simultáneamente:

**macOS / Linux:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/ai-builder-init.sh)
# Selecciona opción 4
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/ai-builder-init.ps1 | iex
# Selecciona opción 4
```

Instala todo con **symlinks inteligentes** para evitar duplicación. Lee:
- [`INSTALLERS.md`](INSTALLERS.md) — documentación completa de instaladores
- [`REASONIX_QUICK_START.md`](REASONIX_QUICK_START.md) — guía rápida para Reasonix
- [`REASONIX_INTEGRATION.md`](REASONIX_INTEGRATION.md) — detalles técnicos de Reasonix

---

## Inicio rápido — crear una app paso a paso

Este repo es el **constructor**, no la app. Lo instalas una vez y luego, en la
carpeta de tu nuevo proyecto, le pides a Claude que construya la app. El
`.builder/`, el `git init` y el código se crean **dentro de tu proyecto**, nunca
en este repo plantilla.

### Las dos carpetas (modelo mental)

Hay **dos carpetas distintas**. El instalador NO crea tu app: solo copia las
herramientas (las skills). La app la creas tú (carpeta vacía) y la **construye
Claude** fase por fase dentro de ella.

```
ai-app-builder/            ← EL CONSTRUCTOR (caja de herramientas). Aquí: git pull.
└── skills/ scripts/ ...       NO es tu app.

mi-app/                    ← TU APP. La creas tú; aquí se construye TODO.
├── .claude/skills/            (1) las skills (Claude Code y opencode las leen)
├── .claude/template/          (1) scaffold base (Next.js); lo usa la Fase 5
├── .opencode/                 (1) agentes, instrucciones y comando (opencode)
├── opencode.json              (1) config de opencode
├── stack.md                   (1) config a rellenar
├── model-profiles.md          (1) perfiles de modelo por fase
│   ── hasta aquí lo deja el instalador ──
├── .builder/                  (2) Claude: discovery, prd, architecture, memory/...
├── src/  prisma/  package.json (2) Claude: copia el template y escribe el código (Fase 5)
└── .git/                      (2) un commit por fase
```

(1) lo monta el instalador (o `new-app`). (2) lo construye Claude cuando abres
Claude Code en `mi-app` y le dices "Quiero crear una aplicación para …".

### Opción A — un solo comando (recomendado)

`new-app` lo hace todo de golpe: crea la carpeta, instala las skills dentro,
copia `stack.md` e inicializa git. Solo te queda rellenar `stack.md` y hablar
con Claude.

```powershell
# Windows / PowerShell
C:\ruta\a\ai-app-builder\scripts\new-app.ps1 C:\proyectos\mi-app
```

```bash
# macOS / Linux
bash /ruta/a/ai-app-builder/scripts/new-app.sh ~/proyectos/mi-app
```

Luego: edita `mi-app/stack.md`, abre Claude Code en esa carpeta y di *"Quiero
crear una aplicación para [tu idea]"*. Salta directo al paso 4 de abajo.

### Opción B — paso a paso (manual)

1. **Crea la carpeta de tu app y colócate dentro.**
   ```powershell
   mkdir C:\proyectos\mi-app; cd C:\proyectos\mi-app
   ```

2. **Instala las skills SOLO en esta app** (modo aislado, se borra fácil luego).
   Ejecuta el instalador *desde dentro* de `mi-app`:
   ```powershell
   C:\ruta\a\ai-app-builder\scripts\install.ps1 -Project    # Windows
   # /ruta/a/ai-app-builder/scripts/install.sh --project    # macOS / Linux
   ```
   Deja todo dentro de `mi-app`: `.claude\skills\`, `stack.md` y
   `model-profiles.md`. No toca otros proyectos ni tu sistema. (Sin `-Project`
   se instala global en `~/.claude/skills`; ver [Instalación](#instalación-en-claude-code).)

3. **Rellena `stack.md`** — único requisito previo. Define stack, **Auth** e
   **Infra** y contesta las restricciones de negocio. Si queda algún `(definir)`,
   el orquestador se para en el *gate de stack*. El default ya es Next.js + Prisma
   + PostgreSQL, así que normalmente basta con confirmar y ajustar Auth/Infra.

4. **Abre Claude Code en la carpeta de tu app y arranca** con:
   > "Quiero crear una aplicación para [tu idea]"
   >
   > (o la frase inequívoca: **"inicia el constructor de apps"**)

5. **Deja que el orquestador conduzca el flujo.** Verás, en orden:

   | Paso | Qué hace | Artefacto |
   |------|----------|-----------|
   | Gate de stack | valida `stack.md`, `git init` si falta, **recall** de memoria | — |
   | Fase 0 *(opc.)* | da forma a una idea difusa hablando | `.builder/brief.md` |
   | Fase 1 Discovery | problema, usuarios, casos de uso `CU-XX` | `.builder/discovery.md` |
   | Fase 2 PRD | requisitos `RF-XX` con criterios de aceptación | `.builder/prd.md` |
   | Fase 3 Arquitectura | datos, API, threat model, contratos §7/§8 | `.builder/architecture.md` |
   | Fase 4 Mockup | sistema de diseño + pantallas navegables | `design-system.md` + `mockup/` |
   | Fase 5 Scaffold | código + tests (TDD doble bucle) | código del proyecto |
   | Fase 6 Auditoría | matriz de trazabilidad, caza huecos | `.builder/audit.md` |

   Cada fase pasa su *gate*, hace **commit**, **captura en memoria** lo aprendido
   (`.builder/memory/`) y emite un *handoff*. En las fases de criterio (Brainstorm,
   PRD, Arquitectura) pide tu confirmación antes de avanzar.

6. **Resultado:** app funcional bajo git (un commit por fase), cada `RF-XX`
   trazado de discovery a test, y la memoria del proyecto en `.builder/memory/`
   lista para la siguiente sesión.

Cuando termines y quieras quitar el andamiaje (skills, `stack.md`) sin tocar tu
código, usa `scripts\uninstall.ps1` — ver [Desinstalar](#desinstalar-borrar-el-andamiaje-al-terminar).

> **En OpenCode / Reasonix** el flujo es el mismo, pero no instalas nada: abre el repo con
> `opencode` o `reasonix` y usa `/build-app quiero crear una aplicación para [tu idea]`.
> Ver [Instalación en OpenCode / Reasonix](#instalación-en-opencode--reasonix).

## v2 — Mejoras

- **Agentes especializados por fase** (`.opencode/agents/`): `arquitecto` (solo lectura),
  `scaffolder` (escritura total), `auditor` (solo lectura). Cada uno con tools restringidas.
- **Instrucciones globales** (`.opencode/instructions/`): convenciones de código y
  git workflow que opencode carga automáticamente como contexto.
- **Permisos y configuración** (`opencode.json`): tools con `ask` para bash/browser,
  skills permitidas por defecto.
- **Tests del template** (`template/__tests__/`): validan que el template tenga todos
  los archivos esenciales, versiones pinned sin `^`, frontmatter de skills correcto.
- **Builder CI** (`.github/workflows/builder-ci.yml`): validate-template, validate-skills
  y validate-config en cada push.

## v2.1 — Memoria, perfiles e instalación

- **Memoria persistente** (`app-memory` → `.builder/memory/`): captura el conocimiento
  que se aprende durante el build —decisiones no obvias, bugs y su fix, restricciones
  descubiertas— **enlazado a la trazabilidad por ID** (`refs: [RF-01]`), y lo recuerda
  al iniciar sesión y al entrar en cada fase. Evita repetir errores y re-discutir lo ya
  decidido entre sesiones. El orquestador hace *recall* al arrancar y *capture* en cada
  fase; `arquitecto`, `scaffolder` y `auditor` pueden escribir en `.builder/memory/`.
- **Perfiles de modelo por fase** (`config/model-profiles.md`): diseñar con el modelo
  más capaz (fases 0–3 y 6), ejecutar el grueso mecánico de la Fase 5 con uno más rápido.
  Recomendación de coste/calidad, no un gate.
- **Scripts de instalación** (`scripts/install.sh`, `scripts/install.ps1`): copian todas
  las skills a Claude Code y dejan `stack.md` + `model-profiles.md` en el cwd, sin copiar
  carpetas a mano.
- **Gate de auditoría ejecutable** (`template/scripts/audit.mjs`, `pnpm audit:builder`):
  la Fase 6 deja de ser declarativa. Un auditor real (Node, cross-platform) comprueba
  datos inline, wiring `fetch→endpoint`, servicios huérfanos, validación Zod y BD de test,
  y **devuelve exit≠0 ante un hueco crítico**. El cierre del proceso y el CI de la app
  generada dependen del código de salida, no de la narración del modelo. Se instala con el
  template, así que la app generada lo ejecuta con `pnpm audit:builder`.

## Las 9 skills de orquestación

| Skill | Fase | Qué hace |
|-------|------|----------|
| `app-orchestrator` | Director | Conduce todo el flujo, comprueba los gates |
| `app-brainstorm` | 0 *(opcional)* | Da forma a una idea difusa hablando → `brief.md` |
| `app-discovery` | 1 | Entrevista guiada → `discovery.md` |
| `app-prd` | 2 | Requisitos con IDs RF-XX → `prd.md` |
| `app-architecture` | 3 | SDD: datos + API + seguridad + componentes/contratos (§7/§8) → `architecture.md` |
| `app-mockup` | 4 | Sistema de diseño + mockups navegables → `design-system.md` + `mockup/` |
| `app-scaffold` | 5 | Primer build funcional con TDD doble bucle derivado de todo → archivos |
| `app-audit` | 6 | Verifica trazabilidad → `audit.md` |
| `app-memory` | Transversal | Memoria persistente entre sesiones → `.builder/memory/` (recall + capture) |

Las 32 de conocimiento son el resto de carpetas dentro de `skills/`. El manifiesto
completo (qué hace cada una, qué fase la usa y de dónde se copió) está en
[`skills/INDEX.md`](skills/INDEX.md).

**Autoridad — proceso vs. referencia.** Las `app-*` son **el proceso**: mandan
cuando construyes una app desde cero (sigue las fases y sus gates). Las 32 de
conocimiento son **referencia invocable en cualquier momento**: para un "testea
esto" o "arregla este bug" sueltos, se usan directamente — no hace falta pasar por
la Fase 0 ni por el flujo completo. Solo construir una app nueva entra por el
orquestador.

**Mantenimiento (evitar drift).** Las 32 son copias de un catálogo externo. Para
ver si han quedado desfasadas o re-sincronizarlas:

```bash
scripts/sync-skills.sh --check    # informa de diferencias con la fuente
scripts/sync-skills.sh --sync     # actualiza las copias desde la fuente
# Fuente por defecto: ~/.agents/skills (cámbiala con SKILLS_SRC=/ruta ...)
```

## Instalación en Claude Code

Hay dos alcances. Elige según si quieres las skills en todas tus apps o **solo
en una**:

| Modo | Destino | Cuándo |
|------|---------|--------|
| **Proyecto** (recomendado, aislado) | `<tu-app>\.claude\skills` | Solo esta app. Se borra eliminando una carpeta. |
| Usuario (global) | `~/.claude/skills` | Lo quieres disponible en todos tus proyectos. |

**Multiplataforma:** en **Windows** usa los `.ps1` (PowerShell va de serie); en
**macOS/Linux** usa los `.sh` invocándolos con `bash` (bash va de serie). No
mezcles: PowerShell no está instalado por defecto en Mac/Linux, y `.sh` en
Windows requiere Git Bash o WSL. En Mac/Linux, si el `.sh` no tiene permiso de
ejecución recién clonado, llámalo con `bash …` (como abajo) o haz
`chmod +x scripts/*.sh`.

**Aislado a una sola app** — ejecútalo *dentro* de la carpeta de tu app:

```powershell
# Windows / PowerShell
cd C:\proyectos\mi-app
C:\ruta\a\ai-app-builder\scripts\install.ps1 -Project
```

```bash
# macOS / Linux
cd ~/proyectos/mi-app
bash /ruta/a/ai-app-builder/scripts/install.sh --project
```

Esto deja **todo dentro de `mi-app`**: `.claude\skills\` (las 41 skills, solo para
esta app), `stack.md` y `model-profiles.md`. No toca tu sistema ni otros proyectos.

**Global** (sin `--project`/`--global`) copia a `~/.claude/skills`. O a mano:

```bash
cp -r skills/* ~/.claude/skills/        # global
cp -r skills/* .claude/skills/          # proyecto (desde dentro de la app)
```

En todos los casos, ajusta `stack.md` a tu stack antes de empezar.

### Desinstalar (borrar el andamiaje al terminar)

Cuando la app esté hecha, quita las skills y la config del constructor **sin
tocar tu código** (`src/`, `prisma/`, ...) ni su git:

```powershell
cd C:\proyectos\mi-app
C:\ruta\a\ai-app-builder\scripts\uninstall.ps1        # quita .claude\skills
C:\ruta\a\ai-app-builder\scripts\uninstall.ps1 -All   # + stack.md y model-profiles.md
# -Builder además borra .builder\ (artefactos + memoria) — irreversible
# -User opera sobre la instalación global (~\.claude\skills)
```

```bash
scripts/uninstall.sh            # quita .claude/skills
scripts/uninstall.sh --all      # + stack.md y model-profiles.md
scripts/uninstall.sh --builder  # + .builder/ (irreversible) · --user para la global
```

O simplemente a mano: `Remove-Item -Recurse -Force .claude\skills` y borra
`stack.md` / `model-profiles.md`. Conserva `.builder\` si quieres la doc y la
trazabilidad; bórralo si no la necesitas.

## Instalación en OpenCode / Reasonix

Tanto OpenCode como Reasonix descubren automáticamente:
- Skills desde `skills/`
- Agentes desde `.opencode/agents/` o `.reasonix/agents/`
- Instrucciones desde `.opencode/instructions/`
- Comandos desde `.opencode/commands/`

### OpenCode

```bash
cd ruta/al/repo
opencode
```

Luego usa el comando incorporado:
> `/build-app quiero crear una aplicación para [tu idea]`

Para usar las skills desde **otro proyecto** sin copiarlas, añade a tu `opencode.json`:
```json
{
  "skills": {
    "paths": ["ruta/al/repo/skills"]
  }
}
```

### Reasonix

```bash
cd ruta/al/repo
reasonix
```

En el chat:
> `/build-app quiero crear una aplicación para [tu idea]`

Reasonix carga **automáticamente** las skills del `.reasonix/skills/` y los agentes
del `.reasonix/agents/`. Para **usar en otro proyecto**, copia `.reasonix/` o configura
en `reasonix.toml` (ver [`REASONIX.md`](REASONIX.md)).

**Tip:** Usa el **master installer** (`ai-builder-init.sh` / `ai-builder-init.ps1`)
para instalar automáticamente todo lo que necesites. Ver [Quick Start](#quick-start--master-installer-un-comando).

## Cómo se usa

### En Claude Code

Simplemente dile:

> "Quiero crear una aplicación para [tu idea]"

(o la frase de arranque inequívoca: **"inicia el constructor de apps"**).

### En OpenCode

Usa el comando incorporado:

> `/build-app quiero crear una aplicación para [tu idea]`

O simplemente dile al agente:

> "Quiero crear una aplicación para [tu idea]"

### En Reasonix

Usa el comando (si está instalado):

> `/build-app quiero crear una aplicación para [tu idea]`

O simplemente escribe tu idea en el chat de Reasonix:

> "Quiero crear una aplicación para [tu idea]"

Lee [`REASONIX_QUICK_START.md`](REASONIX_QUICK_START.md) para instrucciones específicas.

---

**Flujo común (todas las plataformas):**

El orquestador se dispara, aplica el **gate de stack** (que `stack.md` exista y
no tenga campos `(definir)` sin resolver), inicializa git si hace falta, y
arranca. Si la idea aún es difusa ("tengo una idea pero no la tengo clara"),
empieza por la **Fase 0 (Brainstorm)** para darle forma hablando antes de
formalizar; si ya la tienes clara, salta directo a Discovery. A partir de ahí te
va llevando fase por fase con **agentes especializados**: el `arquitecto` diseña
(lectura), el `scaffolder` construye (escritura), el `auditor` verifica (lectura).
Cada fase termina con commit del artefacto y un bloque de handoff.

---

## Documentación por plataforma

Después de instalar, lee los documentos específicos:

| Plataforma | Referencia | Descripción |
|-----------|-----------|-----------|
| **Claude Code** | [`CLAUDE.md`](CLAUDE.md) | Instrucciones completas para Claude Code |
| **OpenCode** | [`OPENCODE.md`](OPENCODE.md) | Instrucciones y workflow en OpenCode |
| **Reasonix** | [`REASONIX_QUICK_START.md`](REASONIX_QUICK_START.md) | Guía rápida de 5 minutos |
| **Reasonix** | [`REASONIX.md`](REASONIX.md) | Instrucciones completas (se instala en tu proyecto) |
| **Reasonix** | [`REASONIX_INTEGRATION.md`](REASONIX_INTEGRATION.md) | Detalles técnicos de la integración |
| **Todos** | [`INSTALLERS.md`](INSTALLERS.md) | Documentación de todos los instaladores |

---

## Por qué funciona (mecanismos y refuerzos)

1. **Checklist (Definition of Done)**: cada skill tiene casillas obligatorias.
   No cierra hasta marcarlas.
2. **Gates entre fases**: cada skill comprueba que el artefacto anterior existe
   y está completo antes de avanzar. Evita el salto silencioso.
3. **Trazabilidad por ID**: cada requisito lleva un `RF-XX`. Arquitectura,
   mockup, código y tests lo referencian. La auditoría final comprueba que toda
   la cadena enlaza. Lo que no se mapea, se ha olvidado.

Y cuatro refuerzos que lo sostienen:

4. **Versionado por fase**: el proyecto va bajo git y cada gate cierra con un
   commit del artefacto. La trazabilidad por ID deja de ser una foto y pasa a
   ser histórica (cuándo y en qué fase cambió cada RF).
5. **Cambios retroactivos declarados**: cuando una fase descubre un hueco en un
   artefacto anterior, lo actualiza y lo declara en el handoff, en vez de
   parchearlo en silencio. El PRD nunca queda por detrás de la realidad.
6. **SDD + TDD doble bucle**: el diseño (Fase 3) llega hasta contratos de
   componente (§7/§8). De ahí nacen los tests, escritos ANTES del código: de
   aceptación por cada RF (bucle externo) y unitarios por contrato (bucle interno).
7. **Gate "todo en verde" + verificación con evidencia**: ninguna fase se cierra
   declarando "funciona" de memoria; se ejecuta la suite y se observa la salida.
   El proceso no termina hasta que toda la suite pasa (cero rojos en prioridad alta).

> El sistema es **autosuficiente**: las skills de orquestación tiran de las skills
> de conocimiento que vienen **incluidas en el repo**. Ejemplos: diseño
> (`design-system-patterns`, `ui-design`) en el mockup; auth/API/datos
> (`auth-implementation-patterns`, `api-design-principles`, `prisma-development`)
> en arquitectura y scaffold; calidad (`testing`, `debugging-strategies`,
> `security-review`, `code-review-excellence`) en scaffold y auditoría. Todo viaja
> contigo: clonas el repo y funciona, sin instalar nada más.

---

## Ejemplo del proceso completo

Idea de partida: *"una app para gestionar el alquiler de armas en un club de tiro,
que registre quién se lleva qué arma y cuándo la devuelve"* (caso real tipo Ridon).

### Fase 0 — Brainstorm *(opcional)*

Si la idea llegara difusa ("quiero algo para el club, no sé bien qué"),
`app-brainstorm` la daría forma hablando: reta supuestos, busca el problema real,
recorta (YAGNI) y produce `brief.md` con la idea en una frase. Como aquí la idea
ya viene clara, se puede saltar directo a Discovery.

### Fase 1 — Discovery

Claude (vía `app-discovery`) pregunta por turnos. Tras la entrevista genera
`discovery.md`:

```markdown
# Discovery — Trazabilidad de alquiler de armas

## Problema
Hoy el control de qué socio se lleva qué arma se hace en papel. Se pierden
registros y no hay forma rápida de saber qué armas están fuera.

## Usuarios / Personas
- **Encargado de armería**: nivel técnico bajo, quiere registrar salidas y
  devoluciones rápido desde un móvil.
- **Administrador del club**: quiere informes y trazabilidad para inspecciones.

## Casos de uso principales
| ID | Caso de uso | Persona | Automatización |
|----|-------------|---------|----------------|
| CU-01 | Registrar salida de un arma a un socio | Encargado | manual (requiere juicio) |
| CU-02 | Registrar devolución | Encargado | manual |
| CU-03 | Ver armas actualmente fuera | Ambos | automatizar (consulta) |
| CU-04 | Generar informe de movimientos para inspección | Admin | automatizar |

## Restricciones
- Datos sensibles (armas + datos personales) → RGPD obligatorio
- Trazabilidad legal: ningún registro se borra, solo se anula

## Métricas de éxito
- Tiempo de registro de una salida < 30 segundos
- 100% de armas fuera localizables en cualquier momento

## Fuera de alcance (v1)
- Reserva anticipada de armas
- App nativa (será web responsive)
```

**Gate**: ✅ problema, personas, 4 casos de uso clasificados, datos sensibles
marcados, métrica medible. Avanza.

### Fase 2 — PRD

`app-prd` lee el discovery y genera `prd.md` con requisitos identificados:

```markdown
### RF-01 — Registrar salida de arma
**Descripción**: el encargado registra qué arma sale, a qué socio y cuándo.
**Persona**: Encargado de armería
**Prioridad**: alta
**Automatización**: manual (humano confirma la entrega física)
**Criterios de aceptación**:
- Dado un socio con licencia válida, cuando el encargado registra una salida,
  entonces queda guardada con arma, socio, fecha/hora y estado "fuera".
- Dado un socio sin licencia válida, cuando se intenta registrar, entonces el
  sistema lo bloquea y avisa.

### RF-03 — Listar armas fuera
**Prioridad**: alta · **Automatización**: automatizar
**Criterios de aceptación**:
- Dado el estado actual, cuando se consulta el listado, entonces se ven todas
  las armas con estado "fuera" y a qué socio.

### RNF-01 — RGPD y trazabilidad
**Descripción**: ningún registro se elimina físicamente (borrado lógico).
Acceso solo a usuarios autenticados con rol. Auditoría de quién consulta.
```

**Gate**: ✅ cada CU tiene RF, todos con ID y criterios, RNF de RGPD presente.
Avanza.

### Fase 3 — Arquitectura (SDD)

`app-architecture` lee PRD + stack.md. Genera `architecture.md` como **SDD**:
modelo de datos, contrato API, threat model y —la clave para el TDD— el diseño
de componentes (§7) con sus contratos (§8). La trazabilidad llega hasta el
contrato:

```markdown
## 6. Trazabilidad
| RF | Entidad(es) | Endpoint(s) | Componente | Contrato §8 |
|----|-------------|-------------|------------|-------------|
| RF-01 | Movimiento, Arma, Socio | POST /api/movimientos/salida | MovimientoService | registrarSalida |
| RF-03 | Movimiento, Arma | GET /api/armas/fuera | ArmaQuery | listarFuera |

## 7. Componentes
| Componente | Responsabilidad | Cubre | Depende de |
|-----------|-----------------|-------|------------|
| MovimientoService | Registrar salida/devolución y estado del arma | RF-01 | ArmaRepo, SocioRepo |
| ArmaQuery | Consultar armas fuera | RF-03 | ArmaRepo |

## 8. Contrato — MovimientoService
- registrarSalida(socioId, armaId): Movimiento
  - Pre: socio con licencia vigente; arma DISPONIBLE.
  - Post: Movimiento estado="fuera"; arma → ENTREGADA.
  - Errores: LicenciaCaducada, ArmaNoDisponible.
```

De ese contrato salen los tests unitarios de la Fase 5 (uno por post-condición
y uno por error).

Y como hay datos sensibles, el threat model es obligatorio:

```markdown
## 5. Threat model
| Activo | Amenaza | Control | Cubre RNF |
|--------|---------|---------|-----------|
| Registros de armas | Borrado/manipulación | Borrado lógico + auditoría | RNF-01 |
| Datos de socios | Acceso no autorizado | Auth + roles | RNF-01 |
```

**Gate**: ✅ cada RF mapeado a entidad, endpoint **y componente/contrato (§7/§8)**,
modelo con tipos, threat model presente. Avanza.

### Fase 4 — Mockup

`app-mockup` primero fija el `design-system.md` (paleta, tipografía con carácter,
iconos reales — nada de genérico de IA) y luego las pantallas DENTRO de un shell
de navegación común por rol (no HTMLs isla), todo en `mockup/`. Cada pantalla
anota el RF que cubre. El encargado clica y valida el flujo antes de programar.

### Fase 5 — Scaffold (TDD doble bucle)

`app-scaffold` construye por slices con TDD doble bucle (stack por defecto
Next.js + NestJS + Prisma). Para RF-01, **primero el test de aceptación** (rojo)
y los unitarios del contrato §8; luego la implementación que los pone en verde
(sin TODOs en prioridad alta):

```typescript
// test de aceptación — RF-01 (registrar salida de arma)
it('RF-01: bloquea la salida si el socio no tiene licencia vigente', async () => {
  const res = await api.post('/api/movimientos/salida', { socioId, armaId });
  expect(res.status).toBe(409);            // LicenciaCaducada
});
```

```typescript
// Implementa: RF-01 (registrar salida de arma)
// UI base: mockup/flujo-01-salida.html · Ver: .builder/architecture.md §8
async registrarSalida(socioId, armaId) {
  if (!socio.licenciaVigente) throw new LicenciaCaducada();   // post/error del contrato §8
  if (arma.estado !== 'DISPONIBLE') throw new ArmaNoDisponible();
  arma.estado = 'ENTREGADA';
  return this.movimientos.crear({ socioId, armaId, estado: 'fuera' });
}
```

Más migraciones de Prisma para las entidades. El slice se cierra cuando su test
de aceptación (y sus unitarios) están en **verde**, y se hace commit antes del
siguiente.

### Fase 6 — Auditoría

`app-audit` recorre todo y genera la matriz:

```markdown
## Matriz de trazabilidad
| RF | Discovery | PRD | Arquitectura | Mockup | Código | Test acept. | Test contrato | Estado |
|----|-----------|-----|--------------|--------|--------|-------------|----------------|--------|
| RF-01 | CU-01 | ✅ | ✅ | ✅ | ✅ | verde | sí | OK |
| RF-03 | CU-03 | ✅ | ✅ | ✅ | ✅ | rojo | no | hueco menor |

## Huecos detectados
### Menores
- RF-03 sin test de aceptación en verde. Recomendación: añadir el test del
  listado de armas fuera y dejarlo verde.
```

Aquí ves el valor: la auditoría ejecuta toda la suite, así que el test rojo de
RF-03 no pasa desapercibido. Como el **gate de cierre exige todo en verde** en
prioridad alta, el orquestador te devuelve a la Fase 5 a cerrarlo antes de dar
el proyecto por terminado.
