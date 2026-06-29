# Estrategia de instalación — AI App Builder

## Principios

1. **Sin instalar nada por defecto** — preguntar primero
2. **Separación clara** — cada plataforma en su directorio
3. **Sin duplicación** — si elige Ambas, usar symlink (no copiar skills dos veces)
4. **Independencia** — si elige solo una plataforma, funciona sin la otra

---

## Flujo de instalación

### Paso 1: Preguntar plataforma

```
¿Con cuál plataforma usarás el AI App Builder?
  1) Claude Code (CLI / Desktop / Web app)
  2) OpenCode
  3) Ambas
Opción (1-3):
```

**NO instalar nada hasta que responda.**

---

### Paso 2: Según la respuesta

#### Opción 1: Claude Code
```
.claude/
├── skills/          ← copia de repo/skills
├── template/        ← copia de repo/template
└── CLAUDE.md        ← instrucciones (NO sobrescribir si existe)

Raíz:
├── CLAUDE.md        ← instrucciones para Claude Code
├── stack.md         ← si no existe
├── model-profiles.md ← si no existe
└── .git             ← init si no existe
```

**NO instala:** `.opencode/`, `opencode.json`, `OPENCODE.md`

---

#### Opción 2: OpenCode
```
.opencode/
├── agents/          ← copia de repo/.opencode/agents
├── instructions/    ← copia de repo/.opencode/instructions
├── commands/        ← copia de repo/.opencode/commands
└── skills/          ← copia de repo/skills
└── template/        ← copia de repo/template

Raíz:
├── OPENCODE.md      ← instrucciones para OpenCode
├── opencode.json    ← copia de repo/opencode.json (NO sobrescribir si existe)
├── stack.md         ← si no existe
├── model-profiles.md ← si no existe
└── .git             ← init si no existe
```

**NO instala:** `.claude/`, `CLAUDE.md`

---

#### Opción 3: Ambas (Claude Code + OpenCode)
```
.claude/
├── skills/          ← copia de repo/skills
├── template/        ← copia de repo/template

.opencode/
├── agents/          ← copia de repo/.opencode/agents
├── instructions/    ← copia de repo/.opencode/instructions
├── commands/        ← copia de repo/.opencode/commands
├── skills/          ← SYMLINK a ../.claude/skills (NO copia)
└── template/        ← SYMLINK a ../.claude/template (NO copia)

Raíz:
├── CLAUDE.md        ← instrucciones para Claude Code
├── OPENCODE.md      ← instrucciones para OpenCode
├── opencode.json    ← copia de repo/opencode.json
├── stack.md         ← si no existe
├── model-profiles.md ← si no existe
└── .git             ← init si no existe
```

**Ventaja de symlinks:** Ambas plataformas comparten skills/template. Si actualizas en `.claude/`, OpenCode ve los cambios automáticamente.

---

## Detalles técnicos

### Symlinks

**Bash (macOS/Linux):**
```bash
ln -s ../\.claude/skills .opencode/skills
ln -s ../\.claude/template .opencode/template
```

**PowerShell (Windows):**
```powershell
New-Item -ItemType SymbolicLink -Path .opencode\skills -Target ..\\.claude\skills
New-Item -ItemType SymbolicLink -Path .opencode\template -Target ..\\.claude\template
```

**Manejo de errores:**
- Si `.opencode/skills` ya existe (y no es symlink), borrar y crear symlink
- Si el symlink ya existe, NO recrear

### Archivos que NO se sobrescriben

- `CLAUDE.md` (si ya existe)
- `OPENCODE.md` (si ya existe)
- `opencode.json` (solo en Opción 2)
- `stack.md` (si ya existe)
- `model-profiles.md` (si ya existe)

### Directorios que sí se limpian

- `.claude/skills/` — borra contenido anterior, copia nuevos
- `.claude/template/` — borra contenido anterior, copia nuevos
- `.opencode/` — borra contenido anterior (excepto skills/template si son symlinks)

---

## Salida esperada

**Opción 1 (Claude Code):**
```
✅ 41 skills instaladas en .claude/skills
✅ template instalado en .claude/template
✅ CLAUDE.md creado (no sobrescrito si existía)
📄 stack.md copiado
📄 model-profiles.md copiado
🔧 git init (si no existía)

Próximo paso: edita stack.md y abre Claude Code
```

**Opción 2 (OpenCode):**
```
✅ .opencode/agents instalado
✅ .opencode/instructions instalado
✅ .opencode/commands instalado
✅ 41 skills instaladas en .opencode/skills
✅ template instalado en .opencode/template
✅ OPENCODE.md creado (no sobrescrito si existía)
✅ opencode.json copiado
📄 stack.md copiado
📄 model-profiles.md copiado
🔧 git init (si no existía)

Próximo paso: edita stack.md y abre OpenCode
```

**Opción 3 (Ambas):**
```
✅ .claude/skills instalado (41 skills)
✅ .claude/template instalado
✅ .opencode/agents instalado
✅ .opencode/instructions instalado
✅ .opencode/commands instalado
✅ .opencode/skills symlink creado → ../.claude/skills
✅ .opencode/template symlink creado → ../.claude/template
✅ CLAUDE.md creado
✅ OPENCODE.md creado
✅ opencode.json copiado
📄 stack.md copiado
📄 model-profiles.md copiado
🔧 git init (si no existía)

Próximo paso: edita stack.md
- Para Claude Code: abre Claude Code
- Para OpenCode: abre OpenCode
```

---

## Casos edge

### Si el usuario presiona Ctrl+C sin responder
→ No instalar nada. Script termina.

### Si .claude/ ya existe con skills viejos
→ Borrar `.claude/skills` y `.claude/template` completamente, instalar nuevos.

### Si .opencode/ existe (Opción 3)
→ Borrar `.opencode/agents`, `.opencode/instructions`, `.opencode/commands`, pero:
  - Si `.opencode/skills` es symlink → NO tocar
  - Si `.opencode/skills` es directorio → borrar y crear symlink
  - Si `.opencode/template` es symlink → NO tocar
  - Si `.opencode/template` es directorio → borrar y crear symlink

### Si opencode.json existe
→ NO sobrescribir. Informar al usuario: "opencode.json ya existe, no se sobrescribió"

### Si stack.md existe
→ NO sobrescribir. Informar: "stack.md ya existe, no se sobrescribió"

---

## Plataformas soportadas

- **Windows:** PowerShell 7+ (scripts/bootstrap.ps1)
- **macOS:** Bash 4+ (scripts/install.sh)
- **Linux:** Bash 4+ (scripts/install.sh)

Ambos scripts verifican que `git` está instalado antes de empezar.

