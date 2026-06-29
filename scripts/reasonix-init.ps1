<#
.SYNOPSIS
  Instalador profesional de AI App Builder para Reasonix (Windows PowerShell).

.DESCRIPTION
  Pensado para ejecutarse de un tirón desde internet, estando DENTRO de tu
  carpeta de proyecto:

    irm https://raw.githubusercontent.com/.../scripts/reasonix-init.ps1 | iex

  Qué hace:
    1. Pregunta si instala AI App Builder en Reasonix
    2. Descarga constructor desde GitHub (rama v2)
    3. Instala: REASONIX.md, agentes, skills, template
    4. Crea .gitignore robusto, stack.md, reasonix.toml
    5. git init + commit inicial
    6. Instrucciones finales para empezar

  Variables de entorno opcionales: AI_BUILDER_REPO, AI_BUILDER_BRANCH.
#>

$ErrorActionPreference = 'Stop'

$repoUrl = if ($env:AI_BUILDER_REPO)   { $env:AI_BUILDER_REPO }   else { 'https://github.com/Collanteslu/ai-app-builder.git' }
$branch  = if ($env:AI_BUILDER_BRANCH) { $env:AI_BUILDER_BRANCH } else { 'v2' }
$proj    = (Get-Location).Path

# ──────────────────────────────────────────────────────────────────────────
# Verificaciones previas
# ──────────────────────────────────────────────────────────────────────────

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Error "Necesitas git instalado."; exit 1
}

if (-not (Get-Command reasonix -ErrorAction SilentlyContinue)) {
  Write-Host "⚠️  reasonix no detectado en PATH."
  Write-Host "   Instálalo: npm i -g reasonix"
  Write-Host "   O descárgalo desde: https://github.com/esengine/DeepSeek-Reasonix"
  $cont = Read-Host "¿Continuar de todas formas? (s/n)"
  if ($cont -ne "s") { exit 1 }
}

# ──────────────────────────────────────────────────────────────────────────
# Confirmación inicial
# ──────────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗"
Write-Host "║     AI App Builder — Instalador profesional para Reasonix      ║"
Write-Host "╚════════════════════════════════════════════════════════════════╝"
Write-Host ""
Write-Host "Este instalador configura:"
Write-Host "  ✅ REASONIX.md — instrucciones principales"
Write-Host "  ✅ .reasonix/agents/ — arquitecto, scaffolder, auditor"
Write-Host "  ✅ .reasonix/skills/ — 41 skills de conocimiento + orquestación"
Write-Host "  ✅ .reasonix/template/ — Next.js template pinned"
Write-Host "  ✅ reasonix.toml — configuración Reasonix"
Write-Host "  ✅ stack.md — configuración técnica"
Write-Host "  ✅ .gitignore — robusto (ephemeral, node_modules, etc.)"
Write-Host "  ✅ git init + commit inicial"
Write-Host ""
$confirm = Read-Host "¿Continuar con la instalación? (s/n)"
if ($confirm -ne "s") { Write-Host "Abortado."; exit 0 }

# ──────────────────────────────────────────────────────────────────────────
# Descargar constructor
# ──────────────────────────────────────────────────────────────────────────

$tmpDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "reasonix-$(Get-Random)") -Force

Write-Host ""
Write-Host "⤓ Descargando constructor..."
git clone --depth 1 --branch $branch $repoUrl $tmpDir -q

$repoDir = $tmpDir.FullName

# ──────────────────────────────────────────────────────────────────────────
# Instalar: .reasonix/
# ──────────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "📦 Instalando estructura Reasonix..."

New-Item -ItemType Directory -Force -Path "$proj\.reasonix" | Out-Null

# Agentes
Write-Host "  • Instalando agentes..."
if (Test-Path "$proj\.reasonix\agents") { Remove-Item -Recurse -Force "$proj\.reasonix\agents" }
Copy-Item -Recurse -Force -Path (Join-Path $repoDir '.opencode\agents') -Destination "$proj\.reasonix\"
Write-Host "    ✅ arquitecto, scaffolder, auditor"

