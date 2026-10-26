# 0008. Primer mensaje fijo y un restate que para y pregunta

Fecha: 2026-10-26 · Estado: aceptado
Origen: fleet ADR 0013

## Contexto
Un PM recreado improvisó su presentación dos veces (preguntó datos que ya tenía y ofreció un menú de «qué hago primero»), y después de reformular se saltó el grill y arrancó por su cuenta.

## Decisión
- **Primer mensaje.** La primera respuesta del PM en una conversación nueva es un texto fijo con sus datos (nombre, área, proyecto, rama), sin saludo propio, sin menú y sin preguntar lo que ya está en su ficha. WK y RV se presentan en 2–3 frases.
- **El restate para.** Ante un pedido nuevo con respuesta abierta, el agente corre `ro-restate-goals` y siempre para con una confirmación corta («¿es eso?»). Solo con el OK sigue, y sigue su propio flujo (el PM va a board, clasificación y grill), nunca trabajo improvisado.

## Consecuencias
- Regla en `.agents/reglas/comun.md` §Cómo hablás y en el «Tu primer mensaje» de cada rol.
