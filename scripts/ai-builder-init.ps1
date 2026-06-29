<#
.SYNOPSIS
  Master installer — Elige plataforma: Claude Code, OpenCode, Reasonix, o Múltiples.

.DESCRIPTION
  Instalador inteligente que:
  1. Pregunta qué plataforma quieres
  2. Descarga el repo una sola vez
  3. Ejecuta el instalador correspondiente
#>

$ErrorActionPreference = 'Stop'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Error "Necesitas git instalado."; exit 1
}

# ──────────────────────────────────────────────────────────────────────────
# Menú principal
# ──────────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗"
Write-Host "║        AI App Builder — Elige tu plataforma de desarrollo      ║"
Write-Host "╚════════════════════════════════════════════════════════════════╝"
Write-Host ""
Write-Host "¿Con cuál plataforma quieres trabajar?"
Write-Host ""
Write-Host "  1) Claude Code (CLI / Desktop / Web app)"
Write-Host "     → .claude/skills + CLAUDE.md"
Write-Host ""
Write-Host "  2) OpenCode"
Write-Host "     → .opencode/agents + .opencode/skills + OPENCODE.md"
Write-Host ""
Write-Host "  3) Reasonix (DeepSeek-native)"
Write-Host "     → .reasonix/agents + .reasonix/skills + REASONIX.md"
Write-Host ""
Write-Host "  4) Múltiples (todas las plataformas)"
Write-Host "     → .claude/ + .opencode/ + .reasonix/ (con symlinks inteligentes)"
Write-Host ""
$choice = Read-Host "Opción (1-4)"

if ($choice -notin @("1", "2", "3", "4")) {
  Write-Error "Opción inválida. Debe ser 1, 2, 3 o 4."; exit 1
}

# ──────────────────────────────────────────────────────────────────────────
# Descargar repo una sola vez
# ──────────────────────────────────────────────────────────────────────────

$tmpDir = Join-Path $env:TEMP "ai-builder-$(Get-Random)"
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

Write-Host ""
Write-Host "⤓ Descargando constructor..."
git clone --depth 1 --branch v2 https://github.com/Collanteslu/ai-app-builder.git $tmpDir -q

$repoDir = $tmpDir
$proj = (Get-Location).Path

# ──────────────────────────────────────────────────────────────────────────
# Funciones comunes
# ──────────────────────────────────────────────────────────────────────────

function Install-Claude {
  Write-Host ""
  Write-Host "📦 Instalando para Claude Code..."
  Write-Host ""

  New-Item -ItemType Directory -Force -Path "$proj\.claude" | Out-Null

  # Skills
  Write-Host "  • Instalando skills..."
  if (Test-Path "$proj\.claude\skills") { Remove-Item -Recurse -Force "$proj\.claude\skills" }
  New-Item -ItemType Directory -Force -Path "$proj\.claude\skills" | Out-Null
  Copy-Item -Recurse -Force -Path (Join-Path $repoDir 'skills\*') -Destination "$proj\.claude\skills"
  $count = (Get-ChildItem -Directory (Join-Path $repoDir 'skills')).Count
  Write-Host "    ✅ $count skills"

  # Template
  Write-Host "  • Instalando template..."
  if (Test-Path "$proj\.claude\template") { Remove-Item -Recurse -Force "$proj\.claude\template" }
  New-Item -ItemType Directory -Force -Path "$proj\.claude\template" | Out-Null
  Get-ChildItem -Force -Path (Join-Path $repoDir 'template') -Exclude 'node_modules', '.next' |
    Copy-Item -Recurse -Force -Destination "$proj\.claude\template"
  Write-Host "    ✅ template"

  # CLAUDE.md
  if (-not (Test-Path "$proj\CLAUDE.md")) {
    Copy-Item (Join-Path $repoDir 'CLAUDE.md') "$proj\CLAUDE.md"
    Write-Host "    ✅ CLAUDE.md"
  }

  # Config
  Copy-Item (Join-Path $repoDir 'config\stack.md') "$proj\stack.md" -ErrorAction SilentlyContinue
  Copy-Item (Join-Path $repoDir 'config\model-profiles.md') "$proj\model-profiles.md" -ErrorAction SilentlyContinue

  # .gitignore
  if (-not (Test-Path "$proj\.gitignore")) {
    Copy-Item (Join-Path $repoDir '.gitignore') "$proj\.gitignore"
  }

  # git init
  if (-not (Test-Path "$proj\.git")) {
    git -C $proj init -q
    git -C $proj add -A
    git -C $proj commit -q -m "chore: bootstrap claude code" 2>$null
  }

  Write-Host ""
  Write-Host "✅ Instalación completada para Claude Code"
  Write-Host ""
  Write-Host "Próximos pasos:"
  Write-Host "  1. Edita stack.md"
  Write-Host "  2. Abre Claude Code y di: 'Quiero crear una aplicación para [tu idea]'"
  Write-Host ""
}

