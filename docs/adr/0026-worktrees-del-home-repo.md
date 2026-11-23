# 0026. En un Home Repo los worktrees salen de .bares y repos

Fecha: 2026-11-22 · Estado: aceptado
Origen: Roberto / HR-CLAVIS#141. Enmienda [0019](0019-worktrees-con-ravn-git-bare-clone.md) solo dentro de un Home Repo.

## Contexto
[0019](0019-worktrees-con-ravn-git-bare-clone.md) fija el bare en `/z/bare/<repo>.git` y los worktrees en `/z/repos/<repo>/`. Un Home Repo ya tiene `.bares/<repo>.git` y `repos/<repo>/`. Seguir 0019 al pie de la letra reclona el miembro en `/z` aunque el bare local exista.

## Decisión
- Dentro de un Home Repo (hay `.bares/` y `repos/`): `BARE_HOME=<home-repo>/.bares` y `WORKTREES_HOME=<home-repo>/repos`. El comando sigue siendo `ravn-git-bare-clone clone <dueño>/<repo>`. Si `.bares/<repo>.git` ya existe, ese clone solo hace fetch y no crea otro bare en `/z/bare`.
- La raíz de worktrees es `<home-repo>/repos/<repo>` (la que deja ese clone, con su `.git` hacia el bare). Ahí van `issue/<n>-<slug>` y `rv-<pr>`. Nunca se duplica el clon en `/z/bare` ni en `/z/repos`.
- El clon de lectura que deja `./pj clonar` en `<home-repo>/<repo>/` sigue sin ser lugar de trabajo.
- Fuera de un Home Repo, vale 0019 tal cual: `/z/bare` y `/z/repos`.

## Consecuencias
- `wk.md` paso 3, `rv.md` y `comun.md` §Git dicen esta topología dentro de un Home Repo y la de 0019 fuera.
- `./pj clean` sigue sin tocar `/z/bare` ni `/z/repos`.
