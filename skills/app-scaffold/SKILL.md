---
name: app-scaffold
description: Fase 5 del proceso de crear una app. Genera un PRIMER BUILD FUNCIONAL Y NAVEGABLE (no andamiaje con TODOs) a partir del PRD, la arquitectura y SOBRE TODO los mockups de la Fase 4, que se convierten en componentes reales. Cubre todos los roles del PRD con su acceso propio. Úsala cuando existan prd.md, architecture.md y mockup/ y el usuario quiera "generar el código", "scaffolding", "montar el proyecto", "convertir los mockups en app". Crea archivos de código reales y funcionales.
---

# Fase 5 — Build funcional (no andamiaje)

Objetivo: entregar una primera versión de la app que se pueda **abrir, navegar
y usar**, derivada de los mockups ya validados. NO entregues páginas placeholder
con "TODO": eso frustra al usuario que viene de ver mockups navegables. Un flujo
de prioridad alta debe FUNCIONAR de punta a punta, aunque sea con datos en memoria.

## Rol en esta fase

**En Claude Code:** Yo (Claude) actúo como **scaffolder** — genero código funcional,
tests (TDD triple bucle), y datos de seed. Tengo acceso completo (read, write, edit,
bash, browser).

**En OpenCode:** El usuario carga `/load scaffolder` — un agente especializado con
acceso completo (read, write, edit, bash, browser).

En ambos casos, ANTES de empezar a codificar:

**Recall de memoria.** Si existe `.builder/memory/MEMORY.md`, ejecuta recall con la
skill `app-memory`. Lee especialmente:
- `gotcha` — rareza del stack, comportamiento inesperado, trampa repetible
- `decision` — por qué se eligió así la arquitectura
- `constraint` — restricción técnica o de negocio

Los gotchas te dicen dónde has de poner cuidado. Las decisiones te dicen cómo
implementar coherentemente con lo ya decidido.

Cuando encuentres un gotcha nuevo (un bug inusual, una configuración sutil),
captúralo con `capture` en `app-memory`, enlazado al RF, para que la Fase 6 lo
verifique.

## Antes de empezar (gate de entrada)

### 0. Copia los ficheros pinned del template

Los versionados exactos están en el template. **Localiza primero la carpeta del
template** (varía según cómo se instaló el constructor), en este orden:

1. `.claude/template/` — instalado en el proyecto (vía `new-app`/`bootstrap`/`install`).
2. `template/` — repo del constructor abierto directamente (opencode).
3. `~/.claude/template/` — instalación global de Claude Code.

Usa la primera que exista como `ORIGEN` y cópiala a la raíz del proyecto
(`destino` = raíz de la app, normalmente el directorio actual):

    # Windows (PowerShell):
    Copy-Item -Recurse -Path .claude\template\* -Destination .\
    # macOS / Linux:
    # cp -r .claude/template/. ./   # el . incluye dotfiles

    pnpm install

Si NINGUNA de las tres rutas existe, párate y avisa al orquestador: el template
no se instaló. No improvises un `package.json` a mano (perderías las versiones
pinned y las configs probadas).

Esto te da: `.nvmrc`, `.npmrc` (pnpm + `save-exact=true`), `package.json`
(versiones fijas sin `^`), `tsconfig.json`, `next.config.ts`, `postcss.config.mjs`,
`globals.css` (Tailwind v4 con `@theme`), `prisma.config.ts` (Prisma 7),
`prisma/schema.prisma`, `.gitignore`, `.env.example`, `docker-compose.yml`
(PostgreSQL 17), `eslint.config.mjs`, `.prettierrc`, `vitest.config.ts`,
`playwright.config.ts`, `.github/workflows/ci.yml`, `src/lib/utils.ts` (cn),
`src/lib/env.ts` (validación con Zod), `src/lib/prisma.ts` (singleton),
`src/app/layout.tsx`, `page.tsx`, `not-found.tsx`, `error.tsx`, `loading.tsx`,
`api/health/route.ts`, y `e2e/example.spec.ts`.

### 1. Lee los docs del proyecto

Lee, en este orden y de verdad:
1. `stack.md` — stack y convenciones.
2. `prd.md` — requisitos con sus RF-XX, prioridades y roles.
3. `architecture.md` — modelo de datos y contrato de API.
4. **`design-system.md` — LA FUENTE DE VERDAD VISUAL.** Tokens de color,
   tipografía, iconos y shell. El build los hereda tal cual (variables CSS,
   misma fuente, mismos iconos). No inventes una paleta nueva ni vuelvas al
   genérico de Tailwind.
