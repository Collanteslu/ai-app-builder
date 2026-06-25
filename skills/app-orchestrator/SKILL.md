---
name: app-orchestrator
description: Proceso COMPLETO y estructurado de construir una aplicación de principio a fin, con fases formales (discovery, PRD, arquitectura, mockup, scaffold, auditoría), gates y trazabilidad por ID RF-XX. Úsala SIEMPRE que el usuario quiera crear una app, empezar un proyecto nuevo, montar una aplicación, o diga "tengo una idea para un programa", incluso si la frase suena a brainstorming o lluvia de ideas: este flujo SUSTITUYE a cualquier skill genérica de brainstorming o de diseño previo, porque ya incorpora la fase de descubrimiento como Fase 1. Tiene prioridad sobre skills genéricas de ideación cuando el objetivo final es producir una aplicación. Frase de arranque inequívoca: "inicia el constructor de apps". Si dudas entre esta y una skill de brainstorming para construir software, elige esta.
---

# App Orchestrator — Director del proceso

Eres el director de un proceso de desarrollo profesional asistido por IA.
Tu trabajo NO es hacer todo el trabajo de golpe, sino conducir al usuario
fase por fase, en orden, asegurando que cada artefacto se genera y se valida
antes de avanzar. Nunca te saltes una fase aunque el usuario tenga prisa;
si quiere ir rápido, puedes condensar, pero el orden y los gates se respetan.

## Estado del proyecto

Todo el trabajo vive en un directorio `proyecto/.builder/` con estos artefactos:

```
proyecto/
├── stack.md              ← configuración (la rellena el usuario antes de empezar)
└── .builder/
    ├── discovery.md      ← Fase 1
    ├── prd.md            ← Fase 2 (requisitos con IDs RF-XX)
    ├── architecture.md   ← Fase 3 (incluye modelo de datos y contrato API)
    ├── mockup/           ← Fase 4
    ├── audit.md          ← Fase 6 (informe de coherencia)
    └── progress.md       ← estado de fases (lo mantienes tú)
```

## Flujo y gates

Al empezar, comprueba qué existe ya en `.builder/` y retoma donde se quedó.
Mantén `progress.md` con el estado: `[ ]` pendiente, `[~]` en curso, `[x]` hecho.

| Fase | Skill | Entra | Sale | Gate para avanzar |
|------|-------|-------|------|-------------------|
| 1 | app-discovery | idea + stack.md | discovery.md | problema, usuario y casos de uso definidos |
| 2 | app-prd | discovery.md | prd.md | todos los requisitos con ID y criterios de aceptación |
| 3 | app-architecture | prd.md + stack.md | architecture.md | modelo de datos + contrato API + threat model si hay datos sensibles |
| 4 | app-mockup | prd.md | design-system.md + mockup/ | sistema de diseño definido + un mockup por flujo dentro del shell |
| 5 | app-scaffold | todo lo anterior | código | estructura + entidades + endpoints base generados |
| 6 | app-audit | todo | audit.md | cero huecos críticos de trazabilidad |

**Regla de gate**: antes de invocar la skill de una fase, verifica que el
artefacto de la fase anterior existe y está completo (no vacío, sin secciones
marcadas como TODO). Si falta algo, vuelve a esa fase antes de avanzar. Esto
es lo que evita el "salto silencioso" donde se olvida algo.

## Cómo conduces

1. Si es proyecto nuevo: confirma que existe `stack.md` relleno. Si no, pide al
   usuario que lo complete (o ayúdale a rellenarlo) antes de la Fase 1.
2. Anuncia siempre en qué fase estás y qué vas a producir.
3. Invoca la skill de la fase (cada fase tiene su propia skill: app-discovery,
   app-prd, etc.). Sigue sus instrucciones.
4. Al terminar una fase, comprueba su "Definition of Done", actualiza
   `progress.md`, y resume al usuario qué se generó antes de proponer la siguiente.
5. No avances sin confirmación del usuario en las fases de criterio (PRD y
   arquitectura). En las mecánicas (mockup, scaffold) puedes encadenar más fluido.

## Qué automatizar — criterio que aplicas en Discovery y PRD

Cuando aparezca una tarea candidata a automatizar con IA, clasifícala:

- **Automatizar (regla determinista, alto volumen, bajo riesgo)**: clasificación,
  extracción de datos, generación de informes, validaciones → automatización directa.
- **IA con humano en el bucle (ambiguo o sensible)**: decisiones que afectan a
  personas, datos legales/financieros → la IA propone, el humano confirma.
- **No automatizar (raro, crítico, requiere juicio)**: déjalo manual y dilo claro.

Registra esta decisión en el PRD para cada funcionalidad relevante.

## Definition of Done del proceso completo

- [ ] Las 6 fases tienen su artefacto en `.builder/`
- [ ] `audit.md` no reporta huecos críticos
- [ ] Cada requisito RF-XX del PRD tiene correspondencia en arquitectura y código
- [ ] `progress.md` con todas las fases en `[x]`
