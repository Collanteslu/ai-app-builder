<#
.SYNOPSIS
  Instalador inteligente del AI App Builder (Windows PowerShell).

.DESCRIPTION
  Pensado para ejecutarse de un tirón desde internet, estando DENTRO de la
  carpeta de tu nuevo proyecto:

    irm https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/bootstrap.ps1 | iex

  Estrategia:
    1. Pregunta qué plataforma: Claude Code (1), OpenCode (2), Ambas (3)
    2. NO instala nada por defecto
    3. Según la respuesta, copia a .claude/ o .opencode/
    4. Si Ambas: crea symlinks para evitar duplicación

  Variables de entorno opcionales: AI_BUILDER_REPO, AI_BUILDER_BRANCH, AI_BUILDER_HOME.
#>

$ErrorActionPreference = 'Stop'

# ──────────────────────────────────────────────────────────────────────────
# Configuración
# ──────────────────────────────────────────────────────────────────────────

$repoUrl = if ($env:AI_BUILDER_REPO)   { $env:AI_BUILDER_REPO }   else { 'https://github.com/Collanteslu/ai-app-builder.git' }
$branch  = if ($env:AI_BUILDER_BRANCH) { $env:AI_BUILDER_BRANCH } else { 'v2' }
$cache   = if ($env:AI_BUILDER_HOME)   { $env:AI_BUILDER_HOME }   else { "$HOME\.ai-app-builder" }
$proj    = (Get-Location).Path

# ──────────────────────────────────────────────────────────────────────────
# Verificaciones previas
# ──────────────────────────────────────────────────────────────────────────

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Error "Necesitas git instalado."; exit 1
}

# ──────────────────────────────────────────────────────────────────────────
# Descargar/actualizar constructor en caché
# ──────────────────────────────────────────────────────────────────────────

if (Test-Path (Join-Path $cache '.git')) {
  Write-Host "↻ Actualizando el constructor en $cache"
  git -C $cache fetch --depth 1 origin $branch -q
  git -C $cache reset --hard "origin/$branch" -q
} else {
  Write-Host "⤓ Descargando el constructor en $cache"
  git clone --depth 1 --branch $branch $repoUrl $cache -q
}

# ──────────────────────────────────────────────────────────────────────────
# Preguntar plataforma (SIN INSTALAR POR DEFECTO)
# ──────────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗"
Write-Host "║         AI App Builder — Selector de plataforma               ║"
Write-Host "╚════════════════════════════════════════════════════════════════╝"
Write-Host ""
Write-Host "¿Con cuál plataforma usarás el AI App Builder?"
Write-Host ""
Write-Host "  1) Claude Code (CLI / Desktop / Web app)"
Write-Host "  2) OpenCode"
Write-Host "  3) Ambas"
Write-Host ""
$platform_choice = Read-Host "Opción (1-3)"

if ($platform_choice -notin @("1", "2", "3")) {
  Write-Error "Opción inválida. Debe ser 1, 2 o 3."; exit 1
}

# ──────────────────────────────────────────────────────────────────────────
# Helpers para symlinks seguros (Windows)
# ──────────────────────────────────────────────────────────────────────────

function Safe-Symlink {
  param(
    [string]$Target,
    [string]$Link
  )

  # Si el link existe y es symlink, verificar que apunta a lo correcto
  if (Test-Path $Link -PathType Container) {
    $item = Get-Item $Link -Force
    if ($item.LinkType -eq 'SymbolicLink') {
      $current = $item.Target
      if ($current -eq $Target) {
        Write-Host "  ℹ️  symlink ya existe: $Link → $Target"
        return
      } else {
        Write-Host "  ⚠️  symlink existente apunta a otro lado, reemplazando..."
        Remove-Item $Link -Force -ErrorAction SilentlyContinue
      }
    } else {
      # Es un directorio normal, borrarlo
      Write-Host "  🗑️  directorio existente, reemplazando con symlink..."
      Remove-Item $Link -Recurse -Force
    }
  }

  # Crear symlink
  New-Item -ItemType SymbolicLink -Path $Link -Target $Target -Force | Out-Null
  Write-Host "  ✅ symlink creado: $Link → $Target"
}

