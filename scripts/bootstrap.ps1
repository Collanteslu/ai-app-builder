<#
.SYNOPSIS
  Instalador remoto del AI App Builder (Windows / PowerShell).

.DESCRIPTION
  Pensado para ejecutarse de un tirón desde internet, estando DENTRO de la
  carpeta de tu nuevo proyecto:

    irm https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/bootstrap.ps1 | iex

  Qué hace: descarga el constructor a una caché ($HOME\.ai-app-builder, o la ruta de
  AI_BUILDER_HOME si está definida), instala las skills en ESTA carpeta
  (.claude\skills), copia stack.md + model-profiles.md, inicializa git y te explica
  cómo lanzar el build-app.

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

# ── Configuración por plataforma ──────────────────────────────────────────
Write-Host ""
Write-Host "¿Con cuál plataforma usarás el AI App Builder?"
Write-Host "  1) Claude Code (CLI / Desktop / Web app)"
Write-Host "  2) OpenCode"
Write-Host "  3) Ambas"
$platform_choice = Read-Host "Opción (1-3)"

# Claude Code: crear CLAUDE.md
if ($platform_choice -eq "1" -or $platform_choice -eq "3") {
  $claudeMd = Join-Path $proj 'CLAUDE.md'
  if (-not (Test-Path $claudeMd)) {
    @"
# Instrucciones para Claude Code

Este proyecto usa el **AI App Builder** — un proceso estructurado de 6 fases
para construir aplicaciones con trazabilidad de requisitos (RF-XX).

## Flujo principal

``````
Quiero crear una aplicación para [tu idea]
``````

O la frase inequívoca si los agentes no se cargan:

``````
inicia el constructor de apps
``````

## Fases

El orquestador conduce 6 fases:

1. **Discovery** → casos de uso (CU-XX)
2. **PRD** → requisitos (RF-XX) con criterios de aceptación
3. **Arquitectura** → modelo de datos, endpoints, SDD
4. **Mockup** → diseño visual navegable
5. **Scaffold** → código + tests (TDD)
6. **Auditoría** → verificación de trazabilidad

## Gates

- ``trace-lint.mjs``: ejecutable en Fase 2 y 3 (verifica trazabilidad de requisitos)
- ``audit:builder``: ejecutable en Fase 5 y 6 (verifica wiring y calidad)
- ``audit:wiring``: ejecutable en Fase 5 (verifica fetch → endpoint)

Todos los gates deben pasar (exit 0) para avanzar.

## Memoria persistente

El proceso captura en ``.builder/memory/`` las decisiones, gotchas y restricciones
que aparecen en cada fase. Esto evita repetir errores y re-litigar decisiones
ya tomadas en sesiones anteriores.

## Configuración

Edita ``stack.md`` antes de empezar (define tu tech stack, Auth, Infra).

---

Para más detalles: ``.claude/skills/app-orchestrator/SKILL.md``
"@ | Set-Content -Path $claudeMd -Encoding UTF8
    Write-Host "✅ CLAUDE.md creado (instrucciones para Claude Code)"
  }
}

# OpenCode: configurar .opencode + opencode.json
if ($platform_choice -eq "2" -or $platform_choice -eq "3") {
  $ocDest = Join-Path $proj '.opencode'
  if (Test-Path $ocDest) { Remove-Item -Recurse -Force $ocDest }
  New-Item -ItemType Directory -Force -Path $ocDest | Out-Null
  Get-ChildItem -Force -Path (Join-Path $cache '.opencode') -Exclude 'node_modules' |
    Copy-Item -Recurse -Force -Destination $ocDest
  Copy-Item -Force (Join-Path $cache 'opencode.json') (Join-Path $proj 'opencode.json')
  Write-Host "✅ .opencode + opencode.json instalados (soporte OpenCode)"

  # Crear OPENCODE.md
  $opencodeMd = Join-Path $proj 'OPENCODE.md'
  if (-not (Test-Path $opencodeMd)) {
    @"
# Instrucciones para OpenCode

Este proyecto usa el **AI App Builder** en OpenCode.

## Agentes especializados

El proceso usa 3 agentes con permisos limitados:

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

## Skills incluidas

Todas las skills están en ``.opencode/`` — llama ``/help`` para listarlas.

## Configuración

Edita ``stack.md`` antes de empezar (define tech stack, Auth, Infra).

---

Para más detalles: ``.opencode/skills/app-orchestrator/SKILL.md``
"@ | Set-Content -Path $opencodeMd -Encoding UTF8
    Write-Host "✅ OPENCODE.md creado (instrucciones para OpenCode)"
  }
}

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
