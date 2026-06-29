# Integración AI App Builder ↔ Reasonix

## Resumen ejecutivo

Reasonix es un agente de IA nativo de DeepSeek (CLI + Desktop) con arquitectura similar a OpenCode:
- `reasonix.toml` — configuración (modelos, providers, plugins)
- `REASONIX.md` — memoria del proyecto (instrucciones persistentes, análogo a CLAUDE.md)
- `AGENTS.md` — estado del proyecto (generado por `/init` o manual)
- `.reasonix/` — metadatos de la interfaz (no versionar)

AI App Builder funciona en Reasonix igual que en Claude Code/OpenCode: **6 fases de construcción de apps con trazabilidad RF-XX**.

---

## Auditoría de los 5 problemas arreglados

### 1. ✅ Paths de template — evitar referencias a .claude/

**Problema original:** scaffolder.md apuntaba a `.claude/template/` (no existe en OpenCode).

**Solución aplicada:** Cambiar a paths agnósticos.

**En Reasonix:**
- Template vive en: `.reasonix/template/` (si se instala local) O `~/.reasonix/template/` (global)
- **ACCIÓN:** scaffolder.md debe decir: "template está en `.reasonix/template/` o `~/.reasonix/template/`. Si no existe, busca `template/` en el repo abierto."

```markdown
## Template
El scaffold base está en:
1. `.reasonix/template/` — instalado localmente (si aplica)
2. `~/.reasonix/template/` — instalación global de Reasonix
3. `template/` — repo abierto directamente en Reasonix

Cópialo a la raíz del proyecto antes de empezar.
```

---

### 2. ✅ Sintaxis agnóstica para agentes — evitar /load (Claude Code)

**Problema original:** OPENCODE.md documentaba `/load arquitecto` (sintaxis de OpenCode tradicional).

**Solución aplicada:** Documentar que la sintaxis depende de la plataforma.

**En Reasonix:**
- NO tiene `/load agente` (eso es OpenCode puro)
- Los agentes se invocan vía **configuración** en `reasonix.toml` + **memory** en `REASONIX.md`
- Los agentes NO se cargan explícitamente — el orquestador los invoca automáticamente

**ACCIÓN:** Crear REASONIX.md que explique:

```markdown
# Instrucciones para Reasonix

Este proyecto usa el **AI App Builder** — 6 fases de construcción con trazabilidad RF-XX.

## Agentes especializados

Reasonix NO tiene "agentes separados" cargables (/load). En su lugar:
- Fase 3 (Arquitectura): El agente-persona es un "Arquitecto" (no cargable)
- Fase 5 (Scaffold): El agente-persona es un "Scaffolder" (no cargable)
- Fase 6 (Auditoría): El agente-persona es un "Auditor" (no cargable)

Cada agente tiene su REASONIX.md de rol (constraints y reglas específicas).
El orquestador en REASONIX.md principal invoca cada uno en su fase.

## Memoria y recall

- `REASONIX.md` — instrucciones para todas las fases (este archivo)
- `REASONIX.md` roles — puede haber sub-archivos como:
  - `.reasonix/fase-3-arquitecto.md` — constraints del arquitecto
  - `.reasonix/fase-5-scaffolder.md` — constraints del scaffolder
  - `.reasonix/fase-6-auditor.md` — constraints del auditor
- `.reasonix/AGENTS.md` — estado del proyecto (generado por `/init`)
- `.builder/memory/` — memoria persistente de decisiones (entre sesiones)

Reasonix carga REASONIX.md como prefijo stable (cache-warm) — los cambios en AGENTS.md o .builder/memory/ son visibles pero no rompen la cache.
```

---

### 3. ✅ Commits iniciales — evitar repos vacíos

**Problema original:** Repo sin commits iniciales después de `git init`.

**Solución aplicada:** Crear `chore: bootstrap` automáticamente.

**En Reasonix:**
- El usuario ejecuta: `reasonix setup` → genera `reasonix.toml`
- Luego: `reasonix /init` → genera `AGENTS.md`
- **ACCIÓN:** El instalador debe hacer `git init && git commit 'chore: bootstrap reasonix'`

```bash
# En el installer de Reasonix
if [ ! -d ".git" ]; then
  git init -q
  git add -A
  git commit -q -m "chore: bootstrap reasonix ai-app-builder" 2>/dev/null || true
fi
```

---

### 4. ✅ stack.md con Auth/Infra sin definir

**Problema original:** stack.md tenía `(definir: ...)` sin instrucciones claras.

**Solución aplicada:** Aclarar en instaladores y REASONIX.md que se rellenan en Fase 0/1.

**En Reasonix:**
- Cuando el usuario ejecuta `reasonix /build-app "quiero crear..."` se inicia Fase 0 (brainstorm)
- El orquestador rellenará stack.md si falta
- **ACCIÓN:** REASONIX.md debe documentar:

```markdown
## stack.md

Archivo de configuración técnica. Puede venir con placeholders:
- `Auth: (definir: ...)` — se rellena en Fase 0/1
- `Infra: (definir: ...)` — se rellena en Fase 0/1
- `Stack: ...` — debe estar predefinido antes de Fase 1

Si quieres rellenarlos ahora, adelante. Si no, el orquestador lo hará.
```

---

### 5. ✅ .gitignore — evitar versionar ephemeral

**Problema original:** .gitignore incompleto o faltante.

**Solución aplicada:** .gitignore robusto que cubra lo básico + ephemeral (template, .builder, .reasonix).