# ──────────────────────────────────────────────────────────────────────────
# OPCIÓN 1: Claude Code
# ──────────────────────────────────────────────────────────────────────────

function Install-Claude-Code {
  Write-Host ""
  Write-Host "📦 Instalando para Claude Code..."
  Write-Host ""

  # Crear .claude si no existe
  New-Item -ItemType Directory -Force -Path "$proj\.claude" | Out-Null

  # Instalar skills
  Write-Host "  • Instalando skills..."
  if (Test-Path "$proj\.claude\skills") { Remove-Item -Recurse -Force "$proj\.claude\skills" }
  New-Item -ItemType Directory -Force -Path "$proj\.claude\skills" | Out-Null
  Copy-Item -Recurse -Force -Path (Join-Path $cache 'skills\*') -Destination "$proj\.claude\skills"
  $count = (Get-ChildItem -Directory (Join-Path $cache 'skills')).Count
  Write-Host "    ✅ $count skills instaladas"

  # Instalar template
  Write-Host "  • Instalando template..."
  if (Test-Path "$proj\.claude\template") { Remove-Item -Recurse -Force "$proj\.claude\template" }
  New-Item -ItemType Directory -Force -Path "$proj\.claude\template" | Out-Null
  Get-ChildItem -Force -Path (Join-Path $cache 'template') -Exclude 'node_modules', '.next' |
    Copy-Item -Recurse -Force -Destination "$proj\.claude\template"
  Write-Host "    ✅ template instalado"

  # Crear CLAUDE.md (NO sobrescribir si existe)
  if (-not (Test-Path "$proj\CLAUDE.md")) {
    @"
# Instrucciones para Claude Code

Este proyecto usa el **AI App Builder** — un proceso estructurado de 6 fases
para construir aplicaciones con trazabilidad de requisitos (RF-XX).

## Flujo principal

Abre Claude Code en esta carpeta y escribe:

``````
Quiero crear una aplicación para [tu idea]
``````

O la frase inequívoca:

``````
inicia el constructor de apps
``````

## Roles de Claude por fase

Claude Code NO tiene agentes formales. En cada fase, yo juego un rol:

1. **Discovery** → descubridor (extrae CU-XX)
2. **PRD** → analista (define RF-XX con criterios)
3. **Arquitectura** → arquitecto (diseño SDD, NO código)
4. **Mockup** → diseñador (mockups navegables)
5. **Scaffold** → scaffolder (código + tests TDD)
6. **Auditoría** → auditor (verifico, NO modifico)

## Gates ejecutables

- ``pnpm trace:builder`` — verifica trazabilidad (F2, F3)
- ``pnpm audit:builder`` — verifica wiring y calidad (F5, F6)
- ``pnpm audit:wiring`` — verifica fetch → endpoint (F5)

Todos deben pasar (exit 0) antes de avanzar.

## Configuración

Edita ``stack.md`` antes de empezar (define tech stack, Auth, Infra).

---

Para más detalles: ``.claude/skills/app-orchestrator/SKILL.md``
"@ | Set-Content -Path "$proj\CLAUDE.md" -Encoding UTF8
    Write-Host "    ✅ CLAUDE.md creado"
  } else {
    Write-Host "    ℹ️  CLAUDE.md ya existe, no se sobrescribió"
  }

  # Copiar stack.md y model-profiles.md
  foreach ($f in @('stack.md', 'model-profiles.md')) {
    if (-not (Test-Path "$proj\$f") -and (Test-Path (Join-Path $cache "config\$f"))) {
      Copy-Item (Join-Path $cache "config\$f") "$proj\$f"
      Write-Host "    📄 $f copiado"
    }
  }

  # git init si no existe
  if (-not (Test-Path "$proj\.git")) {
    git -C $proj init -q
    Write-Host "    🔧 git init"
  }

  Write-Host ""
  Write-Host "✅ Instalación completada para Claude Code"
  Write-Host ""
  Write-Host "Próximos pasos:"
  Write-Host "  1. Edita stack.md (define tu tech stack, Auth, Infra)"
  Write-Host "  2. Abre Claude Code en esta carpeta"
  Write-Host "  3. Escribe: 'Quiero crear una aplicación para [tu idea]'"
}

