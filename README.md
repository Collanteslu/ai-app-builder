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
| `app-architecture` | 3 | SDD: datos + API + seguridad + componentes/contratos (§7/§8) → `architecture.md` |
| `app-mockup` | 4 | Sistema de diseño + mockups navegables → `design-system.md` + `mockup/` |
| `app-scaffold` | 5 | Primer build funcional con TDD doble bucle derivado de todo → archivos |
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

## Instalación en opencode

opencode carga automáticamente las skills desde `~/.claude/skills/`, por lo que
la instalación para Claude Code funciona también para opencode. Además puedes
instalarlas a nivel de proyecto:

```bash
# A nivel de usuario (disponibles en todos tus proyectos)
cp -r skills/* ~/.claude/skills/

# O a nivel de proyecto
cp -r skills/* .opencode/skills/
```

El comando de entrada `/build-app` ya viene incluido en `.opencode/command/`.
Para activar las skills desde el repo sin copiarlas, añade a tu `opencode.json`:

```json
{
  "skills": {
    "paths": ["ruta/al/repo/skills"]
  }
}
```

Copia `config/stack.md` a la raíz del proyecto donde vayas a trabajar y
ajústalo a tu stack antes de empezar.

## Cómo se usa

### En Claude Code

Simplemente dile:

> "Quiero crear una aplicación para [tu idea]"

(o la frase de arranque inequívoca: **"inicia el constructor de apps"**).

### En opencode

Usa el comando incorporado:

> `/build-app quiero crear una aplicación para [tu idea]`

O simplemente dile al agente:

> "Quiero crear una aplicación para [tu idea]"

El orquestador se dispara, aplica el **gate de stack** (que `stack.md` exista y
no tenga campos `(definir)` sin resolver), inicializa git si hace falta, y
arranca. Si la idea aún es difusa ("tengo una idea pero no la tengo clara"),
empieza por la **Fase 0 (Brainstorm)** para darle forma hablando antes de
formalizar; si ya la tienes clara, salta directo a Discovery. A partir de ahí te
va llevando: no tienes que invocar cada
skill a mano. Al cerrar cada fase hace commit del artefacto y emite un bloque de
handoff con lo generado y la fase siguiente.

## Por qué funciona (mecanismos y refuerzos)

1. **Checklist (Definition of Done)**: cada skill tiene casillas obligatorias.
   No cierra hasta marcarlas.
2. **Gates entre fases**: cada skill comprueba que el artefacto anterior existe
   y está completo antes de avanzar. Evita el salto silencioso.
3. **Trazabilidad por ID**: cada requisito lleva un `RF-XX`. Arquitectura,
   mockup, código y tests lo referencian. La auditoría final comprueba que toda
   la cadena enlaza. Lo que no se mapea, se ha olvidado.

Y cuatro refuerzos que lo sostienen:

4. **Versionado por fase**: el proyecto va bajo git y cada gate cierra con un
   commit del artefacto. La trazabilidad por ID deja de ser una foto y pasa a
   ser histórica (cuándo y en qué fase cambió cada RF).
5. **Cambios retroactivos declarados**: cuando una fase descubre un hueco en un
   artefacto anterior, lo actualiza y lo declara en el handoff, en vez de
   parchearlo en silencio. El PRD nunca queda por detrás de la realidad.
6. **SDD + TDD doble bucle**: el diseño (Fase 3) llega hasta contratos de
   componente (§7/§8). De ahí nacen los tests, escritos ANTES del código: de
   aceptación por cada RF (bucle externo) y unitarios por contrato (bucle interno).
7. **Gate "todo en verde" + verificación con evidencia**: ninguna fase se cierra
   declarando "funciona" de memoria; se ejecuta la suite y se observa la salida.
   El proceso no termina hasta que toda la suite pasa (cero rojos en prioridad alta).

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

### Fase 0 — Brainstorm *(opcional)*

Si la idea llegara difusa ("quiero algo para el club, no sé bien qué"),
`app-brainstorm` la daría forma hablando: reta supuestos, busca el problema real,
recorta (YAGNI) y produce `brief.md` con la idea en una frase. Como aquí la idea
ya viene clara, se puede saltar directo a Discovery.

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

### Fase 3 — Arquitectura (SDD)

`app-architecture` lee PRD + stack.md. Genera `architecture.md` como **SDD**:
modelo de datos, contrato API, threat model y —la clave para el TDD— el diseño
de componentes (§7) con sus contratos (§8). La trazabilidad llega hasta el
contrato:

