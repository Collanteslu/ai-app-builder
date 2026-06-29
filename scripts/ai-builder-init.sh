#!/usr/bin/env bash
# ai-builder-init.sh — Master installer para todas las plataformas
# Instalación DIRECTA sin preguntas duplicadas
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/.../scripts/ai-builder-init.sh | bash
#
set -euo pipefail

BRANCH="v2"
BASE_URL="https://raw.githubusercontent.com/Collanteslu/ai-app-builder/$BRANCH"

# ──────────────────────────────────────────────────────────────────────────
# Verificaciones previas
# ──────────────────────────────────────────────────────────────────────────

if ! command -v git &> /dev/null; then
  echo "❌ git no está instalado. Instálalo primero."
  exit 1
fi

# ──────────────────────────────────────────────────────────────────────────
# Menú principal (ÚNICA PREGUNTA)
# ──────────────────────────────────────────────────────────────────────────

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        AI App Builder — Elige tu plataforma de desarrollo      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "¿Con cuál plataforma quieres trabajar?"
echo ""
echo "  1) Claude Code (CLI / Desktop / Web app)"
echo "     → .claude/skills + CLAUDE.md"
echo ""
echo "  2) OpenCode"
echo "     → .opencode/agents + .opencode/skills + OPENCODE.md"
echo ""
echo "  3) Reasonix (DeepSeek-native)"
echo "     → .reasonix/agents + .reasonix/skills + REASONIX.md"
echo ""
echo "  4) Múltiples (todas las plataformas)"
echo "     → .claude/ + .opencode/ + .reasonix/ (con symlinks inteligentes)"
echo ""
read -p "Opción (1-4): " choice

case "$choice" in
  1|2|3|4) ;;
  *)
    echo "❌ Opción inválida. Debe ser 1, 2, 3 o 4."
    exit 1
    ;;
esac

# ──────────────────────────────────────────────────────────────────────────
# Descargar el repositorio a un temporal
# ──────────────────────────────────────────────────────────────────────────

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "📥 Descargando AI App Builder..."
git clone --quiet --depth 1 --branch "$BRANCH" https://github.com/Collanteslu/ai-app-builder.git "$TMPDIR" 2>/dev/null || {
  echo "❌ Error descargando repositorio. Verifica tu conexión a internet."
  exit 1
}

# ──────────────────────────────────────────────────────────────────────────
# Instalación según opción (SIN PREGUNTAS ADICIONALES)
# ──────────────────────────────────────────────────────────────────────────

