#!/usr/bin/env bash
# reasonix-init.sh — instalador profesional de AI App Builder para Reasonix (macOS / Linux)
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/.../scripts/reasonix-init.sh | bash
#
# Estrategia:
#   1. Pregunta si instala AI App Builder en Reasonix (SÍ/NO)
#   2. Descarga constructor desde repo (GitHub)
#   3. Instala: REASONIX.md, agentes (.reasonix/agents/), skills (.reasonix/skills/)
#   4. Crea .gitignore, stack.md, reasonix.toml template
#   5. git init + commit inicial
#   6. Instrucciones finales
#
set -euo pipefail

REPO="https://github.com/Collanteslu/ai-app-builder.git"
BRANCH="v2"
PROJ="$(pwd)"

# ──────────────────────────────────────────────────────────────────────────
# Verificaciones previas
# ──────────────────────────────────────────────────────────────────────────

if ! command -v git &> /dev/null; then
  echo "❌ git no está instalado. Instálalo primero."
  exit 1
fi

if ! command -v reasonix &> /dev/null; then
  echo "⚠️  reasonix no detectado en PATH."
  echo "   Instálalo: npm i -g reasonix"
  echo "   O descárgalo desde: https://github.com/esengine/DeepSeek-Reasonix"
  read -p "¿Continuar de todas formas? (s/n): " cont
  [ "$cont" != "s" ] && exit 1
fi

# ──────────────────────────────────────────────────────────────────────────
# Confirmación inicial
# ──────────────────────────────────────────────────────────────────────────

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     AI App Builder — Instalador profesional para Reasonix      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Este instalador configura:"
echo "  ✅ REASONIX.md — instrucciones principales"
echo "  ✅ .reasonix/agents/ — arquitecto, scaffolder, auditor"
echo "  ✅ .reasonix/skills/ — 41 skills de conocimiento + orquestación"
echo "  ✅ .reasonix/template/ — Next.js template pinned"
echo "  ✅ reasonix.toml — configuración Reasonix"
echo "  ✅ stack.md — configuración técnica"
echo "  ✅ .gitignore — robusto (ephemeral, node_modules, etc.)"
echo "  ✅ git init + commit inicial"
echo ""
read -p "¿Continuar con la instalación de AI App Builder para Reasonix? (s/n): " confirm
[ "$confirm" != "s" ] && echo "Abortado." && exit 0

# ──────────────────────────────────────────────────────────────────────────
# Descargar constructor
# ──────────────────────────────────────────────────────────────────────────

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo ""
echo "⤓ Descargando constructor..."
git clone --depth 1 --branch "$BRANCH" "$REPO" "$TMPDIR" -q

REPO_DIR="$TMPDIR"

# ──────────────────────────────────────────────────────────────────────────
# Instalar: .reasonix/
# ──────────────────────────────────────────────────────────────────────────

echo ""
echo "📦 Instalando estructura Reasonix..."

mkdir -p "$PROJ/.reasonix"

# Agentes
echo "  • Instalando agentes..."
rm -rf "$PROJ/.reasonix/agents"
cp -R "$REPO_DIR/.opencode/agents" "$PROJ/.reasonix/"
echo "    ✅ arquitecto, scaffolder, auditor"

