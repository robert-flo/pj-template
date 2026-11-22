# 0021. Flujo herdr (pj-trio, fleet, watch, --oneshot) y política de Merge Danger

Fecha: 2026-11-17 · Estado: aceptado
Aclara: [0014](0014-el-pm-mergea-tras-apruebo.md), [0016](0016-el-trio-en-herdr-vive-en-ravn-trio.md) y [0018](0018-el-merge-es-el-de-fleet.md)
Enmienda (despacho): cuando el PM corre en Cursor, el despacho en `herdr` usa `--kind cursor` — ver [0025](0025-despacho-cursor-trio-efimero-herdr.md) (que supera [0023](0023-despacho-cursor-cuando-pm-en-cursor.md)).
Enmienda (1 trío por spec, HR-CLAVIS#116/#118): en Engineering, el PM Orquestador despacha **1 solo `pj-trio` por el spec completo** (no un `pj-trio` por cada sub-issue); las fronteras DAG de los sub-issues las ejecuta el WK dentro de ese trío con `/implement-spec`, y el PM del trío orquesta el PR final, la revisión del RV en `herdr` y el merge según Merge Danger. Merge Danger y `fleet`/`watch` de esta ADR siguen vigentes.

## Contexto
La operación multirrepo en `HR-CLAVIS` y la introducción del rol oneshot (`OS`) para tickets triviales validaron un patrón de orquestación local en `herdr` que supera el uso headless de `invoke_subagent` para tareas largas:
1. `invoke_subagent` corre a ciegas en segundo plano, no provee terminales interactivas ni pestañas inspeccionables en vivo para Roberto, y satura el contexto del PM.
2. El polling o consulta continua en bucle dentro de los agentes consume tokens y cuota innecesariamente.
3. El auto-merge sin filtro de riesgo es peligroso si no se evalúa la reversibilidad de la decisión (`Door: two-way` vs `one-way`) y su radio de impacto (`Blast Radius: Low` vs mayor).
4. La ejecución de specs con múltiples sub-issues requiere despachar en paralelo según las fronteras del grafo acíclico dirigido (DAG) de dependencias.

## Decisión
1. **Despacho visible en `herdr`:**
   - Todo trabajo de Engineering se despacha vía `pj-trio <proyecto> <spec> [--repo <miembro>]` (1 trío por spec completo; enmendado por HR-CLAVIS#116/#118), abriendo pestañas dedicadas (`pm`, `wk`, `rv`).
   - Todo trabajo Trivial se despacha vía `pj-trio --oneshot <proyecto> <ticket> [--repo <miembro>]` (o `make a-os` para side-tasks directos).
   - Se evita `invoke_subagent` para tareas de desarrollo o ejecución larga.
2. **Supervisión de flota con 0 tokens:**
   - Se prohíbe el polling activo de estado por parte de los agentes.
   - La espera pasiva del PM se realiza con `pj-trio watch <PROYECTO> --ticket <clave>` (repetible, o lista separada por comas). El flag es el de ravn-trio 0.1.14 (`947e62d` en `58-watch-ticket-filter`): filtra temprano y solo despierta ante eventos accionables (`hecho`, `needs-roberto`, `blocked`, `unknown`) de esos tickets, de inmediato si alguno ya está accionable al arrancar. Cada sesión pasa únicamente las claves que ella despachó. Sin `--ticket`, `watch` sigue observando la flota completa.
   - Las consultas de estado consolidado se realizan bajo demanda con `pj-trio fleet <PROYECTO> [--activos]`.
3. **Política de `Merge Danger` (Merge Gate):**
   - Todo PR redacta su sección `## Merge Danger` (skill `/pr`) declarando `**Door:**` y `**Blast Radius:**`.
   - **Auto-merge:** solo permitido cuando `Door: two-way` Y `Blast Radius: Low` (junto con CI verde, `code-review` limpio, rama mergeable y pruebas reales verificadas).
   - **Merge humano:** si el PR tiene `Door: one-way` o `Blast Radius` distinto de `Low`, ningún agente auto-mergea: se etiqueta `ready-to-merge` y se marca `needs-roberto` para que Roberto revise y apruebe manualmente.
4. **1 trío por spec (enmendado por HR-CLAVIS#116/#118):**
   - El PM Orquestador despacha un único `pj-trio <proyecto> <spec> [--repo <miembro>]` por el spec completo; dentro de ese trío en `herdr`, el PM del trío ordena `/implement-spec` al WK (que resuelve el DAG de sub-issues hacia la rama del spec), pasa el PR final al RV en `herdr` y ejecuta el merge final tras `APRUEBO`.

## Consecuencias
- `.agents/reglas/pm.md` y `.agents/reglas/comun.md` incorporan formalmente estas directrices.
- Los hijos de `pj-template` heredan un flujo homogéneo, visible en `herdr`, económico en tokens y seguro contra regresiones de alto riesgo.