function Install-Reasonix {
  Write-Host ""
  Write-Host "📦 Instalando para Reasonix..."
  Write-Host ""

  New-Item -ItemType Directory -Force -Path "$proj\.reasonix" | Out-Null

  # Agentes
  Write-Host "  • Instalando agentes..."
  if (Test-Path "$proj\.reasonix\agents") { Remove-Item -Recurse -Force "$proj\.reasonix\agents" }
  Copy-Item -Recurse -Force -Path (Join-Path $repoDir '.opencode\agents') -Destination "$proj\.reasonix\"
  Write-Host "    ✅ arquitecto, scaffolder, auditor"

  # Skills
  Write-Host "  • Instalando skills..."
  if (Test-Path "$proj\.reasonix\skills") { Remove-Item -Recurse -Force "$proj\.reasonix\skills" }
  New-Item -ItemType Directory -Force -Path "$proj\.reasonix\skills" | Out-Null
  Get-ChildItem -Path (Join-Path $repoDir 'skills') -Directory | ForEach-Object {
    Copy-Item -Recurse -Force -Path $_.FullName -Destination "$proj\.reasonix\skills\"
  }
  Write-Host "    ✅ 41 skills"

  # Template
  Write-Host "  • Instalando template..."
  if (Test-Path "$proj\.reasonix\template") { Remove-Item -Recurse -Force "$proj\.reasonix\template" }
  New-Item -ItemType Directory -Force -Path "$proj\.reasonix\template" | Out-Null
  Get-ChildItem -Force -Path (Join-Path $repoDir 'template') -Exclude 'node_modules', '.next' |
    Copy-Item -Recurse -Force -Destination "$proj\.reasonix\template"
  Write-Host "    ✅ template"

  # REASONIX.md
  if (-not (Test-Path "$proj\REASONIX.md")) {
    # Crear un REASONIX.md básico
    $reasonixMd = @"
# AI App Builder — Instrucciones para Reasonix

Este proyecto usa el **AI App Builder** — un proceso profesional de 6 fases.

## Flujo principal

``````bash
reasonix /build-app quiero crear una aplicación para [tu idea]
``````

## Agentes como roles

Fase 3: Eres **arquitecto** (read-only código, write architecture.md)
Fase 5: Eres **scaffolder** (full write/edit/bash)
Fase 6: Eres **auditor** (read-only código, write audit.md)

## Gates

``````bash
pnpm trace:builder      # Trazabilidad (F2, F3)
pnpm audit:builder      # Wiring y calidad (F5, F6)
pnpm audit:wiring       # Fetch→endpoint (F5)
``````

Lee REASONIX.md en el proyecto para instrucciones completas.
"@
    Set-Content -Path "$proj\REASONIX.md" -Value $reasonixMd -Encoding UTF8
  }

  # reasonix.toml
  if (-not (Test-Path "$proj\reasonix.toml")) {
    $tomlContent = @"
# Reasonix Configuration for AI App Builder

default_model = "deepseek-chat"

[[providers]]
name = "deepseek"
kind = "openai"
base_url = "https://api.deepseek.com"
model = "deepseek-chat"
api_key_env = "DEEPSEEK_API_KEY"
"@
    Set-Content -Path "$proj\reasonix.toml" -Value $tomlContent -Encoding UTF8
  }

  # Config
  Copy-Item (Join-Path $repoDir 'config\stack.md') "$proj\stack.md" -ErrorAction SilentlyContinue

  # .gitignore
  if (-not (Test-Path "$proj\.gitignore")) {
    Copy-Item (Join-Path $repoDir '.gitignore') "$proj\.gitignore"
  }

  # git init
  if (-not (Test-Path "$proj\.git")) {
    git -C $proj init -q
    git -C $proj add -A
    git -C $proj commit -q -m "chore: bootstrap reasonix" 2>$null
  }

  Write-Host ""
  Write-Host "✅ Instalación completada para Reasonix"
  Write-Host ""
  Write-Host "Próximos pasos:"
  Write-Host "  1. Edita stack.md"
  Write-Host "  2. export DEEPSEEK_API_KEY=sk-..."
  Write-Host "  3. reasonix /build-app quiero crear una aplicación para [tu idea]"
  Write-Host ""
}

# ──────────────────────────────────────────────────────────────────────────
# Ejecutar según opción
# ──────────────────────────────────────────────────────────────────────────

switch ($choice) {
  "1" { Install-Claude }
  "2" { Write-Host "Para OpenCode en Windows, usa Bash (Git Bash / WSL)" }
  "3" { Install-Reasonix }
  "4" {
    Write-Host ""
    Write-Host "📦 Instalando para todas las plataformas..."
    Install-Claude
    Write-Host ""
    Write-Host "Para OpenCode, ejecuta en Git Bash:"
    Write-Host "  bash <(curl -fsSL https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/install.sh)"
    Write-Host ""
    Install-Reasonix
  }
}

# Limpiar
Remove-Item -Recurse -Force $tmpDir

Write-Host ""
Write-Host "🎉 ¡Listo para construir profesionalmente!"
Write-Host ""
