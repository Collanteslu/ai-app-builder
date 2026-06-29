# stack.md — Configuración del proyecto

> Este fichero define el stack y las convenciones. Todas las skills lo leen
> como contexto. Cópialo a la raíz del proyecto y ajústalo antes de empezar.
> Lo que no apliques, déjalo en blanco o bórralo.

## Modo del proyecto

- **Stack legacy (CI3)**: no
  > Ponlo en `sí` solo si el proyecto es un CodeIgniter 3 existente (PHP/MySQL) al
  > que se le añaden funcionalidades. Cuando está en `sí`, las Fases 3–5 se
  > expresan en términos de CI3 (controladores/modelos/vistas, MySQL, query
  > builder) y el mockup debe ser HTML/CSS portable, no React. La trazabilidad
  > RF-XX **no cambia**; solo cambia la tecnología destino. En `no` (por defecto)
  > se usa el stack moderno de abajo.

## Stack

- **Frontend**: Next.js 16 (App Router) + TypeScript 6 + Tailwind CSS 4
- **Backend**: Next.js API Routes + Server Actions
- **Base de datos**: PostgreSQL 17 + Prisma 7
- **Auth**: (definir: NextAuth / Clerk / propia con JWT)
- **Infra**: (definir: Vercel / Docker + VPS)
- **CI/CD**: GitHub Actions
- **Runtime**: Node.js LTS v22.x

## Librerías preferidas

- Validación: Zod 4
- Tests: Vitest 4 + Playwright (e2e)
- Formularios: react-hook-form 7
- ORM/queries: Prisma 7
- Estado cliente: Zustand 5
- Data fetching: TanStack React Query 5 (server + client)
- PDF *(solo si el PRD lo pide)*: react-pdf — no es base; añádelo al `package.json`
  con su versión publicada real solo cuando una funcionalidad lo necesite.

## Versiones pinned

> Las versiones exactas están en `template/` (`package.json`, `.nvmrc`, `.npmrc`,
> `prisma.config.ts`, etc.). Cópialo todo antes de empezar — así evitas el
> paraguas `^` y usas pnpm.
>
> Para la base de datos local: `docker compose up -d` (PostgreSQL 17 en puerto 5432).

## Convenciones

- **Commits**: Conventional Commits en español con emoji (✨ feat, 🐛 fix, ♻️ refactor)
- **Idioma del código**: identificadores en inglés, comentarios en español
- **Gestión Git**: ramas feature/*
- **Estilo**: ESLint + Prettier

## Restricciones de negocio (rellenar por proyecto)

- ¿Datos personales / RGPD? (sí/no — si sí, el threat model es obligatorio)
- ¿Cumplimiento fiscal? (VeriFactu, facturación, etc.)
- ¿Datos sensibles especiales? (salud, armas, financieros)
- ¿Volumen esperado? (usuarios, peticiones/día)
- ¿Integraciones externas obligatorias? (Stripe, SEPA, APIs gobierno)
