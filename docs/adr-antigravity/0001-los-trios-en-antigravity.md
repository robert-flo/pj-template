# 0001 · Los tríos se replican en Antigravity

- Estado: aceptado (2026-10-04, entrevista de Roberto con Real dr eggbot)

## Contexto
La cuota de Grok Bot es chica. Roberto quiere usar el diseño de su flota (tríos PM/WK/RV por repo, reglas comunes, flujo de Matt Pocock) también en Antigravity, sin empezar de cero y sin que eso afecte lo que funciona en Grok Bot.

## Decisión
- **Dos mundos separados.** `robert-flo/antigravity-fleet` es un repo nuevo, copia de fleet con las convenciones de Antigravity. Los cambios de un lado no se propagan al otro.
- **Agentes en cada repo y reglas globales.** Cada repo lleva su trío en `.agents/agents/`, commiteado por PR desde `agentes/<proyecto>/`. Las reglas comunes viven globales en `~/.gemini/config/fleet/`, y cada agente las manda a leer, igual que las fichas de fleet mandan a leer las plantillas. Un proyecto `pj-` lleva una copia del mismo trío en cada repo.
- **Los tres son agentes principales** (`mainAgent: true`, `subagent: false`): Roberto habla con cada uno, como en Grok Bot. No se llaman entre sí; el canal es GitHub y Roberto pasa la posta. *(Cambiado por ADR 0002: Roberto solo habla con el PM, que lanza al WK y al RV como subagentes.)*
- **El WK programa en gracie**, en un worktree propio, y abre el PR con `gh`. No usa cloud agents de Cursor.
- **El tablero es GitHub Issues** con las etiquetas de triage de `robert-flo/Template`. No hay TickTick.
- **Autonomía total en gracie** (`commandExecutionPolicy: eager`), con las mismas reglas de Tu PC de fleet (ADR 0022): lista de lo que nunca se toca, respaldo y bitácora en `~/Work/tries/CAMBIOS.md`.
- **Real dr eggbot traduce las fichas**, no el `agent-creator` de Antigravity.
- **Piloto:** rf-try-clone primero; el resto después de probarlo.

## Consecuencias
- Hay dos copias de las reglas que se pueden desviar; es a propósito.
- Sin TickTick, Roberto ve el estado en GitHub.
- Un nombre de herramienta mal escrito en `tools:` puede colgar al agente (problema conocido de Antigravity), así que por ahora los agentes no limitan `tools`.
