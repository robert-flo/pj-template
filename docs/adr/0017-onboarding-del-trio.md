# 0017. El onboarding del trío: onboarding.yml, autochequeo de logs y ./pj clean

Fecha: 2026-11-16 · Estado: aceptado · Origen: auditoría de antigravity-fleet contra pj-template y el alta de PMs que ya funcionaba (intake de hechos, ficha con huecos propios, primer mensaje fijo con autochequeo)

## Contexto
En antigravity-fleet cada trío traía criterio propio del proyecto en su ficha: qué es (misión), qué no se toca, los primeros pasos del PM, lo que exige el RV en ese stack y cómo prueba el WK. Al pasar a pj-template eso no tuvo dónde vivir: `generar.py` arma un único bloque «Tus datos» igual para los tres roles, las secciones del WK y del RV son genéricas y el «onboarding del PM» se mencionaba sin estar definido. Los PM salían sin alma y sin forma de saber si cargaron sus reglas.

El alta de PMs que sí funcionaba hacía tres cosas: junta los hechos solo y pregunta solo lo abierto (con resumen y un sí), escribe una ficha con huecos propios del proyecto, y el PM abre con una línea de autochequeo (`[log: arranque · cargué … ✔]`) y un primer mensaje fijo palabra por palabra.

## Decisión
- **`onboarding.yml` en el hijo** (versionado, esquema `schema/onboarding.schema.json`): `version`, `hecho` (fecha; vacío = sin hacer), `mision`, `no_tocar[]`, `reglas_proyecto[]`, `primeros_pasos[]`, `wk.como_probar[]`, `rv.exige[]`. `repos:` sigue en `proyecto.yml` y se llena en la misma entrevista.
- **`generar.py` lo inyecta** en las fichas: las tres reciben «El proyecto» (misión, no tocar, reglas); el PM sus primeros pasos (antes de los genéricos, que quedan como piso) y su **primer mensaje ya armado**; el WK «Cómo probás» en §Al empezar; el RV «Lo que exigís». La regla del PM en Cursor lleva la misión. Sin onboarding, las fichas dicen «sin hacer» y el primer mensaje del PM manda a `./pj onboard`.
- **`./pj onboard`** (`scripts/onboard.py`) es la entrevista, en el orden del alta que ya funcionaba: junta los hechos (proyecto.yml, README.md, AGENTS.md, los repos que nombran verificados con `gh`, el Makefile y el stack de cada repo), propone cada campo con una recomendación que Enter acepta, muestra el resumen y escribe solo con un sí. Es idempotente: si ya está hecho muestra los datos y pregunta «¿querés cambiar algo? [n/campo]»; `n` no toca nada. `--mostrar`, `--si`, `--respuestas F` y `--rehacer` lo hacen usable sin terminal (pruebas y CI).
- **Autochequeo**: `.agents/reglas/logs.md` (adaptado del que ya funcionaba, sin referencias a otras plataformas) y cada ficha con «Cargás» (`logs.md`, `comun.md`, su rol). La primera respuesta de cada rol abre con `[log: arranque · cargué <ficha> ✔, … · fuente=archivo]`; el PM sigue con `[log: pm.md §Lo primero · fuente=archivo]` y su primer mensaje. En Cursor el autochequeo nombra primero el adaptador; reemplaza el marcador `soy pm-<slug>.mdc`.
- **Primer mensaje del PM** igual al del alta que funcionaba, salvo el merge: en un hijo el PM mergea cuando el RV publica `APRUEBO` sobre el head exacto ([0014](0014-el-pm-mergea-tras-apruebo.md)). Suma la misión, los repos que supervisa y el primer paso del onboarding.
- **`./pj clean [--onboarding]`** deshace `./pj listo` para poder repetirlo: borra `.pj/`, lo generado (ignorado por git) en `.agents/` y `.cursor/`, los hooks marcados `# pj-hook`, los enlaces de agy de este proyecto que apuntan a este clon y los clones de `repos:` sin trabajo local (con cambios, commits sin subir o stash los deja y sale con 1). `--onboarding` además deja `onboarding.yml` y `repos:` sin hacer. Vive en `./pj` (no en el Makefile del template) porque borra el template; no necesita Python. Idempotente: la segunda vez dice «nada que limpiar».
- **`./pj listo`** ofrece el onboarding si falta y hay terminal; sin terminal imprime el comando exacto.
- **Hijos sin `onboarding.yml`**: `./pj check` avisa y no falla (los que existen hoy no se rompen con el PR de sync); falla solo si el archivo existe y no cumple el esquema.

## Consecuencias
- El hijo versiona hasta 7 archivos a mano; `check.sh` acepta `onboarding.yml`. `nuevo-hijo` lo crea «sin hacer».
- `make check` corre `scripts/prueba-onboarding.sh`: onboard dos veces (mismos bytes), sin terminal, en terminal con `n`, `--rehacer`, clean con clon sucio y limpio, clean dos veces.
- `make humo` / `./pj humo` con agy abre el PM con «hola» y exige el autochequeo, §Lo primero, «soy PM-<p>», la misión y el primer paso.
- Cambiar el alma de un proyecto es cambiar `onboarding.yml` (con `./pj onboard` o un PR trivial del WK); nunca las fichas.
