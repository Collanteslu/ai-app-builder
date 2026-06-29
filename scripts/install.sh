#!/usr/bin/env bash
# install.sh — instalador inteligente para AI App Builder (macOS / Linux)
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash
#
# Estrategia:
#   1. Pregunta qué plataforma: Claude Code (1), OpenCode (2), Ambas (3)
#   2. NO instala nada por defecto
#   3. Según la respuesta, copia a .claude/ o .opencode/
#   4. Si Ambas: crea symlinks para evitar duplicación
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJ="$(pwd)"

# ──────────────────────────────────────────────────────────────────────────
# Verificaciones previas
# ──────────────────────────────────────────────────────────────────────────

if ! command -v git &> /dev/null; then
  echo "❌ git no está instalado. Instálalo primero."
  exit 1
fi

# ──────────────────────────────────────────────────────────────────────────
# Preguntar plataforma (SIN INSTALAR POR DEFECTO)
# ──────────────────────────────────────────────────────────────────────────

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         AI App Builder — Selector de plataforma               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "¿Con cuál plataforma usarás el AI App Builder?"
echo ""
echo "  1) Claude Code (CLI / Desktop / Web app)"
echo "  2) OpenCode"
echo "  3) Ambas"
echo ""
read -p "Opción (1-3): " platform_choice

case "$platform_choice" in
  1|2|3) ;;
  *)
    echo "❌ Opción inválida. Debe ser 1, 2 o 3."
    exit 1
    ;;
esac

# ──────────────────────────────────────────────────────────────────────────
# Helpers para symlinks seguros
# ──────────────────────────────────────────────────────────────────────────

safe_symlink() {
  local target="$1"
  local link="$2"

  # Si el link existe y es symlink, verificar que apunta a lo correcto
  if [ -L "$link" ]; then
    local current=$(readlink "$link")
    if [ "$current" = "$target" ]; then
      echo "  ℹ️  symlink ya existe: $link → $target"
      return 0
    else
      echo "  ⚠️  symlink existente apunta a otro lado, reemplazando..."
      rm "$link"
    fi
  fi

  # Si existe como directorio, borrar y crear symlink
  if [ -d "$link" ] && [ ! -L "$link" ]; then
    echo "  🗑️  directorio existente, reemplazando con symlink..."
    rm -rf "$link"
  fi

  # Crear symlink
  ln -s "$target" "$link"
  echo "  ✅ symlink creado: $link → $target"
}

# ──────────────────────────────────────────────────────────────────────────
# OPCIÓN 1: Claude Code
# ──────────────────────────────────────────────────────────────────────────

