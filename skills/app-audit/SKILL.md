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
 9. **SEED IDS**: busca IDs hardcodeados en el frontend (ej: `"seller-1"`, `"user-1"`)
     y verifica que existen con el mismo valor en el seed. Reporta cualquier ID
     que esté en el frontend pero no en el seed como **hueco crítico**.
10. **AUTH REAL**: verifica que existe `src/app/api/auth/[...nextauth]/route.ts`
     y que las páginas NO tienen userId hardcodeados (busca patrones como
     `userId: "..."` estático). Reporta login simulado como **hueco crítico**.
11. **TEST DB AISLADA**: verifica que existe `docker-compose.test.yml` y que los
     tests NO usan `DATABASE_URL` (deben usar `DATABASE_URL_TEST`). Reporta si
     los tests comparten DB de desarrollo como **hueco crítico**.
12. **COBERTURA MÍNIMA**: cuenta los tests por entidad (patrón `src/__tests__/api/*.test.ts`).
     Si alguna entidad tiene menos de 5 tests, reporta **hueco menor**.
13. **CREATE/EDIT SYMMETRY**: busca todas las páginas `*/new/page.tsx` (creación).
     Para cada una, verifica que existe su correspondiente `*/[id]/edit/page.tsx`
     (edición). También verifica que si existe `POST /api/[entidad]/route.ts`
     existe su correspondiente `PUT /api/[entidad]/[id]/route.ts`.
     Reporta cualquier entidad que se pueda crear pero no editar como **hueco crítico**.
     Este check se ejecuta en un bucle: por cada `new/` encontrado, busca su edit.
14. **CRUD COMPLETO**: para cada entidad con página de listado (ej: `*/products/page.tsx`),
     verifica que existe: detalle (`*/products/[id]/page.tsx`), creación (`*/products/new/page.tsx`),
     y edición (`*/products/[id]/edit/page.tsx`). Reporta cualquier falta como **hueco crítico**.
     Este check también es un bucle: itera sobre todas las entidades y verifica las 4 páginas.
15. **Huérfanos inversos**: ¿hay endpoints, entidades o archivos que NO se mapean
     a ningún RF? (señal de scope creep o de un requisito sin documentar)

## Comprobaciones de calidad

- ¿RNF de RGPD/seguridad presentes y reflejados en el threat model y el código,
  si el discovery marcó datos sensibles?
- ¿Métricas de éxito del discovery siguen reflejadas en el PRD?
- ¿Alguna sección quedó como TODO o vacía en algún artefacto?

## Auditoría ejecutable (script)

Todas las comprobaciones anteriores deben poder ejecutarse como script, no solo
como lectura. El audit genera un archivo `audit.sh` (o `audit.ps1` en Windows)
que el orquestador ejecuta para verificar:

