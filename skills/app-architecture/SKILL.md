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
Tabla RF-XX → entidad(es) → endpoint(s). Marca cualquier RF sin cubrir.
```

## Definition of Done

- [ ] Cada RF del PRD aparece en la tabla de trazabilidad con su entidad y endpoint
- [ ] Modelo de datos con tipos, claves y relaciones (no solo nombres)
- [ ] Contrato de API: ningún endpoint sin RF, ningún RF sin endpoint (salvo justificado)
- [ ] Threat model presente si había datos sensibles en el PRD
- [ ] Desviaciones del stack documentadas como ADR

Cuando esté completo, guarda `architecture.md` y devuelve el control al orquestador.
