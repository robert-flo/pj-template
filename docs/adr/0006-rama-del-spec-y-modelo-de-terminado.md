# 0006. Rama del spec y cuándo algo está hecho

Fecha: 2026-10-26 · Estado: aceptado; el merge del PR final, reemplazado por [0014](0014-el-pm-mergea-tras-apruebo.md)
Origen: fleet ADR 0011

## Decisión
- **El spec es un issue de GitHub**, el mapa común del trabajo. `to-tickets` lo parte en sub-issues; el spec y sus sub-issues llevan `ready-for-agent`. `to-tickets` es obligatorio en Engineering aunque el trabajo quepa en una sesión (al menos un sub-issue).
- **Rama del spec.** Al publicar el spec, el PM crea su rama (`<número>-<slug>`) desde la rama por defecto del repo (`main`, o `personal` en un fork, ADR 0012) y la sube, sin commits suyos.
- **Ramas del WK.** Una por sub-issue, con la rama del spec como base, en un worktree propio. El WK mergea su propio PR a la rama del spec cuando todo está verde y borra rama y worktree.
- **PR final** (el merge a la rama por defecto, reemplazado por [0014](0014-el-pm-mergea-tras-apruebo.md): ahora el PM mergea sin esperar orden): Con todos los sub-issues mergeados, el PM abre el único PR de la rama del spec a la rama por defecto. Ese es el que revisa el RV (ADR 0009) y el que se mergea con la orden de Roberto. La rama por defecto nunca recibe commits directos.
- **Trivial.** Un issue, una rama desde la rama por defecto, un PR a la rama por defecto.
- **Hecho.** Un spec está listo cuando todos sus sub-issues están mergeados y su PR final está listo para mergear; está hecho cuando se mergea y el PM lo confirma en GitHub. Después se borran la rama del spec y su worktree, y los issues cerrados quedan sin etiquetas de triage.

## Consecuencias
- El tablero es GitHub Issues (`.agents/reglas/comun.md` §El tablero).
- Diferencia con el origen: no hay `push --force-with-lease`; antes de empujar va `git pull --rebase --autostash` (`comun.md` §Git).
