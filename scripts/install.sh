#!/usr/bin/env bash
# install.sh — instala las skills del AI App Builder en Claude Code.
#
# Uso:
#   scripts/install.sh                # a nivel de usuario (~/.claude/skills)
#   scripts/install.sh --project      # a nivel de proyecto (.claude/skills del cwd)
#   scripts/install.sh --dest /ruta   # destino explícito
#
# Copia las 8 skills de orquestación + las de conocimiento, y deja una copia de
# config/stack.md y config/model-profiles.md en el cwd como punto de partida.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$HOME/.claude/skills"
PROJECT=0   # 1 = instalación de proyecto (copia .opencode + opencode.json al cwd)

while [ $# -gt 0 ]; do
  case "$1" in
    --project) DEST="$(pwd)/.claude/skills"; PROJECT=1; shift;;
    --dest)    DEST="$2"; shift 2;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "Opción desconocida: $1" >&2; exit 1;;
  esac
done

echo "Instalando skills desde: $REPO/skills"
echo "Destino:                 $DEST"
mkdir -p "$DEST"
cp -R "$REPO/skills/"* "$DEST/"

count=$(find "$REPO/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
echo "✅ $count skills instaladas."

# Template (scaffold base de Fase 5) junto a las skills, excluyendo node_modules/.next
TPL_DEST="$(dirname "$DEST")/template"
rm -rf "$TPL_DEST"
mkdir -p "$TPL_DEST"
find "$REPO/template" -maxdepth 1 -mindepth 1 ! -name node_modules ! -name .next \
  -exec cp -R {} "$TPL_DEST/" \;
echo "✅ template instalado en $TPL_DEST"

# ── Configuración por plataforma (solo instalación de proyecto) ────────────────
if [ "$PROJECT" -eq 1 ]; then
  echo ""
  echo "¿Con cuál plataforma usarás el AI App Builder?"
  echo "  1) Claude Code (CLI / Desktop / Web app)"
  echo "  2) OpenCode"
  echo "  3) Ambas"
  read -p "Opción (1-3): " platform_choice

  # Claude Code: crear/copiar CLAUDE.md
  if [ "$platform_choice" = "1" ] || [ "$platform_choice" = "3" ]; then
    if [ ! -f ./CLAUDE.md ]; then
      cat > ./CLAUDE.md << 'EOF'
# Instrucciones para Claude Code

Este proyecto usa el **AI App Builder** — un proceso estructurado de 6 fases
para construir aplicaciones con trazabilidad de requisitos (RF-XX).

## Flujo principal

```
Quiero crear una aplicación para [tu idea]
```

O la frase inequívoca si los agentes no se cargan:

```
inicia el constructor de apps
```

## Roles de Claude por fase

**Nota:** Claude Code NO tiene agentes formales (eso es OpenCode).
En cada fase, Claude juega un rol especializado:

1. **Discovery** → Claude es descubridor (extrae CU-XX del análisis)
2. **PRD** → Claude es analista (define RF-XX con criterios de aceptación)
3. **Arquitectura** → Claude es **arquitecto** (diseña SDD, NO escribe código)
4. **Mockup** → Claude es diseñador (crea mockups navegables HTML)
5. **Scaffold** → Claude es **scaffolder** (genera código + tests con TDD triple bucle)
6. **Auditoría** → Claude es **auditor** (verifica trazabilidad, NO modifica código)

## Gates

- `trace-lint.mjs`: ejecutable en Fase 2 y 3 (verifica trazabilidad de requisitos)
- `audit:builder`: ejecutable en Fase 5 y 6 (verifica wiring y calidad)
- `audit:wiring`: ejecutable en Fase 5 (verifica fetch → endpoint)

Todos los gates deben pasar (exit 0) para avanzar.

## Memoria persistente

El proceso captura en `.builder/memory/` las decisiones, gotchas y restricciones
que aparecen en cada fase. Esto evita repetir errores y re-litigar decisiones
ya tomadas en sesiones anteriores.

## Configuración

Edita `stack.md` antes de empezar (define tu tech stack, Auth, Infra).

---

Para más detalles: `.claude/skills/app-orchestrator/SKILL.md`
EOF
      echo "✅ CLAUDE.md creado (instrucciones para Claude Code)"
    fi
  fi

  # OpenCode: configurar .opencode + opencode.json
  if [ "$platform_choice" = "2" ] || [ "$platform_choice" = "3" ]; then
    rm -rf "$(pwd)/.opencode"
    mkdir -p "$(pwd)/.opencode"
    find "$REPO/.opencode" -maxdepth 1 -mindepth 1 ! -name node_modules \
      -exec cp -R {} "$(pwd)/.opencode/" \;
    cp "$REPO/opencode.json" "$(pwd)/opencode.json"
    echo "✅ .opencode + opencode.json instalados (soporte OpenCode)"

    # Crear OPENCODE.md con instrucciones específicas
    if [ ! -f ./OPENCODE.md ]; then
      cat > ./OPENCODE.md << 'EOF'
# Instrucciones para OpenCode

Este proyecto usa el **AI App Builder** en OpenCode.

## Agentes especializados

El proceso usa 3 agentes con permisos limitados:

1. **arquitecto** (Fase 3): diseña SDD, read-only en código
   ```
   /load arquitecto
   ```

2. **scaffolder** (Fase 5): genera código, write/edit/bash/browser
   ```
   /load scaffolder
   ```

3. **auditor** (Fase 6): verifica trazabilidad, read-only
   ```
   /load auditor
   ```

## Flujo principal

```
/build-app quiero crear una aplicación para [tu idea]
```

## Skills incluidas

Todas las skills están en `.opencode/` — llama `/help` para listarlas.

## Configuración

Edita `stack.md` antes de empezar (define tech stack, Auth, Infra).

---

Para más detalles: `.opencode/skills/app-orchestrator/SKILL.md`
EOF
      echo "✅ OPENCODE.md creado (instrucciones para OpenCode)"
    fi
  fi

  # Config general
  for f in stack.md model-profiles.md; do
    if [ ! -f "./$f" ] && [ -f "$REPO/config/$f" ]; then
      cp "$REPO/config/$f" "./$f"
      echo "📄 Copiado config/$f → ./$f (ajústalo antes de empezar)."
    fi
  done

  echo ""
  if [ "$platform_choice" = "1" ]; then
    echo "✅ Listo. Lee CLAUDE.md y abre Claude Code en esta carpeta."
  elif [ "$platform_choice" = "2" ]; then
    echo "✅ Listo. Lee OPENCODE.md y usa OpenCode en esta carpeta."
  else
    echo "✅ Listo. Lee CLAUDE.md u OPENCODE.md según tu plataforma."
  fi
fi

echo ""
echo "💡 Próximo paso: edita stack.md (define tu tech stack, Auth, Infra)."
