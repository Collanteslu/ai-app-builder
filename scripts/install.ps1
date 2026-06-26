<#
.SYNOPSIS
  Instala las skills del AI App Builder en Claude Code (Windows / PowerShell).

.DESCRIPTION
  Copia las 8 skills de orquestación + las de conocimiento al destino, y deja una
  copia de config/stack.md y config/model-profiles.md en el cwd como punto de
  partida (sin sobrescribir si ya existen).

.PARAMETER Project
  Instala a nivel de proyecto (.claude/skills del directorio actual) en vez del
  perfil de usuario (~/.claude/skills).

.PARAMETER Dest
  Destino explícito. Tiene prioridad sobre -Project.

.EXAMPLE
  scripts\install.ps1
.EXAMPLE
  scripts\install.ps1 -Project
.EXAMPLE
  scripts\install.ps1 -Dest C:\ruta\skills
#>
param(
  [switch]$Project,
  [string]$Dest
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot

if (-not $Dest) {
  if ($Project) { $Dest = Join-Path (Get-Location) '.claude\skills' }
  else          { $Dest = Join-Path $HOME '.claude\skills' }
}

Write-Host "Instalando skills desde: $repo\skills"
Write-Host "Destino:                 $Dest"
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Copy-Item -Recurse -Force -Path (Join-Path $repo 'skills\*') -Destination $Dest

$count = (Get-ChildItem -Directory (Join-Path $repo 'skills')).Count
Write-Host "✅ $count skills instaladas."

# Template (scaffold base de Fase 5) junto a las skills, excluyendo node_modules/.next
$tplDest = Join-Path (Split-Path $Dest) 'template'
if (Test-Path $tplDest) { Remove-Item -Recurse -Force $tplDest }
New-Item -ItemType Directory -Force -Path $tplDest | Out-Null
Get-ChildItem -Force -Path (Join-Path $repo 'template') -Exclude 'node_modules', '.next' |
  Copy-Item -Recurse -Force -Destination $tplDest
Write-Host "✅ template instalado en $tplDest"

# Punto de partida de configuración en el cwd (sin sobrescribir si ya existe).
foreach ($f in @('stack.md', 'model-profiles.md')) {
  $src = Join-Path $repo "config\$f"
  $dst = Join-Path (Get-Location) $f
  if ((Test-Path $src) -and -not (Test-Path $dst)) {
    Copy-Item $src $dst
    Write-Host "📄 Copiado config\$f -> .\$f (ajustalo antes de empezar)."
  }
}

Write-Host ""
Write-Host 'Listo. Abre tu proyecto y di: "Quiero crear una aplicacion para [tu idea]".'