# Skills
Write-Host "  • Instalando skills (41 total)..."
if (Test-Path "$proj\.reasonix\skills") { Remove-Item -Recurse -Force "$proj\.reasonix\skills" }
New-Item -ItemType Directory -Force -Path "$proj\.reasonix\skills" | Out-Null
Get-ChildItem -Path (Join-Path $repoDir 'skills') -Directory | ForEach-Object {
  Copy-Item -Recurse -Force -Path $_.FullName -Destination "$proj\.reasonix\skills\"
}
$count = (Get-ChildItem -Directory (Join-Path $repoDir 'skills')).Count
Write-Host "    ✅ $count skills instaladas"

# Template
Write-Host "  • Instalando template (Next.js)..."
if (Test-Path "$proj\.reasonix\template") { Remove-Item -Recurse -Force "$proj\.reasonix\template" }
New-Item -ItemType Directory -Force -Path "$proj\.reasonix\template" | Out-Null
Get-ChildItem -Force -Path (Join-Path $repoDir 'template') -Exclude 'node_modules', '.next' |
  Copy-Item -Recurse -Force -Destination "$proj\.reasonix\template"
Write-Host "    ✅ template pinned (Next.js 16.2.9, Prisma 7.8.0, etc.)"

# ──────────────────────────────────────────────────────────────────────────
# Crear REASONIX.md
# ──────────────────────────────────────────────────────────────────────────

if (-not (Test-Path "$proj\REASONIX.md")) {
  Write-Host "  • Generando REASONIX.md..."
  # Leer el contenido desde el template (se reutiliza de install.sh)
  $reasonixContent = @"
# AI App Builder — Instrucciones para Reasonix

Este proyecto usa el **AI App Builder** — un proceso profesional de 6 fases
para construir aplicaciones con trazabilidad de requisitos (RF-XX).

## Flujo principal

``````bash
reasonix /build-app quiero crear una aplicación para [tu idea]
``````

O simplemente:
``````bash
reasonix
# Luego en el chat: /build-app quiero crear...
``````

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

``````bash
pnpm trace:builder      # Verifica trazabilidad RF→CU (Fase 2, 3)
pnpm audit:builder      # Verifica wiring, inline data, calidad (Fase 5, 6)
pnpm audit:wiring       # Verifica fetch→endpoint (Fase 5)
``````

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

## Cómo trabajar profesionalmente

### Fase 1: Discovery
El orquestador conduce Discovery. Produce: `.builder/discovery.md` (CU-XX).

### Fase 2: PRD
El orquestador conduce PRD. Produce: `.builder/prd.md` (RF-XX con criterios).
Gate: `pnpm trace:builder` ← Verifica CU-SIN-RF, RF-SIN-CRITERIO.

### Fase 3: Arquitectura
**Aquí actúas como ARQUITECTO** (constraints: read-only en código).
Produce: `.builder/architecture.md` (modelo de datos, endpoints, SDD).
Gate: `pnpm trace:builder` ← Verifica RF-SIN-ARQUITECTURA, RF-FANTASMA.

### Fase 5: Scaffold
**Aquí actúas como SCAFFOLDER** (constraints: full write/edit/bash/browser).
Tu trabajo: código funcional + tests TDD (triple bucle).

Gates:
- `pnpm audit:builder` ← exit 0
- `pnpm audit:wiring` ← exit 0
- `pnpm test:run` ← todos en verde

### Fase 6: Auditoría
**Aquí actúas como AUDITOR** (constraints: read-only, audit-only).
Tu trabajo: verificar trazabilidad, wiring, seguridad.

Gate:
- `pnpm audit:builder` ← exit 0

---

**¿Listo para empezar?** Ejecuta:

``````bash
reasonix /build-app Quiero crear una aplicación para [tu idea]
``````

¡Buena suerte! 🚀
"@
  Set-Content -Path "$proj\REASONIX.md" -Value $reasonixContent -Encoding UTF8
  Write-Host "    ✅ REASONIX.md creado"
} else {
  Write-Host "    ℹ️  REASONIX.md ya existe"
}

# ──────────────────────────────────────────────────────────────────────────
# Crear reasonix.toml
# ──────────────────────────────────────────────────────────────────────────

if (-not (Test-Path "$proj\reasonix.toml")) {
  Write-Host "  • Generando reasonix.toml..."
  $reasonixToml = @"
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
"@
  Set-Content -Path "$proj\reasonix.toml" -Value $reasonixToml -Encoding UTF8
  Write-Host "    ✅ reasonix.toml creado (rellena DEEPSEEK_API_KEY)"
} else {
  Write-Host "    ℹ️  reasonix.toml ya existe"
}

