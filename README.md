# AI App Builder — Sistema de skills encadenadas

Conjunto de skills para Claude Code que conducen la creación de una app de
principio a fin, fase por fase, con checklists, gates entre fases y trazabilidad
por ID. Diseñado para que no se te cuele nada.

**Autosuficiente:** el repo incluye TODAS las skills que necesita. Lo clonas y
construyes una app desde cero sin instalar ni depender de nada externo. Son dos
capas:

1. **8 skills de orquestación** (`app-*`): conducen el proceso fase por fase.
2. **32 skills de conocimiento**, solo las que las fases realmente invocan para el
   stack por defecto (Next.js, NestJS, Prisma/PostgreSQL, auth, testing, seguridad,
   diseño/UI, a11y…). Sin duplicados ni stacks que no usas. Vienen **dentro del
   repo**, no se referencian de fuera. Si cambias de stack (p. ej. Supabase o
   Drizzle), añades esa skill concreta y listo.

## Las 8 skills de orquestación

| Skill | Fase | Qué hace |
|-------|------|----------|
| `app-orchestrator` | Director | Conduce todo el flujo, comprueba los gates |
| `app-brainstorm` | 0 *(opcional)* | Da forma a una idea difusa hablando → `brief.md` |
| `app-discovery` | 1 | Entrevista guiada → `discovery.md` |
| `app-prd` | 2 | Requisitos con IDs RF-XX → `prd.md` |
| `app-architecture` | 3 | Datos + API + seguridad → `architecture.md` |
| `app-mockup` | 4 | Sistema de diseño + mockups navegables → `design-system.md` + `mockup/` |
| `app-scaffold` | 5 | Primer build funcional + tests derivado de todo → archivos |
| `app-audit` | 6 | Verifica trazabilidad → `audit.md` |

Las 32 de conocimiento son el resto de carpetas dentro de `skills/`. El manifiesto
completo (qué hace cada una, qué fase la usa y de dónde se copió) está en
[`skills/INDEX.md`](skills/INDEX.md).

**Autoridad — proceso vs. referencia.** Las `app-*` son **el proceso**: mandan
cuando construyes una app desde cero (sigue las fases y sus gates). Las 32 de
conocimiento son **referencia invocable en cualquier momento**: para un "testea
esto" o "arregla este bug" sueltos, se usan directamente — no hace falta pasar por
la Fase 0 ni por el flujo completo. Solo construir una app nueva entra por el
orquestador.

**Mantenimiento (evitar drift).** Las 32 son copias de un catálogo externo. Para
ver si han quedado desfasadas o re-sincronizarlas:

```bash
scripts/sync-skills.sh --check    # informa de diferencias con la fuente
scripts/sync-skills.sh --sync     # actualiza las copias desde la fuente
# Fuente por defecto: ~/.agents/skills (cámbiala con SKILLS_SRC=/ruta ...)
```

## Instalación en Claude Code

Copia TODAS las skills (orquestación + conocimiento) a tu carpeta de skills:

```bash
# A nivel de usuario (disponibles en todos tus proyectos)
cp -r skills/* ~/.claude/skills/

# O a nivel de proyecto (solo en este repo)
cp -r skills/* .claude/skills/
```

Copia `config/stack.md` a la raíz del proyecto donde vayas a trabajar y
ajústalo a tu stack antes de empezar.

## Cómo se usa

Simplemente dile a Claude Code:

> "Quiero crear una aplicación para [tu idea]"

(o la frase de arranque inequívoca: **"inicia el constructor de apps"**).

El orquestador se dispara, aplica el **gate de stack** (que `stack.md` exista y
no tenga campos `(definir)` sin resolver), inicializa git si hace falta, y
arranca. Si la idea aún es difusa ("tengo una idea pero no la tengo clara"),
empieza por la **Fase 0 (Brainstorm)** para darle forma hablando antes de
formalizar; si ya la tienes clara, salta directo a Discovery. A partir de ahí te
va llevando: no tienes que invocar cada
skill a mano. Al cerrar cada fase hace commit del artefacto y emite un bloque de
handoff con lo generado y la fase siguiente.

## Por qué funciona (los 3 mecanismos)

1. **Checklist (Definition of Done)**: cada skill tiene casillas obligatorias.
   No cierra hasta marcarlas.
2. **Gates entre fases**: cada skill comprueba que el artefacto anterior existe
   y está completo antes de avanzar. Evita el salto silencioso.
3. **Trazabilidad por ID**: cada requisito lleva un `RF-XX`. Arquitectura,
   mockup, código y tests lo referencian. La auditoría final comprueba que toda
   la cadena enlaza. Lo que no se mapea, se ha olvidado.

Y dos refuerzos que lo sostienen:

4. **Versionado por fase**: el proyecto va bajo git y cada gate cierra con un
   commit del artefacto. La trazabilidad por ID deja de ser una foto y pasa a
   ser histórica (cuándo y en qué fase cambió cada RF).
5. **Cambios retroactivos declarados**: cuando una fase descubre un hueco en un
   artefacto anterior, lo actualiza y lo declara en el handoff, en vez de
   parchearlo en silencio. El PRD nunca queda por detrás de la realidad.

> El sistema es **autosuficiente**: las skills de orquestación tiran de las skills
> de conocimiento que vienen **incluidas en el repo**. Ejemplos: diseño
> (`design-system-patterns`, `ui-design`) en el mockup; auth/API/datos
> (`auth-implementation-patterns`, `api-design-principles`, `prisma-development`)
> en arquitectura y scaffold; calidad (`testing`, `debugging-strategies`,
> `security-review`, `code-review-excellence`) en scaffold y auditoría. Todo viaja
> contigo: clonas el repo y funciona, sin instalar nada más.

---

## Ejemplo del proceso completo

