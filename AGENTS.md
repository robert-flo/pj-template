# AGENTS.md — pj-template

Plantilla única de los tríos PM/WK/RV de Roberto para **Cursor** y **agy** (Antigravity). Si sos un agente trabajando en este repo, leé esto y `docs/pj-template.md`. Las decisiones están en `docs/adr/` y los términos en `GLOSSARY.md`.

## Qué es
- Un meta-repo por proyecto, con un solo trío. Este repo es el molde: reglas, plantillas, scripts y workflows. Los hijos están en `family.yml`.
- Las reglas (`.agents/reglas/`) son las de pj-ravn, la versión más estricta (identidad de git, `pull --rebase --autostash`, nunca `--force`, merge con `--match-head-commit`).
- Solo Cursor y agy: otras plataformas de bots quedan fuera de este template y no se tocan desde acá.
- Lo que va en este repo se lee en `docs/pj-template.md` («Quién manda qué»). Los archivos generados no se tocan a mano.

## Cómo crear un hijo
Un hijo nuevo va en **modo dependencia**: versiona 6 archivos (`proyecto.yml`, `AGENTS.md`, `README.md`, `.gitignore`, `./pj`, `.github/workflows/pj-template.yml`) y trae todo lo demás de este repo al SHA de `template_ref`. Archivos propios a conservar (p. ej. un adaptador propio en `.agents/`) van en `extras:` de `proyecto.yml`. Detalle y por qué no se versiona lo generado: `docs/pj-template.md`.

1. Desde pj-template, con `PJ_TEMPLATE_TOKEN` exportado: `make nuevo-hijo P=<nombre> [DIR=<carpeta>]`. Crea `robert-flo/pj-<nombre>` vacío y privado (si no existe), lo clona en `/z-drive/tries/rf-pj-<nombre>` o en `./`, escribe los 6 archivos con `template_ref` = `main` actual, corre `./pj` y `./pj check`, pushea, carga el secreto y abre el PR de `family.yml`.
2. Completá `area`, `repos`, `specs` y `notas` de `proyecto.yml` y la arquitectura en `AGENTS.md` y `README.md`. `./pj` falla si quedan datos del molde.
3. `./pj check` tiene que pasar. Commit y push (o PR).
4. `./pj clonar` clona los repos de `proyecto.yml` al lado.
5. agy: `./pj agy` una vez por máquina y `agy --agent PM-<proyecto>`. Cursor: abrí la carpeta y hablá con el PM. `./pj humo` confirma que el PM arranca y lee sus reglas.

Después de cada `git clone` de un hijo, un solo comando: `./pj listo` (pull, trae el template, genera, instala los hooks, enlaza las fichas en agy, clona los repos, corre check e imprime `agy --agent PM-<proyecto>`; con `--abrir` lo arranca). Instala los hooks `post-merge` y `post-checkout` (`./pj hooks`), así que cada `git pull` posterior regenera solo. `./pj` a secas sigue regenerando sin más.

Hijos viejos (creados con «Use this template», modo copia): se migran por PR dejando solo los 6 archivos, agregando `template_ref` y llevando `specs` al formato nuevo (ejemplo: `robert-flo/pj-ravn`). Mientras tanto siguen recibiendo PR de sync en modo copia.

Vigilancia: `vigilar-hijos.yml` (diario, solo en pj-template) compara los hijos con `family.yml`, revisa el secreto y mide la deriva de cada hijo frente al template actual. Si falta algo o hay deriva abre el issue «hijos sin registrar o sin secret»; si todo está bien lo cierra.

## Cómo cambiar el template
- Reglas, plantillas, scripts o workflows: PR a este repo. Al mergear a `main`, `notify-children.yml` avisa a los hijos y cada uno recibe su PR de sync.
- Skills: no se editan acá. Cambialas en `robert-flo/skills` (rama `personal`); el sync diario las trae por PR.
- Antes de cada PR: `make check` (esquema, idempotencia, hijo de prueba en modo dependencia y prueba de humo) y, si tenés agy, `make humo`.
- `make deriva` muestra cuánto se desvió cada hijo de `family.yml` del template actual.

## Git
Identidad `Roberto Flores <25asab015@ujmd.edu.sv>`, `git pull --rebase --autostash` antes de empujar, nunca `--force`, todo por PR con squash y `--match-head-commit`.