```bash
#!/bin/bash
# audit.sh — comprobaciones automáticas de la Fase 6
set -e

echo "=== 1. WIRING: fetch → endpoint ==="
for fetch in $(grep -roh "fetch(['\"]/api/[^'\"]*" src/ --include="*.tsx"); do
  route=$(echo $fetch | sed "s|fetch(['\"]/api/||;s|['\"].*||")
  if [ ! -f "src/app/api/$route/route.ts" ]; then
    echo "❌ FETCH HUÉRFANO: /api/$route no tiene route.ts"
    exit 1
  fi
done
echo "✅ Todos los fetch tienen su endpoint"

echo "=== 2. ZERO INLINE DATA ==="
if grep -rn "const \w* = \[" src/app --include="*.tsx" | grep -v "test\|\.test\."; then
  echo "❌ Se encontraron arrays de datos mock en páginas"
  exit 1
fi
echo "✅ No hay datos mock inline"

echo "=== 3. SEED IDS ==="
for id in $(grep -roh '\(sellerId\|userId\|buyerId\): *"[^"]*"' src/app --include="*.tsx" | grep -o '"[^"]*"' | sort -u); do
  if ! grep -q "$id" prisma/seed.ts; then
    echo "❌ ID $id usado en frontend pero no en seed"
    exit 1
  fi
done
echo "✅ Todos los IDs del frontend están en el seed"

echo "=== 4. COBERTURA MÍNIMA ==="
for entity in $(ls src/app/api/ --directory); do
  count=$(grep -c "it(" src/__tests__/api/$entity.test.ts 2>/dev/null || echo 0)
  if [ "$count" -lt 5 ]; then
    echo "⚠️  $entity tiene solo $count tests (mínimo 5)"
  fi
done
echo "✅ Cobertura mínima verificada"

echo "=== 5. TEST DB AISLADA ==="
if grep -q "DATABASE_URL" src/__tests__/api/*.test.ts 2>/dev/null; then
  echo "❌ Tests usan DATABASE_URL en vez de DATABASE_URL_TEST"
  exit 1
fi
echo "✅ Tests usan DB aislada"

echo "=== 6. AUTH REAL ==="
if [ ! -f "src/app/api/auth/\[...nextauth\]/route.ts" ]; then
  echo "❌ No existe el endpoint de NextAuth"
  exit 1
fi
echo "✅ NextAuth configurado"

echo "=== 7. CREATE/EDIT SYMMETRY (bucle) ==="
for newpage in $(find src/app -name "new" -path "*/page.tsx" 2>/dev/null || true); do
  dir=$(dirname "$(dirname "$newpage")")
  entity=$(basename "$dir")
  editpage="$dir/[id]/edit/page.tsx"
  if [ ! -f "$editpage" ]; then
    echo "❌ $entity: tiene new/ pero no [id]/edit/"
    exit 1
  fi
  echo "✅ $entity: new → edit OK"
done

echo "=== 8. CRUD COMPLETO (bucle) ==="
for listpage in $(find src/app/seller src/app/\(shop\) -name "page.tsx" ! -path "*/new/*" ! -path "*/edit/*" ! -path "*\[id\]/*" ! -path "*/api/*" 2>/dev/null || true); do
  dir=$(dirname "$listpage")
  entity=$(basename "$dir")
  # Saltar layouts, login, register, etc que no son entidades CRUD
  case "$entity" in
    layout|login|register|profile|search|chats|orders|dashboard|api) continue;;
  esac
  # Solo entidades con new/ (creables)
  if [ -d "$dir/new" ]; then
    for page in "page.tsx" "[id]/page.tsx" "new/page.tsx" "[id]/edit/page.tsx"; do
      if [ ! -f "$dir/$page" ]; then
        echo "⚠️  $entity: falta $page"
      fi
    done
    echo "✅ $entity: CRUD completo"
  fi
done

echo ""
echo "🎉 Auditoría completa — 0 huecos críticos"
```

Este script se ejecuta como parte del CI y antes de cada commit. Si falla,
el orquestador no permite cerrar la Fase 6.

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

- [ ] **Audit script ejecutado** (`audit.sh` o `audit.ps1`) y salida: 0 errores
- [ ] Matriz de trazabilidad completa, un RF por fila
- [ ] Cada hueco clasificado como crítico o menor con recomendación concreta
- [ ] Huérfanos listados
- [ ] Veredicto claro: se puede cerrar o no
- [ ] Los hallazgos se basan en evidencia comprobada, no en suposición
- [ ] La suite completa se ha ejecutado contra la **test DB** y está en verde (evidencia: comando + salida); cero rojos en prioridad alta
- [ ] Audit script incorporado al CI (`.github/workflows/ci.yml`)
- [ ] **CREATE/EDIT SYMMETRY**: bucle ejecutado y verificado — toda entidad creable es editable
- [ ] Seed IDs verificados: todos los IDs del frontend existen en el seed
- [ ] NextAuth real verificado: no hay login simulado
- [ ] Test DB aislada: docker-compose.test.yml existe y los tests la usan
- [ ] Cobertura >= 5 tests por entidad

Si hay huecos críticos, indica al orquestador a qué fase volver para cerrarlos.
