# Cómo funciona pj-template

Este archivo vive en `robert-flo/pj-template`. Un hijo en modo dependencia lo tiene en `.pj/tpl/docs/pj-template.md` después de `./pj`.

## Modo dependencia (el de los hijos nuevos)
El hijo versiona solo **8 archivos**: `proyecto.yml`, `onboarding.yml` (el alma del trío, [ADR 0017](adr/0017-onboarding-del-trio.md)), `AGENTS.md`, `README.md`, `.gitignore`, `./pj`, `Makefile` (atajos a `./pj`, [ADR 0020](adr/0020-make-agy-pm.md) y [ADR 0024](adr/0024-convencion-simetrica-a-c-y-listo.md)) y `.github/workflows/pj-template.yml`. Todo lo demás llega como dependencia:

**Extras.** Si un hijo necesita conservar archivos propios a mano (por ejemplo un adaptador propio en `.agents/` que se deja intacto, o un `.code-workspace`), los lista en `extras:` de `proyecto.yml`. `./pj check` los acepta versionados y no los revisa (tampoco en la búsqueda de referencias de otras plataformas); `./pj` no los genera ni los borra. Ninguno puede ser uno de los archivos de arriba ni salir del repo.

1. `./pj` lee `template_ref` (SHA completo de pj-template) de `proyecto.yml` y trae ese commit a `.pj/tpl` (ignorado por git; `git fetch --depth 1`, con `PJ_TEMPLATE_TOKEN` o `gh auth git-credential`).
2. Corre `.pj/tpl/scripts/generar.py` con `PJ_RAIZ=<hijo>`: escribe las fichas y adaptadores **y copia** reglas, skills y la regla sin coautor de Cursor a `.agents/` y `.cursor/`.
3. `./pj listo [--abrir] [--dry-run] [--no-clonar]` es el paso único tras un clone: `git pull --rebase --autostash`, trae el template, genera, `./pj hooks` (hooks `post-merge` y `post-checkout` que corren `./pj` tras cada pull o cambio de rama; no pisa hooks propios), `./pj onboard` si falta el onboarding y hay terminal (si no, imprime el comando), `agy`, `clonar`, `check`, e imprime `agy --agent PM-<proyecto>` (`--abrir` lo arranca). Con `--dry-run` (o `PJ_CLONAR_DRY_RUN=1`) simula `clonar` sin tocar git/gh; con `--no-clonar` (o `PJ_SIN_CLONAR=1`) lo salta. Si corrés `./pj listo` dentro de un worktree (`.git` como archivo) y no pasaste `PJ_CLONAR=1`, corre `clonar` automáticamente en `--dry-run` con aviso para no reclonar varios gigas.
4. `./pj onboard` es la entrevista del onboarding (`onboarding.yml` y `repos:`): junta los hechos, propone cada campo (Enter acepta), resume y escribe con tu sí. La segunda vez dice «ya está hecho el <fecha>», muestra los datos y pregunta qué cambiar. `./pj clean [--onboarding]` deshace `./pj listo` (y el onboarding) para repetirlo; no borra clones con trabajo sin subir.
5. `make sync` (`./pj sync`) actualiza `template_ref` en `proyecto.yml` al último `main` de pj-template (o al `HEAD` de `PJ_TEMPLATE_DIR`), copia `pj`, `Makefile` y `.github/workflows/pj-template.yml` del molde, regenera y corre `./pj check` sin hacer commit automático.
6. `./pj <target>` corre cualquier target del `Makefile` del template contra el hijo: `check`, `humo`, `clonar` (`./pj clonar [--dry-run|-n]`), `agy`, `generar`.

**¿Se versiona lo generado? No.** agy y Cursor leen `.agents/` y `.cursor/` del disco, pero las fichas citan reglas y skills que tampoco estarían al clonar: versionar solo las fichas daría un clon a medias. Un solo paso después de clonar (`./pj`) deja todo en disco, igual byte a byte en cualquier máquina porque sale de un SHA fijo. Así el hijo se queda en 8 archivos, el diff de un PR del hijo es solo lo que escribió Roberto, y actualizar el template es cambiar una línea (`template_ref`). `.gitignore` ignora `/.pj/`, `/.agents/`, `/.cursor/`, `/.bares/` y `/repos/` (bloque generado). AGENTS.md del hijo le dice al agente que corra `./pj` si no ve `.agents/reglas/`.