5. **`mockup/` — ESTO ES LA BASE DE LA UI.** Abre cada HTML. La interfaz, la
   navegación, las tablas, los formularios y los estados ya están resueltos ahí.
   Tu trabajo es convertirlos en componentes reales aplicando los tokens del
   sistema de diseño, NO reinventar la UI peor.

Si falta el mockup o el design-system, no generes UI a ciegas: vuelve a la Fase 4.

## Principio rector: los mockups mandan

Cada pantalla del mockup → un componente/página real con la MISMA estructura,
los mismos campos y la misma navegación. Si el mockup tiene un catálogo con
filtro de franja, el build tiene ese catálogo con ese filtro funcionando. Si el
mockup enlaza socio→entrega→devolución, el build conserva esa navegación. No
degrades la UI ni la navegación que ya estaban validadas.

## Cobertura obligatoria por ROL

Lee los roles del PRD (p.ej. Socio, Encargado, Admin) y genera para CADA uno:
- Su **acceso/login propio** (no solo el de admin).
- Sus pantallas, según los mockups de ese rol.
- Su navegación dentro de la app (layout con menú del rol).

Un build que solo deja entrar al admin es un build incompleto. Revisa que ningún
rol del PRD se quede sin entrada a la app.

## Vertical slices funcionales, no TODOs

Construye por flujos completos siguiendo la prioridad del PRD. Para cada RF de
**prioridad alta**, implementa el slice entero y FUNCIONANDO:

  UI (del mockup) → llamada fetch() → endpoint → lógica mínima real → datos (seed/memoria) → respuesta visible

### REGLA FUNDAMENTAL: los datos NUNCA van inline en la página

**Prohibido terminantemente:** arrays de datos mock dentro del componente/página.

```tsx
// ❌ NUNCA — datos inline en la página
const products = [
  { id: "1", title: "Audi A3 2019", status: "ACTIVE", price: "18.500€" },
  ...
]
export default function ProductsPage() {
  return <div>{products.map(...)}</div>  // LOS DATOS NO VIENEN DE UN ARRAY INLINE
}
```

**Siempre:** los datos viven detrás de un endpoint. La página los obtiene con fetch():

```tsx
// ✅ SIEMPRE — la página llama al endpoint
export default function ProductsPage() {
  const [products, setProducts] = useState([])
  useEffect(() => {
    fetch("/api/products?sellerId=seller-1")
      .then(r => r.json())
      .then(data => setProducts(data.products ?? []))
  }, [])
  return <div>{products.map(...)}</div>
}
```

Si no hay BD, los datos mock van DENTRO del endpoint, no en la página:

```ts
// ✅ Así sí — datos mock dentro del API route
export async function GET() {
  const products = [
    { id: "1", title: "Audi A3 2019", status: "ACTIVE", price: "18.500€" },
  ]
  return NextResponse.json({ products })
}
```

### REGLA: validación con Zod en el borde de la API

Todo endpoint que lea el body (`await request.json()`) **valida con un esquema
Zod** antes de tocar la lógica. Nada de `if (!campo) return 400` a mano: define
`const Schema = z.object({...})` y `Schema.safeParse(body)`. Es lo mismo que ya
haces en `src/lib/env.ts`, aplicado a cada entrada HTTP. El auditor lo comprueba
(`NO-ZOD`).

```ts
// ✅ endpoint con validación Zod
const Body = z.object({ sellerId: z.string(), title: z.string().min(1), price: z.number().nonnegative() });
const parsed = Body.safeParse(await request.json());
if (!parsed.success) return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 });
```

### REGLA: el servicio se usa, no se decora

Si generas un servicio (`*-service.ts`), su endpoint **debe importarlo y usarlo**.
Un servicio que no se importa en ninguna página ni route es código muerto: el
auditor lo marca (`ORPHAN-SERVICE`). No dupliques la lógica del servicio dentro
del `route.ts`.

### Código que pasa tsc + lint de Next 16 (a la primera)

El template usa Next 16 con ESLint estricto (React Compiler) y TypeScript 6. Para
que el build generado NO traiga errores, respeta estas reglas al escribir cada
componente y endpoint (cada una viene de un fallo real ya observado):

