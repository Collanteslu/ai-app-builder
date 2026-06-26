<#
.SYNOPSIS
  Elimina el andamiaje del AI App Builder de un proyecto (Windows / PowerShell).

.DESCRIPTION
  Quita las skills instaladas a nivel de proyecto (.claude\skills del cwd) y, con
  -All, también la config del constructor (stack.md, model-profiles.md). NO toca
  tu código (src\, prisma\, ...) ni .builder\ salvo que pases -Builder.

  Pensado para cuando la app ya está construida y quieres dejarla sin el
  andamiaje. Para una instalación global (~\.claude\skills) usa -User.

.PARAMETER All
  Además de las skills, elimina stack.md y model-profiles.md del cwd.

.PARAMETER Builder
  Además, elimina la carpeta .builder\ (artefactos y memoria). Irreversible:
  pierdes discovery/prd/architecture/audit/memory. Úsalo solo si no los quieres.

.PARAMETER User
  Opera sobre la instalación global (~\.claude\skills) en vez de la del proyecto.

.EXAMPLE
  scripts\uninstall.ps1                # quita .claude\skills del proyecto
.EXAMPLE
  scripts\uninstall.ps1 -All           # + stack.md y model-profiles.md
.EXAMPLE
  scripts\uninstall.ps1 -User          # quita la instalación global
#>
param(
  [switch]$All,
  [switch]$Builder,
  [switch]$User
)

$ErrorActionPreference = 'Stop'

if ($User) { $skills = Join-Path $HOME '.claude\skills' }
else       { $skills = Join-Path (Get-Location) '.claude\skills' }

if (Test-Path $skills) {
  Remove-Item -Recurse -Force $skills
  Write-Host "🗑️  Skills eliminadas: $skills"
} else {
  Write-Host "ℹ️  No hay skills en: $skills"
}

if ($All) {
  foreach ($f in @('stack.md', 'model-profiles.md')) {
    $p = Join-Path (Get-Location) $f
    if (Test-Path $p) { Remove-Item $p; Write-Host "🗑️  Eliminado: $f" }
  }
}

if ($Builder) {
  $b = Join-Path (Get-Location) '.builder'
  if (Test-Path $b) { Remove-Item -Recurse -Force $b; Write-Host "🗑️  Eliminado: .builder\ (artefactos + memoria)" }
}

Write-Host ""
Write-Host "✅ Listo. Tu codigo (src\, prisma\, ...) y su git no se han tocado."
