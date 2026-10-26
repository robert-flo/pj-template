# pj-template

La plantilla única de los tríos PM/WK/RV para Cursor y agy. Una sola copia de reglas, skills y plantillas; cada proyecto llena su `proyecto.yml` y genera lo suyo.

```bash
gh repo create robert-flo/pj-miproyecto --private --template robert-flo/pj-template --clone
cd pj-miproyecto
$EDITOR proyecto.yml    # nombre, área, rama base, repos, specs, notas
make generar            # fichas de agy y adaptadores de Cursor
make check              # idempotente y sin {{ }}
make nuevo-hijo P=foo   # crea robert-flo/pj-foo desde el template (necesita PJ_TEMPLATE_TOKEN)
./clone-repos.sh        # clona los repos del proyecto al lado
```

Necesitás `python3` con PyYAML (`sudo pacman -S python-yaml`), `gh` y `git`.

- Cómo crear un hijo y cambiar el template: [`AGENTS.md`](AGENTS.md).
- Quién manda qué, los workflows y el secreto `PJ_TEMPLATE_TOKEN`: [`docs/pj-template.md`](docs/pj-template.md).
- Hijos: [`family.yml`](family.yml).
