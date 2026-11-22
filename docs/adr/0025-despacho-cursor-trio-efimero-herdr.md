# 0025. Despacho del orquestador Cursor vía trío efímero en herdr

Fecha: 2026-11-21 · Estado: aceptado
Origen: Roberto / HR-CLAVIS#85 (#90–#92). Supera [0023](0023-despacho-cursor-cuando-pm-en-cursor.md) y enmienda [0022](0022-make-cursor-pm.md).

## Contexto
Con [0023](0023-despacho-cursor-cuando-pm-en-cursor.md), el PM Orquestador en Cursor despachaba WK, RV y OS como subagentes in-chat (`.cursor/agents/{wk,rv,os}-<slug>.md`). En la práctica eso rompió la paridad arquitectónica con `agy`:
1. Acumulaba los transcripts de ejecución dentro de la misma sesión de pensamiento del PM Orquestador.
2. Carecía de visibilidad por paneles en `herdr`.
3. Obligaba a `pj-template` a mantener dos dialectos de orquestación distintos.

## Decisión
1. **Arquitectura de dos niveles también en Cursor CLI (`make c-pm`):** el PM Orquestador en el Home Repo (`@.cursor/rules/pm-<slug>.mdc`) no codifica ni usa subagentes in-chat; despacha cada ticket hacia un workspace efímero en `herdr` con contexto limpio indicando la plataforma explícita en CLI:
   - Engineering: `pj-trio <proyecto> <ticket> [--repo <miembro>] [--base <rama>] --kind cursor`
   - Trivial: `pj-trio --oneshot <proyecto> <ticket> [--repo <miembro>] --kind cursor` (o `make c-os` / `make listo c-os` para side-tasks directos)
   - Supervisión con 0 tokens: `pj-trio watch <proyecto> --ticket <clave>` (únicamente los tickets despachados en esa sesión).
2. **Separación de regla para el PM efímero:** `scripts/generar.py` genera `.cursor/rules/pm-trio-<slug>.mdc` (desde `plantillas/cursor/pm-trio.mdc`) para el PM efímero dentro de `herdr` (sigue `kickoff.md`, coordina `wk` y `rv` con `herdr agent prompt` / `herdr agent wait --timeout 600000` y aplica el Merge Gate). `.cursor/rules/pm-<slug>.mdc` queda dedicado exclusivamente al PM Orquestador.
3. **Retiro de subagentes in-chat:** se elimina la generación de `.cursor/agents/{wk,rv,os}-<slug>.md` (enmienda a [0022](0022-make-cursor-pm.md)). Se conservan `make c-{pm,wk,rv,os}`, `make listo c-*`, `cursor-agent --yolo --trust`, `mise` y `@.cursor/rules/<rol>-<slug>.mdc` ([0022](0022-make-cursor-pm.md), [0024](0024-convencion-simetrica-a-c-y-listo.md)).
4. **Cursor IDE fuera de alcance:** Cursor IDE (GUI) queda fuera de alcance como orquestador de tríos; la entrada canónica en Cursor es Cursor CLI (`make c-pm` / `make listo c-pm`).
5. **Plataforma explícita:** `agy` sigue siendo el `--kind` por defecto de `pj-trio` cuando se omite el flag; no se introducen variables de entorno como `PJ_TRIO_KIND`.

## Consecuencias
- [0023](0023-despacho-cursor-cuando-pm-en-cursor.md) queda superado; [0022](0022-make-cursor-pm.md) queda enmendado por el retiro de `.cursor/agents/*`.
- Las reglas (`.agents/reglas/{comun,pm}.md`), plantillas (`plantillas/cursor/{pm,pm-trio}.mdc`), generador (`scripts/generar.py`) y verificación (`scripts/humo.py`, `scripts/prueba-cursor.sh`) reflejan este modelo, junto con `--kind cursor` en `ravn-trio`.
- Merge Danger, quién mergea qué y worktrees no cambian ([0014](0014-el-pm-mergea-tras-apruebo.md), [0018](0018-el-merge-es-el-de-fleet.md), [0019](0019-worktrees-con-ravn-git-bare-clone.md)).
