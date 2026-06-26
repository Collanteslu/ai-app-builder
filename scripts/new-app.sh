#!/usr/bin/env bash
# new-app.sh — crea un proyecto nuevo listo para construir con el AI App Builder,
# de una sola vez (macOS / Linux).
#
# En un solo comando: crea la carpeta del proyecto, instala las skills DENTRO de
# ella (aislado, .claude/skills), copia stack.md + model-profiles.md e inicializa
# git. Al terminar solo te queda rellenar stack.md y hablar con Claude.
#
# NO construye la app: eso es la parte interactiva (abres Claude Code en la
# carpeta y le dices "Quiero crear una aplicación para ...").
#
# Uso:
#   bash scripts/new-app.sh ~/proyectos/mi-app
#   bash scripts/new-app.sh ~/proyectos/mi-app --no-git
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJ=""
NO_GIT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --no-git) NO_GIT=1; shift;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    -*) echo "Opción desconocida: $1" >&2; exit 1;;
    *) PROJ="$1"; shift;;
  esac
done

if [ -z "$PROJ" ]; then echo "Uso: bash scripts/new-app.sh <ruta-del-proyecto>" >&2; exit 1; fi

if [ -d "$PROJ" ] && [ -n "$(ls -A "$PROJ" 2>/dev/null | grep -v '^.git$' || true)" ]; then
  echo "⚠️  La carpeta '$PROJ' ya existe y no está vacía. Continúo sin sobrescribir."
else
  mkdir -p "$PROJ"
  echo "📁 Carpeta creada: $PROJ"
fi

# 1) Skills dentro del proyecto (aislado)
mkdir -p "$PROJ/.claude/skills"
cp -R "$REPO/skills/"* "$PROJ/.claude/skills/"
count=$(find "$REPO/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
echo "✅ $count skills instaladas en .claude/skills"

# 2) Config de partida
for f in stack.md model-profiles.md; do
  if [ -f "$REPO/config/$f" ] && [ ! -f "$PROJ/$f" ]; then
    cp "$REPO/config/$f" "$PROJ/$f"
    echo "📄 Copiado $f"
  fi
done

# 3) git init
if [ "$NO_GIT" -eq 0 ]; then
  if command -v git >/dev/null 2>&1; then
    if [ ! -d "$PROJ/.git" ]; then
      git -C "$PROJ" init -q
      echo "🔧 git init"
    fi
  else
    echo "⚠️  git no encontrado; omito git init."
  fi
fi

echo ""
echo "🎉 Proyecto listo en: $PROJ"
echo "Siguiente:"
echo "  1) Edita $PROJ/stack.md (define Auth e Infra, sin '(definir)')."
echo "  2) Abre Claude Code en esa carpeta y di:"
echo '       "Quiero crear una aplicación para [tu idea]"'
