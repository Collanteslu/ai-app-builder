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

### 3. Contrato de API
Endpoints con método, ruta, entrada, salida y código de estado. Cada endpoint
referencia el RF que implementa. Esto evita endpoints "huérfanos" sin requisito.

### 4. Threat model (obligatorio si hay datos sensibles)
Si el PRD tiene RNF de RGPD/seguridad: lista activos a proteger, amenazas,
controles (autenticación, autorización, cifrado, auditoría) y qué RNF cubre cada uno.

### 5. Diseño de componentes/módulos
Descompón cada flujo en componentes con responsabilidad única. Una tabla:
módulo · responsabilidad · qué RF cubre · dependencias. Es el mapa de piezas
que el scaffold construirá.

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

## Definition of Done

- [ ] Cada RF del PRD aparece en la tabla de trazabilidad con su entidad y endpoint
- [ ] Modelo de datos con tipos, claves y relaciones (no solo nombres)
- [ ] Contrato de API: ningún endpoint sin RF, ningún RF sin endpoint (salvo justificado)
- [ ] Threat model presente si había datos sensibles en el PRD
- [ ] Desviaciones del stack documentadas como ADR
- [ ] §7: cada RF de prioridad alta tiene componente(s) asignado(s)
- [ ] §8: cada componente con comportamiento real o que cruza módulo tiene contrato (firma, pre/post, errores); los CRUD simples, contrato mínimo

Cuando esté completo, guarda `architecture.md` y devuelve el control al orquestador.
