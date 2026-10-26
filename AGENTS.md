# AGENTS.md — pj-template

Plantilla única de los tríos PM/WK/RV de Roberto para **Cursor** y **agy** (Antigravity). Si sos un agente trabajando en este repo, leé esto y `docs/pj-template.md`.

## Qué es
- Un meta-repo por proyecto, con un solo trío. Este repo es el molde: reglas, plantillas, scripts y workflows. Los hijos están en `family.yml`.
- Las reglas (`.agents/reglas/`) son las de pj-ravn, la versión más estricta (identidad de git, `pull --rebase --autostash`, nunca `--force`, merge con `--match-head-commit`).
- Solo Cursor y agy: otras plataformas de bots quedan fuera de este template y no se tocan desde acá.
- Lo que va en este repo se lee en `docs/pj-template.md` («Quién manda qué»). Los archivos generados no se tocan a mano.

## Cómo crear un hijo
1. En GitHub: **Use this template** → nuevo repo privado `robert-flo/pj-<proyecto>` (o `gh repo create robert-flo/pj-<proyecto> --private --template robert-flo/pj-template`).
2. Clonalo y llená `proyecto.yml`: `proyecto`, `area`, `rama_base`, `repos` (vacío si es un proyecto de un solo repo), `specs` y `notas`.
3. Corré `make generar`. Borra las fichas de `pj-template` y escribe las de tu proyecto: `.agents/agents/{PM,WK,RV}-<proyecto>.md`, `.cursor/rules/pm-<proyecto>.mdc`, `.cursor/agents/{wk,rv}-<proyecto>.md` y el bloque de repos del `.gitignore`.
4. Reescribí `AGENTS.md` y `README.md` con la arquitectura del proyecto (son del hijo).
5. `make check` tiene que pasar. Commit y push.
6. `./clone-repos.sh` (o `make clonar`) clona los repos de `proyecto.yml` al lado.
7. Agregá `robert-flo/pj-<proyecto>` a `family.yml` de pj-template (por PR) y creá el secreto `PJ_TEMPLATE_TOKEN` en el hijo.

Atajo: desde pj-template, con `PJ_TEMPLATE_TOKEN` exportado, `make nuevo-hijo P=<nombre> [DIR=<carpeta>]` hace los pasos 1 a 7 (crea el repo desde el template si no existe, lo clona en `/z-drive/tries/rf-pj-<nombre>` o en `./`, llena `proyecto.yml`, corre `make generar` y `make check`, pushea, carga el secreto y abre el PR de `family.yml`). Después completá `area` y `notas`: `make check` falla si las notas siguen con el texto de pj-template.

Vigilancia: `vigilar-hijos.yml` (diario, solo en pj-template) compara los repos creados desde el template con `family.yml` y revisa el secreto de cada hijo. Si falta algo abre el issue «hijos sin registrar o sin secret»; si todo está bien lo cierra. Los de `family.yml` que no salieron del template aparecen como pendientes de migrar, sin fallar.
8. agy: `make agy` una vez por máquina y `agy --agent PM-<proyecto>`. Cursor: abrí la carpeta y hablá con el PM.

## Cómo cambiar el template
- Reglas, plantillas, scripts o workflows: PR a este repo. Al mergear a `main`, `notify-children.yml` avisa a los hijos y cada uno recibe su PR de sync.
- Skills: no se editan acá. Cambialas en `robert-flo/skills` (rama `personal`); el sync diario las trae por PR.
- Antes de cada PR: `make check`.

## Git
Identidad `Roberto Flores <25asab015@ujmd.edu.sv>`, `git pull --rebase --autostash` antes de empujar, nunca `--force`, todo por PR con squash y `--match-head-commit`.
