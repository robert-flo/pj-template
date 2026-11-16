# 0014. El PM mergea tras el APRUEBO del RV

Fecha: 2026-10-26 · Estado: aceptado
Reemplaza: el punto **APRUEBO** de [0009](0009-rv-en-el-pr-final.md); el merge del PR final de [0006](0006-rama-del-spec-y-modelo-de-terminado.md); el merge del flujo de código de [0011](0011-trabajo-sobre-la-maquina.md)

## Contexto
Con [0009](0009-rv-en-el-pr-final.md), tras el `APRUEBO` el PM ponía `ready-to-merge` y esperaba la orden «merge» de Roberto. Con el trío en herdr (`pj-trio`) eso dejaba cada ticket parado en Roberto aunque el RV ya lo hubiera aprobado. Se probó de punta a punta en pj-domina (tickets 19 y 20) el 2026-10-26.

## Decisión
- Tras el comentario `APRUEBO <sha>` del RV, el PM mergea sin esperar orden de Roberto: `gh pr merge <M> --squash --delete-branch --match-head-commit <sha>`, con el SHA que nombró el RV.
- Si la cabeza del PR cambió después del `APRUEBO`, el PM no mergea y pide otra revisión.
- El PM confirma el merge y le pasa a Roberto el link del PR, el del veredicto, el SHA del merge y los pasos de validación manual.
- El WK y el RV siguen sin mergear. El resto de [0009](0009-rv-en-el-pr-final.md) (quién revisa, BLOQUEO) sigue vigente.

## Consecuencias
- Reglas en `.agents/reglas/pm.md` paso 8 y `comun.md` (PR #11).
- Los handoffs del trío quedan en `.trio/<ticket>/` de cada hijo (ver `docs/pj-template.md`).
- El merge del PR final de [0006](0006-rama-del-spec-y-modelo-de-terminado.md) y el del flujo de código de [0011](0011-trabajo-sobre-la-maquina.md) quedan anotados como reemplazados, igual que el APRUEBO de [0009](0009-rv-en-el-pr-final.md). La etiqueta `ready-to-merge` y el término «Rama del spec» del glosario siguen esta decisión.
