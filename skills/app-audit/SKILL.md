---
name: app-audit
description: Fase 6 y final del proceso de crear una app. Audita la coherencia y trazabilidad de todos los artefactos (discovery, PRD, arquitectura, mockup, código) y reporta huecos. Úsala cuando quieras "verificar que no falta nada", "auditar el proyecto", "comprobar trazabilidad", "revisión final antes de cerrar". Genera audit.md.
---

# Fase 6 — Auditoría de coherencia

Objetivo: cazar lo que se haya colado. Esta es la red de seguridad del proceso:
recorre todos los artefactos y verifica que cada cosa enlaza con la siguiente.
Lo que no se mapea, se ha olvidado.

## Qué lees

Todos los artefactos de `.builder/`: `discovery.md`, `prd.md`,
`architecture.md`, `mockup/`, y el código generado (busca los comentarios de
trazabilidad `RF-XX`).

## Comprobaciones de trazabilidad

Recorre las cadenas en ambos sentidos y reporta cualquier rotura:

1. **Caso de uso → RF**: ¿cada CU-XX del discovery tiene al menos un RF en el PRD?
2. **RF → arquitectura**: ¿cada RF aparece en la tabla de trazabilidad de la
   arquitectura, con entidad y endpoint?
3. **RF → mockup**: ¿cada RF de prioridad alta tiene una pantalla que lo representa?
4. **RF → código**: ¿cada RF tiene un archivo con su comentario de trazabilidad?
5. **RF → test**: ¿cada RF de prioridad alta tiene al menos un test?
5b. **Suite en verde (gate de cierre duro):** ejecuta toda la suite (unit +
    aceptación + e2e del flujo principal) y observa la salida. Un solo test en
    rojo en prioridad alta → bloquea el cierre; indica al orquestador a qué fase
    volver. Media/baja en `.skip` no bloquea.
6. **WIRING: fetch → endpoint**: busca todos los `fetch('/api/` en el código de
   las páginas. Para cada uno, comprueba que existe el archivo `route.ts` en la
   ruta correspondiente. Reporta los fetch huérfanos (sin endpoint) como
   **hueco crítico**.
7. **WIRING: endpoint → fetch**: busca todos los `route.ts` en `src/app/api/`.
   Para cada endpoint POST/GET que devuelve datos, comprueba que al menos una
   página lo llama con fetch(). Reporta endpoints huérfanos (sin página que los
   consuma) como **hueco menor**.
8. **ZERO INLINE DATA**: busca páginas que contengan arrays de datos mock
   (patrón `const \w+ = [` seguido de objetos con propiedades de datos).
   Reporta cualquier hallazgo como **hueco crítico** — los datos nunca deben
   ir inline en las páginas.
9. **Huérfanos inversos**: ¿hay endpoints, entidades o archivos que NO se mapean
    a ningún RF? (señal de scope creep o de un requisito sin documentar)

## Comprobaciones de calidad

- ¿RNF de RGPD/seguridad presentes y reflejados en el threat model y el código,
  si el discovery marcó datos sensibles?
- ¿Métricas de éxito del discovery siguen reflejadas en el PRD?
- ¿Alguna sección quedó como TODO o vacía en algún artefacto?

## Skills incluidas (úsalas)

La auditoría de trazabilidad es lo propio de esta fase, pero apóyate en estas
skills incluidas para las comprobaciones de calidad:

- **`security-review`**: escáner real de vulnerabilidades sobre el código (no te
  fíes solo de "¿hay threat model?"; pásalo si el PRD tenía datos sensibles).
- **`code-review-excellence`**: revisión de calidad del código más allá de la
  trazabilidad.
- **`accessibility-a11y`**: si había RNF de accesibilidad, audítalo de verdad.
- **`testing`**: cobertura y solidez de los tests por RF.

## Salida: audit.md

```markdown
# Auditoría — [Nombre del proyecto]

## Resumen
Estado: ✅ sin huecos críticos / ⚠️ con huecos / ❌ bloqueante
[Conteo: X RF totales, Y completamente trazados, Z con hueco]

## Matriz de trazabilidad
| RF | Discovery | PRD | Arquitectura | Mockup | Código | Test acept. (verde/rojo) | Test contrato (sí/no) | Estado |
|----|-----------|-----|--------------|--------|--------|--------------------------|------------------------|--------|
| RF-01 | CU-01 | ✅ | ✅ | ✅ | ✅ | verde | sí | OK |
| RF-02 | CU-02 | ✅ | ✅ | ❌ | ⚠️ | rojo | no | hueco |

## Huecos detectados
### Críticos (bloquean cierre)
- [...]
### Menores
- [...]

## Huérfanos (sin requisito)
- [...]

## Recomendaciones
- [Acciones concretas para cerrar cada hueco]
```

## Definition of Done

- [ ] Matriz de trazabilidad completa, un RF por fila
- [ ] Cada hueco clasificado como crítico o menor con recomendación concreta
- [ ] Huérfanos listados
- [ ] Veredicto claro: se puede cerrar o no
- [ ] Los hallazgos se basan en evidencia comprobada, no en suposición
- [ ] La suite completa se ha ejecutado y está en verde (evidencia: comando + salida); cero rojos en prioridad alta

Si hay huecos críticos, indica al orquestador a qué fase volver para cerrarlos.
