#!/usr/bin/env bash
# ai-builder-init.sh — Master installer para todas las plataformas
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/.../scripts/ai-builder-init.sh | bash
#
# Pregunta: ¿Claude Code, OpenCode, Reasonix, o Múltiples?
# Según respuesta, ejecuta el instalador correspondiente.
#
set -euo pipefail

REPO="https://github.com/Collanteslu/ai-app-builder.git"
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
# Menú principal
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
# Descargar e instalar según opción
# ──────────────────────────────────────────────────────────────────────────

case "$choice" in
  1)
    echo ""
    echo "📦 Instalando para Claude Code..."
    echo ""
    bash <(curl -fsSL "$BASE_URL/scripts/install.sh") --project
    ;;

  2)
    echo ""
    echo "📦 Instalando para OpenCode..."
    echo ""
    bash <(curl -fsSL "$BASE_URL/scripts/install.sh") --project
    # La opción 2 se selecciona interactivamente en el script
    ;;

  3)
    echo ""
    echo "📦 Instalando para Reasonix..."
    echo ""
    bash <(curl -fsSL "$BASE_URL/scripts/reasonix-init.sh")
    ;;

  4)
    echo ""
    echo "📦 Instalando para Claude Code + OpenCode + Reasonix..."
    echo ""
    echo "Este instalador se ejecutará 3 veces (una por plataforma)."
    echo ""

    # Claude Code (opción 1)
    echo "─ Fase 1: Claude Code"
    bash <(curl -fsSL "$BASE_URL/scripts/install.sh") --project
    # En el script interactivo, selecciona opción 1

    # OpenCode (opción 2)
    echo ""
    echo "─ Fase 2: OpenCode"
    bash <(curl -fsSL "$BASE_URL/scripts/install.sh") --project
    # En el script interactivo, selecciona opción 2

    # Reasonix (opción 3)
    echo ""
    echo "─ Fase 3: Reasonix"
    bash <(curl -fsSL "$BASE_URL/scripts/reasonix-init.sh")

    echo ""
    echo "✅ Instalación múltiple completada"
    echo "   Todo está listo para trabajar con las 3 plataformas"
    ;;
esac

echo ""
echo "🎉 ¡Listo! Lee los documentos para empezar:"
echo "  • CLAUDE.md (si instalaste Claude Code)"
echo "  • OPENCODE.md (si instalaste OpenCode)"
echo "  • REASONIX.md (si instalaste Reasonix)"
echo "  • REASONIX_QUICK_START.md (para Reasonix rápido)"
echo ""
