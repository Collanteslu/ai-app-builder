#!/usr/bin/env bash
# uninstall.sh — elimina el andamiaje del AI App Builder de un proyecto.
#
# Quita las skills instaladas a nivel de proyecto (.claude/skills del cwd). NO
# toca tu código (src/, prisma/, ...) ni .builder/ salvo que pidas --builder.
#
# Uso:
#   scripts/uninstall.sh             # quita .claude/skills del proyecto
#   scripts/uninstall.sh --all       # + stack.md y model-profiles.md
#   scripts/uninstall.sh --builder   # + .builder/ (artefactos + memoria) ¡irreversible!
#   scripts/uninstall.sh --user      # opera sobre ~/.claude/skills (instalación global)
set -euo pipefail

ALL=0; BUILDER=0; SCOPE="project"
while [ $# -gt 0 ]; do
  case "$1" in
    --all)     ALL=1; shift;;
    --builder) BUILDER=1; shift;;
    --user)    SCOPE="user"; shift;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "Opción desconocida: $1" >&2; exit 1;;
  esac
done

if [ "$SCOPE" = "user" ]; then SKILLS="$HOME/.claude/skills"; else SKILLS="$(pwd)/.claude/skills"; fi

if [ -d "$SKILLS" ]; then rm -rf "$SKILLS"; echo "🗑️  Skills eliminadas: $SKILLS"; else echo "ℹ️  No hay skills en: $SKILLS"; fi

TPL="$(dirname "$SKILLS")/template"
if [ -d "$TPL" ]; then rm -rf "$TPL"; echo "🗑️  Template eliminado: $TPL"; fi

if [ "$ALL" -eq 1 ]; then
  for f in stack.md model-profiles.md; do
    [ -f "./$f" ] && rm "./$f" && echo "🗑️  Eliminado: $f"
  done
fi

if [ "$BUILDER" -eq 1 ] && [ -d "./.builder" ]; then
  rm -rf "./.builder"; echo "🗑️  Eliminado: .builder/ (artefactos + memoria)"
fi

echo ""
echo "✅ Listo. Tu código (src/, prisma/, ...) y su git no se han tocado."
