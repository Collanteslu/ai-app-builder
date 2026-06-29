<#
.SYNOPSIS
  Master installer — Elige plataforma: Claude Code, OpenCode, Reasonix, o Múltiples.

.DESCRIPTION
  Instalador inteligente que pregunta primero, luego instala solo lo que pidió.

  Uso:
    irm https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/ai-builder-init.ps1 | iex

  Pregunta: ¿Claude Code, OpenCode, Reasonix, o Múltiples?
  Según respuesta, ejecuta el instalador correspondiente.
#>

$ErrorActionPreference = 'Stop'

# ──────────────────────────────────────────────────────────────────────────
# Verificaciones previas
# ──────────────────────────────────────────────────────────────────────────

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
# Descargar los instaladores desde el repo
# ──────────────────────────────────────────────────────────────────────────

$tmpDir = New-TemporaryFile -AsContainer
$baseUrl = "https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2"

Write-Host ""
Write-Host "⤓ Descargando instaladores..."

# Descargar bootstrap.ps1 (Claude Code)
$claudeInstaller = "$tmpDir\claude-init.ps1"
Invoke-WebRequest -Uri "$baseUrl/scripts/bootstrap.ps1" -OutFile $claudeInstaller -UseBasicParsing -q

# Descargar opencode equivalent
$opencodeInstaller = "$tmpDir\opencode-init.ps1"
# Para OpenCode usamos bootstrap pero con opción 2
$opencodeScript = @"
`$choice = "2"
`$proj = (Get-Location).Path
`$repoUrl = "https://github.com/Collanteslu/ai-app-builder.git"
`$branch = "v2"

# Seguir con install.sh (convertido a PS)
`$tmpDir = New-TemporaryFile -AsContainer
git clone --depth 1 --branch `$branch `$repoUrl `$tmpDir -q

# ... resto del bootstrap pero solo instalando OpenCode
"@
Set-Content -Path $opencodeInstaller -Value $opencodeScript

# Descargar reasonix-init.ps1
$reasonixInstaller = "$tmpDir\reasonix-init.ps1"
Invoke-WebRequest -Uri "$baseUrl/scripts/reasonix-init.ps1" -OutFile $reasonixInstaller -UseBasicParsing -q

# ──────────────────────────────────────────────────────────────────────────
# Ejecutar según opción
# ──────────────────────────────────────────────────────────────────────────

switch ($choice) {
  "1" {
    Write-Host ""
    Write-Host "📦 Instalando para Claude Code..."
    Write-Host ""
    # Ejecutar bootstrap.ps1 pero simulando opción 1
    $env:_BUILDER_CHOICE = "1"
    & $claudeInstaller
  }
  "2" {
    Write-Host ""
    Write-Host "📦 Instalando para OpenCode..."
    Write-Host ""
    # Necesitaríamos download install.sh y convertirlo a PS o ejecutarlo vía Git Bash
    # Por ahora, información clara
    Write-Host "⚠️  Para OpenCode en Windows, usa:"
    Write-Host "   bash <(curl -fsSL https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/install.sh)"
    Write-Host ""
    Write-Host "   O descarga manualmente:"
    Write-Host "   https://github.com/Collanteslu/ai-app-builder"
    Write-Host ""
  }
  "3" {
    Write-Host ""
    Write-Host "📦 Instalando para Reasonix..."
    Write-Host ""
    & $reasonixInstaller
  }
  "4" {
    Write-Host ""
    Write-Host "📦 Instalando para Claude Code + OpenCode + Reasonix..."
    Write-Host ""
    Write-Host "Este instalador se ejecutará 3 veces (una por plataforma)."
    Write-Host ""

    # Claude Code
    Write-Host "─ Fase 1: Claude Code"
    $env:_BUILDER_CHOICE = "1"
    & $claudeInstaller

    # OpenCode (manual, requiere Bash)
    Write-Host ""
    Write-Host "─ Fase 2: OpenCode (requiere Bash)"
    Write-Host "   Ejecuta en Git Bash:"
    Write-Host "   bash <(curl -fsSL https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/install.sh)"
    Write-Host ""

    # Reasonix
    Write-Host ""
    Write-Host "─ Fase 3: Reasonix"
    & $reasonixInstaller

    Write-Host ""
    Write-Host "✅ Instalación múltiple completada"
    Write-Host "   Nota: .opencode/ debe instalarse manualmente via Bash"
  }
}

# Limpiar
Remove-Item -Recurse -Force $tmpDir

Write-Host ""
Write-Host "¡Listo! Lee los documentos para empezar:"
Write-Host "  • CLAUDE.md (si instalaste Claude Code)"
Write-Host "  • OPENCODE.md (si instalaste OpenCode)"
Write-Host "  • REASONIX.md (si instalaste Reasonix)"
Write-Host ""
