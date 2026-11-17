"""onboarding.yml: lo propio de cada proyecto para el PM, el WK y el RV (ADR 0017).

Lo usan generar.py (inyecta cada bloque en la ficha de su rol), check.sh y onboard.py (la entrevista).
- cargar(raiz): dict validado contra schema/onboarding.schema.json, o None si no hay archivo.
- hecho(o): True si el onboarding ya se hizo (fecha en `hecho`).
- volcar(o): el YAML que escribe onboard.py, con bytes estables (mismas respuestas = mismos bytes).
- vacio(): el estado «sin hacer» (lo que escribe `./pj clean --onboarding`).
- reemplazar_repos(texto, repos): reescribe solo el bloque `repos:` de proyecto.yml, sin tocar comentarios.
"""
import json, pathlib, re
import yaml

TPL = pathlib.Path(__file__).resolve().parent.parent
ARCHIVO = "onboarding.yml"
LISTAS = ("no_tocar", "reglas_proyecto", "primeros_pasos")


class Invalido(Exception):
    pass


def vacio():
    return {"version": 1, "hecho": "", "mision": "", "no_tocar": [], "reglas_proyecto": [],
            "primeros_pasos": [], "wk": {"como_probar": []}, "rv": {"exige": []}}


def validar(o):
    import jsonschema
    esquema = json.loads((TPL / "schema/onboarding.schema.json").read_text())
    err = []
    for e in sorted(jsonschema.Draft202012Validator(esquema).iter_errors(o), key=lambda e: list(e.absolute_path)):
        err.append(f"{'/'.join(str(x) for x in e.absolute_path) or '(raíz)'}: {e.message}")
    return err


def cargar(raiz):
    f = pathlib.Path(raiz) / ARCHIVO
    if not f.exists():
        return None
    try:
        o = yaml.safe_load(f.read_text())
    except yaml.YAMLError as e:
        raise Invalido([f"YAML inválido: {e}"])
    if not isinstance(o, dict):
        raise Invalido(["está vacío o no es un mapa; corré ./pj clean --onboarding y después ./pj onboard"])
    err = validar(o)
    if err:
        raise Invalido(err)
    o["mision"] = o["mision"].strip()
    return o


def hecho(o):
    return bool(o and o.get("hecho"))


def _s(x):
    return json.dumps(str(x).strip(), ensure_ascii=False)


def _lista(clave, xs, sangria=""):
    if not xs:
        return [f"{sangria}{clave}: []"]
    return [f"{sangria}{clave}:"] + [f"{sangria}  - {_s(x)}" for x in xs]


def volcar(o, proyecto):
    out = [f"# Onboarding del trío de {proyecto}: lo propio del proyecto que reciben PM, WK y RV en su ficha.",
           "# Lo escribe `./pj onboard` (entrevista); se puede editar a mano y correr `./pj`.",
           "# hecho vacío = onboarding sin hacer. Esquema: schema/onboarding.schema.json de pj-template.",
           "version: 1", f"hecho: {_s(o.get('hecho', ''))}", f"mision: {_s(o.get('mision', ''))}"]
    for k in LISTAS:
        out += _lista(k, o.get(k) or [])
    out += ["wk:"] + _lista("como_probar", (o.get("wk") or {}).get("como_probar") or [], "  ")
    out += ["rv:"] + _lista("exige", (o.get("rv") or {}).get("exige") or [], "  ")
    return "\n".join(out) + "\n"


# --- proyecto.yml: solo el bloque repos ---------------------------------------------------
def volcar_repos(repos):
    if not repos:
        return ["repos: []"]
    out = ["repos:"]
    for r in repos:
        out.append(f"  - dir: {_s(r['dir'])}")
        out.append(f"    repo: {_s(r['repo'])}")
        out.append(f"    rama: {_s(r['rama'])}")
        if r.get("nota"):
            out.append(f"    nota: {_s(r['nota'])}")
    return out


def reemplazar_repos(texto, repos):
    """Cambia la clave `repos:` y sus ítems (líneas con sangría o `- ` justo debajo); los comentarios
    de ejemplo que siguen y el resto del archivo quedan igual."""
    lineas = texto.splitlines()
    i = next((n for n, l in enumerate(lineas) if re.match(r"^repos:", l)), None)
    if i is None:
        raise Invalido(["proyecto.yml no tiene la clave repos:"])
    j = i + 1
    if not re.match(r"^repos:\s*\[\s*\]\s*(#.*)?$", lineas[i]):
        while j < len(lineas) and (re.match(r"^(\s+\S|- )", lineas[j])) and not lineas[j].lstrip().startswith("#"):
            j += 1
    return "\n".join(lineas[:i] + volcar_repos(repos) + lineas[j:]) + "\n"
