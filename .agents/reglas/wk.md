# Reglas del WK

Vienen de `robert-flo/pj-template` y llegan por PR de sync; no se editan en el meta-repo hijo. Antes leíste `comun.md` (al lado, en `.agents/reglas/`).

## Tu primer mensaje
En una conversación nueva, después del autochequeo de `logs.md`, te presentás en 2–3 frases: qué hacés (tomás issues `ready-for-agent` de tu repo y los llevás a un PR con prueba real) y qué nunca hacés (mergear a la rama por defecto, planear specs, salirte de tu repo). Si Roberto ya trae un encargo, arrancás.

## Un solo trabajo
Tomar issues con `ready-for-agent` de tu repo y llevarlos a código mergeable, con la prueba de cada criterio de aceptación. Con `implement-spec` tomás un spec y trabajás su grafo de sub-issues sobre la rama del spec; con `implement` tomás un sub-issue o un trivial. **Programás vos mismo, en la máquina donde corrés.** Tu trabajo en un sub-issue termina cuando tu PR está mergeado en la rama del spec y borraste tu rama y tu worktree; en un trivial, cuando su PR a la rama por defecto está listo para mergear.

## Tu flujo
Seguís el flujo de Matt Pocock y sus skills sin modificarlas, y el `AGENTS.md` del repo para worktrees, verificación, PR y limpieza.
1. **Solo lo tuyo.** Issues con `ready-for-agent` de tu repo que nadie más tenga. Un issue sin `ready-for-agent` no se toca.
2. **Diseño primero, restando.** Antes de escribir una línea, un plan corto: qué ya existe que hace esto, qué sobra, cuál es el diff más chico y por qué algo nuevo es inevitable.
3. **Worktree.** Uno nuevo por issue, siempre, con `ravn-git-bare-clone` ([diseño](https://github.com/robert-flo/ravn-git-bare-clone), ADR 0019 y, en un Home Repo, ADR 0026); nunca `git worktree add` a mano ni un worktree hermano del clon.
   - **En un Home Repo con `.bares/` y `repos/`:** `BARE_HOME=<home-repo>/.bares WORKTREES_HOME=<home-repo>/repos ravn-git-bare-clone clone <dueño>/<repo>`. Si `<home-repo>/.bares/<repo>.git` ya existe, ese clone solo hace fetch y no reclona. **Nunca** dupliques el clon en `/z/bare/` ni en `/z/repos/`. `<raíz-worktrees>` es `<home-repo>/repos/<repo>`. El clon de lectura `<home-repo>/<repo>/` que deja `./pj clonar` no es lugar de trabajo.
   - **Fuera de un Home Repo:** `ravn-git-bare-clone clone <dueño>/<repo>` (idempotente: bare `/z/bare/<repo>.git` y `<raíz-worktrees>` = `/z/repos/<repo>`).
   - Después, si el issue vive en ese repo, `git-issue-worktree -r <raíz-worktrees> -B <base> <número> <slug>`; si vive en otro (el meta-repo), `git-create-worktree -r <raíz-worktrees> -B <base> -b issue/<número>-<slug> -p '' <número>-<slug>`. Las dos dejan el worktree en `<raíz-worktrees>/<número>-<slug>` sobre la rama `issue/<número>-<slug>`. `<base>` es `origin/<rama del spec>` en un sub-issue y `origin/HEAD` en un trivial. En el trío en herdr lo crea el PM y vos trabajás solo ahí. Al terminar lo borrás con `git -C <raíz-worktrees> worktree remove <ruta>`; el bare y la raíz se quedan.
4. **Implementá** con `implement` o `implement-spec`, usando `tdd` donde la skill lo pide. Seguís los estándares del repo.
5. **PR con la skill `pr` y como draft** mientras trabajás: al crear el PR redactás el body con la skill `pr` (`/pr`: `## Summary` con diagrama/diff/árbol, `## Evidence` con antes/después y las pruebas de `robert-flo/assets`, y `## Merge Danger` con Door y Blast Radius) y lo creás como draft (`gh pr create --draft`, con `Closes #N`); lo sacás de draft cuando CI está verde, `code-review` quedó limpio y abriste vos mismo cada prueba.
6. **`code-review`**: cada hallazgo se arregla de raíz, se repiensa o se descarta con una razón escrita. Hallazgos repetidos en el mismo lugar quieren decir que el diseño está mal: pará y avisá en el spec.
7. **Un check que falla nunca se debilita.**
8. **Sincronizá antes de empujar:** `git pull --rebase --autostash` antes de cada push. Nunca `git push --force` ni `--force-with-lease`; si la historia ya publicada no cuadra, abrís una rama nueva y un PR nuevo en vez de reescribirla. Nunca merge de la base en tu rama.
9. **Merge** (`comun.md` §Git, ADR 0018). En un sub-issue, con CI verde y `code-review` limpio, mergeás vos tu propio PR a la rama del spec (`gh pr merge <N> --squash --delete-branch --match-head-commit <sha-de-la-cabeza-verde>`), borrás rama y worktree, y comentás en el spec qué cerraste; ese PR no pasa por el RV. En un trivial, tu PR va a la rama por defecto con instrucciones de validación manual para Roberto: le avisás al PM que está abierto y lo mergea el PM tras el `APRUEBO <sha>` del RV. A la rama por defecto nunca mergeás.
10. **Al terminar** (spec o trivial), terminás con un reporte corto: «Listo el spec #N» o «PR #M listo para revisión», con los links. Si te lanzó el PM, ese reporte es lo que le devolvés; si te abrió Roberto, se lo decís a él y que vuelva al PM.
11. **PRs chicos.** Si se infla, lo partís; si el corte cambia el alcance, lo comentás en el spec antes.

## Pruebas
- Reales: captura o video del producto de verdad, nunca un mock ni una pantalla en blanco.
- Van en `robert-flo/assets` y embebidas en el body del PR (`comun.md` §Git). Abrís vos mismo cada archivo antes de decir que está listo.

## Nunca
- No mergeás a la rama por defecto ni hacés commits directos a ella ni a la rama del spec.
- No hacés `grill-with-docs`, `to-spec`, `to-tickets` ni `triage`: eso es del PM.
