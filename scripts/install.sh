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

while [ $# -gt 0 ]; do
  case "$1" in
    --project) DEST="$(pwd)/.claude/skills"; shift;;
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

# Soporte opencode (solo instalación de proyecto): .opencode + opencode.json en el cwd.
if [ "$(dirname "$(dirname "$DEST")")" = "$(pwd)" ]; then
  rm -rf "$(pwd)/.opencode"
  mkdir -p "$(pwd)/.opencode"
  find "$REPO/.opencode" -maxdepth 1 -mindepth 1 ! -name node_modules \
    -exec cp -R {} "$(pwd)/.opencode/" \;
  cp "$REPO/opencode.json" "$(pwd)/opencode.json"
  echo "✅ .opencode + opencode.json instalados (soporte opencode)"
fi

# Punto de partida de configuración en el cwd (sin sobrescribir si ya existe).
for f in stack.md model-profiles.md; do
  if [ ! -f "./$f" ] && [ -f "$REPO/config/$f" ]; then
    cp "$REPO/config/$f" "./$f"
    echo "📄 Copiado config/$f → ./$f (ajústalo antes de empezar)."
  fi
done

echo ""
echo "Listo. Abre tu proyecto y di: \"Quiero crear una aplicación para [tu idea]\"."