1. **Declara las funciones helper ANTES del `useEffect`/handler que las usa.**
   El React Compiler da error `Cannot access variable before it is declared` si un
   `const fn = …` se llama dentro de un efecto declarado más arriba. Orden correcto:
   estados → helpers (`loadX`, `resetX`) → efectos que los llaman.
2. **No llames `setState` de forma síncrona en el cuerpo de un `useEffect`.**
   Hazlo dentro del `.then()`/callback async (p. ej. `setLoading(false)` en `.finally`).
   El `setState` síncrono en el cuerpo dispara el aviso `set-state-in-effect`.
3. **Tipa los errores como `unknown` y haz narrowing** (`e instanceof Error`).
   Minimiza `any`; en filtros de Prisma usa `Prisma.XWhereInput`, no `Record<string, any>`.
4. **Cada página de listado tiene su endpoint GET.** Si hay una página de "mis
   compras"/"mis productos", existe `GET /api/<entidad>?…`. No dejes una lista
   alimentada por datos inline porque "aún no hay endpoint": crea el endpoint.
5. **Teardown de tests respeta las FK.** En `afterAll`, borra las dependencias
   antes que la entidad: primero `review`/`message`, luego `order`/`chat`, y al
   final `product`. Si no, salta `Foreign key constraint violated`.
6. **Versiones pinned = versiones publicadas reales.** Si añades una dependencia,
   usa una versión que exista en el registro (`npm view <pkg> version`). No inventes
   pines (un `react-pdf@9.3.0` o `@vitejs/plugin-react@4.5.3` inexistente revienta el install).

Antes del handoff: ejecuta `pnpm exec tsc --noEmit`, `pnpm lint` y `pnpm build`
y observa la salida en verde. No declares "compila" de memoria.

### Checker de wiring obligatorio

Después de generar todas las páginas y endpoints, **verifica explícitamente**:

1. Busca todos los `fetch('/api/` en los archivos de página.
2. Para cada uno, comprueba que existe el archivo `src/app/api/[ruta]/route.ts`.
3. Si falta el endpoint, créalo antes de seguir.
4. Busca páginas que tengan arrays de datos mock (patrón `const .* = [` con objetos de datos).
5. Si las encuentras, sustitúyelas por fetch() — si no existe el endpoint, créalo.

Este paso es OBLIGATORIO y no se salta. El orquestador debe recibir confirmación
de que se ha ejecutado.

### Generación de datos semilla

Usa una capa de datos sencilla con **datos semilla realistas** (los mismos del
mockup) si la BD real aún no está conectada. Lo importante es que el flujo se
recorra y haga algo, no que persista en producción. Pero los datos SIEMPRE van
detrás de un endpoint, nunca inline en la página.

### REGLA: IDs fijos en seed (prohibido UUIDs aleatorios)

Todo ID de usuario, rol o entidad de referencia que el frontend use de forma
hardcodeada (`userId: "user-1"`, `sellerId: "seller-1"`) DEBE tener el mismo
ID fijo en el seed. NUNCA uses UUIDs autogenerados para estos.

```typescript
// ❌ NUNCA — UUID aleatorio, el frontend no sabe cuál es
const user = await prisma.user.create({
  data: { name: "Demo", email: "demo@test.com" },
})
// El frontend hardcodea "seller-1" pero en DB el ID es otro → FK violation

// ✅ SIEMPRE — ID fijo conocido
const user = await prisma.user.create({
  data: { id: "seller-1", name: "Vendedor Demo", email: "vendedor@demo.com" },
})
// El frontend usa "seller-1" y coincide con la DB
```

**Checklist de IDs fijos obligatorios en seed:**
- Usuarios de prueba: `seller-1` (vendedor), `user-1` (comprador)
- Cada entidad que el frontend referencie con un ID hardcodeado
- Los IDs deben estar documentados en el README para que el usuario sepa
  con qué credenciales probar

### Auto-wiring por entidad: generación CRUD completa

Cada entidad del modelo de datos genera automáticamente 5 archivos:

```
src/
  app/api/[entidad]/route.ts          # GET list + POST create
  app/api/[entidad]/[id]/route.ts     # GET one + PUT update + DELETE
  app/(rol)/[entidad]/page.tsx        # Página de listado (consume GET list)
  app/(rol)/[entidad]/[id]/page.tsx   # Página de detalle (consume GET one)
  __tests__/api/[entidad].test.ts     # Tests API: happy + validación + 404 + 409
```

