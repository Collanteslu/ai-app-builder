# AI App Builder + Reasonix — Quick Start

## Instalación (5 minutos)

### macOS / Linux
```bash
cd ~/tu-proyecto-nuevo
bash <(curl -fsSL https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/reasonix-init.sh)
```

### Windows (PowerShell)
```powershell
cd ~\tu-proyecto-nuevo
irm https://raw.githubusercontent.com/Collanteslu/ai-app-builder/v2/scripts/reasonix-init.ps1 | iex
```

## Post-instalación

```bash
# 1. Configura Reasonix
export DEEPSEEK_API_KEY=sk-...  # O edita reasonix.toml

# 2. Edita stack.md (opcional, puede rellenarse en Fase 0/1)
nano stack.md

# 3. Inicia el proceso
reasonix
```

En el chat de Reasonix:
```
/build-app Quiero crear un sistema de gestión de tareas con roles
```

## 6 Fases — Cómo funciona

| Fase | Tú eres... | Produces | Gate |
|------|-----------|----------|------|
| 1 | Descubridor | `.builder/discovery.md` (CU-XX) | — |
| 2 | Analista | `.builder/prd.md` (RF-XX) | `pnpm trace:builder` |
| 3 | **ARQUITECTO** | `.builder/architecture.md` | `pnpm trace:builder` |
| 4 | Diseñador | `design-system.md` + `mockup/` | — |
| 5 | **SCAFFOLDER** | Código + tests | `audit:builder` + `audit:wiring` |
| 6 | **AUDITOR** | `.builder/audit.md` | `audit:builder` |

**Roles especiales (constraints automáticos):**
- **Fase 3:** read-only en código, write en architecture.md + memory
- **Fase 5:** full write/edit/bash/browser
- **Fase 6:** read-only en código, write en audit.md + memory

## Gates — No se saltan

```bash
# Fase 2/3 — Trazabilidad de requisitos
pnpm trace:builder

# Fase 5 — Wiring + inline data
pnpm audit:builder
pnpm audit:wiring

# Fase 6 — Auditoría final
pnpm audit:builder
```

**Si un gate falla, hay un problema real. Arréglalo.**

## Memory — Memoria entre sesiones

Captura decisiones, gotchas, restricciones en `.builder/memory/`:

```bash
# Durante Fase 3: documentar decisión
/app-memory capture "decision" "Por qué elegimos Prisma en lugar de Drizzle" "RF-01"

# Durante Fase 5: documentar gotcha
/app-memory capture "gotcha" "NextJS 16 tiene delay en compilación con Prisma... usar inline" "RF-05"

# Durante Fase 6: documentar restricción
/app-memory capture "constraint" "RGPD: usuarios UK requieren consentimiento explícito" "RNF-02"
```

Reasonix carga memory automáticamente (prefix cache native de DeepSeek = barato).

## Commits — Por fase

```bash
# Al cerrar cada fase
git commit -m "✨ fase 3: architecture.md (RF-01..RF-08)"
git commit -m "✨ fase 5: scaffold (slices A, B, C)"
git commit -m "✨ fase 6: audit.md (cero críticos)"
```

## Estructura de carpetas

```
./
├── REASONIX.md                  ← Instrucciones (este archivo en el proyecto)
├── reasonix.toml                ← Config de Reasonix
├── stack.md                     ← Config técnica
├── .reasonix/
│   ├── agents/                  ← arquitecto.md, scaffolder.md, auditor.md
│   ├── skills/                  ← 41 skills
│   ├── template/                ← Next.js template
│   └── AGENTS.md                ← Estado del proyecto
├── .builder/
│   ├── discovery.md             ← Casos de uso (Fase 1)
│   ├── prd.md                   ← Requisitos (Fase 2)
│   ├── architecture.md          ← SDD (Fase 3)
│   ├── mockup/                  ← HTML navegables (Fase 4)
│   ├── audit.md                 ← Auditoría final (Fase 6)
│   ├── progress.md              ← Estado de avance
│   └── memory/                  ← Decisiones + gotchas
├── src/                         ← Código (Fase 5)
├── prisma/                      ← Modelo de datos
└── .git/
```

