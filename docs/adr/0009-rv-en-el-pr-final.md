# 0009. El RV revisa el PR final

Fecha: 2026-10-26 · Estado: aceptado
Origen: fleet ADR 0017

## Contexto
El `code-review` del WK es una autorrevisión, no una segunda mirada. Revisar cada PR de sub-issue gastaría mucho sin dar la misma señal: el punto de más valor es el PR que llega a la rama por defecto.

## Decisión
- El RV revisa el PR final de una rama de spec (o el PR de un trivial) a la rama por defecto, antes que Roberto. Los PRs de sub-issues a la rama del spec no pasan por él.
- Su prompt es «Review this repository as if you are blocking or approving a production PR.»
- Su veredicto es un comentario del PR que empieza con **BLOQUEO** o **APRUEBO** (todo usa la cuenta de Roberto y GitHub no deja aprobar un PR propio).
- El RV no programa código de PR, no hace commits, no mergea ni cambia etiquetas.
- **BLOQUEO:** el trabajo vuelve al WK (o al grill si es de diseño) y después se pide otra revisión.
- **APRUEBO:** el PM pone `ready-to-merge` (el rol `ready-for-human` de Matt) y le pasa a Roberto el PR, el veredicto y los pasos de validación manual. Solo con una orden explícita de Roberto («merge») el PM mergea, con squash y atado al commit aprobado (`--match-head-commit`), confirma el merge y le pasa el SHA. Si Roberto rechaza, se quita `ready-to-merge` y vuelve al WK o al grill.

## Consecuencias
- Reglas en `.agents/reglas/rv.md` y `pm.md` paso 8.
