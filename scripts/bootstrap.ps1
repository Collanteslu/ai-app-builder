<#
.SYNOPSIS
  Instalador remoto del AI App Builder (Windows / PowerShell).

.DESCRIPTION
  Pensado para ejecutarse de un tirón desde internet, estando DENTRO de la
  carpeta de tu nuevo proyecto:

    irm https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/bootstrap.ps1 | iex

  Qué hace: descarga el constructor a una caché (%LOCALAPPDATA%\ai-app-builder),
  instala las skills en ESTA carpeta (.claude\skills), copia stack.md +
  model-profiles.md, inicializa git y te explica cómo lanzar el build-app.

  Variables de entorno opcionales: AI_BUILDER_REPO, AI_BUILDER_BRANCH,
  AI_BUILDER_HOME. La ruta del proyecto es el directorio actual.
#>
$ErrorActionPreference = 'Stop'

# Cache unificada: $HOME/.ai-app-builder en ambas (bash y PowerShell).
# Así usuario no tiene dos cachés en localizaciones distintas (WSL vs native).
$repoUrl = if ($env:AI_BUILDER_REPO)   { $env:AI_BUILDER_REPO }   else { 'https://github.com/Collanteslu/ai-app-builder.git' }
$branch  = if ($env:AI_BUILDER_BRANCH) { $env:AI_BUILDER_BRANCH } else { 'v2' }
$cache   = if ($env:AI_BUILDER_HOME)   { $env:AI_BUILDER_HOME }   else { "$HOME\.ai-app-builder" }
$proj    = (Get-Location).Path

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Error "Necesitas git instalado."; exit 1
}

# 1) Obtener/actualizar el constructor en la caché
if (Test-Path (Join-Path $cache '.git')) {
  Write-Host "↻ Actualizando el constructor en $cache"
  git -C $cache fetch --depth 1 origin $branch -q
  git -C $cache reset --hard "origin/$branch" -q
} else {
  Write-Host "⤓ Descargando el constructor en $cache"
  git clone --depth 1 --branch $branch $repoUrl $cache -q
}

# 2) Instalar en el proyecto (directorio actual)
$skillsDest = Join-Path $proj '.claude\skills'
New-Item -ItemType Directory -Force -Path $skillsDest | Out-Null
Copy-Item -Recurse -Force -Path (Join-Path $cache 'skills\*') -Destination $skillsDest
$count = (Get-ChildItem -Directory (Join-Path $cache 'skills')).Count
Write-Host "✅ $count skills instaladas en .claude\skills"

$tplDest = Join-Path $proj '.claude\template'
if (Test-Path $tplDest) { Remove-Item -Recurse -Force $tplDest }
New-Item -ItemType Directory -Force -Path $tplDest | Out-Null
Get-ChildItem -Force -Path (Join-Path $cache 'template') -Exclude 'node_modules', '.next' |
  Copy-Item -Recurse -Force -Destination $tplDest
Write-Host "✅ template instalado en .claude\template"

$ocDest = Join-Path $proj '.opencode'
if (Test-Path $ocDest) { Remove-Item -Recurse -Force $ocDest }
New-Item -ItemType Directory -Force -Path $ocDest | Out-Null
Get-ChildItem -Force -Path (Join-Path $cache '.opencode') -Exclude 'node_modules' |
  Copy-Item -Recurse -Force -Destination $ocDest
Copy-Item -Force (Join-Path $cache 'opencode.json') (Join-Path $proj 'opencode.json')
Write-Host "✅ .opencode + opencode.json instalados (soporte opencode)"

foreach ($f in @('stack.md', 'model-profiles.md')) {
  $src = Join-Path $cache "config\$f"
  $dst = Join-Path $proj $f
  if ((Test-Path $src) -and -not (Test-Path $dst)) { Copy-Item $src $dst; Write-Host "📄 Copiado $f" }
}

if (-not (Test-Path (Join-Path $proj '.git'))) { git -C $proj init -q; Write-Host "🔧 git init" }

# 3) Explicar cómo lanzar el build-app
@"

🎉 Proyecto listo en: $proj

Como ejecutar el proceso de build-app:

  1) Edita stack.md y define tu stack, Auth e Infra (sin dejar '(definir)').
  2) Abre Claude Code en esta carpeta y escribe:

        Quiero crear una aplicacion para [tu idea]

     (o la frase inequivoca: "inicia el constructor de apps")

  El orquestador conduce las fases: Discovery -> PRD -> Arquitectura -> Mockup ->
  Scaffold -> Auditoria. Cada fase genera su artefacto en .builder\, hace commit
  y captura lo aprendido en .builder\memory\. Confirmas en las fases de criterio.

  En opencode: abre la carpeta con 'opencode' y usa
        /build-app quiero crear una aplicacion para [tu idea]

Para actualizar el constructor mas adelante, vuelve a ejecutar este comando.
"@ | Write-Host
