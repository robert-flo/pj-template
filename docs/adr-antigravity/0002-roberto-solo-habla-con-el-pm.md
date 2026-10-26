# 0002. Roberto solo habla con el PM

Fecha: 2026-10-04 · Estado: aceptado · Reemplaza en parte a 0001 (los agentes ya no son independientes entre sí)

## Contexto
En el piloto de rf-try-clone el trío funcionó de punta a punta, pero Roberto tenía que cerrar `agy` y abrirlo con otro agente en cada relevo (PM → WK → RV → PM). Antigravity permite que un agente sea a la vez principal y subagente (`mainAgent: true`, `subagent: true`), y el PM tiene la herramienta `invoke_subagent`.

## Decisión
- Roberto solo abre al PM. El WK y el RV llevan `subagent: true` (y siguen con `mainAgent: true` por si Roberto quiere abrirlos solos).
- El PM lanza al WK con el issue o spec, espera su reporte, lanza al RV con el PR, y con APRUEBO pone `ready-to-merge` y le pasa todo a Roberto. El merge sigue siendo orden de Roberto.
- GitHub sigue siendo el registro de todo: issues, PRs y el veredicto del RV como comentario `APRUEBO`/`BLOQUEO` (todos usan la cuenta de Roberto y GitHub no deja aprobar un PR propio).

## Consecuencias
- Una sola sesión por pedido; el PM se queda esperando mientras el WK programa.
- Si el WK o el RV se traban, el PM se lo dice a Roberto con el error en vez de reintentar sin fin.
