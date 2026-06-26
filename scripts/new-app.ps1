<#
.SYNOPSIS
  Crea un proyecto nuevo listo para construir con el AI App Builder, de una sola
  vez (Windows / PowerShell).

.DESCRIPTION
  En un solo comando: crea la carpeta del proyecto, instala las skills DENTRO de
  ella (aislado, .claude\skills), copia stack.md + model-profiles.md e inicializa
  git. Al terminar solo te queda rellenar stack.md y hablar con Claude.

  NO construye la app: eso es la parte interactiva (abres Claude Code en la
  carpeta y le dices "Quiero crear una aplicación para ...").

.PARAMETER Path
  Ruta de la carpeta del proyecto a crear. Obligatorio.

.PARAMETER NoGit
  No ejecuta git init.

.EXAMPLE
  C:\ruta\a\ai-app-builder\scripts\new-app.ps1 C:\proyectos\mi-app
#>
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Path,
  [switch]$NoGit
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot

if (Test-Path $Path) {
  $items = Get-ChildItem -Force $Path | Where-Object { $_.Name -ne '.git' }
  if ($items) { Write-Warning "La carpeta '$Path' ya existe y no esta vacia. Continuo sin sobrescribir." }
} else {
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
  Write-Host "📁 Carpeta creada: $Path"
}

# 1) Skills dentro del proyecto (aislado)
$skillsDest = Join-Path $Path '.claude\skills'
New-Item -ItemType Directory -Force -Path $skillsDest | Out-Null
Copy-Item -Recurse -Force -Path (Join-Path $repo 'skills\*') -Destination $skillsDest
$count = (Get-ChildItem -Directory (Join-Path $repo 'skills')).Count
Write-Host "✅ $count skills instaladas en .claude\skills"

# 1b) Template (scaffold base de Fase 5), excluyendo node_modules/.next
$tplDest = Join-Path $Path '.claude\template'
if (Test-Path $tplDest) { Remove-Item -Recurse -Force $tplDest }
New-Item -ItemType Directory -Force -Path $tplDest | Out-Null
Get-ChildItem -Force -Path (Join-Path $repo 'template') -Exclude 'node_modules', '.next' |
  Copy-Item -Recurse -Force -Destination $tplDest
Write-Host "✅ template instalado en .claude\template"

# 1c) Soporte opencode: .opencode (agentes, instrucciones, comandos) + opencode.json
$ocDest = Join-Path $Path '.opencode'
if (Test-Path $ocDest) { Remove-Item -Recurse -Force $ocDest }
New-Item -ItemType Directory -Force -Path $ocDest | Out-Null
Get-ChildItem -Force -Path (Join-Path $repo '.opencode') -Exclude 'node_modules' |
  Copy-Item -Recurse -Force -Destination $ocDest
Copy-Item -Force (Join-Path $repo 'opencode.json') (Join-Path $Path 'opencode.json')
Write-Host "✅ .opencode + opencode.json instalados (soporte opencode)"

# 2) Config de partida
foreach ($f in @('stack.md', 'model-profiles.md')) {
  $src = Join-Path $repo "config\$f"
  $dst = Join-Path $Path $f
  if ((Test-Path $src) -and -not (Test-Path $dst)) {
    Copy-Item $src $dst
    Write-Host "📄 Copiado $f"
  }
}

# 3) git init
if (-not $NoGit) {
  if (Get-Command git -ErrorAction SilentlyContinue) {
    if (-not (Test-Path (Join-Path $Path '.git'))) {
      git -C $Path init -q
      Write-Host "🔧 git init"
    }
  } else {
    Write-Warning "git no encontrado; omito git init."
  }
}

Write-Host ""
Write-Host "🎉 Proyecto listo en: $Path"
Write-Host "Siguiente:"
Write-Host "  1) Edita $Path\stack.md (define Auth e Infra, sin '(definir)')."
Write-Host "  2) Abre Claude Code en esa carpeta y di:"
Write-Host '       "Quiero crear una aplicacion para [tu idea]"'
