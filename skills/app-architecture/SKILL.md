---
name: app-architecture
description: Fase 3 del proceso de crear una app. Define la arquitectura técnica a partir del PRD y stack.md, incluyendo modelo de datos, contrato de API y threat model de seguridad. Úsala cuando exista prd.md y el usuario quiera "diseñar la arquitectura", "modelo de datos", "endpoints", "decisiones técnicas". Genera architecture.md.
---

# Fase 3 — Arquitectura técnica

Objetivo: decidir CÓMO se construye, antes de escribir código. Esta fase
agrupa tres piezas que otros equipos separan, pero que aquí van juntas porque
se alimentan entre sí: modelo de datos, contrato de API y seguridad.

## Antes de empezar (gate de entrada)

Lee `prd.md` y `stack.md`. Si el PRD no existe o tiene requisitos sin ID, no
continúes: vuelve a la Fase 2. Cada decisión de arquitectura debe poder rastrearse
a un RF-XX o RNF-XX.

Comprueba en `stack.md` si el proyecto es **legacy (CI3)**. Si lo es, la
arquitectura se expresa en sus términos (controladores/modelos/vistas de
CodeIgniter 3, MySQL, query builder) en vez de Prisma/NestJS, y el contrato de
API puede ser de rutas CI3 clásicas. El modelo de trazabilidad RF-XX no cambia;
solo cambia la tecnología destino.

## Qué produces

### 1. Decisiones de stack y arquitectura
Parte de `stack.md`. Si el PRD justifica desviarse del stack por defecto,
documéntalo como ADR (registro de decisión: contexto → opciones → elección →
consecuencias). Define capas, patrón general (monolito, API+SPA, etc.) y dónde
encaja la IA si la hay (producción / interno / solo desarrollo).

### 2. Modelo de datos
Entidades, atributos, relaciones, claves e índices. Una tabla por entidad con
sus campos. Marca qué entidad cubre qué requisito (RF-XX).

**Regla de IDs fijos en seed:**
Toda entidad que el frontend vaya a referenciar con un ID hardcodeado
(ej: `userId: "seller-1"`, `roleId: "admin"`) debe especificar su ID fijo
en el modelo de datos. No se permiten UUIDs autogenerados para estas entidades.
La columna "ID seed" debe incluir el valor exacto que tendrá en el seed:

| Campo | Tipo | ID seed | Notas |
|-------|------|---------|-------|
| id | String (UUID) | `seller-1` | ID fijo conocido por el frontend |

La tabla de trazabilidad debe incluir una columna "ID seed" para cada entidad
que el frontend referencie directamente. Esto evita el error más común:
el frontend usa un ID que no existe en la DB.

### 3. Contrato de API
Endpoints con método, ruta, entrada, salida y código de estado. Cada endpoint
referencia el RF que implementa. Esto evita endpoints "huérfanos" sin requisito.

**Requisito mínimo por entidad del modelo de datos:**
Toda entidad que aparece en el modelo de datos debe tener, como mínimo:
- `GET /api/[entidad]` — listar (con filtro por vendedor/usuario según el contexto)
- `GET /api/[entidad]/[id]` — obtener uno
- `POST /api/[entidad]` — crear
- `PUT o PATCH /api/[entidad]/[id]` — actualizar (si la entidad es modificable)
- `DELETE /api/[entidad]/[id]` — borrar (si aplica)

**CREATE/EDIT SYMMETRY (regla de simetría):**
Si existe `POST /api/[entidad]` (crear), debe existir `PUT /api/[entidad]/[id]` (editar).
Si existe `*/[entidad]/new/page.tsx` (formulario de creación), debe existir
`*/[entidad]/[id]/edit/page.tsx` (formulario de edición).
Esta simetría se verifica en la auditoría con un bucle sobre todas las entidades.

Sin estos endpoints mínimos, el scaffold no puede conectar las páginas a los
datos, y el sistema entero depende de arrays mock inline. La tabla de endpoints
debe incluir el verbo, la ruta completa y el código de estado de éxito esperado
(201 para creación, 200 para el resto).

### 4. Threat model (obligatorio si hay datos sensibles)
Si el PRD tiene RNF de RGPD/seguridad: lista activos a proteger, amenazas,
controles (autenticación, autorización, cifrado, auditoría) y qué RNF cubre cada uno.

### 4b. Arquitectura de autenticación (obligatorio, siempre)
El contrato de API debe incluir los endpoints de autenticación real (NextAuth):
- `GET/POST /api/auth/[...nextauth]` — ruta catch-all de NextAuth
- Especificar qué providers: credentials, Google, GitHub (según PRD)
- El threat model debe asumir autenticación real desde el día 1, no simulada

### 4c. Base de datos de test (obligatorio)
La arquitectura debe especificar una base de datos PostgreSQL separada para tests:
- Puerto: 5433 (distinto de la DB de desarrollo 5432)
- Nombre: `app_test`
- La DB de test se levanta con `docker-compose.test.yml`
- Los tests NUNCA usan `DATABASE_URL` (desarrollo), siempre `DATABASE_URL_TEST`
- El seed de test contiene los mismos IDs fijos que el seed de desarrollo

### 5. Diseño de componentes/módulos
Descompón cada flujo en componentes con responsabilidad única. Una tabla:
módulo · responsabilidad · qué RF cubre · dependencias (incluyendo endpoints de
los que depende). Es el mapa de piezas que el scaffold construirá.

