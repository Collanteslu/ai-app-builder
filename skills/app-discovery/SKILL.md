---
name: app-discovery
description: Fase 1 del proceso de crear una app. Entrevista guiada para definir el problema, el usuario, los casos de uso y qué se puede automatizar. Úsala cuando empiece un proyecto nuevo y aún no exista discovery.md, o cuando el usuario diga "ayúdame a definir la idea", "qué necesito antes de programar", "vamos a empezar el descubrimiento". Genera discovery.md.
---

# Fase 1 — Discovery (descubrimiento)

Objetivo: pasar de una idea vaga a un problema bien definido. NO escribas
código ni requisitos aún. Tu trabajo es preguntar y escuchar.

## Punto de partida

Si existe `.builder/brief.md` (la Fase 0 dio forma a la idea), **léelo y arranca
desde ahí**: no repitas las preguntas que ya quedaron resueltas en el brief;
ataca directamente sus "preguntas abiertas para Discovery". Si no hay brief
(la idea ya venía clara y se saltó la Fase 0), empieza desde la idea cruda.

## Cómo entrevistas

Haz UNA pregunta a la vez (o como mucho un grupo pequeño), espera respuesta, y
profundiza. No sueltes un cuestionario entero de golpe. Adapta las siguientes
según lo que ya sepas por la conversación o por `stack.md`:

1. **Problema**: ¿Qué tarea o decisión manual quieres eliminar o mejorar? ¿Qué
   duele hoy?
2. **Usuario**: ¿Quién lo usará? ¿Uno o varios perfiles? Define cada persona
   (rol, nivel técnico, qué quiere conseguir).
3. **Estado actual**: ¿Cómo se resuelve hoy sin la app? (Excel, papel, a mano…)
4. **Casos de uso**: ¿Cuáles son las 3-5 acciones principales que alguien hará?
5. **Automatización**: para cada caso de uso, ¿es repetitivo y con reglas claras?
   Clasifícalo: automatizar / IA con humano en el bucle / manual.
6. **Restricciones**: ¿RGPD, datos sensibles, cumplimiento fiscal, plazos, presupuesto?
7. **Éxito**: ¿Cómo sabrás que funciona? (métrica concreta, no "que vaya bien")
8. **Fuera de alcance**: ¿Qué NO va a hacer la app, al menos en v1?

## Salida: discovery.md

Genera el fichero con esta estructura exacta:

```markdown
# Discovery — [Nombre del proyecto]

## Problema
[1-2 párrafos]

## Usuarios / Personas
- **[Persona 1]**: rol, nivel técnico, objetivo
- **[Persona 2]**: ...

## Situación actual
[Cómo se hace hoy]

## Casos de uso principales
| ID | Caso de uso | Persona | Automatización |
|----|-------------|---------|----------------|
| CU-01 | ... | ... | automatizar / humano-en-bucle / manual |

## Restricciones
- [RGPD / fiscal / sensibles / plazos / presupuesto]

## Métricas de éxito
- [Métrica concreta y medible]

## Fuera de alcance (v1)
- [...]
```

## Definition of Done

No cierres la fase hasta que TODO esto esté:

- [ ] Problema descrito en términos de tarea/decisión concreta
- [ ] Al menos una persona definida con su objetivo
- [ ] Mínimo 3 casos de uso, cada uno con su clasificación de automatización
- [ ] Restricciones revisadas (si hay datos sensibles, marcado explícito)
- [ ] Al menos una métrica de éxito medible
- [ ] Fuera de alcance escrito (aunque sea breve)

Si falta algo, sigue preguntando. Cuando esté completo, guarda
`discovery.md` y avisa al orquestador de que la Fase 1 está lista.
