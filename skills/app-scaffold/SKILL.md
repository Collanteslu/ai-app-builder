---
name: app-scaffold
description: Fase 5 del proceso de crear una app. Genera un PRIMER BUILD FUNCIONAL Y NAVEGABLE (no andamiaje con TODOs) a partir del PRD, la arquitectura y SOBRE TODO los mockups de la Fase 4, que se convierten en componentes reales. Cubre todos los roles del PRD con su acceso propio. Úsala cuando existan prd.md, architecture.md y mockup/ y el usuario quiera "generar el código", "scaffolding", "montar el proyecto", "convertir los mockups en app". Crea archivos de código reales y funcionales.
---

# Fase 5 — Build funcional (no andamiaje)

Objetivo: entregar una primera versión de la app que se pueda **abrir, navegar
y usar**, derivada de los mockups ya validados. NO entregues páginas placeholder
con "TODO": eso frustra al usuario que viene de ver mockups navegables. Un flujo
de prioridad alta debe FUNCIONAR de punta a punta, aunque sea con datos en memoria.

## Antes de empezar (gate de entrada)

### 0. Copia los ficheros pinned de `template/`

Los versionados exactos están en `template/`. Cópialos antes de hacer nada:

    # Windows (PowerShell):
    Copy-Item -Recurse -Path template\* -Destination destino\
    # macOS / Linux:
    # cp -r template/. destino/   # el . incluye dotfiles

    Set-Location -LiteralPath destino
    pnpm install

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
recorra y haga algo, no que persista en producción. Pero los datos SEMPRE van
detrás de un endpoint, nunca inline en la página.

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

Según `stack.md` (por defecto Next.js + NestJS + Prisma; o CI3 si es legacy):
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

## Definition of Done

No cierres la fase hasta que TODO esto sea cierto:

- [ ] **WIRING CHECK OK**: cada `fetch('/api/...')` en páginas tiene un archivo `route.ts` existente. Verificado con grep + glob.
- [ ] **ZERO INLINE DATA**: ninguna página contiene arrays de datos mock. Verificado con grep de `const .* = \[` en páginas.
- [ ] **API TESTS**: cada endpoint tiene test de API que cubre: happy path (200/201), validación (400), no encontrado (404), conflicto (409).
- [ ] **SERVICE TESTS**: cada servicio tiene tests unitarios derivados de su contrato §8.
- [ ] Cada ROL del PRD tiene su login/acceso propio y su navegación
- [ ] Cada pantalla del mockup tiene su componente real equivalente (misma UI y navegación)
- [ ] Cada RF de prioridad alta se recorre de punta a punta (UI → fetch → endpoint → DB → respuesta → UI) y produce un resultado REAL
- [ ] Cada RF de prioridad alta tiene test de API en verde, etiquetado con `RF-XX-api`
- [ ] Cada RF de prioridad alta tiene test de servicio en verde, etiquetado con `RF-XX-svc`
- [ ] La suite completa (API + servicio + e2e) se ejecuta y pasa en el handoff, con evidencia (comando + salida); cero rojos/skip en prioridad alta
- [ ] El build **compila/arranca** sin errores y los tests pasan
- [ ] Las validaciones que bloquean funcionan de verdad (no son un TODO ni un alert)
- [ ] Los cambios de estado se reflejan en los listados
- [ ] Datos semilla realistas cargados (los del seed, conectados a los endpoints)
- [ ] Cero páginas con arrays de datos mock, texto crudo de endpoints o "TODO" en flujos de prioridad alta
- [ ] README con instrucciones de arranque y mapa rol→pantalla→RF
- [ ] Cada archivo de requisito con su comentario de trazabilidad

Autocomprobación final antes de entregar (verificación con evidencia): no
declares "funciona" de memoria. Arranca de verdad la app,
ejecuta los tests y observa la salida; abre la app como cada rol y recorre sus
flujos de prioridad alta. Si algo enseña un TODO, una pantalla rota o un test en
rojo, NO está hecho: complétalo antes de devolver el control al orquestador.

Cuando esté completo, devuelve el control al orquestador para la auditoría (Fase 6).