El scaffold debe generarlos en este orden y verificar que existen antes de seguir:
1. API route (GET list + POST create)
2. API route con [id] (GET one + PUT + DELETE)
3. Página de listado que llama a `GET /api/[entidad]`
4. Página de detalle que llama a `GET /api/[entidad]/[id]`
5. Tests de API para el endpoint

Si cualquiera de estos archivos falta al final del scaffold, el checker de
wiring lo marca como hueco crítico y el orquestador no puede cerrar la fase.

### Autenticación real (NextAuth) desde el primer slice

NO generes login simulado. Desde el primer commit, la app tiene:

- `src/app/api/auth/[...nextauth]/route.ts` con los providers del PRD
- `src/lib/auth.ts` con la configuración de NextAuth
- `src/lib/auth-config.ts` con los providers (credentials + OAuth si aplica)
- Middleware que protege las rutas según el rol
- Session provider en el layout raíz
- Botón de login/logout funcional en el header
- Hook `useSession` o `getServerSession` en cada página que necesite el usuario

El scaffold NO puede generar páginas que usen `"seller-1"` hardcodeado como
userId. Desde el principio, cada página obtiene el userId de la sesión:

```tsx
// ✅ SIEMPRE — userId de la sesión, no hardcodeado
const { data: session } = useSession()
const userId = session?.user?.id
fetch(`/api/products?sellerId=${userId}`)
```

Si el PRD especifica autenticación (OAuth, email/password, etc.), el scaffold
la implementa de verdad con NextAuth. No hay excusa para login simulado.

### Base de datos de test aislada

Los tests NO pueden compartir la base de datos de desarrollo. El template
incluye:

1. `docker-compose.test.yml` con PostgreSQL 17 en puerto diferente (5433)
2. `.env.test` con `DATABASE_URL_TEST=postgresql://user:password@localhost:5433/app_test`
3. Scripts `pnpm db:test:up` (levanta) y `pnpm db:test:down` (baja)
4. Los tests de API **deben** usar `DATABASE_URL_TEST` (no `DATABASE_URL`)
5. Cada suite de test limpia SOLO los datos que creó, nunca el seed
6. El CI ejecuta los tests contra la test DB, no contra la de desarrollo

**Cómo preparar la BD de test:**
```bash
pnpm db:test:up              # levanta docker-compose.test.yml
DATABASE_URL_TEST=postgresql://user:password@localhost:5433/app_test pnpm db:migrate
DATABASE_URL_TEST=postgresql://user:password@localhost:5433/app_test pnpm db:seed
pnpm test:run               # ejecuta tests (deben usar DATABASE_URL_TEST)
pnpm db:test:down           # baja el contenedor cuando termines
```

O crea un script unificado en `package.json` si necesitas `db:test:setup` como comodidad:
```bash
"db:test:setup": "pnpm db:test:up && DATABASE_URL_TEST=... pnpm db:migrate && DATABASE_URL_TEST=... pnpm db:seed"
```

El `docker-compose.test.yml` viene listo en el template:

### Tests API generados automáticamente

Por cada endpoint, el scaffold genera un test en `src/__tests__/api/[entidad].test.ts`
siguiendo esta plantilla:

```typescript
import { describe, it, expect, beforeAll, afterAll } from "vitest"
import { NextRequest } from "next/server"
import { GET as list, POST as create } from "@/app/api/[entidad]/route"
import { GET as getOne, PUT as update, DELETE as remove } from "@/app/api/[entidad]/[id]/route"

const BASE = "http://localhost:3000"

describe("RF-XX — GET /api/[entidad]", () => {
  it("devuelve 200 con la lista", async () => { ... })
  it("filtra por parámetros", async () => { ... })
  it("devuelve 400 si falta parámetro obligatorio", async () => { ... })
})

describe("RF-XX — POST /api/[entidad]", () => {
  it("crea y devuelve 201", async () => { ... })
  it("rechaza datos inválidos con 400", async () => { ... })
  it("rechaza duplicado con 409", async () => { ... })
})

describe("RF-XX — GET /api/[entidad]/[id]", () => {
  it("devuelve 200 con el detalle", async () => { ... })
  it("devuelve 404 si no existe", async () => { ... })
})
```

