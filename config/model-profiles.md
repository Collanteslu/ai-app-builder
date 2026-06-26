# Perfiles de modelo por fase

Inspirado en el SDD de gentle-ai: no todas las fases necesitan el mismo modelo.
Las fases de **criterio** (donde una mala decisión se propaga por toda la cadena)
piden el modelo más capaz; las **mecánicas** (donde el contrato ya está fijado y
solo hay que ejecutar) corren bien —y más barato— con uno rápido.

Esto es una **recomendación de coste/calidad**, no un gate. El proceso funciona
con un solo modelo; estos perfiles solo te ayudan a asignar potencia donde rinde.

| Fase | Skill | Naturaleza | Perfil sugerido | Por qué |
|------|-------|-----------|-----------------|---------|
| 0 Brainstorm | `app-brainstorm` | criterio | **alto** | Retar supuestos y encontrar el problema real exige razonamiento |
| 1 Discovery | `app-discovery` | criterio | **alto** | Una entrevista pobre arrastra huecos hasta la auditoría |
| 2 PRD | `app-prd` | criterio | **alto** | Los RF y criterios de aceptación son el contrato de todo lo demás |
| 3 Arquitectura | `app-architecture` | criterio | **alto** | Modelo de datos, threat model y contratos §7/§8 condicionan el código |
| 4 Mockup | `app-mockup` | mixta | **medio** | El sistema de diseño es criterio; generar las pantallas es mecánico |
| 5 Scaffold | `app-scaffold` | mecánica | **medio/rápido** | El contrato ya está fijado; se ejecuta TDD slice a slice |
| 6 Auditoría | `app-audit` | criterio | **alto** | Cazar lo que se coló pide la misma rigurosidad que diseñarlo |
| — Memoria | `app-memory` | mecánica | **rápido** | Recall y capture son lectura/escritura estructurada |

## Cómo aplicarlo

### En opencode (perfiles SDD nativos)
opencode permite asignar modelo por agente. Asigna el modelo capaz a `arquitecto`
y `auditor`, y uno más rápido a `scaffolder`. Consulta la documentación de
opencode para la sintaxis de `model` por agente en `.opencode/agents/*.md`.

### En Claude Code
No hay cambio de modelo por fase automático: trabajas con el modelo de la sesión.
Si quieres optimizar coste, usa un modelo capaz (Opus) para las fases 0–3 y 6, y
puedes bajar a uno más rápido (Sonnet) para el grueso mecánico de la Fase 5.

> Regla práctica: **diseñar con el mejor modelo, ejecutar con el más rápido,
> auditar de nuevo con el mejor.** El coste se va en la Fase 5 (mucho token), y es
> justo la más mecánica una vez que los contratos §8 están cerrados.
