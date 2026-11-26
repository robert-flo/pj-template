# 0027. Topología centralizada única de bares y worktrees con ravn-wt

Fecha: 2026-11-26 · Estado: aceptado
Origen: Roberto / HR-CLAVIS#239, pj-template#104. Reemplaza y enmienda [0019](0019-worktrees-con-ravn-git-bare-clone.md) y [0026](0026-worktrees-del-home-repo.md).

## Contexto
Históricamente existían múltiples topologías desarticuladas en la workstation:
1. [0019](0019-worktrees-con-ravn-git-bare-clone.md) fijaba bares en `/z/bare/<repo>.git` y worktrees en `/z/repos/<repo>/`.
2. [0026](0026-worktrees-del-home-repo.md) introdujo una excepción para los Home Repos (`HR-*`), ubicando bares en `<home-repo>/.bares/<repo>.git` y worktrees en `<home-repo>/repos/<repo>/`.
3. Esto generó dispersión, clonados redundantes, inconsistencias de `origin/HEAD`, desfases entre `/z/bare` y los Home Repos, y rutas huérfanas en los repositorios al crear carpetas planas `<repo>/<ticket>-<slug>` en lugar de reflejar el namespace de la rama.

Roberto estableció el 2026-11-26 las cuatro decisiones definitivas de centralización:
1. Árbol único canónico: `<RAIZ>/repos/<repo>/<rama>`.
2. Home Repos (`HR-*`) leen directo de `<RAIZ>/repos/<repo>/<rama-base>` sin copias locales ni symlinks.
3. `/z/bare` y `/z/repos` quedan obsoletos y desfasados; se deprecian y migran a `<RAIZ>/.bare` y `<RAIZ>/repos`.
4. Worktrees con convención simétrica e invariante `carpeta == rama`: `issue/<ticket>-<slug>` y `specs/<ticket>-<slug>`.

## Decisión
- **Raíz central única (`RAVN_HOME_REPOS_ROOT`):**
  `/z-home-repos` (fallback `$HOME/z-home-repos`).
  - Bares centrales: `<RAIZ>/.bare/<repo>.git`.
  - Repositorios y worktrees centrales: `<RAIZ>/repos/<repo>/`.
- **CLI Canónico (`ravn-wt`):**
  `ravn-wt` (del paquete `ravn-git-bare-clone`) es la herramienta y comando canónico para gestionar bares y worktrees.
- **Invariante Carpeta == Rama:**
  - Issues y tickets triviales: carpeta `issue/<n>-<slug>` en rama `issue/<n>-<slug>`.
  - Specs y branches de integración: carpeta `specs/<n>-<slug>` en rama `specs/<n>-<slug>`.
  - Revisión del RV: carpeta `rv/<pr>` en rama local `rv/<pr>`.
- **Base remota obligatoria y sincronización previa:**
  Al crear un worktree, `ravn-wt create` ejecuta siempre `git fetch --prune origin` (salvo `--no-fetch`) y asegura `origin/HEAD` llamando `remote set-head origin --auto`. Todo worktree parte siempre de una referencia remota (`origin/HEAD`, `origin/specs/...` u `origin/<rama>`), nunca de la rama local del clon de lectura.
- **Home Repos y `./pj clonar`:**
  `clone-repos.sh` delega en `ravn-wt clone <dueño>/<repo>`. Los Home Repos ya no contienen `.bares/` locales ni `repos/` anidados; los agentes leen el código directamente de `/z-home-repos/repos/<repo>/<rama-base>`.

## Consecuencias
- Quedan obsoletas las rutas `/z/bare` y `/z/repos`, así como las carpetas `.bares/` dentro de cada Home Repo.
- Se eliminan de las reglas de los agentes (`comun.md`, `wk.md`, `rv.md`, `os.md`) todas las bifurcaciones condicionales («dentro de Home Repo vs fuera de Home Repo»).
- Los agentes usan exclusivamente la convención unificada:
  - WK / OS: `ravn-wt create -r /z-home-repos/repos/<repo> -B origin/HEAD -b issue/<n>-<slug> -p '' issue/<n>-<slug>`
  - RV: `ravn-wt create -N -r /z-home-repos/repos/<repo> -B origin/<rama-PR> -b rv/<pr> -p '' rv/<pr>`
- `./pj clean` no toca `/z-home-repos/.bare` ni `/z-home-repos/repos`.