**En Reasonix:**
- `.reasonix/` — metadatos de la interfaz, NO versionar
- `.reasonix/template/` — template local, NO versionar
- `.builder/` — artefactos del proceso, NO versionar
- `.reasonix/AGENTS.md` — generado, puede IR o NO versionar según strategy

**ACCIÓN:** .gitignore debe tener:

```gitignore
# Reasonix
.reasonix/          # Metadatos de interfaz y desktop
.reasonix/template/ # Template local (descargable)

# Builder artifacts
.builder/           # Artefactos del proceso (discovery, PRD, architecture, etc.)

# Template y config (instalados, no versionables)
.claude/template/
.opencode/template/

# Node.js y estándar
node_modules/
.env
.env.local
*.log
dist/
build/
.next/
```

---

## Estructura de REASONIX.md para AI App Builder

```markdown
# AI App Builder — Instrucciones para Reasonix

[Versión agnóstica de CLAUDE.md + OPENCODE.md + documentación de agentes]

## Flujo principal

```bash
reasonix /build-app quiero crear una aplicación para [tu idea]
```

## 6 Fases

1. **Discovery** — descubridor
2. **PRD** — analista
3. **Arquitectura** — arquitecto (constraints: read-only en código)
4. **Mockup** — diseñador
5. **Scaffold** — scaffolder (constraints: full write/edit/bash)
6. **Auditoría** — auditor (constraints: read-only, audit-only)

## Agentes como roles, no como cargas explícitas

En Reasonix, no hay `/load agente`. Cada fase asume un **rol**:
- El sistema conoce que en Fase 3 eres arquitecto (constraints de ese rol aplican)
- En Fase 5 eres scaffolder (tienes todos los tools)
- En Fase 6 eres auditor (read-only + audit-only)

Estos roles se documentan en sub-REASONIX.md o en [conditional instructions] si Reasonix lo soporta.

## Memory y recall

- `REASONIX.md` — instrucciones generales (este archivo, cache-stable)
- `REASONIX.md` roles — constraints por rol (si es posible auto-detectar)
- `.builder/memory/MEMORY.md` — decisiones capturadas entre sesiones
- `.reasonix/AGENTS.md` — estado actual del proyecto

Recall automático: al entrar a una fase, el sistema carga la memoria relevante.

## Gates ejecutables

- `pnpm trace:builder` — verifica trazabilidad (Fase 2, 3)
- `pnpm audit:builder` — verifica wiring y calidad (Fase 5, 6)
- `pnpm audit:wiring` — verifica fetch↔endpoint (Fase 5)

Si Reasonix no tiene acceso a `pnpm`, usar scripts Go equivalentes.

## Stack.md

Configuración técnica. Placeholders rellenados en Fase 0/1:
- Auth: el orquestador elige NextAuth/OAuth/etc. según opciones del usuario
- Infra: el orquestador elige based on stack (Vercel/Docker/etc.)
- Stack: Next.js, Prisma, Tailwind, etc. (puede venir predefinido)
```

---

## Cómo crear Skills en Reasonix

### Opción A: Skills como Markdown (análogo a OpenCode)

Si Reasonix soporta skills como Markdown (similar a OpenCode):

```
.reasonix/skills/
├── app-orchestrator/
│   └── REASONIX.md (o SKILL.md)
├── app-discovery/
│   └── REASONIX.md
├── app-prd/
│   └── REASONIX.md
...
```

Cada skill es un Markdown con:
```markdown
---
name: app-orchestrator
description: Director del proceso de 6 fases
---

## Reglas

[Instrucciones para el agente en esta fase]
```

### Opción B: Skills como instrucciones en REASONIX.md

Si Reasonix es más minimalista, todo va en `REASONIX.md`:

```markdown
# AI App Builder — Fases y constraints

## Fase 1: Discovery
[Instrucciones + constraints de esta fase]

## Fase 2: PRD
[Instrucciones + constraints]

...

## Fase 6: Auditoría
[Instrucciones + constraints]
```

### Opción C: Skills como plugins MCP

Si Reasonix soporta plugins MCP, las skills pueden ser **herramientas MCP**:
```toml
# reasonix.toml
[[plugins]]
name = "app-orchestrator"
command = ["node", "skills/app-orchestrator/index.mjs"]
```

---

## Checklist de integración

- [ ] Crear REASONIX.md con instrucciones de AI App Builder
- [ ] Documentar que template vive en `.reasonix/template/`
- [ ] Documentar que agentes son roles, no cargas explícitas
- [ ] Crear installer que haga `git init && git commit`
- [ ] Actualizar .gitignore para `.reasonix/`, `.builder/`
- [ ] Determinar si Reasonix soporta: Markdown skills, conditional prompts, plugin MCP
- [ ] Crear scripts equivalentes si Reasonix no tiene `pnpm` (trace-lint.mjs, audit.mjs)
- [ ] Auditar que scaffolder.md no refiera `.claude/template/`
- [ ] Auditar que no hay `/load agente` en documentación Reasonix
- [ ] Crear stack.md con instructions claras sobre Auth/Infra

---

## Nota sobre DeepSeek vs Claude

DeepSeek (Reasonix) tiene **prefix cache nativo**, lo que significa:
- La memoria stable (REASONIX.md) se cachea automáticamente
- Cambios en `.builder/memory/` no rompen la cache (go to the turn tail)
- La recall de decisiones es más eficiente en tokens

Esto es **una ventaja para AI App Builder**: la memoria entre sesiones es más barata.

