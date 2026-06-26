# Git workflow

## Inicialización
- El proyecto debe estar bajo `git init` antes de la Fase 1
- Si no existe, ejecútalo antes de empezar

## Commits por fase
**Obligatorio:** al cerrar cada gate, haz commit del artefacto:
```
✨ fase N: <artefacto> (<IDs>)
```

Esto convierte la trazabilidad por ID en trazabilidad **histórica**: se puede responder "¿cuándo y en qué fase se introdujo el RF-XX?".

## Commits retroactivos
Si una fase descubre un hueco en un artefacto previo:
1. Actualiza el artefacto anterior
2. Haz commit con mensaje:
   ```
   ♻️ cambio retroactivo: <artefacto> — <qué se corrigió>
   ```
3. Decláralo en el campo "Cambios retroactivos" del handoff

## Estructura de ramas
- `main` — estable
- `feature/*` — para desarrollo de funcionalidades
- No hacer push hasta que el proceso completo esté cerrado
