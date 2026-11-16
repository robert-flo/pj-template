# 0016. El trío en herdr vive en ravn-trio

Fecha: 2026-11-16 · Estado: aceptado

## Contexto
`pj-trio` empezó como script de la workstation y pj-template describía su comportamiento a mano. Hoy sale del paquete `ravn-trio` de `[omarchy-personal]` (`/usr/bin/pj-trio`), con código en [robert-flo/ravn-trio](https://github.com/robert-flo/ravn-trio). Las dos descripciones se separaron: la regla de merge, de dónde sale `pj-trio` y el nombre de los worktrees del WK. Roberto decidió el 2026-11-16 que ravn-trio es la fuente de verdad del trío local.

## Decisión
- Cómo corre el trío en herdr (pestañas, nombres de agente, arranque del PM, handoffs en `.trio/`, worktrees del WK) se documenta solo en ravn-trio. pj-template lo enlaza y no lo copia.
- Precedencia: el flujo y sus reglas (`.agents/reglas/` y estos ADR, sobre todo [0006](0006-rama-del-spec-y-modelo-de-terminado.md) y [0014](0014-el-pm-mergea-tras-apruebo.md)) mandan sobre ravn-trio. Si chocan, se corrige ravn-trio por PR. En lo que no está acá, manda ravn-trio.
- Worktrees del WK: la convención de ravn-trio (`<clon>-wt-<n>-<AAAAMMDDhhmmss>` en `feat/<n>-<slug>`). La base sale de 0006: un sub-issue parte de la rama de su spec (`pj-trio --base <rama del spec>`) y un trivial de `origin/HEAD`. El PR va contra esa base.

## Consecuencias
- `docs/pj-template.md` §Trío en herdr y `.agents/reglas/wk.md` paso 3 enlazan ravn-trio. `.gitignore` ignora `*-wt-*/`.
- [ravn-trio#23](https://github.com/robert-flo/ravn-trio/pull/23) alinea `trio-pm-prompt.md` con 0014 y agrega `--base`.
- Los `.trio/README.md` de los hijos apuntan a ravn-trio, no a la workstation.
