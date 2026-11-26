# 0019. Los worktrees salen de ravn-git-bare-clone

Fecha: 2026-11-16 · Estado: reemplazado por [0027](0027-topologia-centralizada-ravn-wt.md)
Origen: [robert-flo/ravn-git-bare-clone](https://github.com/robert-flo/ravn-git-bare-clone) (su README); fleet ADR 0011 («`git-issue-worktree` … never raw `git worktree`»)
Reemplaza: los worktrees del WK de [0016](0016-el-trio-en-herdr-vive-en-ravn-trio.md) (`<clon>-wt-<n>-<fecha>`, hermano del clon)

> [!NOTE]
> Reemplazado por [0027](0027-topologia-centralizada-ravn-wt.md). La topología `/z/bare` y `/z/repos` queda obsoleta y se unifica en `/z-home-repos/.bare` y `/z-home-repos/repos` con `ravn-wt`.

## Contexto
[0016](0016-el-trio-en-herdr-vive-en-ravn-trio.md) copiaba la convención de ravn-trio: `git worktree add` a mano, hermano del clon. Fleet ADR 0011 pide `git-issue-worktree` y nunca `git worktree` a mano, y la herramienta ya existe: `ravn-git-bare-clone` (paquete de `[omarchy-personal]`), con `/z/bare` y `/z/repos` como topología de la workstation. Roberto, 2026-11-16: la herramienta existe y hay que usarla.

## Decisión
- Bare: `$BARE_HOME/<repo>.git` (por defecto `/z/bare`). Raíz de worktrees: `$WORKTREES_HOME/<repo>/` (por defecto `/z/repos`), con un `.git` que apunta al bare. La rama por defecto queda libre.
- Antes de crear un worktree: `ravn-git-bare-clone clone <dueño>/<repo>` (idempotente: clona o sincroniza).
- Worktree de un issue: `git-issue-worktree -r /z/repos/<repo> -B <base> <n> <slug>` si el issue vive en ese repo; si vive en otro (el meta-repo), `git-create-worktree -r /z/repos/<repo> -B <base> -b issue/<n>-<slug> -p '' <n>-<slug>`. Resultado: `/z/repos/<repo>/<n>-<slug>` en la rama `issue/<n>-<slug>`.
- `<base>`: `origin/<rama del spec>` en un sub-issue, `origin/HEAD` en un trivial.
- El RV prueba en `rv-<pr>` (rama local `rv/<pr>` sin subir, `git-create-worktree -N`).
- Al terminar, `git -C /z/repos/<repo> worktree remove <ruta>`. Nunca `git worktree add` a mano.
- Los clones de `./pj clonar` dentro del meta-repo siguen siendo para leer (el PM y el contexto de los agentes). Nadie trabaja en ellos.

## Consecuencias
- `./pj listo` no cambia y `./pj clean` nunca toca `/z/bare` ni `/z/repos`: son compartidos entre proyectos y guardan el trabajo del WK. `clean` deshace solo lo que creó `listo`.
- `wk.md` paso 3, `rv.md`, `comun.md` §Git y el `AGENTS.md` de los hijos lo dicen igual. Dentro de un Home Repo manda [0026](0026-worktrees-del-home-repo.md): `.bares/` y `repos/`, sin duplicar en `/z`.
- Fuera de un Home Repo, ravn-trio crea el worktree del ticket con `ravn-git-bare-clone` en `/z/repos/<repo>/<n>-<slug>`.
