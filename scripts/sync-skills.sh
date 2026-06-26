#!/usr/bin/env bash
#
# sync-skills.sh — mantiene las 32 skills de conocimiento al día respecto a su fuente.
#
# Las skills bajo skills/ (excepto las app-*) son COPIAS de un catálogo externo.
# Con el tiempo la fuente se actualiza y estas copias quedan obsoletas en silencio.
# Este script las re-sincroniza y/o detecta el "drift" entre copia y fuente.
#
# Uso:
#   scripts/sync-skills.sh --check     # solo informa de diferencias, no toca nada
#   scripts/sync-skills.sh --sync      # copia desde la fuente (SOBRESCRIBE las copias)
#   SKILLS_SRC=/otra/ruta scripts/sync-skills.sh --check   # fuente alternativa
#
# IMPORTANTE: ejecuta --check ANTES de --sync. --sync es destructivo: sobrescribe
# cualquier edición local que hayas hecho a mano en las copias bajo skills/.
#
# Fuente por defecto: ~/.agents/skills  (ajústala con SKILLS_SRC si la tuya difiere).
# Los .DS_Store se ignoran (no cuentan como drift).

set -euo pipefail

SRC="${SKILLS_SRC:-$HOME/.agents/skills}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$HERE/skills"

MODE="${1:---check}"

if [[ ! -d "$SRC" ]]; then
  echo "✗ No existe la fuente: $SRC"
  echo "  Define la ruta real con: SKILLS_SRC=/ruta/a/skills $0 $MODE"
  exit 1
fi

# Las skills de conocimiento = todas las de skills/ que NO son app-* (ni INDEX.md).
SKILLS=()
for d in "$DEST"/*/; do
  n="$(basename "$d")"
  [[ "$n" == app-* ]] && continue
  SKILLS+=("$n")
done

drift=0; missing=0
total=${#SKILLS[@]}
for s in "${SKILLS[@]}"; do
  if [[ ! -d "$SRC/$s" ]]; then
    echo "⚠ $s — no está en la fuente ($SRC); no se puede sincronizar"
    missing=$((missing+1))
    continue
  fi
  if ! diff -rq --exclude=.DS_Store "$SRC/$s" "$DEST/$s" >/dev/null 2>&1; then
    if [[ "$MODE" == "--sync" ]]; then
      rm -rf "$DEST/$s" && cp -R "$SRC/$s" "$DEST/$s"
      find "$DEST/$s" -name .DS_Store -delete   # coherencia con el --check
      echo "↻ $s — actualizada"
    else
      echo "≠ $s — DIFIERE de la fuente"
    fi
    drift=$((drift+1))
  fi
done

echo "---"
if [[ "$MODE" == "--sync" ]]; then
  # Sella la fecha de última sincronización en el INDEX (hace visible el drift en el tiempo).
  INDEX="$DEST/INDEX.md"
  if [[ -f "$INDEX" ]] && grep -q "Última sincronización:" "$INDEX"; then
    today="$(date +%Y-%m-%d)"
    srcdisp="$SRC"; case "$SRC" in "$HOME"/*) srcdisp="~${SRC#"$HOME"}";; esac
    tmp="$(mktemp)"
    sed -E "s|(Última sincronización:).*|\1 ${today} (fuente: ${srcdisp})|" "$INDEX" > "$tmp" && mv "$tmp" "$INDEX"
    echo "Sello de fecha actualizado: $today"
  fi
  echo "Sincronizadas: $drift · sin fuente: $missing · total: $total"
else
  if [[ $drift -eq 0 && $missing -eq 0 ]]; then
    echo "✓ Todo al día respecto a $SRC (${#SKILLS[@]} skills)"
  else
    echo "Drift: $drift · sin fuente: $missing · total: $total"
    echo "Ejecuta '$0 --sync' para actualizar las copias."
  fi
fi
