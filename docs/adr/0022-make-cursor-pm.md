# 0022. `make cursor-pm` / `./pj cursor`: atajos Cursor espejo de agy

Fecha: 2026-11-21 · Estado: aceptado
Origen: Roberto / HR-CLAVIS#71–#72: nomenclatura A (`c-*` rápido, `cursor-*` completo); Fase 1 sin fallback agy→Cursor.

## Contexto
Abrir el trío en agy ya es trivial (`make pm` / `make agy-pm`, [ADR 0020](0020-make-agy-pm.md)). En Cursor CLI no había camino canónico equivalente (`cursor-agent --yolo --trust --workspace …`) ni atajos en el `Makefile` del hijo. Cambiar el significado de `make pm` rompería la memoria muscular.

## Decisión
- `./pj cursor [pm|wk|rv|os] [--solo] [args…]` (pm por defecto) es el espejo de `./pj agy`: sin `--solo` corre `./pj listo` y solo si OK ejecuta `cursor-agent --yolo --trust --workspace <raiz-del-hijo> args…`. Con `--solo` (o `--sin-listo`) salta pull y listo. Sin `cursor-agent` en el PATH, error claro y exit 127.
- **pm:** sin prompt de rol (la regla `alwaysApply` del PM ya aplica). **wk/rv/os:** prompt inicial que manda a seguir `.cursor/agents/<rol>-<slug>.md`.
- El `Makefile` del hijo (`plantillas/hijo/Makefile`) agrega, sin tocar `pm` / `os` / `agy-*`:
  - rápidos: `make c-pm`, `c-wk`, `c-rv`, `c-os` → `./pj cursor <rol> --solo`
  - completos: `make cursor-pm`, `cursor-wk`, `cursor-rv`, `cursor-os` → `./pj cursor <rol>`
- `make fleet` / `make watch` (pj-trio) se conservan.
- `scripts/prueba-cursor.sh` (parte de `make check`) lo prueba con un `cursor-agent` de mentira en el PATH.

## Consecuencias
- `make pm` / `make agy-*` siguen = agy ([ADR 0020](0020-make-agy-pm.md)).
- Los hijos reciben los targets vía PR de sync (`./pj check` exige `Makefile` byte-igual al molde).
- Despacho PM-en-Cursor → subagentes Cursor (vs `pj-trio`→agy) es política de sesión / regla generada; no cambia este launcher.
- Sin fallback automático agy→Cursor (fuera de alcance de esta ADR).
