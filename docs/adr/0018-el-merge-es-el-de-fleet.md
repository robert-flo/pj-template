# 0018. Quién mergea qué es la regla de fleet

Fecha: 2026-11-16 · Estado: aceptado
Origen: fleet `CIRCUITO.md` C5, C6, C9 y C10; fleet ADR 0011; fleet `templates/ficha-reviewer.md`
Aclara: [0006](0006-rama-del-spec-y-modelo-de-terminado.md) y [0014](0014-el-pm-mergea-tras-apruebo.md)

## Contexto
pj-template existe para que los tríos de agy y Cursor hagan lo mismo que los tríos de fleet. Al juntar todo en el `AGENTS.md` de HR-CLAVIS apareció un choque: [0014](0014-el-pm-mergea-tras-apruebo.md) y `comun.md` decían «el WK y el RV nunca mergean», pero `wk.md` paso 9 (y [0006](0006-rama-del-spec-y-modelo-de-terminado.md)) hacen que el WK mergee sus sub-issues a la rama del spec. Roberto, 2026-11-16: si un WK de fleet hace A, el WK de agy no puede hacer B. La regla ya estaba decidida en fleet; acá solo se copia.

Lo que dice fleet, textual:
- `CIRCUITO.md` C5: «El RV publica `APRUEBO <sha>` o `BLOQUEO` en el PR sin pedirle permiso a nadie».
- `CIRCUITO.md` C6: «Con `APRUEBO` sobre el head exacto, el PM mergea con `gh pr merge --squash --delete-branch --match-head-commit`. Si el head se movió, vuelve a revisión.»
- `CIRCUITO.md` C9: «Nadie le pide confirmación a Roberto dentro del circuito.»
- ADR 0011 de fleet, *Worker branches*: el worker «gets CI green and runs `/code-review`, then merges its own PR into the spec branch when everything passes».
- `GLOSSARY.md` de fleet, *Reviewer*: revisa solo el PR final; «Workers' sub-issue PRs do not go through it».
- `templates/ficha-reviewer.md`: «No programás, no hacés commits, no mergeás, no cerrás PRs».

## Decisión
Una sola regla, la de fleet:
- **Sub-issue → rama del spec:** lo mergea el WK, con CI verde y `code-review` limpio, sin RV.
- **PR final (rama del spec → rama por defecto) y trivial:** lo revisa el RV y lo mergea el PM tras `APRUEBO <sha>` sobre el head exacto, sin esperar orden de Roberto. Si el head cambió, vuelve a revisión.
- **El RV nunca mergea.** El WK nunca mergea a la rama por defecto.
- Todo merge: `gh pr merge <N> --squash --delete-branch --match-head-commit <sha>`.

Donde fleet calla: `CIRCUITO.md` no distingue sub-issue de PR final, pero C10 dice que gana sobre las fichas, no sobre los ADR de fleet que sí lo distinguen (0011, 0017), y no los contradice. Se toma la lectura que deja vigentes los dos: el circuito C3–C8 aplica a los PR que revisa el RV (final y trivial). Las fichas de PM de fleet que todavía dicen «solo mergeo cuando vos me lo ordenás» quedan pisadas por C6 y C9 (la nota de `CIRCUITO.md` sobre los repos de fleet no aplica a los hijos de pj-template).

## Consecuencias
- `comun.md` §Git, `wk.md` paso 9, `pm.md` paso 7, [0014](0014-el-pm-mergea-tras-apruebo.md) y el glosario dicen lo mismo.
- ravn-trio (`pj-trio`) sigue esta regla: con `--base` (sub-issue) no hay paso RV y el WK mergea su PR a la rama del spec.
- Si fleet cambia la regla, se cambia acá con un ADR nuevo que cite el cambio de fleet.
