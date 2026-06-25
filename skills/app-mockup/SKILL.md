---
name: app-mockup
description: Fase 4 del proceso de crear una app. Genera mockups PROFESIONALES y navegables a partir del PRD, con una dirección de diseño coherente (paleta única, tipografía con personalidad, iconos reales, shell de navegación y estados). NO genera el look genérico por defecto de Tailwind. Úsala cuando exista prd.md y el usuario quiera "hacer el mockup", "wireframe", "prototipo", "diseño de la interfaz", "ver cómo quedaría". Genera design-system.md y los HTML en mockup/.
---

# Fase 4 — Mockup profesional (con dirección de diseño)

Objetivo: visualizar los flujos con un diseño que parezca un producto real, no
un andamiaje. El fallo más común es escupir el genérico de IA: fondo slate-100,
tarjetas blancas redondeadas, un color aleatorio por pantalla y emojis como
iconos. Eso queda prohibido aquí. Cada decisión visual debe ser deliberada y
coherente en toda la app.

## Antes de empezar (gates de entrada)

1. Lee `prd.md`. Cada pantalla debe corresponder a RF-XX. Si no hay PRD, vuelve
   a la Fase 2.
2. Lee `stack.md`: si el proyecto es **legacy (CI3)**, el mockup debe poder
   traducirse a vistas PHP/HTML clásicas (evita depender de componentes que solo
   existan en React); mantén el HTML/CSS portable.
3. **Fija una dirección visual.** Si el usuario no dio ninguna, pregúntale UNA
   referencia o estilo ("limpio tipo Linear", "serio tipo banca", "cálido y
   cercano"…). Si no responde o dice "tú decides", elige tú una dirección
   concreta justificada por el dominio del PRD y decláralo. Sin dirección, el
   resultado siempre tira a genérico.

> **Skills de diseño incluidas (úsalas).** Dirección visual — `premium-frontend-ui`,
> `ui-design`, `ux-design`; sistema y tokens — `design-system-patterns`;
> calidad transversal — `responsive-design`, `accessibility-a11y`,
> `interaction-design`; componentes — `shadcn` si el proyecto usa shadcn.
> Aun así, los principios mínimos para no caer en el genérico están aquí abajo y
> son obligatorios siempre.

## Principios de diseño (autocontenidos, obligatorios)

Para no producir el "look de IA por defecto", aplica estos seis principios. Son
la dirección mínima incrustada; no requieren ninguna skill externa:

1. **Una paleta intencional, no slate-100.** Elige un fondo y superficies con
   carácter ligado al dominio; el gris azulado por defecto está prohibido.
2. **Un acento de marca, con disciplina.** Un color de acento en toda la app;
   los demás colores son semánticos (éxito/error), nunca "uno por pantalla".
3. **Tipografía con personalidad.** Una display con carácter (uso comedido) +
   una body legible, ambas reales (Google Fonts). La fuente del sistema sola = genérico.
4. **Iconos reales, nunca emojis.** Lucide/SVG. Un emoji como icono de UI delata IA.
5. **Jerarquía y espacio deliberados.** Tamaños, pesos y espaciado que guían el
   ojo; no todo al mismo nivel dentro de tarjetas blancas iguales.
6. **Un elemento firma.** Un detalle memorable que distingue la app — uno solo.

## Paso 1 — Sistema de diseño (design-system.md)

ANTES de tocar ninguna pantalla, define el sistema y guárdalo en
`.builder/design-system.md`. Todas las pantallas y luego el scaffold lo heredan.

```markdown
# Sistema de diseño — [Proyecto]

## Dirección
[1-2 frases: el estilo elegido y por qué encaja con el dominio]

## Color (4-6 hex con nombre)
- --bg: #...
- --surface: #...
- --text: #...
- --accent: #...        ← UN acento de marca, usado con disciplina
- --danger / --success: #...  ← semánticos, NO un color por pantalla

## Tipografía
- Display: [fuente con carácter, uso comedido] vía Google Fonts
- Body: [fuente legible complementaria]
- (escala y pesos definidos)

## Iconos
Librería real (lucide vía CDN o SVG inline). NUNCA emojis como iconos de UI.

## Layout / shell
[Estructura común: topbar o sidebar persistente, dónde va la navegación por rol]

## Elemento firma
[El detalle memorable que distingue esta app — uno, no diez]
```

Revisa el sistema contra el genérico: si tu paleta/tipografía es la que sacarías
para cualquier app, cámbiala y di por qué. Solo entonces construyes.

## Paso 2 — Shell de navegación (no pantallas isla)

Crea un layout común reutilizado por todas las pantallas de un mismo rol:
topbar o sidebar persistente con el menú del rol, identidad del usuario y salida.
Las pantallas viven DENTRO del shell; no son HTML sueltos que enlazan con texto.
La navegación entre secciones se hace desde el menú, no con "← volver" de texto.

## Paso 3 — Pantallas por rol y flujo

Para cada rol del PRD y cada flujo de prioridad alta, una pantalla DENTRO del
shell, derivada de los RF. Reglas de calidad:

- Aplica los tokens de `design-system.md`. Cero colores aleatorios por pantalla.
- Iconos reales (lucide/SVG), nunca emojis de adorno.
- No mezcles funciones dispares en una pantalla (no juntes catálogo + pago en una).
- Incluye los **estados reales**, no solo el camino feliz:
  vacío ("aún no hay reservas, crea la primera"), carga, error, y bloqueo.
- Copy desde el lado del usuario (verbos de acción claros: "Reservar", "Entregar"),
  no jerga del sistema.
- Datos de ejemplo realistas y consistentes entre pantallas.
- Marca el RF-XX que cubre cada pantalla (comentario o etiqueta discreta) para la
  trazabilidad de la auditoría.

## Salida

```
.builder/
├── design-system.md          ← el sistema, fuente de verdad visual
└── mockup/
    ├── index.html            ← entrada con selección de rol
    ├── _shell.css            ← tokens + estilos del shell (compartido)
    ├── socio-*.html
    ├── encargado-*.html
    └── admin-*.html
```

Navegable abriendo `index.html`. Fidelidad media-alta: debe parecer producto.

## Definition of Done

- [ ] `design-system.md` con paleta de 4-6 hex, tipografía emparejada e icono real
- [ ] El sistema NO es el genérico por defecto (revisado y justificado)
- [ ] Shell de navegación común por rol; las pantallas viven dentro, no son islas
- [ ] Iconos reales (lucide/SVG), CERO emojis como iconos de UI
- [ ] Un acento de marca coherente; colores semánticos solo para estado
- [ ] Estados vacío/carga/error presentes, no solo el camino feliz
- [ ] Cada pantalla mapea su RF-XX
- [ ] Copy claro desde el lado del usuario

Autocrítica antes de entregar: mira el conjunto. Si parece "una app de IA
cualquiera", no está hecho: aplica la regla de Chanel (quita un adorno) y sube
el carácter del elemento firma. Cuando convenza, devuelve el control al orquestador.
