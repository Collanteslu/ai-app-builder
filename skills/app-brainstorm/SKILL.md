---
name: app-brainstorm
description: Fase 0 (opcional) del proceso de crear una app. Da forma a una idea AÚN DIFUSA hablando con el usuario, antes de formalizar nada: explora el problema real, reta supuestos y compara enfoques. Úsala cuando la idea todavía no está clara y el usuario diga cosas como "tengo una idea pero no la tengo clara", "ayúdame a pensarla", "no sé bien qué quiero", "dale forma conmigo", "estoy dándole vueltas a algo". Es la fase divergente previa al Discovery (que es la convergente). Genera brief.md.
---

# Fase 0 — Brainstorm (dar forma a la idea)

Objetivo: convertir una corazonada vaga en un **concepto con forma**, hablando.
Esta fase es DIVERGENTE: explora, reta y abre alternativas. No formaliza todavía
(eso es Discovery, la Fase 1). Aquí no hay tablas de casos de uso ni IDs: hay una
conversación que destila qué es realmente la idea y por qué merece existir.

Es OPCIONAL. Si el usuario ya llega con la idea clara, sáltala y ve directo a
Discovery. Úsala cuando la idea aún es niebla.

## Diferencia con Discovery (no las confundas)

- **Brainstorm (esta fase)**: ¿qué construimos y por qué? Diverge. Reta el
  supuesto de partida, busca el problema real bajo la feature pedida, compara
  formas distintas de resolverlo, recorta lo que no hace falta. Salida: `brief.md`.
- **Discovery (Fase 1)**: dado un concepto con forma, ¿quién, qué casos de uso,
  qué restricciones? Converge y formaliza. Salida: `discovery.md`.

Si te encuentras haciendo tablas de casos de uso aquí, te has adelantado: eso es
Discovery. Aquí se piensa, no se documenta el catálogo.

## Cómo conduces la conversación

Como la skill de brainstorming clásica, pero orientada a producto:

1. **Una pregunta cada vez.** Nada de cuestionarios. Espera respuesta y profundiza.
2. **Prefiere opción múltiple** cuando puedas: es más fácil de contestar que el
   folio en blanco ("¿esto es más para A, B o C?").
3. **Busca el problema real, no la solución pedida.** Si el usuario pide "una
   app con login y dashboard", pregunta qué decisión o dolor hay detrás. La
   feature pedida rara vez es el problema.
4. **Reta el supuesto de partida** con respeto: "¿y si esto no necesitara app y
   bastara una hoja compartida?" Si la idea sobrevive al reto, es más fuerte.
5. **Propón 2-3 direcciones** distintas de cómo podría ser la app, con su
   compromiso, y recomienda una razonada. No te cases con la primera.
6. **YAGNI sin piedad.** Por cada cosa que el usuario quiere meter, pregunta si
   hace falta en la v1. Recorta y dilo.
7. **Detecta si es demasiado grande.** Si lo que describe son varios sistemas
   independientes (chat + facturación + analítica…), no le des forma a todo:
   ayúdale a partirlo y dale forma SOLO al primer trozo. Cada trozo hará luego
   su propio ciclo discovery→…→auditoría.

Sigue hasta que tú y el usuario podáis decir la idea en una frase y él la
reconozca como suya. Ese es el momento de escribir el brief.

## Salida: brief.md

Guárdalo en `.builder/brief.md`. Es corto a propósito (media página):

```markdown
# Brief — [Nombre provisional]

## La idea en una frase
[El concepto destilado. Si no cabe en una frase, aún no tiene forma.]

## El problema real
[Qué dolor o decisión hay detrás. A menudo NO es lo que se pidió literalmente.]

## Para quién (esbozo)
[Quién lo sufre hoy. Sin formalizar personas todavía — eso es Discovery.]

## Forma de la solución
[Qué ES y qué NO ES. El "shape": web/app, asistida por IA o no, el corazón
de la cosa en 2-3 frases.]

## Direcciones consideradas
- **Elegida**: [enfoque] — por qué encaja.
- Descartada: [otro enfoque] — por qué no.
- Descartada: [otro] — por qué no.

## Recortado de la v1 (YAGNI)
- [Lo que deliberadamente dejamos fuera y por qué]

## Preguntas abiertas para Discovery
- [Lo que queda por concretar en la Fase 1: personas exactas, casos de uso,
  restricciones, métricas…]
```

## Definition of Done

No cierres la fase hasta que TODO esto esté:

- [ ] La idea cabe en UNA frase y el usuario la reconoce como suya
- [ ] El problema real está identificado (no solo la feature que se pidió)
- [ ] Al menos una dirección alternativa considerada y descartada con motivo
- [ ] Recorte YAGNI explícito (algo que se decidió dejar fuera de la v1)
- [ ] Lista de preguntas abiertas que hereda Discovery
- [ ] El usuario ha confirmado el brief antes de avanzar

Cuando esté completo, guarda `brief.md`, haz commit y devuelve el control al
orquestador. La Fase 1 (Discovery) partirá de este brief en lugar de la idea cruda.
