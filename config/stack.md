# stack.md — Configuración del proyecto

> Este fichero define el stack y las convenciones. Todas las skills lo leen
> como contexto. Cópialo a la raíz del proyecto y ajústalo antes de empezar.
> Lo que no apliques, déjalo en blanco o bórralo.

## Stack (versiones concretas)

- **Frontend**: Next.js 16.2.9 (App Router) + TypeScript 6.0.3 + Tailwind CSS 4.3.1
- **Backend**: Next.js API Routes + Server Actions
- **Base de datos**: PostgreSQL 17 + Prisma 7.8.0
- **Auth**: (definir: NextAuth / Clerk / propia con JWT)
- **Infra**: (definir: Vercel / Docker + VPS)
- **CI/CD**: GitHub Actions
- **Runtime**: Node.js LTS v22.x

## Librerías preferidas

- Validación: Zod 4.4.3
- Tests: Vitest 4.1.9 + Playwright 1.61.1 (e2e)
- Formularios: react-hook-form 7.80.0
- ORM/queries: Prisma 7.8.0
- Estado cliente: Zustand 5.0.8
- Data fetching: TanStack React Query 5.101.1 (server + client)
- PDF: react-pdf

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
