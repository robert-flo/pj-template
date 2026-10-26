# 0001. Un trío fijo por proyecto: el PM planifica, el WK programa, el RV revisa

Fecha: 2026-10-26 · Estado: aceptado
Origen: fleet ADR 0001, fleet ADR 0019

## Contexto
`grill-with-docs` y `to-spec` están pensados para correr en el mismo contexto: `to-spec` sintetiza el grill sin volver a entrevistar. Partir la planificación entre varios agentes pierde justo ese contexto y multiplica el gasto. Además, crear un agente nuevo por spec deja agentes sueltos.

## Decisión
- Cada proyecto (un repo o un meta-repo `pj-` con varios) tiene un solo trío fijo: `PM-<proyecto>`, `WK-<proyecto>` y `RV-<proyecto>`.
- El PM hace solo toda la planificación: restate, grill, spec y tickets. El relevo entre agentes ocurre una sola vez, de planificar a ejecutar.
- El PM le pasa cada spec nuevo a su WK fijo; no se crea un agente por spec. Un proyecto de varios repos sigue teniendo un solo trío.
- Un RV por proyecto y no uno global, para que conozca el stack y las reglas de ese repo sin mezclar contextos.
- `<proyecto>` lo elige Roberto. Si un proyecto necesita dos PMs, el área va dentro del nombre del proyecto (`PM-reel-desktop`).

## Consecuencias
- Las fichas de agy y los adaptadores de Cursor salen de `proyecto.yml` con esos tres nombres (`scripts/generar.py`).
- Cómo se hablan los tres en cada plataforma está en `.agents/reglas/comun.md` §El trío y en `docs/adr-antigravity/0002`.
