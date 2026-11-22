# 0022. `./pj cursor` / `c-*`: atajos Cursor espejo de agy

Fecha: 2026-11-21 · Estado: aceptado (enmendado en nombres de targets de `Makefile` por [0024](0024-convencion-simetrica-a-c-y-listo.md) y en el retiro de `.cursor/agents/` por [0025](0025-despacho-cursor-trio-efimero-herdr.md))
Origen: Roberto / HR-CLAVIS#71–#72: Fase 1 sin fallback agy→Cursor.

> **Enmienda ([ADR 0024](0024-convencion-simetrica-a-c-y-listo.md)):** los targets completos `make cursor-*` fueron reemplazados por la composición `make listo c-*`, manteniendo `make c-{pm,wk,rv,os}` en `--solo` por defecto, en simetría con `make a-{pm,wk,rv,os}`.
> **Enmienda ([ADR 0025](0025-despacho-cursor-trio-efimero-herdr.md)):** se retira la generación de subagentes in-chat `.cursor/agents/*`, reemplazada por `pm-trio-<slug>.mdc` y despacho en `herdr` con `pj-trio --kind cursor`. Se conservan `make c-*`, `cursor-agent --yolo --trust`, `mise` y `@.cursor/rules/<rol>-<slug>.mdc`.

## Contexto
Abrir el trío en agy ya es trivial (`./pj agy`, [ADR 0020](0020-make-agy-pm.md)). En Cursor CLI no había camino canónico equivalente (`cursor-agent --yolo --trust --workspace …`) ni atajos en el `Makefile` del hijo.

## Decisión
- `./pj cursor [pm|wk|rv|os] [--solo] [args…]` (pm por defecto) es el espejo de `./pj agy`: sin `--solo` corre `./pj listo` y solo si OK ejecuta, con mise, `MISE_MINIMUM_RELEASE_AGE=0 mise use -g --quiet cursor-agent` y `mise x cursor-agent -- cursor-agent --yolo --trust --workspace <raiz-del-hijo> args…`. Con `--solo` (o `--sin-listo`) salta pull y listo. Sin mise, el `cursor-agent` del PATH (con aviso). Sin ninguno, exit 127.
- El prompt, para los cuatro roles, es solo `@.cursor/rules/<rol>-<slug>.mdc`. El CLI no tiene `--agent`; esa mención es la identidad. Las reglas van con `alwaysApply: false` y sin `description`. WK, RV y OS siguen también como subagentes `.cursor/agents/`.
- El `Makefile` del hijo (`plantillas/hijo/Makefile`) ofrece:
  - rápidos (`--solo`): `make c-pm`, `c-wk`, `c-rv`, `c-os` → `./pj cursor <rol> --solo`
  - con actualización previa: `make listo c-pm` (enmienda [0024](0024-convencion-simetrica-a-c-y-listo.md), reemplaza a `make cursor-*`)
- `make fleet` / `make watch` (pj-trio) se conservan.
- `scripts/prueba-cursor.sh` (parte de `make check`) lo prueba con mise y `cursor-agent` de mentira.

## Consecuencias
- `make a-*` / `make listo a-*` = agy; `make c-*` / `make listo c-*` = Cursor ([ADR 0024](0024-convencion-simetrica-a-c-y-listo.md)).
- Los hijos reciben los targets vía PR de sync (`./pj check` exige `Makefile` byte-igual al molde).
- Despacho PM-en-Cursor → subagentes Cursor (vs `pj-trio`→agy) es política de sesión / regla generada ([0023](0023-despacho-cursor-cuando-pm-en-cursor.md)); no cambia este launcher.
- Sin fallback automático agy→Cursor (fuera de alcance de esta ADR).
