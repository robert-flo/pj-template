# Cómo funciona pj-template

Este archivo lo manda `robert-flo/pj-template` y llega igual a cada hijo. No lo editás en el hijo.

## Quién manda qué
| Qué | Dónde | Quién lo escribe |
| --- | --- | --- |
| Reglas comunes y de rol | `.agents/reglas/{comun,pm,wk,rv}.md` | pj-template (llegan por PR de sync) |
| Skills | `.agents/skills/` + `skills-lock.json` | CI, desde `robert-flo/skills@personal` (engineering, productivity, in-progress) |
| Skills por rol | `plantillas/roles.yml` (+ `skills_extra` del hijo) | pj-template / el hijo |
| Fichas de agy | `.agents/agents/{PM,WK,RV}-<proyecto>.md` | `scripts/generar.py` |
| Adaptadores de Cursor | `.cursor/rules/pm-<proyecto>.mdc`, `.cursor/agents/{wk,rv}-<proyecto>.md` | `scripts/generar.py` |
| Regla sin coautor de Cursor | `.cursor/rules/no-cursor-coauthor.mdc` | pj-template |
| Datos del proyecto | `proyecto.yml` | vos, en el hijo |
| Arquitectura del proyecto | `AGENTS.md`, `README.md` | vos, en el hijo |

La lista exacta de lo que manda el template está en `template-paths.txt`. Nada generado se edita a mano: si querés cambiarlo, cambiá la plantilla (en pj-template) o `proyecto.yml` (en el hijo) y corré `make generar`.

## Motores
- **agy**: `agy --agent PM-<proyecto>` desde la raíz del meta-repo. Antes, una vez por máquina, `make agy` (enlaza las fichas en `~/.gemini/config/agents`, porque agy interactivo solo resuelve `--agent` con los agentes globales). `skills:` del frontmatter es declarativo: agy carga todas las de `.agents/skills/`.
- **Cursor**: el PM es la regla `alwaysApply`; WK y RV son subagentes en `.cursor/agents/`. Cursor carga las skills de `.agents/skills/`; no hay `.cursor/skills/`.

## CI
- `pj-sync.yml` (reutilizable, vive solo acá): trae lo de `template-paths.txt`, sincroniza skills, regenera, corre `scripts/check.sh` y abre un PR `pj-template/sync-<run>` si algo cambió (cierra los PR de sync viejos).
- `pj-template.yml` (caller, igual en todos): corre `pj-sync` a diario, a mano o cuando pj-template avisa (`repository_dispatch: pj-template-updated`).
- `notify-children.yml` (solo en pj-template): al cambiar algo del template en `main`, avisa a cada hijo de `family.yml`.
- `check.yml`: corre `scripts/check.sh` en cada PR.

### Secreto
`PJ_TEMPLATE_TOKEN`, en pj-template y en cada hijo: PAT fine-grained de `robert-flo` con acceso a pj-template y a los hijos, permisos *Contents: read and write* y *Pull requests: read and write*. Hace falta porque pj-template es privado (checkout cruzado), para disparar `repository_dispatch` en los hijos y para que el PR de sync dispare CI (con `GITHUB_TOKEN` no lo hace). `robert-flo/skills` es público y no necesita token; como no puede avisar sin un token propio, los hijos lo revisan a diario.

Además, pj-template tiene que permitir que otros repos de `robert-flo` usen sus workflows (Settings → Actions → General → Access: «Accessible from repositories owned by the user»).
