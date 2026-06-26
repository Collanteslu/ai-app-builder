# stack.md — Configuración del proyecto

> Este fichero define el stack y las convenciones. Todas las skills lo leen
> como contexto. Cópialo a la raíz del proyecto y ajústalo antes de empezar.
> Lo que no apliques, déjalo en blanco o bórralo.

## Stack

- **Frontend**: Next.js 15 (App Router) + TypeScript + Tailwind
- **Backend**: Next.js API Routes + Server Actions
- **Base de datos**: PostgreSQL + Prisma
- **Auth**: (definir: NextAuth / Clerk / propia con JWT)
- **Infra**: (definir: Vercel / Docker + VPS)
- **CI/CD**: GitHub Actions

## Librerías preferidas

- Validación: zod
- Tests: vitest + playwright (e2e)
- Formularios: react-hook-form
- ORM/queries: Prisma
- Estado cliente: Zustand
- Data fetching: TanStack React Query (server + client)
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