**Cobertura mínima:** 5 tests por endpoint (200, 201, 400, 404, 409).
Si una entidad tiene menos de 5 tests al final del scaffold, el DoD lo bloquea.

**Los TODO solo se permiten en RF de prioridad media/baja.** Y aun así, deben
ser pantallas que cargan y se ven, con un aviso claro de "pendiente", nunca el
texto crudo de un endpoint pegado en la página.

## Lógica de negocio que SÍ va en este build (prioridad alta)

A partir de los criterios de aceptación del PRD, implementa de verdad:
- Validaciones que bloquean (licencia vigente, categoría que habilita el arma).
- Cambios de estado (DISPONIBLE → ENTREGADA → DISPONIBLE / EN_MANTENIMIENTO).
- Disponibilidad por franja (no ofrecer un arma ya reservada en esa franja).
- Borrado lógico (las bajas no desaparecen; se marcan).
- Registro de auditoría append-only de las acciones (si el PRD lo pide).

Esto no es "lógica compleja opcional": son los criterios de aceptación. Si no
están, el flujo no cumple su RF.

## Ritmo: TDD triple bucle por slice

No renderices todo de golpe. Por cada slice de RF de **prioridad alta**:

1. **Bucle 1 — API (aceptación):** escribe primero el **test de API** que llama
   al endpoint real con fetch() y verifica la respuesta completa (código, cuerpo,
   errores). Este test usa la base de datos real (via `prisma`). Nace en rojo.
   Solo cuando el endpoint devuelve lo esperado, pasas al siguiente bucle.
   
   ```ts
   // test-api-orders.ts — ejemplo
   it("POST /api/orders crea una orden y devuelve 201", async () => {
     const res = await fetch("http://localhost:3000/api/orders", {
       method: "POST",
       headers: { "Content-Type": "application/json" },
       body: JSON.stringify({ productId: "...", buyerId: "user-1" }),
     })
     expect(res.status).toBe(201)
     const body = await res.json()
     expect(body.id).toBeDefined()
     expect(body.status).toBe("PAID")
   })
   ```
   
   El **e2e (playwright)** solo para el **flujo principal del PRD**, no uno por RF.

2. **Bucle 2 — Servicio (unidad):** implementa guiado por los **contratos del §8**.
   Test unitario desde el contrato (rojo) → código mínimo (verde) → refactor.
   Repite hasta cubrir los servicios del slice.

3. **Bucle 3 — UI (integración):** escribe el test de la página que verifica que
   la UI se renderiza y que llama al endpoint correcto. Para páginas cliente,
   test de que el fetch() se dispara con los parámetros correctos. Este bucle
   solo se activa cuando los bucles 1 y 2 están en verde.

4. Slice cerrado cuando los tres bucles pasan a **verde**.
5. Etiqueta: API con `RF-XX-api`; servicio con `RF-XX-svc`; UI con `RF-XX-ui`.
6. **Checkpoint:** ejecuta la suite completa, debe estar **verde**, y haz commit
   antes del siguiente slice. Si algo se queda rojo, aplica `debugging-strategies`.

### Tests de API: estructura obligatoria

Cada suite de API sigue este patrón:

```ts
import { describe, it, expect, beforeAll } from "vitest"

const BASE = "http://localhost:3000/api"

describe("RF-XX — [nombre del endpoint]", () => {
  // Happy path
  it("GET /api/... devuelve 200 con la lista", async () => { ... })
  it("POST /api/... crea y devuelve 201", async () => { ... })

  // Validaciones
  it("POST /api/... sin campo obligatorio devuelve 400", async () => { ... })
  it("GET /api/... con id inexistente devuelve 404", async () => { ... })

  // Límites
  it("POST /api/... con datos inválidos devuelve 422/400", async () => { ... })
})
```

Cada suite de API cubre como mínimo: **happy path** (200/201), **validación** (400),
**no encontrado** (404), y **conflicto** (409). Esto es el mínimo profesional
para cualquier endpoint.

### Reglas de contrato (§8 ↔ tests)
- **Drift:** si la implementación revela que un contrato §8 era incorrecto,
  actualiza §8 en `architecture.md` (cambio retroactivo + commit) y ajusta el
  test al **contrato corregido** — nunca al revés.
- **Precedencia aceptación > contrato:** si seguir el contrato no hace pasar la
  aceptación, manda el RF: corrige §8 y, con él, el test.

