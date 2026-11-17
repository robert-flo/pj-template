# Logs de instrucciones («console.log figurativo»)

Vienen de `robert-flo/pj-template` y llegan por PR de sync; no se editan en el meta-repo hijo. Valen igual para PM, WK y RV, en agy y en Cursor.

LOGS: on

Para apagarlos en todos los tríos, cambiá la línea de arriba a `LOGS: off` en pj-template. Con `off` no escribís ningún `[log: …]`; todo lo demás sigue igual.

## Qué es
Cada mensaje tuyo empieza con una o varias líneas de traza que dicen qué instrucción estás aplicando y de dónde sale, para que Roberto vea si seguís lo establecido o estás improvisando. Es una traza, no un adorno: si no la aplicaste de verdad, no la escribís.

## Formato
Una línea por instrucción, al inicio del mensaje, antes del texto normal:

```
[log: <instrucción> · fuente=<origen>]
```

- `<instrucción>`: dónde vive la regla, lo más preciso que podás: `<archivo> §<sección>` (por ejemplo `pm.md §Tu flujo 4`), `skill /<nombre>` (por ejemplo `skill /grill-with-docs`), `AGENTS.md §<sección>` del repo, o una frase corta si no hay sección.
- `<origen>`, uno de estos:
  - `archivo`: tu ficha (`.agents/agents/`), una regla de `.agents/reglas/` o un adaptador de `.cursor/`.
  - `skill`: una skill de `.agents/skills/`.
  - `repo`: un archivo del repo en que trabajás (`AGENTS.md`, `docs/agents/`, ADRs, Makefile, `onboarding.yml`).
  - `pedido`: lo que Roberto (o el PM que te lanzó) te pidió en este chat.
  - `criterio`: tu propio criterio, sin regla escrita. Usalo con honestidad: es justo lo que Roberto quiere ver.

Ejemplos:

```
[log: pm.md §Tu flujo 4 · fuente=archivo]
[log: skill /to-spec · fuente=skill]
[log: AGENTS.md §verify · fuente=repo]
[log: no hay regla para esto, pregunto · fuente=criterio]
```

## Reglas
1. Máximo cuatro líneas por mensaje: las instrucciones que más pesaron en ese mensaje.
2. Solo citás archivos, secciones y skills que de verdad leíste en esta conversación. Nunca inventés una sección.
3. Los logs no cuentan como parte del texto: si una regla dice «copiá este mensaje palabra por palabra», los logs van arriba y el mensaje va igualito abajo.
4. En lo que publicás fuera del chat (issues, PRs, commits, comentarios) no van logs.

## Autochequeo del primer mensaje (obligatorio)
Tu primera respuesta de cada conversación nueva empieza con esta línea. Primero va tu ficha (y en Cursor, antes, el adaptador que te cargó) y después cada archivo de «Cargás» de tu ficha, en orden, con ✔ si lo leíste completo o ✘ si no pudiste:

```
[log: arranque · cargué <tu ficha> ✔, <archivo1> ✔, <archivo2> ✔, … · fuente=archivo]
```

Tu ficha trae la línea ya escrita con sus rutas exactas. Si algún archivo quedó en ✘, decilo en una frase y no sigas como si lo tuvieras. Después del autochequeo seguís lo que tu ficha diga para el primer mensaje.

## Relectura
Si en una conversación nueva, o después de compactar, ya no tenés claro lo que dice tu ficha, volvé a leerla (y los archivos que lista) antes de responder, y abrí con `[log: relectura de <ficha> · fuente=archivo]`.
