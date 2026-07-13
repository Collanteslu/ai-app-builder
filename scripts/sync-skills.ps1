<#
.SYNOPSIS
  Mantiene las skills de conocimiento al día respecto a su fuente.

.DESCRIPTION
  Las skills bajo skills/ (excepto las app-*) son COPIAS de un catálogo externo.
  Este script las re-sincroniza y/o detecta el "drift" entre copia y fuente.

.PARAMETER Check
  Solo informa de diferencias, no toca nada.

.PARAMETER Sync
  Copia desde la fuente (SOBRESCRIBE las copias).

.PARAMETER SkillsSrc
  Ruta alternativa a la fuente. Por defecto: ~\.agents\skills

.EXAMPLE
  .\scripts\sync-skills.ps1 -Check
  .\scripts\sync-skills.ps1 -Sync
  .\scripts\sync-skills.ps1 -Check -SkillsSrc C:\mis\skills

.NOTES
  Ejecuta -Check ANTES de -Sync. -Sync es destructivo: sobrescribe
  cualquier edición local que hayas hecho a mano en las copias bajo skills/.
#>

param(
  [switch]$Check,
  [switch]$Sync,
  [string]$SkillsSrc = ""
)

$ErrorActionPreference = "Stop"

$HERE = Split-Path -Parent $PSCommandPath
$DEST = Resolve-Path "$HERE\..\skills"
if (-not $SkillsSrc) {
  $SkillsSrc = "$env:USERPROFILE\.agents\skills"
}

$MODE = "check"
if ($Sync) { $MODE = "sync" }

if (-not (Test-Path $SkillsSrc)) {
  Write-Host "✗ No existe la fuente: $SkillsSrc"
  Write-Host "  Define la ruta real con: -SkillsSrc C:\ruta\a\skills"
  exit 1
}

# Skills de conocimiento = todas las de skills/ que NO son app-* (ni INDEX.md).
$skills = Get-ChildItem -Path $DEST -Directory | Where-Object { $_.Name -notlike "app-*" } | ForEach-Object { $_.Name }
$total = $skills.Count
$drift = 0
$missing = 0

foreach ($s in $skills) {
  $srcDir = Join-Path $SkillsSrc $s
  $destDir = Join-Path $DEST $s

  if (-not (Test-Path $srcDir)) {
    Write-Host "⚠ $s — no está en la fuente ($SkillsSrc); no se puede sincronizar"
    $missing++
    continue
  }

  # diff-equivalente: comparar número y fechas de archivos (suficiente para detectar drift)
  $srcFiles = Get-ChildItem -Recurse $srcDir | Where-Object { -not $_.PSIsContainer -and $_.Name -ne ".DS_Store" } | ForEach-Object { $_.FullName.Replace($srcDir, "").TrimStart("\") } | Sort-Object
  $destFiles = Get-ChildItem -Recurse $destDir | Where-Object { -not $_.PSIsContainer -and $_.Name -ne ".DS_Store" } | ForEach-Object { $_.FullName.Replace($destDir, "").TrimStart("\") } | Sort-Object

  $differs = $false
  if ($srcFiles.Count -ne $destFiles.Count) {
    $differs = $true
  } else {
    for ($i = 0; $i -lt $srcFiles.Count; $i++) {
      if ($srcFiles[$i] -ne $destFiles[$i]) { $differs = $true; break }
      $srcContent = Get-Content (Join-Path $srcDir $srcFiles[$i]) -Raw
      $destContent = Get-Content (Join-Path $destDir $destFiles[$i]) -Raw
      if ($srcContent -ne $destContent) { $differs = $true; break }
    }
  }

  if ($differs) {
    if ($MODE -eq "sync") {
      Remove-Item -Recurse -Force $destDir -ErrorAction SilentlyContinue
      Copy-Item -Recurse $srcDir $destDir
      Write-Host "↻ $s — actualizada"
    } else {
      Write-Host "≠ $s — DIFIERE de la fuente"
    }
    $drift++
  }
}

Write-Host "---"
if ($MODE -eq "sync") {
  $index = Join-Path $DEST "INDEX.md"
  if (Test-Path $index) {
    $today = Get-Date -Format "yyyy-MM-dd"
    $srcDisp = $SkillsSrc
    if ($SkillsSrc -match "^$env:USERPROFILE") {
      $srcDisp = "~" + $SkillsSrc.Substring($env:USERPROFILE.Length)
    }
    (Get-Content $index) -replace "(Última sincronización:).*", "`${1} $today (fuente: $srcDisp)" | Set-Content $index
    Write-Host "Sello de fecha actualizado: $today"
  }
  Write-Host "Sincronizadas: $drift · sin fuente: $missing · total: $total"
} else {
  if ($drift -eq 0 -and $missing -eq 0) {
    Write-Host "✓ Todo al día respecto a $SkillsSrc ($total skills)"
  } else {
    Write-Host "Drift: $drift · sin fuente: $missing · total: $total"
    Write-Host "Ejecuta '.\scripts\sync-skills.ps1 -Sync' para actualizar las copias."
  }
}
