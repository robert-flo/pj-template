# 0020. `make agy-pm`: un comando para actualizar y abrir el trío en agy

Fecha: 2026-11-16 · Estado: aceptado
Origen: Roberto, 2026-11-16: juntar su wrapper `agy` (mise), `agy --agent PM-<proyecto>` y `git pull --rebase --autostash && ./pj listo` en un solo `make agy-pm`, y que venga así desde pj-template.

## Contexto
Abrir el PM eran tres pasos a mano: `git pull --rebase --autostash && ./pj listo` y después el wrapper `agy` de la workstation (`MISE_MINIMUM_RELEASE_AGE=0`, `mise use -g --quiet antigravity-cli`, `mise x antigravity-cli -- agy --dangerously-skip-permissions`) con `--agent PM-<proyecto>`. Saltarse el pull o `./pj listo` deja al agente con reglas o `template_ref` viejos.

## Decisión
- `./pj agy [pm|wk|rv] [args…]` (pm por defecto) corre `./pj listo` (pull, template, genera, hooks, enlaces de agy, clona, check) y, solo si terminó bien, abre `<ROL>-<proyecto>` con lo mismo que el wrapper: `MISE_MINIMUM_RELEASE_AGE=0`, `mise use -g --quiet antigravity-cli` y `exec mise x antigravity-cli -- agy --dangerously-skip-permissions --agent <ROL>-<proyecto> args…`. Sin mise usa el `agy` del PATH (y avisa); sin ninguno, error y sale con 127. `./pj listo --abrir` abre el PM igual.
- El hijo versiona un `Makefile` de atajos (`plantillas/hijo/Makefile`; lo mandan pj-template y el PR de sync, como `./pj`): `make agy-pm`, `make agy-wk`, `make agy-rv` (`ARGS="…"` va a agy), `make listo`, `make onboard`, `make clean`, `make check`. Cada target solo llama a `./pj`: la lógica vive en un lugar.
- El enlace de las fichas solo, que antes era `./pj agy`, pasa a `./pj enlazar` (`./pj listo` lo sigue haciendo).

## Consecuencias
- El hijo versiona 8 archivos; `./pj check` exige que `Makefile` sea igual al de pj-template, y `nuevo-hijo.sh`, `ci-sync.sh` y `deriva.sh` lo copian.
- `scripts/prueba-agy.sh` (parte de `make check`) lo prueba con mise y agy de mentira: el pull y `./pj listo` corren antes, nombre de la ficha por rol, argumentos tal cual, dos corridas iguales, la vuelta sin mise, el error sin ninguno y que no abre nada si `./pj listo` falla.
- `--dangerously-skip-permissions` es la elección de Roberto para su workstation (el mismo wrapper); las reglas del trío siguen mandando.