# ──────────────────────────────────────────────────────────────────────────
# OPCIÓN 2: OpenCode
# ──────────────────────────────────────────────────────────────────────────

function Install-OpenCode {
  Write-Host ""
  Write-Host "📦 Instalando para OpenCode..."
  Write-Host ""

  # Crear .opencode si no existe
  New-Item -ItemType Directory -Force -Path "$proj\.opencode" | Out-Null

  # Instalar agentes
  Write-Host "  • Instalando agentes..."
  if (Test-Path "$proj\.opencode\agents") { Remove-Item -Recurse -Force "$proj\.opencode\agents" }
  Copy-Item -Recurse -Force -Path (Join-Path $cache '.opencode\agents') -Destination "$proj\.opencode\"
  Write-Host "    ✅ agentes instalados"

  # Instalar instrucciones
  Write-Host "  • Instalando instrucciones..."
  if (Test-Path "$proj\.opencode\instructions") { Remove-Item -Recurse -Force "$proj\.opencode\instructions" }
  Copy-Item -Recurse -Force -Path (Join-Path $cache '.opencode\instructions') -Destination "$proj\.opencode\"
  Write-Host "    ✅ instrucciones instaladas"

  # Instalar comandos
  Write-Host "  • Instalando comandos..."
  if (Test-Path "$proj\.opencode\commands") { Remove-Item -Recurse -Force "$proj\.opencode\commands" }
  Copy-Item -Recurse -Force -Path (Join-Path $cache '.opencode\commands') -Destination "$proj\.opencode\"
  Write-Host "    ✅ comandos instalados"

  # Instalar skills
  Write-Host "  • Instalando skills..."
  if (Test-Path "$proj\.opencode\skills") { Remove-Item -Recurse -Force "$proj\.opencode\skills" }
  New-Item -ItemType Directory -Force -Path "$proj\.opencode\skills" | Out-Null
  Copy-Item -Recurse -Force -Path (Join-Path $cache 'skills\*') -Destination "$proj\.opencode\skills"
  $count = (Get-ChildItem -Directory (Join-Path $cache 'skills')).Count
  Write-Host "    ✅ $count skills instaladas"

  # Instalar template
  Write-Host "  • Instalando template..."
  if (Test-Path "$proj\.opencode\template") { Remove-Item -Recurse -Force "$proj\.opencode\template" }
  New-Item -ItemType Directory -Force -Path "$proj\.opencode\template" | Out-Null
  Get-ChildItem -Force -Path (Join-Path $cache 'template') -Exclude 'node_modules', '.next' |
    Copy-Item -Recurse -Force -Destination "$proj\.opencode\template"
  Write-Host "    ✅ template instalado"

  # Copiar opencode.json (NO sobrescribir si existe)
  if (-not (Test-Path "$proj\opencode.json")) {
    Copy-Item (Join-Path $cache 'opencode.json') "$proj\opencode.json"
    Write-Host "    ✅ opencode.json copiado"
  } else {
    Write-Host "    ℹ️  opencode.json ya existe, no se sobrescribió"
  }

  # Crear OPENCODE.md
  if (-not (Test-Path "$proj\OPENCODE.md")) {
    @"
# Instrucciones para OpenCode

Este proyecto usa el **AI App Builder** en OpenCode.

## Agentes especializados

OpenCode tiene 3 agentes formales con permisos limitados:

1. **arquitecto** (Fase 3): diseña SDD, read-only en código
   ``````
   /load arquitecto
   ``````

2. **scaffolder** (Fase 5): genera código, write/edit/bash/browser
   ``````
   /load scaffolder
   ``````

3. **auditor** (Fase 6): verifica trazabilidad, read-only
   ``````
   /load auditor
   ``````

## Flujo principal

``````
/build-app quiero crear una aplicación para [tu idea]
``````

## Gates ejecutables

- ``pnpm trace:builder`` — verifica trazabilidad (F2, F3)
- ``pnpm audit:builder`` — verifica wiring y calidad (F5, F6)
- ``pnpm audit:wiring`` — verifica fetch → endpoint (F5)

## Configuración

Edita ``stack.md`` antes de empezar (define tech stack, Auth, Infra).

---

Para más detalles: ``.opencode/skills/app-orchestrator/SKILL.md``
"@ | Set-Content -Path "$proj\OPENCODE.md" -Encoding UTF8
    Write-Host "    ✅ OPENCODE.md creado"
  } else {
    Write-Host "    ℹ️  OPENCODE.md ya existe, no se sobrescribió"
  }

  # Copiar stack.md y model-profiles.md
  foreach ($f in @('stack.md', 'model-profiles.md')) {
    if (-not (Test-Path "$proj\$f") -and (Test-Path (Join-Path $cache "config\$f"))) {
      Copy-Item (Join-Path $cache "config\$f") "$proj\$f"
      Write-Host "    📄 $f copiado"
    }
  }

  # git init si no existe
  if (-not (Test-Path "$proj\.git")) {
    git -C $proj init -q
    Write-Host "    🔧 git init"
  }

  Write-Host ""
  Write-Host "✅ Instalación completada para OpenCode"
  Write-Host ""
  Write-Host "Próximos pasos:"
  Write-Host "  1. Edita stack.md (define tu tech stack, Auth, Infra)"
  Write-Host "  2. Abre OpenCode en esta carpeta"
  Write-Host "  3. Escribe: '/build-app quiero crear una aplicación para [tu idea]'"
}

