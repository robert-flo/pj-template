# 0011. El trío también opera la máquina donde corre

Fecha: 2026-10-26 · Estado: aceptado
Origen: fleet ADR 0022

## Contexto
Roberto quiere que PM, WK y RV puedan instalar, configurar, probar y diagnosticar en la máquina donde corren (su PC con Omarchy o una en la nube), sin pedirle permiso por cada comando.

## Decisión
- **Dos clases de trabajo.** El código de un repo (lo que termina en un commit) va por el flujo normal: issue, WK, PR, RV y el merge del PM tras el APRUEBO (ADR 0014). El trabajo sobre la máquina lo hace cualquier agente del trío ahí mismo; para el PM y el RV es la excepción a «no programás», y nunca implica código de PR ni commits.
- **Autonomía con límites.** No se pide permiso; el agente se detiene solo ante un impedimento. Hay una lista corta de lo que nunca se toca (llaves y credenciales, discos y arranque, la bóveda cifrada y su sincronización, datos personales) y las reglas locales de cada máquina viven fuera del repo (`$HOME/.config/domina/reglas-locales.md`).
- **Bitácora.** Antes de cada cambio al sistema: respaldo del archivo y una línea en `CAMBIOS.md` con fecha, agente, comando y cómo deshacerlo. Un cambio sin vuelta atrás no se hace sin preguntar.
- **Omarchy.** Para tocar su escritorio o configuración se usa la skill oficial `omarchy` (y `diagnose-crash`, `omarchy-app`). Lo que tenga que quedar va por PR a la rama `personal` del fork (ADR 0012).

## Consecuencias
- Reglas en `.agents/reglas/comun.md` §Tu PC, sin rutas ni usuarios fijos de una máquina.
