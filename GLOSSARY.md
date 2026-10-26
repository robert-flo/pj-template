# Glosario de los tríos

Origen: fleet GLOSSARY.md (solo los términos que no dependen de una plataforma).

## Proyecto
Un cuerpo de trabajo de Roberto con un solo trío; vive en un meta-repo `pj-<proyecto>` hecho con este template.
_Evitar_: usar «proyecto» para un solo repo.

## Repo
Cada repo es una historia independiente con sus issues, glosario y ADRs. Un proyecto puede abarcar varios (ADR 0003).

## Prefijos
`pj-`: meta-repo de un proyecto (trío y `proyecto.yml`). `rf-`: carpeta local de un repo propio de `robert-flo`. `fo-`: carpeta local de un fork (`fo-skills`).

## Trío
El equipo fijo de un proyecto: `PM-<proyecto>`, `WK-<proyecto>` y `RV-<proyecto>` (ADR 0001).
_Evitar_: equipo, squad.

## PM
Dueño del proyecto: corre el flujo de Matt (restate, grill, spec, tickets) hasta sub-issues `ready-for-agent` y sigue cada spec hasta su PR final (ADR 0005). No escribe código de producción.
_Evitar_: planner, agente de proyecto.

## WK
Programa los issues `ready-for-agent` en ramas que salen de la rama del spec y reporta al PM (ADR 0007).
_Evitar_: executor, worker como bot desechable.

## RV
Revisa solo el PR final a la rama por defecto y comenta `BLOQUEO` o `APRUEBO` (ADR 0009).

## Rama del spec
La rama de integración de un spec, creada por el PM desde la rama por defecto al publicar el spec. Los PRs del WK se mergean a ella; su único PR final es el que Roberto ordena mergear (ADR 0006).
_Evitar_: feature branch.

## Listo para mergear
CI verde, sin hallazgos de seguridad, sin hilos de review de bots abiertos y con prueba real de cada criterio. Los gates que solo esperan a un humano no cuentan.
_Evitar_: CLEAN, done.

## Plantilla
Un formato fijo que da Roberto y que los agentes aplican sin improvisar (ADR 0002).

## Impedimento
Algo que un agente no puede resolver solo; la única razón para detenerse al operar la máquina (ADR 0011).
_Evitar_: bloqueo (BLOQUEO es el veredicto del RV).

## Bitácora
`CAMBIOS.md` junto al meta-repo: una línea por cambio al sistema, escrita antes del cambio, con fecha, agente, comando y cómo deshacerlo (ADR 0011).
_Evitar_: log.

## personal
La rama larga con los cambios de Roberto en un fork; es la rama por defecto y está protegida (ADR 0012).

## upstream
En un fork, la rama espejo (fast-forward) de la línea que se sigue del proyecto de origen. Es nombre de rama, no solo de remoto (ADR 0012).
_Evitar_: quattro como nombre genérico.

## Estado ↔ etiqueta
El estado de un issue o PR se lee en sus etiquetas de triage (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-to-merge`, `wontfix`); la tabla está en `.agents/reglas/comun.md` §El tablero. `ready-to-merge` es el nombre en los repos de Roberto del rol `ready-for-human` de Matt.