# ──────────────────────────────────────────────────────────────────────────
# OPCIÓN 3: Ambas (Claude Code + OpenCode con symlinks)
# ──────────────────────────────────────────────────────────────────────────

function Install-Both {
  Write-Host ""
  Write-Host "📦 Instalando para Claude Code + OpenCode (con symlinks)..."
  Write-Host ""

  # Instalar en .claude/ (principal)
  Write-Host "  • Instalando en .claude\ (principal)..."
  New-Item -ItemType Directory -Force -Path "$proj\.claude" | Out-Null

  # Instalar skills
  if (Test-Path "$proj\.claude\skills") { Remove-Item -Recurse -Force "$proj\.claude\skills" }
  New-Item -ItemType Directory -Force -Path "$proj\.claude\skills" | Out-Null
  Copy-Item -Recurse -Force -Path (Join-Path $cache 'skills\*') -Destination "$proj\.claude\skills"
  $count = (Get-ChildItem -Directory (Join-Path $cache 'skills')).Count
  Write-Host "    ✅ $count skills en .claude\skills"

  # Instalar template
  if (Test-Path "$proj\.claude\template") { Remove-Item -Recurse -Force "$proj\.claude\template" }
  New-Item -ItemType Directory -Force -Path "$proj\.claude\template" | Out-Null
  Get-ChildItem -Force -Path (Join-Path $cache 'template') -Exclude 'node_modules', '.next' |
    Copy-Item -Recurse -Force -Destination "$proj\.claude\template"
  Write-Host "    ✅ template en .claude\template"

  # Instalar en .opencode/
  Write-Host "  • Instalando en .opencode\ (agentes + instrucciones)..."
  New-Item -ItemType Directory -Force -Path "$proj\.opencode" | Out-Null

  # Instalar agentes
  if (Test-Path "$proj\.opencode\agents") { Remove-Item -Recurse -Force "$proj\.opencode\agents" }
  Copy-Item -Recurse -Force -Path (Join-Path $cache '.opencode\agents') -Destination "$proj\.opencode\"
  Write-Host "    ✅ agentes instalados"

  # Instalar instrucciones
  if (Test-Path "$proj\.opencode\instructions") { Remove-Item -Recurse -Force "$proj\.opencode\instructions" }
  Copy-Item -Recurse -Force -Path (Join-Path $cache '.opencode\instructions') -Destination "$proj\.opencode\"
  Write-Host "    ✅ instrucciones instaladas"

  # Instalar comandos
  if (Test-Path "$proj\.opencode\commands") { Remove-Item -Recurse -Force "$proj\.opencode\commands" }
  Copy-Item -Recurse -Force -Path (Join-Path $cache '.opencode\commands') -Destination "$proj\.opencode\"
  Write-Host "    ✅ comandos instalados"

  # Crear symlinks desde .opencode/ hacia .claude/
  Write-Host "  • Creando symlinks (sin duplicación de skills/template)..."
  Safe-Symlink "..\.claude\skills" "$proj\.opencode\skills"
  Safe-Symlink "..\.claude\template" "$proj\.opencode\template"

  # Copiar opencode.json
  if (-not (Test-Path "$proj\opencode.json")) {
    Copy-Item (Join-Path $cache 'opencode.json') "$proj\opencode.json"
    Write-Host "    ✅ opencode.json copiado"
  } else {
    Write-Host "    ℹ️  opencode.json ya existe, no se sobrescribió"
  }

  # Crear CLAUDE.md
  if (-not (Test-Path "$proj\CLAUDE.md")) {
    @"
# Instrucciones para Claude Code

Este proyecto soporta AMBAS plataformas: Claude Code y OpenCode.

## Para Claude Code

Abre Claude Code en esta carpeta y escribe:

``````
Quiero crear una aplicación para [tu idea]
``````

Los skills están en ``.claude\skills\``.

## Roles de Claude

En cada fase, yo juego un rol:
- Fase 3: arquitecto (diseño SDD, sin código)
- Fase 5: scaffolder (código + tests TDD)
- Fase 6: auditor (verifico, sin modificar)

## Configuración

Edita ``stack.md`` antes de empezar.

---

Para más detalles: ``.claude\skills\app-orchestrator\SKILL.md``
"@ | Set-Content -Path "$proj\CLAUDE.md" -Encoding UTF8
    Write-Host "    ✅ CLAUDE.md creado"
  } else {
    Write-Host "    ℹ️  CLAUDE.md ya existe"
  }

  # Crear OPENCODE.md
  if (-not (Test-Path "$proj\OPENCODE.md")) {
    @"
# Instrucciones para OpenCode

Este proyecto soporta AMBAS plataformas: Claude Code y OpenCode.

## Para OpenCode

Abre OpenCode en esta carpeta y escribe:

``````
/build-app quiero crear una aplicación para [tu idea]
``````

Los agentes están en ``.opencode\agents\`` y los skills en ``.opencode\skills\`` (symlink a ``.claude\skills\``).

## Agentes

- ``/load arquitecto`` (Fase 3)
- ``/load scaffolder`` (Fase 5)
- ``/load auditor`` (Fase 6)

## Configuración

Edita ``stack.md`` antes de empezar.

---

Para más detalles: ``.opencode\skills\app-orchestrator\SKILL.md``
"@ | Set-Content -Path "$proj\OPENCODE.md" -Encoding UTF8
    Write-Host "    ✅ OPENCODE.md creado"
  } else {
    Write-Host "    ℹ️  OPENCODE.md ya existe"
  }

  # Copiar stack.md y model-profiles.md
  foreach ($f in @('stack.md', 'model-profiles.md')) {
    if (-not (Test-Path "$proj\$f") -and (Test-Path (Join-Path $cache "config\$f"))) {
      Copy-Item (Join-Path $cache "config\$f") "$proj\$f"
      Write-Host "    📄 $f copiado"
    }
  }

  # git init
  if (-not (Test-Path "$proj\.git")) {
    git -C $proj init -q
    Write-Host "    🔧 git init"
  }

  Write-Host ""
  Write-Host "✅ Instalación completada para Claude Code + OpenCode"
  Write-Host ""
  Write-Host "Próximos pasos:"
  Write-Host "  1. Edita stack.md"
  Write-Host "  2. Para Claude Code: abre Claude Code y escribe tu idea"
  Write-Host "  3. Para OpenCode: abre OpenCode y escribe: /build-app [tu idea]"
}

# ──────────────────────────────────────────────────────────────────────────
# Ejecutar según opción
# ──────────────────────────────────────────────────────────────────────────

switch ($platform_choice) {
  "1" { Install-Claude-Code }
  "2" { Install-OpenCode }
  "3" { Install-Both }
}

Write-Host ""
Write-Host "💡 Recuerda: edita stack.md para definir tu configuración técnica."
Write-Host ""