**Cada componente de página debe depender de al menos un endpoint.**
Si un componente muestra datos (lista, detalle, formulario con opciones), debe
tener un endpoint del que obtenerlos. La columna "dependencias" debe listar la
ruta del endpoint del que depende. Si un componente no depende de ningún endpoint,
es un candidato a tener datos mock inline y debe marcarse como riesgo en la auditoría.

### 6. Contratos de interfaz interna
Por cada componente con comportamiento real (lógica, validación, cambios de
estado) o que cruza límites de módulo, define su interfaz pública: firma
entrada→salida, precondiciones, postcondiciones y errores esperados. Un CRUD
simple lleva contrato mínimo (no sobrediseñes). **Estos contratos son la fuente
de los tests unitarios** de la Fase 5.
Legacy (CI3): "componente" = controlador/modelo/librería; "contrato" = interfaz
pública PHP de esa clase.

## Salida: architecture.md

```markdown
# Arquitectura — [Nombre del proyecto]

## 1. Stack y patrón
[Resumen + capas. Diagrama en texto si ayuda]

## 2. ADRs (decisiones)
### ADR-01 — [Decisión]
Contexto · Opciones · Elección · Consecuencias

## 3. Modelo de datos
### Entidad: [nombre]  (cubre RF-XX)
| Campo | Tipo | Restricciones | Notas |
|-------|------|---------------|-------|
Relaciones: [...]
Índices: [...]

## 4. Contrato de API
| Método | Ruta | Entrada | Salida | Estado | Cubre |
|--------|------|---------|--------|--------|-------|
| POST | /api/... | {...} | {...} | 201 | RF-01 |

## 5. Threat model
| Activo | Amenaza | Control | Cubre RNF |
|--------|---------|---------|-----------|

## 6. Trazabilidad
Tabla RF-XX → entidad(es) → endpoint(s) → componente(s) → contrato §8.
Marca cualquier RF sin cubrir.

## 7. Componentes
| Componente | Responsabilidad | Cubre | Depende de |
|-----------|-----------------|-------|------------|
| MovimientoService | Registrar salida/devolución y estado del arma | RF-01, RF-02 | ArmaRepo, SocioRepo |

## 8. Contratos
### Contrato — MovimientoService
- `registrarSalida(socioId, armaId): Movimiento`
  - Pre: socio con licencia vigente; arma DISPONIBLE.
  - Post: Movimiento estado="fuera"; arma → ENTREGADA.
  - Errores: LicenciaCaducada, ArmaNoDisponible.
```

## Skills incluidas (úsalas)

Aplícalas en la pieza que les toca (todas vienen incluidas en el repo):

- **API**: `api-design-principles` (REST/GraphQL coherente), `error-handling-patterns`
  (contrato de errores).
- **Auth** (según el campo *Auth* de `stack.md`): `auth-implementation-patterns`,
  y la concreta — `jwt-security` o `nextauth-authentication`.
- **Datos**: `postgresql-best-practices` + `prisma-development`.
- **Seguridad / threat model**: `security-best-practices`, `security-review`.
- **Operación**: `logging-best-practices` si el PRD pide trazas/auditoría.

## Gate ejecutable de trazabilidad (duro)

El hueco más caro de esta fase es un RF del PRD que nunca llega a la arquitectura:
hoy no se ve hasta la auditoría de la Fase 6. El linter `scripts/trace-lint.mjs`
del template lo caza ya, cotejando `prd.md` ↔ `architecture.md`. Localízalo igual
que en la Fase 5 (el template aún no se copió) y ejecútalo desde la raíz:

```bash
# Windows (PowerShell) — primera ruta que exista:
node .claude\template\scripts\trace-lint.mjs   # instalado en el proyecto
# node template\scripts\trace-lint.mjs          # repo del constructor (opencode)
# node "$env:USERPROFILE\.claude\template\scripts\trace-lint.mjs"  # global
```

Para esta fase, los críticos que **bloquean** son `RF-SIN-ARQUITECTURA` (un RF del
PRD sin entidad/endpoint que lo soporte) y `RF-FANTASMA` (un RF en la arquitectura
que no existe en el PRD — scope creep). Si exit≠0, cierra el hueco antes de pasar
a la Fase 4. Pega la salida real en el handoff.

## Definition of Done

- [ ] Cada RF del PRD aparece en la tabla de trazabilidad con su entidad y endpoint
- [ ] **`trace-lint.mjs` ejecutado con exit 0** (cero `RF-SIN-ARQUITECTURA` ni `RF-FANTASMA`); salida real en el handoff
- [ ] **IDs fijos**: cada entidad referenciada por el frontend tiene un ID seed documentado en el modelo
- [ ] **Auth real**: los endpoints de NextAuth están especificados en el contrato de API (no login simulado)
- [ ] **Test DB**: la BD de test (puerto 5433) está especificada con su docker-compose
- [ ] Modelo de datos con tipos, claves y relaciones (no solo nombres)
- [ ] Contrato de API: ningún endpoint sin RF, ningún RF sin endpoint (salvo justificado)
- [ ] Threat model presente si había datos sensibles en el PRD
- [ ] Desviaciones del stack documentadas como ADR
- [ ] §7: cada RF de prioridad alta tiene componente(s) asignado(s)
- [ ] §8: cada componente con comportamiento real o que cruza módulo tiene contrato (firma, pre/post, errores); los CRUD simples, contrato mínimo

Cuando esté completo, guarda `architecture.md` y devuelve el control al orquestador.
