# 0023. Despacho Cursor→Cursor cuando el PM corre en Cursor

Fecha: 2026-11-21 · Estado: aceptado
Origen: Roberto / HR-CLAVIS#71–#73 (Fase 1). Enmienda el default de despacho de [0021](0021-flujo-herdr-y-politica-merge-danger.md) según la sesión del PM. Los atajos de entrada viven en [0022](0022-make-cursor-pm.md).

## Contexto
Con [0021](0021-flujo-herdr-y-politica-merge-danger.md) el default era siempre `pj-trio`→agy en herdr. Eso choca cuando el PM ya está en Cursor (IDE o CLI vía `make c-pm` / `make cursor-pm` / `cursor-agent`): rebotar a agy/herdr gasta cuota de Gemini y rompe la expectativa de quedarse en la misma plataforma. [0022](0022-make-cursor-pm.md) ya dejó los atajos CLI; faltaba la política de sesión.

## Decisión
1. **Si la sesión del PM es Cursor** (IDE con regla `alwaysApply`, o CLI abierta con `./pj cursor` / `make c-pm` / `make cursor-pm`): el default es lanzar WK, RV y OS como subagentes `.cursor/agents/{wk,rv,os}-*` (Task / equivalente). **No** se abre `pj-trio`→agy por defecto.
2. **Si la sesión del PM es agy / herdr:** el default sigue siendo el despacho visible de [0021](0021-flujo-herdr-y-politica-merge-danger.md) (`pj-trio`, `fleet`, `watch`, `--oneshot`).
3. **Override explícito:** Roberto puede pedir herdr/`pj-trio`/agy desde una sesión Cursor (o al revés) cuando quiera visibilidad en herdr. El pedido manda sobre el default.
4. **Sin `--runtime` en `pj-trio`:** no se añade selector de runtime en esta fase (Fase 2 opcional después).
5. La política vive en `.agents/reglas/{pm,comun}.md` y en la plantilla `plantillas/cursor/pm.mdc` (texto generado en `.cursor/rules/pm-*.mdc`).

## Consecuencias
- Merge Danger, quién mergea qué y worktrees no cambian ([0014](0014-el-pm-mergea-tras-apruebo.md), [0018](0018-el-merge-es-el-de-fleet.md), [0019](0019-worktrees-con-ravn-git-bare-clone.md)).
- `make pm` / `make agy-*` siguen = agy; `make c-*` / `make cursor-*` siguen = Cursor ([0020](0020-make-agy-pm.md), [0022](0022-make-cursor-pm.md)).
- Sin fallback automático agy→Cursor por cuota (Fase 3, fuera de alcance).
