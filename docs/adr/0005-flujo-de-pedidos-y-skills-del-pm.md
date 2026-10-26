# 0005. Flujo de pedidos y skills del PM

Fecha: 2026-10-26 · Estado: aceptado
Origen: fleet ADR 0008, fleet ADR 0009, fleet ADR 0010

## Decisión
- **Clasificar primero.** Todo pedido nuevo se clasifica Trivial o Engineering (Task Sizing del `AGENTS.md` del repo), se dice en voz alta y Roberto tiene un veto barato antes de arrancar.
- **Trivial:** sin grill ni spec. Un issue `ready-for-agent`; el WK corre `implement` y `code-review`.
- **Engineering:** siempre `grill-with-docs` (repetido hasta que no quede ambigüedad), después `to-spec` y después `to-tickets`, sin saltar pasos, terminando en issues `ready-for-agent`. No hay entrega de «spec solo».
- **Skills de flujo.** El PM las corre una a la vez como su flujo, nunca una desde adentro de otra. `ask-matt` no es un paso: es el mapa para cuando no sabe cómo seguir. `wayfinder` cuando todavía no hay repo o el trabajo no cabe en una sesión. `prototype` es la única excepción a «el PM no toca código» (rama `prototype/<nombre>`, desechable). `triage` solo para issues que el PM no creó. `implement`, `implement-spec`, `tdd`, `code-review` y `retro` son del WK.
- **Dueño de punta a punta.** El PM es dueño del pedido hasta que se mergea o Roberto lo descarta; publicar tickets no es el final.
- **Reglas de oficio** (adaptadas del Engineer Bot de Lingxi Li): títulos limpios (el estado vive en las etiquetas, el único prefijo es `<número> - `); board primero (el pedido tiene issue antes de planear y los seguimientos van al mismo issue); buscar antes de crear y enlazar en vez de duplicar; no tocar asignado, milestone ni prioridad que pone Roberto; mensajes cortos y decididos; nunca inventar links; un bloqueo que viene de la rama por defecto se registra y se escala, el PM no lo arregla.
- **Descartado:** auto-merge, watchers de alta frecuencia y las reglas de estilo personal de los autores.

## Consecuencias
- Todo esto vive en `.agents/reglas/pm.md` §Tu flujo y §Reglas de GitHub, y las skills por rol en `plantillas/roles.yml`.