case "$choice" in
  1)
    echo ""
    echo "📦 Instalando AI App Builder para Claude Code..."
    echo ""

    # Copiar skills
    mkdir -p ".claude/skills"
    cp -R "$TMPDIR/skills/"* ".claude/skills/" 2>/dev/null || true
    echo "✅ Skills instaladas en .claude/skills"

    # Copiar archivos de config
    [ ! -f "CLAUDE.md" ] && cp "$TMPDIR/CLAUDE.md" . && echo "📄 CLAUDE.md"
    [ ! -f "stack.md" ] && cp "$TMPDIR/config/stack.md" . && echo "📄 stack.md"
    [ ! -f "model-profiles.md" ] && cp "$TMPDIR/config/model-profiles.md" . && echo "📄 model-profiles.md"

    # Git init
    if [ ! -d ".git" ]; then
      git init -q && echo "🔧 git init"
    fi

    echo ""
    echo "✅ Instalación completada para Claude Code"
    ;;

  2)
    echo ""
    echo "📦 Instalando AI App Builder para OpenCode..."
    echo ""

    # Copiar skills y agentes
    mkdir -p ".opencode/skills"
    cp -R "$TMPDIR/skills/"* ".opencode/skills/" 2>/dev/null || true
    mkdir -p ".opencode/agents" ".opencode/instructions" ".opencode/commands"
    [ -d "$TMPDIR/.opencode/agents" ] && cp -R "$TMPDIR/.opencode/agents/"* ".opencode/agents/" 2>/dev/null || true
    [ -d "$TMPDIR/.opencode/instructions" ] && cp -R "$TMPDIR/.opencode/instructions/"* ".opencode/instructions/" 2>/dev/null || true
    [ -d "$TMPDIR/.opencode/commands" ] && cp -R "$TMPDIR/.opencode/commands/"* ".opencode/commands/" 2>/dev/null || true
    echo "✅ OpenCode instalado"

    # Copiar archivos de config
    [ ! -f "OPENCODE.md" ] && cp "$TMPDIR/OPENCODE.md" . && echo "📄 OPENCODE.md"
    [ ! -f "opencode.json" ] && cp "$TMPDIR/opencode.json" . && echo "📄 opencode.json"
    [ ! -f "stack.md" ] && cp "$TMPDIR/config/stack.md" . && echo "📄 stack.md"

    # Git init
    if [ ! -d ".git" ]; then
      git init -q && echo "🔧 git init"
    fi

    echo ""
    echo "✅ Instalación completada para OpenCode"
    ;;

  3)
    echo ""
    echo "📦 Instalando AI App Builder para Reasonix..."
    echo ""

    # Copiar skills y agentes
    mkdir -p ".reasonix/skills"
    cp -R "$TMPDIR/skills/"* ".reasonix/skills/" 2>/dev/null || true
    mkdir -p ".reasonix/agents"
    [ -d "$TMPDIR/.reasonix/agents" ] && cp -R "$TMPDIR/.reasonix/agents/"* ".reasonix/agents/" 2>/dev/null || true
    echo "✅ Reasonix instalado"

    # Copiar archivos de config
    [ ! -f "REASONIX.md" ] && cp "$TMPDIR/REASONIX.md" . && echo "📄 REASONIX.md"
    [ ! -f "REASONIX_QUICK_START.md" ] && cp "$TMPDIR/REASONIX_QUICK_START.md" . && echo "📄 REASONIX_QUICK_START.md"
    [ ! -f "stack.md" ] && cp "$TMPDIR/config/stack.md" . && echo "📄 stack.md"

    # Git init
    if [ ! -d ".git" ]; then
      git init -q && echo "🔧 git init"
    fi

    echo ""
    echo "✅ Instalación completada para Reasonix"
    ;;

  4)
    echo ""
    echo "📦 Instalando para todas las plataformas (Claude Code + OpenCode + Reasonix)..."
    echo ""

    # Copiar skills comunes
    mkdir -p ".claude/skills"
    cp -R "$TMPDIR/skills/"* ".claude/skills/" 2>/dev/null || true
    echo "✅ Skills base instaladas en .claude/skills"

    # Claude Code
    echo "  ✓ Fase 1: Claude Code"
    [ ! -f "CLAUDE.md" ] && cp "$TMPDIR/CLAUDE.md" . && echo "    📄 CLAUDE.md"

    # OpenCode (con symlink)
    echo "  ✓ Fase 2: OpenCode"
    mkdir -p ".opencode/agents" ".opencode/instructions" ".opencode/commands"
    [ -d "$TMPDIR/.opencode/agents" ] && cp -R "$TMPDIR/.opencode/agents/"* ".opencode/agents/" 2>/dev/null || true
    ln -sf "../.claude/skills" ".opencode/skills" 2>/dev/null || true
    echo "    🔗 Skills linked: .opencode/skills → .claude/skills"
    [ ! -f "OPENCODE.md" ] && cp "$TMPDIR/OPENCODE.md" . && echo "    📄 OPENCODE.md"
    [ ! -f "opencode.json" ] && cp "$TMPDIR/opencode.json" . && echo "    📄 opencode.json"

    # Reasonix (con symlink)
    echo "  ✓ Fase 3: Reasonix"
    mkdir -p ".reasonix/agents"
    [ -d "$TMPDIR/.reasonix/agents" ] && cp -R "$TMPDIR/.reasonix/agents/"* ".reasonix/agents/" 2>/dev/null || true
    ln -sf "../.claude/skills" ".reasonix/skills" 2>/dev/null || true
    echo "    🔗 Skills linked: .reasonix/skills → .claude/skills"
    [ ! -f "REASONIX.md" ] && cp "$TMPDIR/REASONIX.md" . && echo "    📄 REASONIX.md"

    # Config común
    [ ! -f "stack.md" ] && cp "$TMPDIR/config/stack.md" . && echo "📄 stack.md"
    [ ! -f "model-profiles.md" ] && cp "$TMPDIR/config/model-profiles.md" . && echo "📄 model-profiles.md"

    # Git init
    if [ ! -d ".git" ]; then
      git init -q && echo "🔧 git init"
    fi

    echo ""
    echo "✅ Instalación múltiple completada"
    ;;
esac

echo ""
echo "🎉 ¡Listo!"
echo ""
echo "Siguiente:"
echo "  1) Edita stack.md (define qué plataforma usarás)"
echo "  2) Abre tu IDE en esta carpeta"
echo "  3) Cuéntale a Claude: 'Quiero crear una aplicación para [tu idea]'"
echo ""
