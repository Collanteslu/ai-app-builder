# AGENTS.md — Cómo trabajar en este repo

> Esto es el **constructor** (la caja de herramientas), no una app generada.
> Las apps se construyen en otra carpeta usando estas skills. Ver `README.md`.

## Qué es

Conjunto de skills + template + scripts que conducen la creación de una app fase
por fase (Discovery → PRD → Arquitectura → Mockup → Scaffold → Auditoría) con
gates ejecutables y trazabilidad por ID `RF-XX`. Funciona en **opencode** (nativo)
y **Claude Code** (vía `.claude/skills` copiado por el instalador).

## Layout

```
skills/                 ← 41 skills: 9 app-* (orquestación) + 32 conocimiento
  INDEX.md              ← registro de skills (fuente de verdad de qué hay)
config/                 ← stack.md + model-profiles.md (plantillas que rellena el usuario)
template/               ← scaffold base Next.js que la Fase 5 copia a la app
  scripts/audit.mjs     ← gate de la Fase 6 (exit≠0 = crítico)
  scripts/trace-lint.mjs← gate de las Fases 2/3 (exit≠0 = hueco de trazabilidad)
  __tests__/            ← validan que el template y las skills están enteras
scripts/                ← instaladores multiplataforma (install/new-app/bootstrap/uninstall)
.opencode/              ← agents/, commands/, instructions/ (leídos por opencode)
.github/workflows/ci.yml← CI del constructor (ver abajo)
```

## Cómo validar tus cambios

Antes de dar por buena una edición en este repo, comprueba lo que aplique:

- **Skills**: `cd template && pnpm test` (corre `__tests__/skills-validate.test.ts`
  + `template-validate.test.ts`). Cubre frontmatter de SKILL.md, name==dir,
  descripción ≤1024 y archivos esenciales del template.
- **Sintaxis de scripts**: `node --check template/scripts/*.mjs`.
- **opencode.json válido**: `node -e "JSON.parse(require('fs').readFileSync('opencode.json','utf8'))"`.
- **Gates ejecutables**: `cd template && node scripts/audit.mjs` (debe exit 0
  sobre el template limpio) y `node scripts/trace-lint.mjs`.
- **CI local**: `.github/workflows/ci.yml` replica todo esto en GitHub. Si cambia
  un gate o una skill, ese CI es la red.

## Convenciones (resumen)

- **Idioma**: código en inglés, commits/comentarios/docs en español.
- **Commits**: Conventional Commits en español con emoji (`✨ feat:`, `🐛 fix:`,
  `♻️ refactor:`, `🔧 chore:`). Detalle por fase en `.opencode/instructions/`.
- **Versiones pinned, sin `^`**: el template fija versiones exactas; no introduzcas
  `^`/`~` en `template/package.json`.
- **No se commitea**: `node_modules/`, `.next/`, `*.tsbuildinfo`, `coverage/`,
  `.opencode/node_modules` (ya en gitignores).

## Añadir una skill de conocimiento

1. Crea `skills/<nombre>/SKILL.md` con frontmatter `name` (== dir) y `description`.
2. Añade una fila en `skills/INDEX.md` (qué hace y qué fase la cablea).
3. Si una fase `app-*` debe invocarla, nómbrala en esa skill.
4. El CI valida el frontmatter y que `INDEX.md` ↔ `skills/` están sincronizados.

## Cambiar el stack por defecto

El stack vive en `config/stack.md` y el template base en `template/`. Cambiar de
stack (p. ej. a Supabase/Drizzle) implica: añadir la skill nueva, apuntarla en
`INDEX.md`, ajustar `stack.md` y el `template/`. **Es un cambio mayor**: hazlo en
su propia rama y valida el CI entero.