## Tests (parte del build, no de la auditoría)

La Fase 6 audita "RF → test", pero **los tests se escriben aquí**. Para cada
**RF de prioridad alta**, escribe al menos un test que ejercite su criterio de
aceptación (Dado/Cuando/Entonces), con el framework de `stack.md`
(por defecto vitest; e2e con playwright para el flujo principal; o el framework
del stack si es otro —PHPUnit en CI3 legacy—). El test lleva
en su nombre o en un comentario el `RF-XX` que cubre, para que la auditoría lo
enlace. Sin esto, la auditoría marcará huecos de test sistemáticamente.

Los tests nacen en dos niveles (ver "Ritmo: TDD doble bucle"): **aceptación**
por RF (API/integración; e2e solo flujo principal) y **unitarios** por contrato
§8. Skills de apoyo incluidas: `testing`, `javascript-testing-patterns`,
`e2e-testing-patterns`/`playwright`. El framework según `stack.md`.

## Skills incluidas (úsalas)

Aplícalas en lo que les toca. Según el stack por defecto:
`nextjs-app-router-patterns` / `nextjs-react-typescript` (front), `nodejs-backend-patterns`
/ `api-development` (back), `prisma-development` (datos), `zod-schema-validation`
(validación), `error-handling-patterns`, `react-query`/`react-state-management`,
`tailwindcss`, `accessibility-a11y`. Testing: `testing`, `javascript-testing-patterns`,
`e2e-testing-patterns`/`playwright`. Depuración: `debugging-strategies`.
(Estas cubren el stack por defecto. Si cambias de stack —Supabase, Drizzle…—
añade al repo la skill correspondiente.)

## Estructura del proyecto

Según `stack.md` (por defecto Next.js App Router + API Routes + Prisma; o CI3 si es legacy):
- Estructura de carpetas, configs, linter.
- Esquema/migraciones que reflejan el modelo de datos de la arquitectura.
- Capa de datos con seed (los datos de ejemplo de los mockups).
- README con cómo arrancar y un mapa rol → pantallas → RF.

## Trazabilidad en el código

Cada archivo que implementa un requisito lleva en cabecera:

```
// Implementa: RF-01 (reserva de franja por el socio)
// UI base: mockup/flujo-01-socio-reserva.html
// Ver: .builder/architecture.md §4
```

## Gates ejecutables (verificación antes de cerrar Fase 5)

La Fase 5 no confía en declaraciones de memoria. Los gates REALES son:

### 1. `pnpm audit:builder` — auditoría automática
Detecta CRÍTICOS que bloquean:
- **INLINE-DATA**: arrays de datos mock dentro de componentes
- **WIRING**: fetch() sin su route.ts correspondiente
- **ORPHAN-SERVICE**: servicios que no se usan
- **NO-ZOD**: endpoints que leen body sin validar
- **CREATE-EDIT**: hay `/new/` pero falta `[id]/edit/`

Si **exit 0**: OK. Si **exit ≠ 0**: cierra el crítico antes de cerrar la fase.

```bash
pnpm audit:builder
# Salida: "✅ cero CRÍTICOS" o "❌ CRÍTICO: [descripción]"
```

### 2. `pnpm audit:wiring` — verificación de fetch ↔ route.ts
Bucle sobre todos los fetch():
- Extrae ruta de `fetch('/api/X/...')`
- Verifica que existe `src/app/api/X/route.ts`
- Reporta fetch huérfano como CRÍTICO

También reporta CRÍTICO si hay arrays mock inline.

Si **exit 0**: OK. Si **exit ≠ 0**: fix wiring antes de cerrar.

```bash
pnpm audit:wiring
# Salida: "✅ Wiring OK: N fetch() verificados" o "❌ CRÍTICO: fetch sin route"
```

### 3. Suite de tests en verde
```bash
pnpm test:run                      # unit + API
pnpm db:test:up && pnpm test:e2e  # e2e contra test DB
```

Si hay tests en rojo en prioridad alta: fija antes de cerrar.

## Definition of Done: BLOQUEANTES vs MEJORAS