# Skills
echo "  • Instalando skills (41 total)..."
rm -rf "$PROJ/.reasonix/skills"
mkdir -p "$PROJ/.reasonix/skills"
cp -R "$REPO_DIR/skills"/* "$PROJ/.reasonix/skills/"
count=$(find "$REPO_DIR/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
echo "    ✅ $count skills instaladas"

# Template
echo "  • Instalando template (Next.js)..."
rm -rf "$PROJ/.reasonix/template"
mkdir -p "$PROJ/.reasonix/template"
find "$REPO_DIR/template" -maxdepth 1 -mindepth 1 \
  ! -name "node_modules" ! -name ".next" \
  -exec cp -R {} "$PROJ/.reasonix/template/" \;
echo "    ✅ template pinned (Next.js 16.2.9, Prisma 7.8.0, etc.)"

# ──────────────────────────────────────────────────────────────────────────
# Crear REASONIX.md
# ──────────────────────────────────────────────────────────────────────────

if [ ! -f "$PROJ/REASONIX.md" ]; then
  echo "  • Generando REASONIX.md..."
  cat > "$PROJ/REASONIX.md" << 'REASONIX_EOF'
# AI App Builder — Instrucciones para Reasonix

Este proyecto usa el **AI App Builder** — un proceso profesional de 6 fases
para construir aplicaciones con trazabilidad de requisitos (RF-XX).

## Flujo principal

```bash
reasonix /build-app quiero crear una aplicación para [tu idea]
```

O simplemente:
```bash
reasonix
# Luego en el chat: /build-app quiero crear...
```

## 6 Fases de construcción

1. **Discovery** → Descubridor extrae CU-XX (casos de uso)
2. **PRD** → Analista define RF-XX (requisitos con criterios)
3. **Arquitectura** → Arquitecto diseña SDD (read-only en código)
4. **Mockup** → Diseñador crea mockups navegables
5. **Scaffold** → Scaffolder genera código + tests TDD (full write/edit)
6. **Auditoría** → Auditor verifica trazabilidad (read-only, audit-only)

## Agentes como roles (no carga explícita)

En Reasonix, **NO hay `/load agente`**. En su lugar, cada fase asume un **rol**:

- **Fase 3 (Arquitectura)**: Eres arquitecto
  - Constraints: read-only en código, write-only para architecture.md + memory
  - Objetivo: SDD puro (sin detalles de implementación)
  - Memory: Documenta cada decisión (por qué A y no B)

- **Fase 5 (Scaffold)**: Eres scaffolder
  - Constraints: full write/edit/bash/browser
  - Objetivo: Código funcional + tests TDD (triple bucle)
  - Memory: Documenta gotchas (bugs raros, rareza del stack)

- **Fase 6 (Auditoría)**: Eres auditor
  - Constraints: read-only en código, write-only para audit.md + memory
  - Objetivo: Verificar trazabilidad, wiring, calidad
  - Memory: Documenta huecos encontrados (para próxima iteración)

Reasonix detecta automáticamente en qué fase estás y aplica los constraints correctos.

## Memoria persistente entre sesiones

- **REASONIX.md** — este archivo (instrucciones, cache-stable)
- **.reasonix/AGENTS.md** — estado del proyecto (generado por `/init`)
- **.builder/memory/MEMORY.md** — decisiones capturadas
  - `decision/` — por qué se eligió tal arquitectura
  - `gotcha/` — bugs raros, trucos del stack
  - `constraint/` — restricciones técnicas o de negocio

Cada sesión, haz recall de memoria relevante. Reasonix carga REASONIX.md como prefijo
stable (cache-warm en DeepSeek), así que los cambios en .builder/memory/ son visibles
sin romper la cache.

## Gates ejecutables (verificación automática)

```bash
pnpm trace:builder      # Verifica trazabilidad RF→CU (Fase 2, 3)
pnpm audit:builder      # Verifica wiring, inline data, calidad (Fase 5, 6)
pnpm audit:wiring       # Verifica fetch→endpoint (Fase 5)
```

**Regla de oro:** No avances de fase sin que los gates pasen (exit 0).

- Fase 2 gate: `pnpm trace:builder` ← cierra PRD
- Fase 3 gate: `pnpm trace:builder` ← cierra Arquitectura
- Fase 5 gate: `pnpm audit:builder && pnpm audit:wiring` ← cierra Scaffold
- Fase 6 gate: `pnpm audit:builder` ← cierra Auditoría

## Configuración técnica (stack.md)

Archivo: `stack.md`

Define tu stack (puede rellenarse parcialmente ahora o completamente en Fase 0/1):
- **Tech Stack:** Next.js, Prisma, TypeScript, Tailwind, Vitest, Playwright
- **Auth:** NextAuth, OAuth, JWT (se elige en Fase 0/1)
- **Infra:** Vercel, Docker, Railway (se elige en Fase 0/1)
- **Restricciones:** RGPD, compliance, etc.
- **Modo legacy:** CI3 (CodeIgniter 3) vs moderno (Next.js)

## Herramientas de la Fase 5 (Scaffold)

Para máxima calidad, usa estas herramientas mientras scaffoldeas:

- **`testing`** — testing patterns (TDD triple bucle)
- **`zod-schema-validation`** — validación de inputs/outputs
- **`error-handling-patterns`** — manejo de errores consistente
- **`nextjs-app-router-patterns`** — patrones Next.js 16 App Router
- **`prisma-development`** — Prisma 7 best practices
- **`security-best-practices`** — seguridad (OWASP, RGPD)

Invócalas cuando necesites: "Necesito ayuda con [herramienta]".

## Herramientas de la Fase 6 (Auditoría)

- **`security-review`** — auditoría de seguridad real
- **`code-review-excellence`** — revisión de calidad de código
- **`accessibility-a11y`** — si el PRD pide accesibilidad

## Estructura del proyecto

```
./
├── REASONIX.md                   ← Este archivo (instrucciones, cache-stable)
├── stack.md                      ← Configuración técnica (Auth, Infra, Stack)
├── reasonix.toml                 ← Configuración de Reasonix (modelos, providers)
├── .reasonix/
│   ├── agents/                   ← arquitecto.md, scaffolder.md, auditor.md
│   ├── skills/                   ← 41 skills de conocimiento + orquestación
│   ├── template/                 ← Template pinned (Next.js 16.2.9, etc.)
│   ├── AGENTS.md                 ← Estado del proyecto (generado por /init)
│   └── .gitignore                ← NO versionar metadata de desktop
├── .builder/
│   ├── discovery.md              ← Fase 1 (casos de uso CU-XX)
│   ├── prd.md                    ← Fase 2 (requisitos RF-XX)
│   ├── architecture.md           ← Fase 3 (SDD, modelo de datos, endpoints)
│   ├── mockup/                   ← Fase 4 (mockups navegables HTML)
│   ├── audit.md                  ← Fase 6 (informe de trazabilidad)
│   ├── progress.md               ← Estado de avance ([ ] pendiente, [~] en curso, [x] hecho)
│   └── memory/                   ← Memoria persistente entre sesiones
│       ├── MEMORY.md             ← Índice de memorias
│       └── *.md                  ← decision, gotcha, constraint, context
├── src/                          ← Código generado en Fase 5
│   ├── app/                      ← Next.js App Router
│   └── lib/                      ← Servicios, utilidades
├── prisma/                       ← Modelo de datos (Fase 3 → Fase 5)
│   ├── schema.prisma
│   └── migrations/
└── .git/                         ← Control de versiones (commit por fase)
```

## Cómo trabajar profesionalmente

### Fase 1: Discovery
```bash
reasonix
# En el chat: /build-app Quiero crear un sistema para [tu idea]
```
El orquestador conduce Discovery. Produce: `.builder/discovery.md` (CU-XX).

### Fase 2: PRD
El orquestador conduce PRD. Produce: `.builder/prd.md` (RF-XX con criterios).
Gate: `pnpm trace:builder` ← Verifica CU-SIN-RF, RF-SIN-CRITERIO.

### Fase 3: Arquitectura
**Aquí actúas como ARQUITECTO** (constraints: read-only en código).
Produce: `.builder/architecture.md` (modelo de datos, endpoints, SDD).
Gate: `pnpm trace:builder` ← Verifica RF-SIN-ARQUITECTURA, RF-FANTASMA.

Recuerda: **SDD puro, sin detalles de implementación.** Si descubres un RFC
que falta en el PRD, añádelo como cambio retroactivo (commit + handoff).

### Fase 4: Mockup
El orquestador conduce Mockup. Produce: `design-system.md`, `mockup/` (HTML navegable).

### Fase 5: Scaffold
**Aquí actúas como SCAFFOLDER** (constraints: full write/edit/bash/browser).
Tu trabajo: código funcional + tests TDD (triple bucle: API → Service → UI).

Antes de empezar: haz recall de `.builder/memory/` (gotchas, decisiones, constraints).

Gates:
- `pnpm audit:builder` ← exit 0 (zero inline data, zero wiring huérfano)
- `pnpm audit:wiring` ← exit 0 (cada fetch tiene endpoint)
- `pnpm test:run` ← todos en verde (unit + API)

**Regla de oro:** No entregues código con datos inline o fetch huérfano.

### Fase 6: Auditoría
**Aquí actúas como AUDITOR** (constraints: read-only, audit-only).
Tu trabajo: verificar trazabilidad, wiring, seguridad, accesibilidad.

Antes de empezar: haz recall de `.builder/memory/` (gotchas, constraints).

Gate:
- `pnpm audit:builder` ← exit 0 (cero CRÍTICOS)

Produce: `.builder/audit.md` (matriz de trazabilidad, huecos, recomendaciones).

Si encuentras un hueco crítico, devuelve a Fase 5. Si encuentras avisos,
documenta en el handoff.

## Handoff entre fases

Cada fase termina con un **handoff explícito**:

```
── Handoff Fase N → N+1 ──
Artefacto: .builder/<archivo> (commit <hash>)
DoD: [x] casillas completadas
IDs nuevos/afectados: RF-01..RF-08, RNF-01
Cambios retroactivos: ninguno (o "actualizado prd.md: RF-09 añadido")
Memoria: "capturada decision: por qué elegimos Prisma en lugar de Drizzle"
Siguiente: <fase N+1> — produce <artefacto>
```

## Configuración de Reasonix (reasonix.toml)

El instalador crea un template. Rellena con tus APIs:

```toml
default_model = "deepseek-chat"

[[providers]]
name = "deepseek"
kind = "openai"
base_url = "https://api.deepseek.com"
model = "deepseek-chat"
api_key_env = "DEEPSEEK_API_KEY"
```

Para más opciones, ver: https://github.com/esengine/DeepSeek-Reasonix/docs/GUIDE.md

## Notas finales

- **Commit por fase.** Al cerrar cada fase, haz un commit trazable:
  ```bash
  git commit -m "✨ fase 3: architecture.md (RF-01..RF-08)"
  ```

- **Sin defaults.** Si el orquestador no pregunta algo, pregúntalo tú.
  Mejor tomar decisión temprano que descubrir inconsistencias en Fase 6.

- **Memoria es oro.** Cuando captures una decisión, un gotcha o una restricción,
  documéntalo en `.builder/memory/`. La próxima iteración (o el próximo miembro
  del equipo) te lo agradecerá.

- **Gates no se saltan.** Si un gate falla, hay un problema real. Arréglalo,
  no lo ignores.

---

**¿Listo para empezar?** Ejecuta:

```bash
reasonix /build-app Quiero crear una aplicación para [tu idea]
```

Reasonix te guiará por las 6 fases. ¡Buena suerte! 🚀
REASONIX_EOF
  echo "    ✅ REASONIX.md creado"
else
  echo "    ℹ️  REASONIX.md ya existe"
fi

# ──────────────────────────────────────────────────────────────────────────
# Crear reasonix.toml template
# ──────────────────────────────────────────────────────────────────────────

if [ ! -f "$PROJ/reasonix.toml" ]; then
  echo "  • Generando reasonix.toml..."
  cat > "$PROJ/reasonix.toml" << 'REASONIX_TOML_EOF'
# Reasonix Configuration for AI App Builder

default_model = "deepseek-chat"

[[providers]]
name = "deepseek"
kind = "openai"
base_url = "https://api.deepseek.com"
model = "deepseek-chat"
api_key_env = "DEEPSEEK_API_KEY"

# Descomenta para usar modelos alternativos
# [[providers]]
# name = "grok"
# kind = "openai"
# base_url = "https://api.x.ai/v1"
# model = "grok-vision-beta"
# api_key_env = "GROK_API_KEY"

[permissions]
# read = true           # Permitir lectura de archivos
# write = true          # Permitir escritura de archivos
# bash = true           # Permitir ejecución de bash
# browser = false       # NO permitir navegador
REASONIX_TOML_EOF
  echo "    ✅ reasonix.toml creado (rellena DEEPSEEK_API_KEY)"
else
  echo "    ℹ️  reasonix.toml ya existe"
fi

# ──────────────────────────────────────────────────────────────────────────
# Copiar stack.md y model-profiles.md
# ──────────────────────────────────────────────────────────────────────────

for f in stack.md model-profiles.md; do
  if [ ! -f "$PROJ/$f" ] && [ -f "$REPO_DIR/config/$f" ]; then
    cp "$REPO_DIR/config/$f" "$PROJ/$f"
    echo "  • 📄 $f copiado"
  fi
done

# ──────────────────────────────────────────────────────────────────────────
# Actualizar .gitignore (robusto)
# ──────────────────────────────────────────────────────────────────────────

if [ ! -f "$PROJ/.gitignore" ]; then
  echo "  • Creando .gitignore..."
  cat > "$PROJ/.gitignore" << 'GITIGNORE_EOF'
# Reasonix
.reasonix/              # Metadatos de interfaz/desktop
.reasonix/template/     # Template local (descargable, no versionar)
reasonix.log

# Builder artifacts (ephemeral)
.builder/               # Generado durante el proceso (discovery, PRD, architecture, etc.)

# Template (instalado, no versionar)
.claude/template/
.opencode/template/

# Node.js
node_modules/
npm-debug.log*
yarn-error.log*
.pnpm-debug.log*
pnpm-lock.yaml

# Build
dist/
build/
.next/
out/
.turbo/

# Environment
.env
.env.local
.env.*.local
.env.test

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Cache
.cache/
.eslintcache

# Testing
coverage/
.nyc_output/

# OS
Thumbs.db
.DS_Store

# Temp
.tmp/
temp/
GITIGNORE_EOF
  echo "    ✅ .gitignore creado"
else
  echo "    ℹ️  .gitignore ya existe"
fi

# ──────────────────────────────────────────────────────────────────────────
# git init + commit inicial
# ──────────────────────────────────────────────────────────────────────────

if [ ! -d "$PROJ/.git" ]; then
  echo "  • Inicializando git..."
  cd "$PROJ"
  git init -q
  git add -A
  git commit -q -m "chore: bootstrap reasonix ai-app-builder" 2>/dev/null || true
  echo "    ✅ git init + commit inicial"
else
  echo "    ℹ️  .git ya existe"
fi

# ──────────────────────────────────────────────────────────────────────────
# Instrucciones finales
# ──────────────────────────────────────────────────────────────────────────

echo ""
echo "✅ Instalación completada para Reasonix"
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    Próximos pasos                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "1️⃣  Configurar Reasonix:"
echo "   • Edita reasonix.toml (rellena DEEPSEEK_API_KEY)"
echo "   • O ejecuta: export DEEPSEEK_API_KEY=sk-..."
echo ""
echo "2️⃣  Configurar tu proyecto:"
echo "   • Edita stack.md (define Tech Stack, Auth, Infra)"
echo "   • Auth y Infra pueden rellenarse después en Fase 0/1"
echo ""
echo "3️⃣  Iniciar el proceso:"
echo "   • Ejecuta: reasonix"
echo "   • En el chat, escribe:"
echo "     /build-app Quiero crear una aplicación para [tu idea]"
echo ""
echo "4️⃣  Flujo de trabajo profesional:"
echo "   • Lee REASONIX.md para entender las 6 fases"
echo "   • Actúa como arquitecto en Fase 3, scaffolder en Fase 5, auditor en Fase 6"
echo "   • Gates: pnpm trace:builder, pnpm audit:builder, pnpm audit:wiring"
echo "   • Documenta decisiones/gotchas en .builder/memory/"
echo ""
echo "📚 Documentación:"
echo "   • REASONIX.md — instrucciones completas"
echo "   • stack.md — configuración técnica"
echo "   • .reasonix/skills/ — 41 skills de conocimiento"
echo "   • .reasonix/agents/ — arquitecto, scaffolder, auditor"
echo ""
echo "💡 Recuerda:"
echo "   • Gates no se saltan (exit 0 antes de cambiar fase)"
echo "   • Memoria es oro (captura decisiones, gotchas, restricciones)"
echo "   • Commit por fase (trazabilidad histórica)"
echo ""
echo "¡Listo para construir profesionalmente! 🚀"
echo ""
