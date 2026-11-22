# 0024. Convención simétrica `a-*` / `c-*` en `--solo` y composición `make listo <target>`

Fecha: 2026-11-21 · Estado: aceptado
Origen: Roberto / pj-template#81 (#82, #83, #84). Enmienda [0020](0020-make-agy-pm.md) y [0022](0022-make-cursor-pm.md).

## Contexto
La convención anterior (`make agy-pm`, `make cursor-pm`, `make pm`, `make c-pm`) presentaba dos problemas:
1. **Asimetría entre motores:** agy usaba `make pm` / `make os` (sin `wk`/`rv` rápidos) y `make agy-*`, mientras Cursor CLI usaba `make c-*` y `make cursor-*`.
2. **Arranque lento por defecto:** los targets completos corrían `git pull --rebase --autostash` y `./pj listo` en cada invocación, penalizando el arranque cotidiano cuando el repo ya estaba actualizado.

## Decisión
1. **Atajos simétricos rápidos por defecto (`--solo`):**
   - agy: `make a-pm`, `make a-wk`, `make a-rv`, `make a-os` → `./pj agy <rol> --solo $(ARGS)`.
   - Cursor CLI: `make c-pm`, `make c-wk`, `make c-rv`, `make c-os` → `./pj cursor <rol> --solo $(ARGS)`.
2. **Actualización explícita por composición:** para correr `git pull --rebase --autostash` y `./pj listo` antes de abrir el agente, se compone `make listo a-pm` o `make listo c-pm` (y análogos `a-*` / `c-*`).
3. **Eliminación de targets heredados:** se eliminan `make pm`, `make os`, `make agy-*` y `make cursor-*` de `plantillas/hijo/Makefile`.
4. **Ayuda agrupada:** `.DEFAULT_GOAL := help` muestra los targets organizados por sección (`##@`).

## Consecuencias
- `scripts/prueba-agy.sh` y `scripts/prueba-cursor.sh` (parte de `make check`) verifican que los targets antiguos fallen y que `a-*` / `c-*` invoquen `--solo`.
- Los hijos reciben el nuevo `Makefile` vía PR de sync (`./pj check` exige coincidencia byte a byte).
- Documentación y reglas (`AGENTS.md`, `README.md`, `docs/pj-template.md`, `plantillas/cursor/pm.mdc`, `.agents/reglas/*`, `docs/adr/*`) reflejan exclusivamente `a-*` / `c-*` y `make listo <target>`.
