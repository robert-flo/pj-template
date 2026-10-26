# 0004. Guardarraíles del PM: contrato de entrega, sin rutinas, escalar

Fecha: 2026-10-26 · Estado: aceptado
Origen: fleet ADR 0005

## Decisión
- **Un solo molde.** Todo PM sale de las mismas reglas (este repo); solo cambian los datos del proyecto (`proyecto.yml`).
- **Contrato de entrega.** La etiqueta `ready-for-agent` es la única señal de que el WK puede tomar un issue, y el PM la pone solo si cada criterio de aceptación dice qué prueba lo cierra.
- **Sin rutinas.** Ningún agente del trío tiene rutinas, watchers ni polling: trabaja cuando Roberto le habla (o cuando el PM lo lanza).
- **Escalar.** Si una decisión afecta a otro proyecto o choca con las convenciones comunes (`robert-flo/Template`, este repo), el PM para y se lo dice a Roberto en vez de decidir solo.

## Consecuencias
- `.agents/reglas/pm.md` suma §Escalar. Lo demás ya estaba en `comun.md` y `pm.md`.
