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
trap 'rm -rf "$TMPDIR"' EXIT

echo "📥 Descargando AI App Builder..."
git clone --quiet --depth 1 --branch "$BRANCH" https://github.com/Collanteslu/ai-app-builder.git "$TMPDIR" 2>/dev/null || {
  echo "❌ Error descargando repositorio. Verifica tu conexión a internet."
  exit 1
}
# Mostrar el commit exacto que se va a instalar (transparencia + revisión manual
# de la integridad del repo upstream antes de ejecutar nada).
CLONE_COMMIT="$(git -C "$TMPDIR" rev-parse HEAD 2>/dev/null || echo 'desconocido')"
echo "    🔖 Commit instalado: $CLONE_COMMIT"
echo "    💡 Verifica en: https://github.com/Collanteslu/ai-app-builder/commit/$CLONE_COMMIT"

# ──────────────────────────────────────────────────────────────────────────
# Helpers (definidos antes del case para reutilizar en todas las ramas)
# ──────────────────────────────────────────────────────────────────────────

# Crear .gitignore mínimo para que `git add -A` no filtre secretos locales.
ensure_minimal_gitignore() {
  local dir="${1:-$PROJ}"
  local gi="$dir/.gitignore"
  if [ -f "$gi" ]; then
    return 0
  fi
  cat > "$gi" << 'GI_EOF'
# Secretos y entorno (nunca commitear)
.env
.env.*
!.env.example
*.pem
*.key
id_rsa*
id_ed25519*

# Dependencias y artefactos
node_modules/
.next/
dist/
build/
*.tsbuildinfo

# IDEs y OS
.DS_Store
Thumbs.db
.idea/
.vscode/
!.vscode/settings.json

# Logs y cobertura
*.log
coverage/
.nyc_output/

# Reasonix / OpenCode / Claude
.reasonix/
.opencode/
.claude/

# Builder state
.builder/
GI_EOF
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
      ensure_minimal_gitignore "$PROJ"
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
    # OPENCODE.md no existe en el repo upstream (se genera localmente);
    # si está en $TMPDIR lo copiamos, si no, lo creamos desde heredoc.
    if [ ! -f "OPENCODE.md" ]; then
      if [ -f "$TMPDIR/OPENCODE.md" ]; then
        cp "$TMPDIR/OPENCODE.md" .
      else
        cat > OPENCODE.md << 'OPENCODE_EOF'
# AI App Builder — Instrucciones para OpenCode

Este proyecto usa el **AI App Builder** — un proceso profesional de 6 fases
para construir aplicaciones con trazabilidad de requisitos (RF-XX).

## Flujo principal

```bash
opencode
# Luego en el chat: /build-app quiero crear una aplicación para [tu idea]
```

## 6 Fases de construcción

1. **Discovery** → Descubridor extrae CU-XX (casos de uso)
2. **PRD** → Analista define RF-XX (requisitos con criterios)
3. **Arquitectura** → Arquitecto diseña SDD (read-only en código)
4. **Mockup** → Diseñador crea mockups navegables
5. **Scaffold** → Scaffolder genera código + tests TDD (full write/edit)
6. **Auditoría** → Auditor verifica trazabilidad (read-only, audit-only)

## Agentes disponibles

- **arquitecto** (Fase 3) — diseño técnico SDD
- **scaffolder** (Fase 5) — código + tests
- **auditor** (Fase 6) — trazabilidad y calidad

Usa `/load arquitecto`, `/load scaffolder`, `/load auditor` según la fase.
OPENCODE_EOF
      fi
      echo "📄 OPENCODE.md"
    fi
    [ ! -f "opencode.json" ] && cp "$TMPDIR/opencode.json" . && echo "📄 opencode.json"
    [ ! -f "stack.md" ] && cp "$TMPDIR/config/stack.md" . && echo "📄 stack.md"

    # Git init
    if [ ! -d ".git" ]; then
      ensure_minimal_gitignore "$PROJ"
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
    # REASONIX.md se genera localmente (no viene en $TMPDIR).
    if [ ! -f "REASONIX.md" ]; then
      if [ -f "$TMPDIR/REASONIX.md" ]; then
        cp "$TMPDIR/REASONIX.md" .
      else
        cat > REASONIX.md << 'REASONIX_EOF'
# AI App Builder — Instrucciones para Reasonix

Este proyecto usa el **AI App Builder** — un proceso profesional de 6 fases
para construir aplicaciones con trazabilidad de requisitos (RF-XX).

## Flujo principal

```bash
reasonix /build-app quiero crear una aplicación para [tu idea]
```

## 6 Fases de construcción

1. **Discovery** → Descubridor extrae CU-XX (casos de uso)
2. **PRD** → Analista define RF-XX (requisitos con criterios)
3. **Arquitectura** → Arquitecto diseña SDD (read-only en código)
4. **Mockup** → Diseñador crea mockups navegables
5. **Scaffold** → Scaffolder genera código + tests TDD (full write/edit)
6. **Auditoría** → Auditor verifica trazabilidad (read-only, audit-only)

## Agentes como roles (no carga explícita)

En Reasonix, **NO hay `/load agente`**. En su lugar, cada fase asume un **rol**:

- **Fase 3 (Arquitectura)**: Eres arquitecto
- **Fase 5 (Scaffold)**: Eres scaffolder
- **Fase 6 (Auditoría)**: Eres auditor

Reasonix detecta automáticamente en qué fase estás y aplica los constraints correctos.
REASONIX_EOF
      fi
      echo "📄 REASONIX.md"
    fi
    [ ! -f "REASONIX_QUICK_START.md" ] && cp "$TMPDIR/REASONIX_QUICK_START.md" . && echo "📄 REASONIX_QUICK_START.md"
    [ ! -f "stack.md" ] && cp "$TMPDIR/config/stack.md" . && echo "📄 stack.md"

    # Git init
    if [ ! -d ".git" ]; then
      ensure_minimal_gitignore "$PROJ"
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
    cd "$PROJ" 2>/dev/null || cd .
    ln -sf -- "../.claude/skills" ".opencode/skills" 2>/dev/null || true
    echo "    🔗 Skills linked: .opencode/skills → .claude/skills"
    if [ ! -f "OPENCODE.md" ]; then
      if [ -f "$TMPDIR/OPENCODE.md" ]; then
        cp "$TMPDIR/OPENCODE.md" .
      else
        cat > OPENCODE.md << 'OPENCODE_EOF'
# AI App Builder — Instrucciones para OpenCode

Este proyecto usa el **AI App Builder** — un proceso profesional de 6 fases.

## Flujo principal

```bash
opencode
# Luego en el chat: /build-app quiero crear una aplicación para [tu idea]
```

## 6 Fases

1. **Discovery** → Descubridor extrae CU-XX
2. **PRD** → Analista define RF-XX
3. **Arquitectura** → Arquitecto diseña SDD (read-only en código)
4. **Mockup** → Diseñador crea mockups
5. **Scaffold** → Scaffolder genera código + tests
6. **Auditoría** → Auditor verifica trazabilidad

Usa `/load arquitecto`, `/load scaffolder`, `/load auditor` según la fase.
OPENCODE_EOF
      fi
      echo "    📄 OPENCODE.md"
    fi
    [ ! -f "opencode.json" ] && cp "$TMPDIR/opencode.json" . && echo "    📄 opencode.json"

    # Reasonix (con symlink)
    echo "  ✓ Fase 3: Reasonix"
    mkdir -p ".reasonix/agents"
    [ -d "$TMPDIR/.reasonix/agents" ] && cp -R "$TMPDIR/.reasonix/agents/"* ".reasonix/agents/" 2>/dev/null || true
    ln -sf -- "../.claude/skills" ".reasonix/skills" 2>/dev/null || true
    echo "    🔗 Skills linked: .reasonix/skills → .claude/skills"
    if [ ! -f "REASONIX.md" ]; then
      if [ -f "$TMPDIR/REASONIX.md" ]; then
        cp "$TMPDIR/REASONIX.md" .
      else
        cat > REASONIX.md << 'REASONIX_EOF'
# AI App Builder — Instrucciones para Reasonix

Este proyecto usa el **AI App Builder** — un proceso profesional de 6 fases.

## Flujo principal

```bash
reasonix /build-app quiero crear una aplicación para [tu idea]
```

## Agentes como roles

Fase 3: Eres **arquitecto** (read-only código, write architecture.md)
Fase 5: Eres **scaffolder** (full write/edit/bash)
Fase 6: Eres **auditor** (read-only código, write audit.md)
REASONIX_EOF
      fi
      echo "    📄 REASONIX.md"
    fi

    # Config común
    [ ! -f "stack.md" ] && cp "$TMPDIR/config/stack.md" . && echo "📄 stack.md"
    [ ! -f "model-profiles.md" ] && cp "$TMPDIR/config/model-profiles.md" . && echo "📄 model-profiles.md"

    # Git init
    if [ ! -d ".git" ]; then
      ensure_minimal_gitignore "$PROJ"
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