## Quién manda qué
| Qué | Dónde | Quién lo escribe |
| --- | --- | --- |
| Reglas comunes, de rol y de logs | `.agents/reglas/{logs,comun,pm,wk,rv}.md` | pj-template (al hijo lo copia `./pj`) |
| Skills | `.agents/skills/` + `skills-lock.json` | CI de pj-template, desde `robert-flo/skills@personal` |
| Skills por rol | `plantillas/roles.yml` (+ `skills_extra` del hijo) | pj-template / el hijo |
| Esquema de `proyecto.yml` | `schema/proyecto.schema.json` | pj-template |
| Archivos fijos del hijo | `plantillas/hijo/{pj,Makefile,pj-template.yml,gitignore}` (`Makefile`: atajos simétricos `a-*` / `c-*` y `make listo <target>`, [ADR 0024](adr/0024-convencion-simetrica-a-c-y-listo.md)) | pj-template (el PR de sync los actualiza) |
| Fichas de agy | `.agents/agents/{PM,WK,RV}-<proyecto>.md` | `scripts/generar.py` |
| Adaptadores de Cursor | `.cursor/rules/{pm,pm-trio,wk,rv,os}-<proyecto>.mdc` (`alwaysApply: false`, sin `description`) y `.cursor/rules/no-cursor-coauthor.mdc` | `scripts/generar.py` |
| Datos del proyecto, con `template_ref` | `proyecto.yml` | vos, en el hijo (`template_ref` lo sube el PR de sync) |
| Alma del trío (misión, no tocar, reglas, primeros pasos, cómo prueba el WK, qué exige el RV) | `onboarding.yml` (esquema `schema/onboarding.schema.json`) | `./pj onboard`, en el hijo |
| Arquitectura del proyecto | `AGENTS.md`, `README.md` | vos, en el hijo |

## proyecto.yml
Lo valida `schema/proyecto.schema.json` (JSON Schema 2020-12, con `jsonschema` de Python) en `generar` y en `check`:
- `specs` es una lista de `{ref, titulo, orden, primero}`: `ref` con forma `dueño/repo#N`, `orden` entero (se listan de menor a mayor), y si hay specs, **exactamente uno** con `primero: true`. La ficha del PM lo marca como «primer trabajo» y su «Primeros pasos» arranca por ahí. `orden` no se puede repetir.
- Los textos van entre comillas: un `#` sin comillas en `area`, `titulo`, `nota` o `ref` corta el valor (YAML lo toma como comentario). `generar` lo detecta y falla; la forma de `ref` también delata un corte.
- No se aceptan claves de más.

`generar` falla si quedan datos del molde en un hijo: `proyecto: pj-template`, las notas de pj-template, fichas `*pj-template*` sobrantes o (en modo dependencia) falta `template_ref`.

## Motores
- **agy**: `make a-pm` (o `a-wk`, `a-rv`, `a-os`; `ARGS="…"`) desde la raíz del hijo = `./pj agy [pm|wk|rv|os] --solo [args…]` (arranque rápido al instante, sin `git pull` ni `./pj listo`). Para actualizar antes de abrir: `make listo a-pm` (corre `git pull --rebase --autostash` y `./pj listo`, y si pasó ejecuta `MISE_MINIMUM_RELEASE_AGE=0 mise use -g --quiet antigravity-cli` y `exec mise x antigravity-cli -- agy --dangerously-skip-permissions --agent <ROL>-<proyecto> args…`; sin mise, el `agy` del PATH; [ADR 0020](adr/0020-make-agy-pm.md), enmendado por [ADR 0024](adr/0024-convencion-simetrica-a-c-y-listo.md)). `./pj listo` (o solo `./pj enlazar`; `make agy` en pj-template) enlaza las fichas en `~/.gemini/config/agents`, porque agy interactivo solo resuelve `--agent` con los agentes globales. `skills:` del frontmatter es declarativo: agy carga todas las de `.agents/skills/`.
- **Cursor CLI**: `make c-pm` (o `c-wk`/`c-rv`/`c-os`; `ARGS="…"`) = `./pj cursor [pm|wk|rv|os] --solo [args…]` (arranque rápido al instante). Para actualizar antes: `make listo c-pm` (corre `./pj listo` y después, espejo de agy, `MISE_MINIMUM_RELEASE_AGE=0 mise use -g --quiet cursor-agent` y `exec mise x cursor-agent -- cursor-agent --yolo --trust --workspace <raiz> args… @.cursor/rules/<rol>-<slug>.mdc` para pm, wk, rv y os; [ADR 0022](adr/0022-make-cursor-pm.md), enmendado por [ADR 0024](adr/0024-convencion-simetrica-a-c-y-listo.md) y [ADR 0025](adr/0025-despacho-cursor-trio-efimero-herdr.md)). El prompt es solo esa mención. Sin mise, el `cursor-agent` del PATH; sin ninguno, exit 127.
- **Reglas y despacho Cursor**: las reglas de rol (`.cursor/rules/{pm,pm-trio,wk,rv,os}-<slug>.mdc`) van con `alwaysApply: false` y sin `description`, así Cursor no las mete solas; Cursor carga las skills de `.agents/skills/` (no hay `.cursor/skills/`). No se generan subagentes in-chat en `.cursor/agents/`: `pm-<slug>.mdc` es el PM Orquestador y despacha tríos efímeros en `herdr` con `pj-trio --kind cursor` (donde corre `pm-trio-<slug>.mdc`, `wk-<slug>.mdc` y `rv-<slug>.mdc`, o `os-<slug>.mdc` en `--oneshot`). Cursor IDE queda fuera de alcance como orquestador de tríos ([ADR 0025](adr/0025-despacho-cursor-trio-efimero-herdr.md)).

