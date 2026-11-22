# pj-template

La plantilla única de los tríos PM/WK/RV para Cursor y agy. Una sola copia de reglas, skills y plantillas; cada hijo versiona solo `proyecto.yml`, `onboarding.yml`, `AGENTS.md`, `README.md`, `.gitignore`, `./pj`, su `Makefile` de atajos y su workflow, y trae lo demás como dependencia al SHA de `template_ref`.

```bash
make nuevo-hijo P=foo   # crea robert-flo/pj-foo en modo dependencia (necesita PJ_TEMPLATE_TOKEN)
make check              # esquema de proyecto.yml, idempotencia, hijo de prueba y humo estático
make humo               # además arranca PM-<proyecto> con agy sin interacción (si está agy)
make deriva             # % de archivos idénticos de cada hijo frente al template actual
make generar            # fichas de agy y adaptadores de Cursor de este repo

# en un hijo
make a-pm               # abre el PM en agy al instante (--solo; a-wk, a-rv, a-os; Cursor CLI: c-pm/wk/rv/os)
make listo a-pm         # actualiza primero (git pull + ./pj listo) y abre el PM (o make listo c-pm)
./pj                    # trae pj-template@template_ref a .pj/ y genera .agents/ y .cursor/
./pj listo [--abrir]    # todo de una tras clonar: pull, template, genera, hooks, onboarding (si falta), agy, clonar, check
./pj onboard            # entrevista del PM (onboarding.yml); 2ª vez: «ya está hecho», muestra y pregunta qué cambiar
./pj clean [--onboarding]  # deshace ./pj listo para repetirlo (--onboarding: también el onboarding); idempotente
./pj hooks              # cada git pull regenera solo (lo instala ./pj listo)
./pj agy [pm|wk|rv|os] [--solo] [args…]     # atajos: make a-pm/wk/rv/os (--solo) o make listo a-pm
./pj cursor [pm|wk|rv|os] [--solo] [args…]  # atajos: make c-pm/wk/rv/os (--solo) o make listo c-pm
./pj check | humo | clonar | enlazar
```

Necesitás `python3` (con el módulo venv); PyYAML y jsonschema se instalan solos en `.pj/venv` desde `requirements.txt`, `gh`, `git` y `make`.

- Cómo crear un hijo y cambiar el template: [`AGENTS.md`](AGENTS.md).
- En Cursor CLI (`make c-pm`), el PM Orquestador despacha tríos efímeros en `herdr` con `pj-trio --kind cursor` y `.cursor/rules/pm-trio-<slug>.mdc` (sin subagentes in-chat; Cursor IDE queda fuera de alcance): [ADR 0025](docs/adr/0025-despacho-cursor-trio-efimero-herdr.md).
- Onboarding del trío (misión, no tocar, primeros pasos, cómo prueba el WK, qué exige el RV): [ADR 0017](docs/adr/0017-onboarding-del-trio.md).
- Modo dependencia, esquema, prueba de humo, workflows y el secreto `PJ_TEMPLATE_TOKEN`: [`docs/pj-template.md`](docs/pj-template.md).
- Hijos: [`family.yml`](family.yml).