```markdown
## 6. Trazabilidad
| RF | Entidad(es) | Endpoint(s) | Componente | Contrato §8 |
|----|-------------|-------------|------------|-------------|
| RF-01 | Movimiento, Arma, Socio | POST /api/movimientos/salida | MovimientoService | registrarSalida |
| RF-03 | Movimiento, Arma | GET /api/armas/fuera | ArmaQuery | listarFuera |

## 7. Componentes
| Componente | Responsabilidad | Cubre | Depende de |
|-----------|-----------------|-------|------------|
| MovimientoService | Registrar salida/devolución y estado del arma | RF-01 | ArmaRepo, SocioRepo |
| ArmaQuery | Consultar armas fuera | RF-03 | ArmaRepo |

## 8. Contrato — MovimientoService
- registrarSalida(socioId, armaId): Movimiento
  - Pre: socio con licencia vigente; arma DISPONIBLE.
  - Post: Movimiento estado="fuera"; arma → ENTREGADA.
  - Errores: LicenciaCaducada, ArmaNoDisponible.
```

De ese contrato salen los tests unitarios de la Fase 5 (uno por post-condición
y uno por error).

Y como hay datos sensibles, el threat model es obligatorio:

```markdown
## 5. Threat model
| Activo | Amenaza | Control | Cubre RNF |
|--------|---------|---------|-----------|
| Registros de armas | Borrado/manipulación | Borrado lógico + auditoría | RNF-01 |
| Datos de socios | Acceso no autorizado | Auth + roles | RNF-01 |
```

**Gate**: ✅ cada RF mapeado a entidad, endpoint **y componente/contrato (§7/§8)**,
modelo con tipos, threat model presente. Avanza.

### Fase 4 — Mockup

`app-mockup` primero fija el `design-system.md` (paleta, tipografía con carácter,
iconos reales — nada de genérico de IA) y luego las pantallas DENTRO de un shell
de navegación común por rol (no HTMLs isla), todo en `mockup/`. Cada pantalla
anota el RF que cubre. El encargado clica y valida el flujo antes de programar.

### Fase 5 — Scaffold (TDD doble bucle)

`app-scaffold` construye por slices con TDD doble bucle (stack por defecto
Next.js + NestJS + Prisma). Para RF-01, **primero el test de aceptación** (rojo)
y los unitarios del contrato §8; luego la implementación que los pone en verde
(sin TODOs en prioridad alta):

```typescript
// test de aceptación — RF-01 (registrar salida de arma)
it('RF-01: bloquea la salida si el socio no tiene licencia vigente', async () => {
  const res = await api.post('/api/movimientos/salida', { socioId, armaId });
  expect(res.status).toBe(409);            // LicenciaCaducada
});
```

```typescript
// Implementa: RF-01 (registrar salida de arma)
// UI base: mockup/flujo-01-salida.html · Ver: .builder/architecture.md §8
async registrarSalida(socioId, armaId) {
  if (!socio.licenciaVigente) throw new LicenciaCaducada();   // post/error del contrato §8
  if (arma.estado !== 'DISPONIBLE') throw new ArmaNoDisponible();
  arma.estado = 'ENTREGADA';
  return this.movimientos.crear({ socioId, armaId, estado: 'fuera' });
}
```

Más migraciones de Prisma para las entidades. El slice se cierra cuando su test
de aceptación (y sus unitarios) están en **verde**, y se hace commit antes del
siguiente.

### Fase 6 — Auditoría

`app-audit` recorre todo y genera la matriz:

```markdown
## Matriz de trazabilidad
| RF | Discovery | PRD | Arquitectura | Mockup | Código | Test acept. | Test contrato | Estado |
|----|-----------|-----|--------------|--------|--------|-------------|----------------|--------|
| RF-01 | CU-01 | ✅ | ✅ | ✅ | ✅ | verde | sí | OK |
| RF-03 | CU-03 | ✅ | ✅ | ✅ | ✅ | rojo | no | hueco menor |

## Huecos detectados
### Menores
- RF-03 sin test de aceptación en verde. Recomendación: añadir el test del
  listado de armas fuera y dejarlo verde.
```

Aquí ves el valor: la auditoría ejecuta toda la suite, así que el test rojo de
RF-03 no pasa desapercibido. Como el **gate de cierre exige todo en verde** en
prioridad alta, el orquestador te devuelve a la Fase 5 a cerrarlo antes de dar
el proyecto por terminado.
