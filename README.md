# pj-template

La plantilla única de los tríos PM/WK/RV para Cursor y agy. Una sola copia de reglas, skills y plantillas; cada hijo versiona solo `proyecto.yml`, `AGENTS.md`, `README.md`, `.gitignore`, `./pj` y su workflow, y trae lo demás como dependencia al SHA de `template_ref`.

```bash
make nuevo-hijo P=foo   # crea robert-flo/pj-foo en modo dependencia (necesita PJ_TEMPLATE_TOKEN)
make check              # esquema de proyecto.yml, idempotencia, hijo de prueba y humo estático
make humo               # además arranca PM-<proyecto> con agy sin interacción (si está agy)
make deriva             # % de archivos idénticos de cada hijo frente al template actual
make generar            # fichas de agy y adaptadores de Cursor de este repo

# en un hijo
./pj                    # trae pj-template@template_ref a .pj/ y genera .agents/ y .cursor/
./pj listo [--abrir]    # todo de una tras clonar: pull, template, genera, hooks, agy, clonar, check
./pj hooks              # cada git pull regenera solo (lo instala ./pj listo)
./pj check | humo | clonar | agy
```

Necesitás `python3` con PyYAML y jsonschema (`sudo pacman -S python-yaml python-jsonschema`), `gh`, `git` y `make`.

- Cómo crear un hijo y cambiar el template: [`AGENTS.md`](AGENTS.md).
- Modo dependencia, esquema, prueba de humo, workflows y el secreto `PJ_TEMPLATE_TOKEN`: [`docs/pj-template.md`](docs/pj-template.md).
- Hijos: [`family.yml`](family.yml).