Idea de partida: *"una app para gestionar el alquiler de armas en un club de tiro,
que registre quién se lleva qué arma y cuándo la devuelve"* (caso real tipo Ridon).

### Fase 1 — Discovery

Claude (vía `app-discovery`) pregunta por turnos. Tras la entrevista genera
`discovery.md`:

```markdown
# Discovery — Trazabilidad de alquiler de armas

## Problema
Hoy el control de qué socio se lleva qué arma se hace en papel. Se pierden
registros y no hay forma rápida de saber qué armas están fuera.

## Usuarios / Personas
- **Encargado de armería**: nivel técnico bajo, quiere registrar salidas y
  devoluciones rápido desde un móvil.
- **Administrador del club**: quiere informes y trazabilidad para inspecciones.

## Casos de uso principales
| ID | Caso de uso | Persona | Automatización |
|----|-------------|---------|----------------|
| CU-01 | Registrar salida de un arma a un socio | Encargado | manual (requiere juicio) |
| CU-02 | Registrar devolución | Encargado | manual |
| CU-03 | Ver armas actualmente fuera | Ambos | automatizar (consulta) |
| CU-04 | Generar informe de movimientos para inspección | Admin | automatizar |

## Restricciones
- Datos sensibles (armas + datos personales) → RGPD obligatorio
- Trazabilidad legal: ningún registro se borra, solo se anula

## Métricas de éxito
- Tiempo de registro de una salida < 30 segundos
- 100% de armas fuera localizables en cualquier momento

## Fuera de alcance (v1)
- Reserva anticipada de armas
- App nativa (será web responsive)
```

**Gate**: ✅ problema, personas, 4 casos de uso clasificados, datos sensibles
marcados, métrica medible. Avanza.

### Fase 2 — PRD

`app-prd` lee el discovery y genera `prd.md` con requisitos identificados:

```markdown
### RF-01 — Registrar salida de arma
**Descripción**: el encargado registra qué arma sale, a qué socio y cuándo.
**Persona**: Encargado de armería
**Prioridad**: alta
**Automatización**: manual (humano confirma la entrega física)
**Criterios de aceptación**:
- Dado un socio con licencia válida, cuando el encargado registra una salida,
  entonces queda guardada con arma, socio, fecha/hora y estado "fuera".
- Dado un socio sin licencia válida, cuando se intenta registrar, entonces el
  sistema lo bloquea y avisa.

### RF-03 — Listar armas fuera
**Prioridad**: alta · **Automatización**: automatizar
**Criterios de aceptación**:
- Dado el estado actual, cuando se consulta el listado, entonces se ven todas
  las armas con estado "fuera" y a qué socio.

### RNF-01 — RGPD y trazabilidad
**Descripción**: ningún registro se elimina físicamente (borrado lógico).
Acceso solo a usuarios autenticados con rol. Auditoría de quién consulta.
```

**Gate**: ✅ cada CU tiene RF, todos con ID y criterios, RNF de RGPD presente.
Avanza.

### Fase 3 — Arquitectura

`app-architecture` lee PRD + stack.md. Genera `architecture.md` con modelo de
datos, contrato API y threat model. La parte clave es la tabla de trazabilidad:

```markdown
## 6. Trazabilidad
| RF | Entidad(es) | Endpoint(s) |
|----|-------------|-------------|
| RF-01 | Movimiento, Arma, Socio | POST /api/movimientos/salida |
| RF-03 | Movimiento, Arma | GET /api/armas/fuera |
```

Y como hay datos sensibles, el threat model es obligatorio:

```markdown
## 5. Threat model
| Activo | Amenaza | Control | Cubre RNF |
|--------|---------|---------|-----------|
| Registros de armas | Borrado/manipulación | Borrado lógico + auditoría | RNF-01 |
| Datos de socios | Acceso no autorizado | Auth + roles | RNF-01 |
```

**Gate**: ✅ cada RF mapeado a entidad y endpoint, modelo con tipos, threat
model presente. Avanza.

### Fase 4 — Mockup

`app-mockup` genera un HTML por flujo: `flujo-01-salida.html`,
`flujo-03-armas-fuera.html`, enlazados desde `index.html`. Cada pantalla anota
el RF que cubre. El encargado puede clicar y validar el flujo antes de programar.

### Fase 5 — Scaffold

`app-scaffold` lee todo y genera el esqueleto (aquí con el stack por defecto
Next.js + NestJS + Prisma). Cada archivo lleva su comentario de trazabilidad:

```typescript
// Implementa: RF-01 (registrar salida de arma)
// Ver: .builder/architecture.md §4
@Post('salida')
async registrarSalida(@Body() dto: SalidaDto) {
  // TODO: validar licencia del socio (criterio de aceptación 2)
  // TODO: crear movimiento con estado "fuera"
}
```

Más migraciones de Prisma para las entidades y tests base referenciando los
criterios de aceptación.

### Fase 6 — Auditoría

`app-audit` recorre todo y genera la matriz:

```markdown
## Matriz de trazabilidad
| RF | Discovery | PRD | Arquitectura | Mockup | Código | Test | Estado |
|----|-----------|-----|--------------|--------|--------|------|--------|
| RF-01 | CU-01 | ✅ | ✅ | ✅ | ✅ | ✅ | OK |
| RF-03 | CU-03 | ✅ | ✅ | ✅ | ✅ | ❌ | hueco menor |

## Huecos detectados
### Menores
- RF-03 no tiene test. Recomendación: añadir test del listado de armas fuera.
```

Aquí ves el valor: sin la auditoría, el test olvidado de RF-03 habría pasado
desapercibido. El orquestador te diría que vuelvas brevemente a la Fase 5 para
cerrarlo, y el proyecto queda completo y trazado de punta a punta.
