"""Carga y valida proyecto.yml contra schema/proyecto.schema.json (lo usan generar.py y check.sh).

Además del esquema revisa lo que un esquema no ve:
- un `#` sin comillas en un valor de texto (YAML lo toma como comentario y corta el valor);
- `orden` repetido en specs;
- datos del molde que quedaron en un hijo (nombre pj-template, notas de pj-template).
"""
import json, pathlib, re
import yaml

TPL = pathlib.Path(__file__).resolve().parent.parent
NOTAS_MOLDE = ("Este repo es la plantilla de los meta-repos hijos", "llegan a los hijos por PR")
# Claves de texto libre donde un " #" sin comillas corta el valor sin avisar.
TEXTO = ("area", "titulo", "nota", "ref")


class Invalido(Exception):
    pass


def _comentarios_que_cortan(texto):
    err = []
    for n, l in enumerate(texto.splitlines(), 1):
        m = re.match(r"^\s*(?:-\s+)?(%s):\s*(.*)$" % "|".join(TEXTO), l)
        if not m or m.group(2)[:1] in ('"', "'", "|", ">", ""):
            continue
        if re.search(r"\s#", m.group(2)):
            err.append(f"línea {n}: `{m.group(1)}` tiene un # sin comillas y YAML corta el valor ahí; ponelo entre comillas")
    return err


def cargar(raiz, dependencia):
    """dependencia=True: hijo en modo dependencia (pj-template vive en .pj/tpl)."""
    f = pathlib.Path(raiz) / "proyecto.yml"
    texto = f.read_text()
    p = yaml.safe_load(texto) or {}
    err = _comentarios_que_cortan(texto)
    try:
        import jsonschema
    except ImportError:
        raise Invalido(["falta el módulo jsonschema (corré con el python de .pj/venv: bash scripts/py.sh)"])
    esquema = json.loads((TPL / "schema/proyecto.schema.json").read_text())
    v = jsonschema.Draft202012Validator(esquema)
    for e in sorted(v.iter_errors(p), key=lambda e: list(e.absolute_path)):
        donde = "/".join(str(x) for x in e.absolute_path) or "(raíz)"
        err.append(f"{donde}: {e.message}")
    specs = p.get("specs") if isinstance(p.get("specs"), list) else []
    ordenes = [s.get("orden") for s in specs if isinstance(s, dict)]
    if len(ordenes) != len(set(ordenes)):
        err.append("specs: hay `orden` repetidos")
    if dependencia or p.get("proyecto") != "pj-template":
        if p.get("proyecto") == "pj-template":
            err.append("proyecto: sigue llamándose pj-template; poné el nombre del hijo")
        if any(t in (p.get("notas") or "") for t in NOTAS_MOLDE):
            err.append("notas: todavía tienen el texto de pj-template; escribí las del proyecto")
        if dependencia and not p.get("template_ref"):
            err.append("template_ref: falta el SHA de pj-template que usa este hijo")
    if err:
        raise Invalido(err)
    p["repos"] = p.get("repos") or []
    p["specs"] = sorted(specs, key=lambda s: s["orden"])
    p["notas"] = (p.get("notas") or "").strip()
    p["skills_extra"] = p.get("skills_extra") or {}
    p["extras"] = p.get("extras") or []
    return p


if __name__ == "__main__":
    import os, sys
    raiz = pathlib.Path(os.environ.get("PJ_RAIZ") or TPL).resolve()
    try:
        cargar(raiz, raiz != TPL)
    except Invalido as e:
        for x in e.args[0]:
            print(f"FALLA proyecto.yml: {x}")
        sys.exit(1)
    print("ok   proyecto.yml cumple schema/proyecto.schema.json")