**BLOQUEANTE** (must-have para pasar a Fase 6): cierra Fase 5 solo si estos 6 items están ✓:
1. `pnpm audit:builder` **exit 0** (zero CRÍTICOS)
2. `pnpm audit:wiring` **exit 0** (cada fetch() tiene route.ts, zero inline data)
3. AUTH REAL (NextAuth con session, no simulado)
4. TEST DB AISLADA (DATABASE_URL_TEST, no DATABASE_URL)
5. Suite de tests en verde contra test DB (unit + API de prioridad alta)
6. Cada RF de prioridad alta funciona de punta a punta (navegable, datos reales desde DB/seed)

**MEJORA** (aviso, no bloquea): reporta en el handoff pero permiten cerrar Fase 5:
- E2E del flujo principal (puede estar incompleto)
- Cobertura de tests >= 5 por entidad (puede ser < 5)
- README con instrucciones (puede estar incompleto)
- Seed documentation

Si los 6 bloqueantes están verdes, Fase 5 cierra. Los avisos se listan en el handoff
para que la Fase 6 audite (y repor) pero no detienen el progreso.

---

No cierres la fase hasta que al menos ESTOS bloqueantes sean ciertos:

- [ ] **`pnpm audit:builder` con exit 0** antes del handoff (gate mecánico: cero CRÍTICOS — datos inline, fetch sin endpoint). Si falla, ciérralo antes de devolver el control.
- [ ] **WIRING CHECK OK**: cada `fetch('/api/...')` en páginas tiene un archivo `route.ts` existente. Verificado con grep + glob.
- [ ] **ZERO INLINE DATA**: ninguna página contiene arrays de datos mock.
- [ ] **SEED IDS FIJOS**: todos los IDs que el frontend referencia están en el seed con el mismo valor.
- [ ] **CRUD POR ENTIDAD**: cada entidad tiene sus 5 archivos (route list, route id, página list, página detail, tests). Verificado con glob.
- [ ] **CREATE/EDIT SYMMETRY**: cada `*/new/page.tsx` tiene su `*/[id]/edit/page.tsx`. Cada `POST /api/[entidad]` tiene su `PUT /api/[entidad]/[id]`. Verificado con bucle sobre todas las entidades.
- [ ] **AUTH REAL**: login/registro usan NextAuth con session real, no simulado.
- [ ] **TEST DB AISLADA**: los tests usan `DATABASE_URL_TEST`, no `DATABASE_URL`.
- [ ] **API TESTS**: cada endpoint tiene test de API que cubre: happy path (200/201), validación (400), no encontrado (404), conflicto (409). Mínimo 5 tests por endpoint.
- [ ] **SERVICE TESTS**: cada servicio tiene tests unitarios derivados de su contrato §8.
- [ ] Cobertura total de tests >= 5 por entidad + 5 por servicio.
- [ ] Cada ROL del PRD tiene su login/acceso propio y su navegación
- [ ] Cada pantalla del mockup tiene su componente real equivalente (misma UI y navegación)
- [ ] Cada RF de prioridad alta se recorre de punta a punta (UI → fetch → endpoint → DB → respuesta → UI) y produce un resultado REAL
- [ ] Cada RF de prioridad alta tiene test de API en verde, etiquetado con `RF-XX-api`
- [ ] Cada RF de prioridad alta tiene test de servicio en verde, etiquetado con `RF-XX-svc`
- [ ] La suite completa (API + servicio + e2e) se ejecuta y pasa contra la **test DB**, no contra la de desarrollo
- [ ] El build **compila/arranca** sin errores y los tests pasan
- [ ] Las validaciones que bloquean funcionan de verdad (no son un TODO ni un alert)
- [ ] Los cambios de estado se reflejan en los listados
- [ ] Datos semilla realistas cargados con IDs fijos (los del seed, conectados a los endpoints)
- [ ] Cero páginas con arrays de datos mock, IDs hardcodeados, texto crudo de endpoints o "TODO" en flujos de prioridad alta
- [ ] README con instrucciones de arranque, credenciales de prueba y mapa rol→pantalla→RF
- [ ] Cada archivo de requisito con su comentario de trazabilidad

Autocomprobación final antes de entregar (verificación con evidencia): no
declares "funciona" de memoria. Arranca de verdad la app,
ejecuta los tests y observa la salida; abre la app como cada rol y recorre sus
flujos de prioridad alta. Si algo enseña un TODO, una pantalla rota o un test en
rojo, NO está hecho: complétalo antes de devolver el control al orquestador.

Cuando esté completo, devuelve el control al orquestador para la auditoría (Fase 6).