# ──────────────────────────────────────────────────────────────────────────
# Copiar stack.md y model-profiles.md
# ──────────────────────────────────────────────────────────────────────────

foreach ($f in @('stack.md', 'model-profiles.md')) {
  if (-not (Test-Path "$proj\$f") -and (Test-Path (Join-Path $repoDir "config\$f"))) {
    Copy-Item (Join-Path $repoDir "config\$f") "$proj\$f"
    Write-Host "  • 📄 $f copiado"
  }
}

# ──────────────────────────────────────────────────────────────────────────
# Crear/actualizar .gitignore
# ──────────────────────────────────────────────────────────────────────────

if (-not (Test-Path "$proj\.gitignore")) {
  Write-Host "  • Creando .gitignore..."
  $gitignore = @"
# Reasonix
.reasonix/              # Metadatos de interfaz/desktop
.reasonix/template/     # Template local (descargable, no versionar)
reasonix.log

# Builder artifacts (ephemeral)
.builder/               # Generado durante el proceso

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
"@
  Set-Content -Path "$proj\.gitignore" -Value $gitignore -Encoding UTF8
  Write-Host "    ✅ .gitignore creado"
} else {
  Write-Host "    ℹ️  .gitignore ya existe"
}

# ──────────────────────────────────────────────────────────────────────────
# git init + commit inicial
# ──────────────────────────────────────────────────────────────────────────

if (-not (Test-Path "$proj\.git")) {
  Write-Host "  • Inicializando git..."
  git -C $proj init -q
  git -C $proj add -A
  git -C $proj commit -q -m "chore: bootstrap reasonix ai-app-builder" 2>$null
  Write-Host "    ✅ git init + commit inicial"
} else {
  Write-Host "    ℹ️  .git ya existe"
}

# Limpiar temp
Remove-Item -Recurse -Force $tmpDir

# ──────────────────────────────────────────────────────────────────────────
# Instrucciones finales
# ──────────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "✅ Instalación completada para Reasonix"
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗"
Write-Host "║                    Próximos pasos                              ║"
Write-Host "╚════════════════════════════════════════════════════════════════╝"
Write-Host ""
Write-Host "1️⃣  Configurar Reasonix:"
Write-Host "   • Edita reasonix.toml (rellena DEEPSEEK_API_KEY)"
Write-Host "   • O ejecuta: `$env:DEEPSEEK_API_KEY = 'sk-...'"
Write-Host ""
Write-Host "2️⃣  Configurar tu proyecto:"
Write-Host "   • Edita stack.md (define Tech Stack, Auth, Infra)"
Write-Host "   • Auth y Infra pueden rellenarse después en Fase 0/1"
Write-Host ""
Write-Host "3️⃣  Iniciar el proceso:"
Write-Host "   • Ejecuta: reasonix"
Write-Host "   • En el chat, escribe:"
Write-Host "     /build-app Quiero crear una aplicación para [tu idea]"
Write-Host ""
Write-Host "4️⃣  Flujo de trabajo profesional:"
Write-Host "   • Lee REASONIX.md para entender las 6 fases"
Write-Host "   • Actúa como arquitecto en Fase 3, scaffolder en Fase 5, auditor en Fase 6"
Write-Host "   • Gates: pnpm trace:builder, pnpm audit:builder, pnpm audit:wiring"
Write-Host "   • Documenta decisiones/gotchas en .builder/memory/"
Write-Host ""
Write-Host "📚 Documentación:"
Write-Host "   • REASONIX.md — instrucciones completas"
Write-Host "   • stack.md — configuración técnica"
Write-Host "   • .reasonix/skills/ — 41 skills de conocimiento"
Write-Host "   • .reasonix/agents/ — arquitecto, scaffolder, auditor"
Write-Host ""
Write-Host "💡 Recuerda:"
Write-Host "   • Gates no se saltan (exit 0 antes de cambiar fase)"
Write-Host "   • Memoria es oro (captura decisiones, gotchas, restricciones)"
Write-Host "   • Commit por fase (trazabilidad histórica)"
Write-Host ""
Write-Host "¡Listo para construir profesionalmente! 🚀"
Write-Host ""