install_claude_code() {
  echo ""
  echo "📦 Instalando para Claude Code..."
  echo ""

  # Crear .claude si no existe
  mkdir -p "$PROJ/.claude"

  # Instalar skills
  echo "  • Instalando skills..."
  rm -rf "$PROJ/.claude/skills"
  mkdir -p "$PROJ/.claude/skills"
  cp -R "$REPO/skills"/* "$PROJ/.claude/skills/"
  count=$(find "$REPO/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  echo "    ✅ $count skills instaladas"

  # Instalar template
  echo "  • Instalando template..."
  rm -rf "$PROJ/.claude/template"
  mkdir -p "$PROJ/.claude/template"
  find "$REPO/template" -maxdepth 1 -mindepth 1 \
    ! -name "node_modules" ! -name ".next" \
    -exec cp -R {} "$PROJ/.claude/template/" \;
  echo "    ✅ template instalado"

  # Crear CLAUDE.md (NO sobrescribir si existe)
  if [ ! -f "$PROJ/CLAUDE.md" ]; then
    cp "$REPO/CLAUDE.md" "$PROJ/CLAUDE.md" 2>/dev/null || cat > "$PROJ/CLAUDE.md" << 'EOF'
# Instrucciones para Claude Code

Este proyecto usa el **AI App Builder** — un proceso estructurado de 6 fases
para construir aplicaciones con trazabilidad de requisitos (RF-XX).

## Flujo principal

Abre Claude Code en esta carpeta y escribe:

```
Quiero crear una aplicación para [tu idea]
```

O la frase inequívoca:

```
inicia el constructor de apps
```

## Roles de Claude por fase

Claude Code NO tiene agentes formales. En cada fase, yo juego un rol:

1. **Discovery** → descubridor (extrae CU-XX)
2. **PRD** → analista (define RF-XX con criterios)
3. **Arquitectura** → arquitecto (diseño SDD, NO código)
4. **Mockup** → diseñador (mockups navegables)
5. **Scaffold** → scaffolder (código + tests TDD)
6. **Auditoría** → auditor (verifico, NO modifico)

## Gates ejecutables

- `pnpm trace:builder` — verifica trazabilidad (F2, F3)
- `pnpm audit:builder` — verifica wiring y calidad (F5, F6)
- `pnpm audit:wiring` — verifica fetch → endpoint (F5)

Todos deben pasar (exit 0) antes de avanzar.

## Configuración

Edita `stack.md` antes de empezar (define tech stack, Auth, Infra).

---

Para más detalles: `.claude/skills/app-orchestrator/SKILL.md`
EOF
    echo "    ✅ CLAUDE.md creado"
  else
    echo "    ℹ️  CLAUDE.md ya existe, no se sobrescribió"
  fi

  # Copiar stack.md y model-profiles.md si no existen
  for f in stack.md model-profiles.md; do
    if [ ! -f "$PROJ/$f" ] && [ -f "$REPO/config/$f" ]; then
      cp "$REPO/config/$f" "$PROJ/$f"
      echo "    📄 $f copiado"
    fi
  done

  # git init y commit inicial si es nuevo
  if [ ! -d "$PROJ/.git" ]; then
    cd "$PROJ"
    git init -q
    echo "    🔧 git init"
    # Crear commit inicial de bootstrap
    git add -A
    git commit -q -m "chore: bootstrap opencode builder" 2>/dev/null || true
    echo "    ✅ commit inicial creado"
  fi

  echo ""
  echo "✅ Instalación completada para Claude Code"
  echo ""
  echo "Próximos pasos:"
  echo "  1. Edita stack.md (define tu tech stack, Auth, Infra)"
  echo "  2. Abre Claude Code en esta carpeta"
  echo "  3. Escribe: 'Quiero crear una aplicación para [tu idea]'"
}

# ──────────────────────────────────────────────────────────────────────────
# OPCIÓN 2: OpenCode
# ──────────────────────────────────────────────────────────────────────────

install_opencode() {
  echo ""
  echo "📦 Instalando para OpenCode..."
  echo ""

  # Crear .opencode si no existe
  mkdir -p "$PROJ/.opencode"

  # Instalar agentes
  echo "  • Instalando agentes..."
  rm -rf "$PROJ/.opencode/agents"
  cp -R "$REPO/.opencode/agents" "$PROJ/.opencode/"
  echo "    ✅ agentes instalados"

  # Instalar instructions
  echo "  • Instalando instrucciones..."
  rm -rf "$PROJ/.opencode/instructions"
  cp -R "$REPO/.opencode/instructions" "$PROJ/.opencode/"
  echo "    ✅ instrucciones instaladas"

  # Instalar commands
  echo "  • Instalando comandos..."
  rm -rf "$PROJ/.opencode/commands"
  cp -R "$REPO/.opencode/commands" "$PROJ/.opencode/"
  echo "    ✅ comandos instalados"

  # Instalar skills
  echo "  • Instalando skills..."
  rm -rf "$PROJ/.opencode/skills"
  mkdir -p "$PROJ/.opencode/skills"
  cp -R "$REPO/skills"/* "$PROJ/.opencode/skills/"
  count=$(find "$REPO/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  echo "    ✅ $count skills instaladas"

  # Instalar template
  echo "  • Instalando template..."
  rm -rf "$PROJ/.opencode/template"
  mkdir -p "$PROJ/.opencode/template"
  find "$REPO/template" -maxdepth 1 -mindepth 1 \
    ! -name "node_modules" ! -name ".next" \
    -exec cp -R {} "$PROJ/.opencode/template/" \;
  echo "    ✅ template instalado"

  # Copiar opencode.json (NO sobrescribir si existe)
  if [ ! -f "$PROJ/opencode.json" ]; then
    cp "$REPO/opencode.json" "$PROJ/opencode.json"
    echo "    ✅ opencode.json copiado"
  else
    echo "    ℹ️  opencode.json ya existe, no se sobrescribió"
  fi

  # Crear OPENCODE.md (NO sobrescribir si existe)
  if [ ! -f "$PROJ/OPENCODE.md" ]; then
    cat > "$PROJ/OPENCODE.md" << 'EOF'
# Instrucciones para OpenCode

Este proyecto usa el **AI App Builder** en OpenCode.

## Agentes especializados

OpenCode (o Reasonix) tiene 3 agentes formales con permisos limitados:

1. **arquitecto** (Fase 3): diseña SDD, read-only en código
   - Ubicado en: `.opencode/agents/arquitecto.md`
   - Se invoca automáticamente en Fase 3 del flujo

2. **scaffolder** (Fase 5): genera código, write/edit/bash/browser
   - Ubicado en: `.opencode/agents/scaffolder.md`
   - Se invoca automáticamente en Fase 5 del flujo

3. **auditor** (Fase 6): verifica trazabilidad, read-only
   - Ubicado en: `.opencode/agents/auditor.md`
   - Se invoca automáticamente en Fase 6 del flujo

**Nota:** La sintaxis específica para invocar agentes depende de tu plataforma:
- En OpenCode tradicional: `/load agente`
- En Reasonix o plataformas similares: usa la sintaxis nativa de esa herramienta
- El orquestador se encarga de cargar el agente correcto en el momento correcto

## Flujo principal

Usa el comando principal de tu plataforma:

```
/build-app quiero crear una aplicación para [tu idea]
```

(O el equivalente en tu herramienta: opencode, reasonix, etc.)

## Gates ejecutables

- `pnpm trace:builder` — verifica trazabilidad (F2, F3)
- `pnpm audit:builder` — verifica wiring y calidad (F5, F6)
- `pnpm audit:wiring` — verifica fetch → endpoint (F5)

## Configuración

Edita `stack.md` antes de empezar (define tech stack, Auth, Infra).

---

Para más detalles: `.opencode/instructions/` y `.opencode/skills/app-orchestrator/SKILL.md`
EOF
    echo "    ✅ OPENCODE.md creado"
  else
    echo "    ℹ️  OPENCODE.md ya existe, no se sobrescribió"
  fi

  # Copiar stack.md y model-profiles.md si no existen
  for f in stack.md model-profiles.md; do
    if [ ! -f "$PROJ/$f" ] && [ -f "$REPO/config/$f" ]; then
      cp "$REPO/config/$f" "$PROJ/$f"
      echo "    📄 $f copiado"
    fi
  done

  # git init y commit inicial si es nuevo
  if [ ! -d "$PROJ/.git" ]; then
    cd "$PROJ"
    git init -q
    echo "    🔧 git init"
    # Crear commit inicial de bootstrap
    git add -A
    git commit -q -m "chore: bootstrap opencode builder" 2>/dev/null || true
    echo "    ✅ commit inicial creado"
  fi

  echo ""
  echo "✅ Instalación completada para OpenCode"
  echo ""
  echo "Próximos pasos:"
  echo "  1. Edita stack.md (define tu tech stack, Auth, Infra)"
  echo "  2. Abre OpenCode en esta carpeta"
  echo "  3. Escribe: '/build-app quiero crear una aplicación para [tu idea]'"
}

# ──────────────────────────────────────────────────────────────────────────
# OPCIÓN 3: Ambas (Claude Code + OpenCode con symlinks)
# ──────────────────────────────────────────────────────────────────────────

install_both() {
  echo ""
  echo "📦 Instalando para Claude Code + OpenCode (con symlinks)..."
  echo ""

  # Primero, instalar en .claude/ (como principal)
  echo "  • Instalando en .claude/ (principal)..."
  mkdir -p "$PROJ/.claude"

  # Instalar skills en .claude/
  rm -rf "$PROJ/.claude/skills"
  mkdir -p "$PROJ/.claude/skills"
  cp -R "$REPO/skills"/* "$PROJ/.claude/skills/"
  count=$(find "$REPO/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  echo "    ✅ $count skills en .claude/skills"

  # Instalar template en .claude/
  rm -rf "$PROJ/.claude/template"
  mkdir -p "$PROJ/.claude/template"
  find "$REPO/template" -maxdepth 1 -mindepth 1 \
    ! -name "node_modules" ! -name ".next" \
    -exec cp -R {} "$PROJ/.claude/template/" \;
  echo "    ✅ template en .claude/template"

  # Ahora instalar OpenCode (agentes, instructions, commands)
  echo "  • Instalando en .opencode/ (agentes + instrucciones)..."
  mkdir -p "$PROJ/.opencode"

  rm -rf "$PROJ/.opencode/agents"
  cp -R "$REPO/.opencode/agents" "$PROJ/.opencode/"
  echo "    ✅ agentes instalados"

  rm -rf "$PROJ/.opencode/instructions"
  cp -R "$REPO/.opencode/instructions" "$PROJ/.opencode/"
  echo "    ✅ instrucciones instaladas"

  rm -rf "$PROJ/.opencode/commands"
  cp -R "$REPO/.opencode/commands" "$PROJ/.opencode/"
  echo "    ✅ comandos instalados"

  # Crear symlinks desde .opencode/ hacia .claude/
  echo "  • Creando symlinks (sin duplicación de skills/template)..."
  safe_symlink "../.claude/skills" "$PROJ/.opencode/skills"
  safe_symlink "../.claude/template" "$PROJ/.opencode/template"

  # Copiar opencode.json
  if [ ! -f "$PROJ/opencode.json" ]; then
    cp "$REPO/opencode.json" "$PROJ/opencode.json"
    echo "    ✅ opencode.json copiado"
  else
    echo "    ℹ️  opencode.json ya existe, no se sobrescribió"
  fi

  # Crear CLAUDE.md y OPENCODE.md
  if [ ! -f "$PROJ/CLAUDE.md" ]; then
    cat > "$PROJ/CLAUDE.md" << 'EOF'
# Instrucciones para Claude Code

Este proyecto soporta AMBAS plataformas: Claude Code y OpenCode.

## Para Claude Code

Abre Claude Code en esta carpeta y escribe:

```
Quiero crear una aplicación para [tu idea]
```

Los skills están en `.claude/skills/`.

## Roles de Claude

En cada fase, yo juego un rol:
- Fase 3: arquitecto (diseño SDD, sin código)
- Fase 5: scaffolder (código + tests TDD)
- Fase 6: auditor (verifico, sin modificar)

## Configuración

Edita `stack.md` antes de empezar.

---

Para más detalles: `.claude/skills/app-orchestrator/SKILL.md`
EOF
    echo "    ✅ CLAUDE.md creado"
  else
    echo "    ℹ️  CLAUDE.md ya existe"
  fi

  if [ ! -f "$PROJ/OPENCODE.md" ]; then
    cat > "$PROJ/OPENCODE.md" << 'EOF'
# Instrucciones para OpenCode

Este proyecto soporta AMBAS plataformas: Claude Code y OpenCode.

## Para OpenCode

Abre OpenCode en esta carpeta y escribe:

```
/build-app quiero crear una aplicación para [tu idea]
```

Los agentes están en `.opencode/agents/` y los skills en `.opencode/skills/` (symlink a `.claude/skills/`).

## Agentes

- `/load arquitecto` (Fase 3)
- `/load scaffolder` (Fase 5)
- `/load auditor` (Fase 6)

## Configuración

Edita `stack.md` antes de empezar.

---

Para más detalles: `.opencode/skills/app-orchestrator/SKILL.md`
EOF
    echo "    ✅ OPENCODE.md creado"
  else
    echo "    ℹ️  OPENCODE.md ya existe"
  fi

  # Copiar stack.md y model-profiles.md
  for f in stack.md model-profiles.md; do
    if [ ! -f "$PROJ/$f" ] && [ -f "$REPO/config/$f" ]; then
      cp "$REPO/config/$f" "$PROJ/$f"
      echo "    📄 $f copiado"
    fi
  done

  # git init
  if [ ! -d "$PROJ/.git" ]; then
    cd "$PROJ"
    git init -q
    echo "    🔧 git init"
  fi

  echo ""
  echo "✅ Instalación completada para Claude Code + OpenCode"
  echo ""
  echo "Próximos pasos:"
  echo "  1. Edita stack.md"
  echo "  2. Para Claude Code: abre Claude Code y escribe tu idea"
  echo "  3. Para OpenCode: abre OpenCode y escribe: /build-app [tu idea]"
}

# ──────────────────────────────────────────────────────────────────────────
# Ejecutar según opción
# ──────────────────────────────────────────────────────────────────────────

case "$platform_choice" in
  1) install_claude_code ;;
  2) install_opencode ;;
  3) install_both ;;
esac

echo ""
echo "⚠️  Importante: stack.md tiene placeholders (definir: ...) para Auth e Infra."
echo "   Estos se rellenarán automáticamente al iniciar Fase 0/1 del proceso."
echo "   Si quieres definirlos ahora, adelante. Si no, el orquestador lo hará."
echo ""
