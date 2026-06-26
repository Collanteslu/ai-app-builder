#!/usr/bin/env bash
# bootstrap.sh — instalador remoto del AI App Builder (macOS / Linux).
#
# Pensado para ejecutarse de un tirón desde internet, estando DENTRO de la
# carpeta de tu nuevo proyecto:
#
#   curl -fsSL https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/bootstrap.sh | bash
#
# Qué hace: descarga el constructor a una caché (~/.ai-app-builder), instala las
# skills en ESTA carpeta (.claude/skills), copia stack.md + model-profiles.md,
# inicializa git y te explica cómo lanzar el proceso de build-app.
#
# Variables opcionales:
#   AI_BUILDER_REPO    repo del constructor (default: el oficial)
#   AI_BUILDER_BRANCH  rama (default: v2)
#   AI_BUILDER_HOME    ruta de la caché (default: ~/.ai-app-builder)
# Argumento opcional: ruta del proyecto (default: el directorio actual).
set -euo pipefail

REPO_URL="${AI_BUILDER_REPO:-https://github.com/Collanteslu/ai-app-builder.git}"
BRANCH="${AI_BUILDER_BRANCH:-v2}"
CACHE="${AI_BUILDER_HOME:-$HOME/.ai-app-builder}"
PROJ="${1:-$(pwd)}"

command -v git >/dev/null 2>&1 || { echo "❌ Necesitas git instalado." >&2; exit 1; }

# 1) Obtener/actualizar el constructor en la caché
if [ -d "$CACHE/.git" ]; then
  echo "↻ Actualizando el constructor en $CACHE"
  git -C "$CACHE" fetch --depth 1 origin "$BRANCH" -q
  git -C "$CACHE" reset --hard "origin/$BRANCH" -q
else
  echo "⤓ Descargando el constructor en $CACHE"
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$CACHE" -q
fi

# 2) Instalar en el proyecto (directorio actual por defecto)
mkdir -p "$PROJ/.claude/skills"
cp -R "$CACHE/skills/"* "$PROJ/.claude/skills/"
count=$(find "$CACHE/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
echo "✅ $count skills instaladas en .claude/skills"

rm -rf "$PROJ/.claude/template"
mkdir -p "$PROJ/.claude/template"
find "$CACHE/template" -maxdepth 1 -mindepth 1 ! -name node_modules ! -name .next \
  -exec cp -R {} "$PROJ/.claude/template/" \;
echo "✅ template instalado en .claude/template"

rm -rf "$PROJ/.opencode"
mkdir -p "$PROJ/.opencode"
find "$CACHE/.opencode" -maxdepth 1 -mindepth 1 ! -name node_modules \
  -exec cp -R {} "$PROJ/.opencode/" \;
cp "$CACHE/opencode.json" "$PROJ/opencode.json"
echo "✅ .opencode + opencode.json instalados (soporte opencode)"

for f in stack.md model-profiles.md; do
  if [ -f "$CACHE/config/$f" ] && [ ! -f "$PROJ/$f" ]; then
    cp "$CACHE/config/$f" "$PROJ/$f"
    echo "📄 Copiado $f"
  fi
done

if [ ! -d "$PROJ/.git" ]; then git -C "$PROJ" init -q; echo "🔧 git init"; fi

# 3) Explicar cómo lanzar el build-app
cat <<EOF

🎉 Proyecto listo en: $PROJ

Cómo ejecutar el proceso de build-app:

  1) Edita stack.md y define tu stack, Auth e Infra (sin dejar '(definir)').
  2) Abre Claude Code en esta carpeta y escribe:

        Quiero crear una aplicación para [tu idea]

     (o la frase inequívoca: "inicia el constructor de apps")

  El orquestador conduce las fases: Discovery → PRD → Arquitectura → Mockup →
  Scaffold → Auditoría. Cada fase genera su artefacto en .builder/, hace commit
  y captura lo aprendido en .builder/memory/. Confirmas en las fases de criterio.

  En opencode: abre la carpeta con 'opencode' y usa
        /build-app quiero crear una aplicación para [tu idea]

Para actualizar el constructor más adelante, vuelve a ejecutar este comando.
EOF
