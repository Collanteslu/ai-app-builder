# stack.md — Configuración del proyecto

> Este fichero define el stack y las convenciones. Todas las skills lo leen
> como contexto. Cópialo a la raíz del proyecto y ajústalo antes de empezar.
> Lo que no apliques, déjalo en blanco o bórralo.

## Stack por defecto

- **Frontend**: Next.js 15 (App Router) + TypeScript + Tailwind
- **Backend**: NestJS + TypeScript
- **Base de datos**: PostgreSQL + Prisma
- **Auth**: (definir: NextAuth / Clerk / propia con JWT)
- **Infra**: (definir: Hetzner + Coolify / Vercel / VPS Docker)
- **CI/CD**: GitHub Actions

> Alternativa legacy (proyectos tipo Ridon): CodeIgniter 3 + PHP 7.4 + MySQL.
> Si el proyecto es sobre este stack, indícalo aquí y las skills se adaptan.

## Librerías preferidas

- Validación: zod
- Tests: vitest + playwright (e2e)
- Formularios: react-hook-form
- ORM/queries: Prisma (o query builder de CI3 si es legacy)
- PDF: DomPDF (legacy) / react-pdf
- (añade las tuyas)

## Convenciones

- **Commits**: Conventional Commits en español con emoji (✨ feat, 🐛 fix, ♻️ refactor)
- **Idioma del código**: identificadores en inglés, comentarios en español
- **Gestión Git**: GitKraken, ramas feature/*
- **Estilo**: ESLint + Prettier

## Restricciones de negocio (rellenar por proyecto)

- ¿Datos personales / RGPD? (sí/no — si sí, el threat model es obligatorio)
- ¿Cumplimiento fiscal? (VeriFactu, facturación, etc.)
- ¿Datos sensibles especiales? (salud, armas, financieros)
- ¿Volumen esperado? (usuarios, peticiones/día)
- ¿Integraciones externas obligatorias? (Stripe, SEPA, APIs gobierno)