## Workflow profesional

### Entrada a Fase 3 (Arquitectura)

```
1. Lee PRD (.builder/prd.md)
2. Ejecuta recall: /app-memory recall
3. Diseña: entidades, endpoints, threat model
4. Docume en architecture.md
5. Gate: pnpm trace:builder ← debe salir exit 0
6. Commit: git commit -m "✨ fase 3: architecture.md"
7. Handoff al orquestador
```

**Constraints en Fase 3:** NO escribas código fuente, solo design.

### Entrada a Fase 5 (Scaffold)

```
1. Lee architecture (.builder/architecture.md)
2. Ejecuta recall: /app-memory recall
3. Copia template: cp -r .reasonix/template/* ./
4. pnpm install
5. Codifica por slices (prioridad alta primero)
6. TDD triple bucle: API test → Service test → UI test
7. Gates:
   - pnpm audit:builder ← exit 0
   - pnpm audit:wiring ← exit 0
   - pnpm test:run ← todos en verde
8. Commit: git commit -m "✨ fase 5: scaffold (slices A, B, C)"
9. Handoff al orquestador
```

**Constraints en Fase 5:** Tienes acceso completo (write/edit/bash/browser).

### Entrada a Fase 6 (Auditoría)

```
1. Lee todo (.builder/ completo)
2. Ejecuta recall: /app-memory recall
3. Ejecuta gates:
   - pnpm audit:builder ← exit 0
   - pnpm audit:wiring ← exit 0
   - pnpm test:run ← todos en verde
4. Verifica manualmente:
   - Trazabilidad RF→código
   - CREATE/EDIT symmetry (si CRUD)
   - Seed IDs correctos
   - Auth real (no simulado)
5. Documenta en audit.md
6. Gate final: pnpm audit:builder ← exit 0
7. Commit: git commit -m "✨ fase 6: audit.md (cero críticos)"
8. Handoff final al usuario
```

**Constraints en Fase 6:** read-only en código, write en audit.md + memory.

## Stack por defecto

```
Frontend: Next.js 16.2.9 + React 19.1.2 + TypeScript 6.0.3 + Tailwind 4.3.1
Backend: Next.js API Routes
ORM: Prisma 7.8.0
Testing: Vitest 4.1.9 (unit) + Playwright 1.61.1 (e2e)
Auth: NextAuth (configurable)
Infra: Vercel (configurable)
```

Configurable en `stack.md`.

## Troubleshooting

### reasonix no se instala
```bash
npm i -g reasonix
# O descarga desde: https://github.com/esengine/DeepSeek-Reasonix/releases
```

### DEEPSEEK_API_KEY no funciona
```bash
# Verifica que está seteada
echo $DEEPSEEK_API_KEY

# O rellena en reasonix.toml
nano reasonix.toml
```

### Gate falla (audit:builder exit 1)
```bash
# Lee la salida del gate
pnpm audit:builder

# Arreglalo
# (probablemente: inline data, fetch sin endpoint, ou validate con Zod)

# Reintenta
pnpm audit:builder
```

### No recuerda memory entre sesiones
```bash
# Verifica que .builder/memory/ existe
ls -la .builder/memory/

# Haz recall explícito
reasonix
# En el chat: /app-memory recall
```

## Recursos

- **REASONIX.md** — instrucciones completas (en tu proyecto)
- **REASONIX_INTEGRATION.md** — detalles técnicos de la integración
- **stack.md** — configuración de tu proyecto
- **Reasonix oficial:** https://github.com/esengine/DeepSeek-Reasonix
- **AI App Builder:** https://github.com/Collanteslu/ai-app-builder

## ¡Listo!

Ejecuta:
```bash
reasonix /build-app Tu idea aquí
```

Reasonix te guiará por las 6 fases. ¡A construir! 🚀
