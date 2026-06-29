# Índice de skills

Dos capas (ver README): **9 de orquestación** (`app-*`, el proceso) y **32 de
conocimiento** (referencia que las fases invocan). Este índice es el **registro**
que el orquestador lee al arrancar para saber qué skills hay disponibles y en qué
fase encaja cada una: para qué sirven, qué fase las usa y de dónde se copiaron
(para poder re-sincronizarlas, ver `scripts/sync-skills.sh`).

> Última sincronización: 2026-06-26 (fuente: ~/.agents/skills)
> La columna "Fase(s)" refleja dónde está **cableada** la skill (la nombra esa
> `app-*`), no dónde sería relevante. Es descriptiva, para poder podar con verdad.

## Skills de orquestación (el proceso)

| Skill | Fase |
|-------|------|
| `app-orchestrator` | Director |
| `app-brainstorm` | 0 *(opcional)* |
| `app-discovery` | 1 |
| `app-prd` | 2 |
| `app-architecture` | 3 |
| `app-mockup` | 4 |
| `app-scaffold` | 5 |
| `app-audit` | 6 |
| `app-memory` | Transversal (recall + capture en todas las fases) |

## Skills de conocimiento (referencia invocable)

Fuente de todas: `~/.agents/skills/<skill>` (copia local; re-sincroniza con el script).

| Skill | Fase(s) que la usa | Propósito |
|-------|--------------------|-----------|
| `accessibility-a11y` | 4, 5, 6 | WCAG y UI accesible |
| `api-design-principles` | 3 | Diseño de API REST/GraphQL |
| `api-development` | 5 | Principios de API aplicados a Next.js API Routes (la skill cubre NestJS/Go; aquí se usa solo el criterio de diseño) |
| `auth-implementation-patterns` | 3 | Patrones de auth (JWT, OAuth, sesiones, RBAC) |
| `code-review-excellence` | 6 | Revisión de código |
| `debugging-strategies` | 5 | Depuración sistemática / causa raíz |
| `design-system-patterns` | 4 | Tokens y theming del sistema de diseño |
| `e2e-testing-patterns` | 5 | Tests end-to-end |
| `error-handling-patterns` | 3, 5 | Manejo de errores robusto |
| `interaction-design` | 4 | Microinteracciones y motion |
| `javascript-testing-patterns` | 5 | Tests unit/integración JS/TS |
| `jwt-security` | 3 | JWT seguro |
| `logging-best-practices` | 3 | Logging estructurado / auditoría |
| `nextauth-authentication` | 3 | NextAuth (Auth.js) |
| `nextjs-app-router-patterns` | 5 | App Router, RSC, streaming |
| `nextjs-react-typescript` | 5 | Next + React + TS + shadcn + Tailwind |
| `nodejs-backend-patterns` | 5 | Backend Node (Express/Fastify) |
| `playwright` | 5 | E2E con Playwright |
| `postgresql-best-practices` | 3 | Esquema y queries en PostgreSQL |
| `premium-frontend-ui` | 4 | UI premium, anti-genérico |
| `prisma-development` | 3, 5 | Prisma ORM: esquema y migraciones |
| `react-query` | 5 | Estado de servidor / data fetching |
| `react-state-management` | 5 | Estado de cliente (Zustand/Jotai/RTK) |
| `responsive-design` | 4 | Diseño responsive mobile-first |
| `security-best-practices` | 3 | Seguridad backend, validación de entrada |
| `security-review` | 3, 6 | Escáner de vulnerabilidades |
| `shadcn` | 4 | Componentes shadcn/ui |
| `tailwindcss` | 5 | Estilos utility-first |
| `testing` | 5, 6 | Buenas prácticas de test |
| `ui-design` | 4 | UI accesible y usable |
| `ux-design` | 4 | UX centrado en el usuario |
| `zod-schema-validation` | 5 | Validación con Zod |

> Si cambias de stack, añade aquí (y al repo) la skill concreta del nuevo stack
> —p. ej. `supabase`, `drizzle-orm`— y bórrala del catálogo si deja de usarse.
