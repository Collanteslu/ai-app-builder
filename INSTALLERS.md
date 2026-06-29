# Instaladores — AI App Builder

Hay dos formas de instalar AI App Builder:

## Opción 1: Master Installer (recomendado — elige plataforma)

El **master installer** pregunta qué plataforma quieres y ejecuta el instalador correspondiente.

### macOS / Linux
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/ai-builder-init.sh)
```

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/ai-builder-init.ps1 | iex
```

**Te pregunta:**
```
¿Con cuál plataforma quieres trabajar?

  1) Claude Code (CLI / Desktop / Web app)
  2) OpenCode
  3) Reasonix (DeepSeek-native)
  4) Múltiples (todas las plataformas)
```

Luego instala **solo lo que pidió**.

---

## Opción 2: Instaladores específicos (si ya sabes qué plataforma)

### Claude Code

**macOS / Linux:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/install.sh) --project
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/bootstrap.ps1 | iex
```

Instala:
- `.claude/skills/` (41 skills)
- `.claude/template/` (Next.js template pinned)
- `CLAUDE.md` (instrucciones)
- `stack.md`, `model-profiles.md`
- `.gitignore`, `git init + commit`

---

### OpenCode

**macOS / Linux:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/install.sh) --project
# Selecciona opción 2 cuando pregunte
```

**Windows:**
OpenCode funciona mejor en POSIX. Usa WSL/Git Bash o descarga manualmente del repo.

Instala:
- `.opencode/agents/` (arquitecto, scaffolder, auditor)
- `.opencode/skills/` (41 skills)
- `.opencode/commands/`, `.opencode/instructions/`
- `OPENCODE.md` (instrucciones)
- `opencode.json`, `stack.md`
- `.gitignore`, `git init + commit`

---

### Reasonix

**macOS / Linux:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/reasonix-init.sh)
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/reasonix-init.ps1 | iex
```

Instala:
- `.reasonix/agents/` (arquitecto, scaffolder, auditor)
- `.reasonix/skills/` (41 skills)
- `.reasonix/template/` (Next.js template pinned)
- `REASONIX.md` (instrucciones)
- `reasonix.toml`, `stack.md`
- `.gitignore`, `git init + commit`

---

## Múltiples plataformas (en el mismo proyecto)

Si quieres trabajar con **Claude Code + OpenCode + Reasonix** simultáneamente:

**macOS / Linux:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/ai-builder-init.sh)
# Selecciona opción 4
```

**Windows:**
```powershell
irm https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/ai-builder-init.ps1 | iex
# Selecciona opción 4
```

**Esto instala:**
- `.claude/` (skills, template)
- `.opencode/` (agents, skills, commands, instructions)
- `.reasonix/` (agents, skills, template)
- `CLAUDE.md`, `OPENCODE.md`, `REASONIX.md`
- Symlinks inteligentes para evitar duplicación
- `.gitignore` robusto
- `git init + commit`

**Ventaja:** Las 3 plataformas comparten skills/template vía symlinks. Si actualizas en `.claude/`, las otras lo ven automáticamente.

---

## Post-instalación

### Configura el stack

```bash
nano stack.md
# Define: Tech Stack, Auth, Infra, Restricciones
```

### Configura la plataforma (si es Reasonix)

```bash
nano reasonix.toml
# Rellena: DEEPSEEK_API_KEY (o export DEEPSEEK_API_KEY=sk-...)
```

### Inicia el proceso

**Claude Code:**
```bash
# Abre Claude Code en esta carpeta
# Escribe: "Quiero crear una aplicación para [tu idea]"
```

**OpenCode:**
```bash
# Abre OpenCode en esta carpeta
# Escribe: "/build-app quiero crear una aplicación para [tu idea]"
```

**Reasonix:**
```bash
reasonix
# En el chat: "/build-app quiero crear una aplicación para [tu idea]"
```

---

## Documentación por plataforma

Después de instalar, lee:

- **Claude Code:** `CLAUDE.md`
- **OpenCode:** `OPENCODE.md`
- **Reasonix:** `REASONIX.md` o `REASONIX_QUICK_START.md`
- **Técnico (integración Reasonix):** `REASONIX_INTEGRATION.md`

---

## Troubleshooting

### Error: "curl: no encontrado"
En Windows, usa PowerShell en lugar de bash.

### Error: "git no instalado"
Descarga Git desde https://git-scm.com/

### Error: "reasonix no encontrado"
```bash
npm i -g reasonix
# O descarga desde https://github.com/esengine/DeepSeek-Reasonix
```

### .opencode no se instaló en Windows
OpenCode funciona mejor en POSIX. Usa WSL o descarga manualmente el repo.

---

## Qué instala cada plataforma

| Componente | Claude Code | OpenCode | Reasonix |
|------------|-------------|----------|----------|
| Agentes especializados | Roles (implícitos) | ✅ `.opencode/agents/` | ✅ `.reasonix/agents/` |
| Skills (41 total) | ✅ `.claude/skills/` | ✅ `.opencode/skills/` | ✅ `.reasonix/skills/` |
| Template (Next.js) | ✅ `.claude/template/` | `.opencode/template/` | ✅ `.reasonix/template/` |
| Instrucciones | `CLAUDE.md` | `OPENCODE.md` | `REASONIX.md` |
| Config principal | `stack.md` | `opencode.json` | `reasonix.toml` |
| Memory entre sesiones | `.builder/memory/` | `.builder/memory/` | `.builder/memory/` |
| Gates ejecutables | `trace-lint.mjs`, `audit.mjs` | `trace-lint.mjs`, `audit.mjs` | `trace-lint.mjs`, `audit.mjs` |

---

## Flujo de instalación

```
Usuario ejecuta master installer
    ↓
¿Qué plataforma? (1-4)
    ↓
    ├─ Claude Code    → bootstrap.ps1 / install.sh (opción 1)
    ├─ OpenCode       → install.sh (opción 2)
    ├─ Reasonix       → reasonix-init.ps1 / reasonix-init.sh
    └─ Múltiples      → Ejecuta todos 3
    ↓
Copia: agentes, skills, template, config
    ↓
Crea: INSTRUCCIONES.md, .gitignore
    ↓
git init + commit 'chore: bootstrap [plataforma]'
    ↓
Muestra: "Próximos pasos" (editar stack.md, lanzar plataforma)
```

---

**Recomendación:** Usa el **master installer** si no estás seguro qué plataforma elegir. Te deja elegir interactivamente.
