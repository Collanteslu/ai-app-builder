---
name: app-prd
description: Fase 2 del proceso de crear una app. Genera el PRD (documento de requisitos de producto) a partir de discovery.md, con requisitos funcionales y no funcionales identificados con IDs (RF-XX, RNF-XX) y criterios de aceptación. Úsala cuando exista discovery.md y el usuario quiera "generar el PRD", "escribir los requisitos", "documento de requisitos". Genera prd.md.
---

# Fase 2 — PRD (requisitos de producto)

Objetivo: convertir el discovery en requisitos accionables y trazables.
La clave profesional aquí es la **trazabilidad por ID**: cada requisito lleva
un identificador único que arquitectura, código y tests referenciarán después.
Sin esto, las cosas se olvidan silenciosamente.

## Antes de empezar (gate de entrada)

Lee `discovery.md`. Si no existe o está incompleto, no continúes: vuelve a la
Fase 1. El PRD se construye SOBRE el discovery, no desde cero.

## Cómo generas el PRD

Convierte cada caso de uso del discovery en uno o varios requisitos
funcionales. Cada requisito debe ser verificable (algo que se pueda probar como
cumplido o no). Asigna IDs correlativos:

- **RF-XX**: requisitos funcionales (qué hace el sistema)
- **RNF-XX**: requisitos no funcionales (rendimiento, seguridad, RGPD, usabilidad)

Cada requisito funcional lleva criterios de aceptación en formato Given/When/Then
(Dado/Cuando/Entonces) para que sea testeable.

## Salida: prd.md

```markdown
# PRD — [Nombre del proyecto]

## 1. Objetivo
[Una frase: qué resuelve y para quién]

## 2. Personas
[Heredadas de discovery.md, refinadas]

## 3. Requisitos funcionales
### RF-01 — [Título]
**Descripción**: [qué hace]
**Persona**: [quién lo usa]
**Prioridad**: alta / media / baja
**Automatización**: automatizar / humano-en-bucle / manual
**Criterios de aceptación**:
- Dado [contexto], cuando [acción], entonces [resultado esperado]

### RF-02 — ...

## 4. Requisitos no funcionales
### RNF-01 — [Rendimiento / Seguridad / RGPD / etc.]
**Descripción**: [criterio medible, p.ej. "respuesta < 500ms en p95"]

## 5. Métricas de éxito
[Heredadas de discovery, cuantificadas]

## 6. Fuera de alcance (v1)
[...]

## 7. Supuestos y dependencias
[Integraciones externas, decisiones pendientes]
```

## Reglas de calidad

- Un requisito = una capacidad verificable. Si un RF tiene varios "y", divídelo.
- Si hay datos personales o sensibles (revisa restricciones del discovery),
  añade RNF de RGPD/seguridad obligatorios. No es opcional.
- Marca prioridades para que el scaffold sepa qué construir primero.

## Gate ejecutable de trazabilidad (duro)

Igual que la Fase 6 no se cierra "de memoria", esta tampoco. El template incluye
un linter de trazabilidad temprana, `scripts/trace-lint.mjs`, que coteja
`discovery.md` ↔ `prd.md` ↔ `architecture.md` y devuelve **exit≠0** si hay un
hueco CRÍTICO (un CU sin RF, un RF sin criterio de aceptación). Pégale la salida
real, no la resumas.

El template aún no se ha copiado (eso es la Fase 5), así que **localiza el script**
en el constructor instalado, en este orden, y ejecútalo desde la raíz del
proyecto (lee `.builder/` del directorio actual):

```bash
# Windows (PowerShell) — usa la primera ruta que exista:
node .claude\template\scripts\trace-lint.mjs   # instalado en el proyecto
# node template\scripts\trace-lint.mjs          # repo del constructor abierto (opencode)
# node "$env:USERPROFILE\.claude\template\scripts\trace-lint.mjs"  # instalación global
```

Para esta fase, los críticos relevantes son `CU-SIN-RF` y `RF-SIN-CRITERIO`. Si
exit≠0 por uno de ellos, **no cierres la fase**: ciérralo antes. (El crítico
`RF-SIN-ARQUITECTURA` aún no aplica aquí —la arquitectura no existe— y el script
lo ignora si falta `architecture.md`.)

## Definition of Done

- [ ] Cada caso de uso del discovery tiene al menos un RF que lo cubre
- [ ] Todos los RF tienen ID, criterios de aceptación y clasificación de automatización
- [ ] Hay RNF de seguridad/RGPD si el discovery marcó datos sensibles
- [ ] Métricas de éxito cuantificadas
- [ ] Objetivo en una sola frase clara
- [ ] **`trace-lint.mjs` ejecutado con exit 0** (cero críticos de PRD); la salida real se anota en el handoff

Cuando esté completo, guarda `prd.md` y devuelve el control al orquestador.
