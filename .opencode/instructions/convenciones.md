# Convenciones de código

## Commits
- Usa Conventional Commits en español con emoji
- Formato: `<tipo>: <descripción corta>`
- Tipos: `✨ feat`, `🐛 fix`, `♻️ refactor`, `📝 docs`, `🧪 test`, `🔧 chore`
- Ejemplo: `✨ feat: añadir autenticación con NextAuth`

## Idioma
- Código (variables, funciones, tipos): **inglés**
- Comentarios, commits, documentación: **español**

## Estructura de commits por fase
Cada fase del proceso genera un commit con su artefacto:
- `✨ fase 1: discovery.md (CU-01..CU-05)`
- `✨ fase 2: prd.md (RF-01..RF-12)`
- `✨ fase 3: architecture.md (ADR-01, modelo datos)`
- `✨ fase 4: mockups + design-system.md`
- `✨ fase 5: scaffold + tests`
- `✨ fase 6: audit.md`

## Trazabilidad
Cada archivo de código lleva en cabecera:
```
// Implementa: RF-XX
// UI base: mockup/flujo-XX.html
```
