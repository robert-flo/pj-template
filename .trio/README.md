# .trio/ — handoffs del trío PM/WK/RV en herdr

Cada ticket que corre el trío deja acá su carpeta `.trio/<ticket>/` (plan, reporte del WK, veredicto del RV), y se commitea a git.

## Cómo lanzarlo

Desde la estación de trabajo, con `pj-trio` de `robert-flo/PJ-NIRI-rf-omarchy-workstation` (`scripts/pj-trio`):

```bash
pj-trio pj-template <ticket> --repo <miembro>
```

- `<ticket>`: número del issue a trabajar.
- `<miembro>`: el `dir` del repo en `proyecto.yml` donde cae el ticket.

Abre en herdr las pestañas `pm`, `wk` y `rv`, cada una con `agy --agent PM-pj-template` / `WK-pj-template` / `RV-pj-template` (agentes `pm-pj-template`, `wk-pj-template`, `rv-pj-template`). El estado se ve con `trio-status`.

El PM mergea solo después del `APRUEBO <sha>` del RV: `gh pr merge <N> --squash --delete-branch --match-head-commit <sha>`.
