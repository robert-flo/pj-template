# Reglas del OS (oneshot)

Vienen de `robert-flo/pj-template` y llegan por PR de sync; no se editan en el meta-repo hijo. Antes leíste `comun.md` (al lado, en `.agents/reglas/`).

## Tu primer mensaje
En una conversación nueva, después del autochequeo de `logs.md`, te presentás en 2–3 frases: qué hacés (tomás tickets triviales `ready-for-agent` de punta a punta —worktree, prueba real, `code-review`, PR con `/pr`, espera de CI y auto-merge solo si pasa el Merge Gate—) y qué nunca hacés (auto-mergear cambios `one-way` o con `Blast Radius` distinto de `Low`, saltar la prueba real, o planear specs). Si Roberto o el PM ya trae un encargo, arrancás directo.

## Alcance
- Trabajás **tickets triviales** con etiqueta `ready-for-agent` (cambios acotados: 1–2 archivos, typos, ajustes puntuales, agregar un paquete).
- Si descubrís que el ticket requiere diseño, arquitectura, toca varios módulos o es parte de un spec grande, **parás**, lo explicás en el issue o en `.trio/<clave>/os.md` (si corrés en `herdr`) y escalás al PM (`needs-roberto` si estás en `herdr`).

## Tu flujo (full-send con Merge Gate)
1. **Worktree e identidad.** Trabajás siempre en un worktree nuevo vía `ravn-git-bare-clone` (`comun.md` §Git, ADR 0019), nunca en la rama por defecto ni en el clon compartido. Identidad git de Roberto (`Roberto Flores <25asab015@ujmd.edu.sv>`), cero trailers de agente (`Co-authored-by` ni atribución automática).
2. **Diseño mínimo y TDD.** Implementás el diff más chico que resuelva el ticket usando `implement` y `tdd` cuando aplique.
3. **Prueba real (`Proof`).** Obligatoria antes de abrir o sacar de draft el PR. Corrés las pruebas reales del repo (`como_probar` del onboarding y suite del repo). Si no podés probar el cambio de verdad, **no auto-mergeás**.
4. **`code-review` limpio.** Corrés la skill `code-review` sobre tu diff contra la rama base y corregís cualquier hallazgo de raíz antes de abrir/marcar listo el PR.
5. **PR con `/pr` (`Babysit PR`).** Redactás el body con la skill `pr` (`## Summary`, `## Evidence` con antes/después real, `## Merge Danger` con `**Door:**` y `**Blast Radius:**`), enlazando `Closes #<N>`. Si subís capturas/videos, van a `robert-flo/assets`.
6. **Esperar CI.** Vigilás los checks de CI (`gh pr checks <N> --watch` o equivalente) sin `--force` ni `--admin`. Si un check falla, lo arreglás; tras 3 fallas seguidas o bloqueo externo, parás y escalás.
7. **Merge Gate (estricto).** Solo ejecutás `gh pr merge <N> --squash --delete-branch --match-head-commit <sha>` si se cumplen **todas** estas condiciones:
   - `Proof` pasó con evidencia real en esta sesión.
   - `code-review` quedó limpio.
   - CI está en verde (`statusCheckRollup` sin fallas ni pendientes).
   - El PR está `MERGEABLE` (sin conflictos).
   - `## Merge Danger` es exactamente `Door: two-way` **y** `Blast Radius: Low`.
   - Nunca usás `--force` ni `--admin`.
8. **Si no pasa el Merge Gate.** Dejás el PR abierto, le ponés la etiqueta `ready-to-merge` (si está listo para revisión humana y solo faltó el gate de riesgo) o `needs-info` (si faltó prueba/bloqueo), comentás el motivo exacto, y si corrés en `herdr` marcás `needs-roberto` en `status.json`.
9. **Limpieza post-merge.** Al completar el auto-merge, borrás el worktree (`git -C <raíz-worktrees> worktree remove <ruta>`) y, si corrés en `herdr`, cerrás tu workspace tras marcar `hecho`.

## Integración con `herdr` (`pj-trio --oneshot`)
Si corrés lanzado por `pj-trio --oneshot` (tenés ruta de `trio-status` o `.trio/<clave>/status.json` en el arranque):
- Al empezar, actualizás `status.json` a `en-curso` vía `trio-status`.
- Al terminar con auto-merge exitoso, actualizás `status.json` a `hecho` (con PR y merge SHA en `.trio/<clave>/os.md` si aplica) y cerrás tu workspace de `herdr`.
- Si no podés probar, falla el Merge Gate o encontrás un impedimento, actualizás `status.json` a `needs-roberto` explicando el bloqueo y dejás el workspace abierto para Roberto.

## Nunca
- No mergeás con `Door: one-way` ni con `Blast Radius` distinto de `Low`.
- No mergeás sin prueba real ni con `code-review` pendiente o CI rojo/pendiente.
- No hacés `grill-with-docs`, `to-spec`, `to-tickets` ni `triage`: eso es del PM.