## Prueba de humo
`scripts/humo.py` (parte de `check`, y `./pj humo` / `make humo`):
- Estático, siempre (también en CI, donde no hay agy): cada ficha PM/WK/RV existe, tiene `name`, `tools` y las secciones obligatorias, manda a leer `comun.md` y su regla, sus skills existen en `.agents/skills/<s>/SKILL.md`, toda ruta `.agents/…` o `.cursor/…` citada en fichas y adaptadores de Cursor existe, las cuatro reglas de rol son `alwaysApply: false` y sin `description`, `plantillas/hijo/pj` contiene `--yolo`, `--trust` y `@.cursor/rules/`, y el PM marca el primer trabajo.
- Con agy (`make humo` / `./pj humo`, después de `./pj listo` o `./pj enlazar`): corre `agy --agent PM-<proyecto> --print …` sin interacción y exige que responda con su nombre tras leer sus reglas. Sin agy en el PATH avisa y queda solo lo estático.

## CI
- `pj-template.yml` del hijo (lo manda `plantillas/hijo/`): en PR y push corre `./pj check`; a diario, a mano o cuando pj-template avisa, llama a `pj-sync`.
- `pj-sync.yml` (reutilizable, vive solo acá, lógica en `scripts/ci-sync.sh`):
  - hijo en modo dependencia: sube `template_ref` al último `main` de pj-template, actualiza `./pj` y el caller, corre `./pj check` y abre un PR `pj-template/sync-<run>` (cierra los viejos);
  - pj-template: sincroniza skills desde `robert-flo/skills@personal` por PR;
  - hijo viejo (modo copia, sin `template_ref`): copia `template-paths.txt`, skills y regenera, por PR.
- `notify-children.yml` (solo acá): al cambiar algo del template en `main`, avisa a cada hijo de `family.yml`.
- `vigilar-hijos.yml` (solo acá, diario y a mano): hijos sin registrar o sin secreto, y **deriva** (`scripts/deriva.sh`, también `make deriva`): regenera cada hijo con el template actual y muestra en el resumen del run el % de archivos idénticos y qué cambia. Si hay problemas o deriva > 0, abre o actualiza el issue «hijos sin registrar o sin secret».
- `check.yml` (acá): `scripts/check.sh` en cada PR; además de lo del hijo, arma un hijo de prueba en modo dependencia y verifica que `generar` rechace `#` sin comillas, dos `primero`, `orden` no entero, notas o nombre del molde, fichas sobrantes y falta de `template_ref`.

### Secreto
`PJ_TEMPLATE_TOKEN`, en pj-template y en cada hijo: PAT fine-grained de `robert-flo` con acceso a pj-template y a los hijos, permisos *Contents: read and write*, *Pull requests: read and write* y *Workflows: read and write* (el PR de sync puede tocar el caller). Hace falta porque pj-template es privado (`./pj` lo baja en CI), para disparar `repository_dispatch` en los hijos y para que el PR de sync dispare CI (con `GITHUB_TOKEN` no lo hace).

El workflow del hijo (`plantillas/hijo/pj-template.yml`) corre el sync en línea, con los mismos pasos que `pj-sync.yml` (`scripts/ci-sync.sh` y `scripts/ci-pr.sh`): un hijo público no puede llamar workflows de un repo privado. Además, pj-template tiene que permitir que otros repos de `robert-flo` usen sus workflows (Settings → Actions → General → Access: «Accessible from repositories owned by the user»).

## Trío en herdr (`pj-trio`)

Cada meta-repo hijo tiene `.trio/` (con `.gitkeep` y `README.md`) para los handoffs del trío, que se commitean. Se lanza con `pj-trio <proyecto> <ticket> --repo <miembro> [--kind <agy|cursor>]` (por defecto `agy`; `--kind cursor` para el orquestador en Cursor CLI, [ADR 0025](adr/0025-despacho-cursor-trio-efimero-herdr.md)), que viene del paquete `ravn-trio` de `[omarchy-personal]` (`/usr/bin/pj-trio`). La fuente de verdad de cómo corre el trío (pestañas, arranque del PM, handoffs y worktrees del WK) es [robert-flo/ravn-trio](https://github.com/robert-flo/ravn-trio); acá no se duplica. Si algo choca, mandan `.agents/reglas/` y los ADR [0018](adr/0018-el-merge-es-el-de-fleet.md) (quién mergea qué, la regla de fleet) y [0027](adr/0027-topologia-centralizada-ravn-wt.md) (worktrees con `ravn-wt` en la raíz central `/z-home-repos`), y se corrige ravn-trio. [ravn-trio#23](https://github.com/robert-flo/ravn-trio/pull/23) alinea `trio-pm-prompt.md` con esa regla. Ver [ADR 0016](adr/0016-el-trio-en-herdr-vive-en-ravn-trio.md).

## Empaquetado Arch (`*-arch`) y canal `[omarchy-personal]`

El aprovisionamiento de secretos (`SSH_DEPLOY_KEY`, `GPG_PRIVATE_KEY`, `GPG_PASSPHRASE`) y el ciclo de publicación de paquetes Arch en `omarchy-personal-repo` están detallados en [docs/runbook-secrets-empaquetado-arch.md](runbook-secrets-empaquetado-arch.md).
