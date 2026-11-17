#!/usr/bin/env python3
"""./pj onboard — la entrevista de onboarding del trío (ADR 0017). Idempotente.

Mismo orden que el alta de un PM que ya funcionaba: primero junta los hechos solo (proyecto.yml,
README.md, AGENTS.md, los repos que esos archivos nombran y lo que cada repo tiene: Makefile, stack),
después propone cada campo con una respuesta recomendada (Enter la acepta), muestra el resumen y
escribe solo con tu sí. Escribe onboarding.yml (y `repos:` de proyecto.yml) y regenera las fichas.

  ./pj onboard                 primera vez: la entrevista. Ya hecho: muestra los datos y pregunta
                               «¿querés cambiar algo? [n/campo]»; n o Enter no toca nada.
  ./pj onboard --mostrar       solo imprime los datos (o «sin hacer»).
  ./pj onboard --si            sin preguntas: acepta todas las recomendaciones.
  ./pj onboard --respuestas F  sin preguntas: toma las respuestas de F (YAML con cualquiera de los campos
                               de onboarding.yml más `repos`); lo que falte, la recomendación.
  --rehacer                    con --si o --respuestas: rehace aunque ya esté hecho.
Sin terminal y sin --si/--respuestas: si ya está hecho lo muestra y sale con 0; si no, explica y sale con 1.
PJ_HOY=AAAA-MM-DD fija la fecha (pruebas).
"""
import argparse, datetime, json, os, pathlib, re, shutil, subprocess, sys
import yaml

TPL = pathlib.Path(__file__).resolve().parent.parent
RAIZ = pathlib.Path(os.environ.get("PJ_RAIZ") or TPL).resolve()
sys.path.insert(0, str(TPL / "scripts"))
import onboarding as ob  # noqa: E402
import proyecto as proyecto_mod  # noqa: E402

CAMPOS = [  # (clave, título, tipo)
    ("repos", "repos que supervisa el trío", "repos"),
    ("mision", "misión del proyecto (qué es y para qué está el trío)", "texto"),
    ("no_tocar", "lo que el trío no toca nunca", "lista"),
    ("reglas_proyecto", "reglas propias del proyecto", "lista"),
    ("primeros_pasos", "primeros pasos del PM (el primero va en su primer mensaje)", "lista"),
    ("wk.como_probar", "cómo prueba el WK en este proyecto", "lista"),
    ("rv.exige", "lo que exige el RV en este proyecto", "lista"),
]
ALIAS = {"repos": "repos", "mision": "mision", "misión": "mision", "no_tocar": "no_tocar", "notocar": "no_tocar",
         "reglas": "reglas_proyecto", "reglas_proyecto": "reglas_proyecto", "pasos": "primeros_pasos",
         "primeros_pasos": "primeros_pasos", "probar": "wk.como_probar", "como_probar": "wk.como_probar",
         "wk": "wk.como_probar", "exige": "rv.exige", "rv": "rv.exige", "todo": "todo"}


def hoy():
    return os.environ.get("PJ_HOY") or datetime.date.today().isoformat()


def leer(f):
    try:
        return (RAIZ / f).read_text()
    except OSError:
        return ""


NO_EXISTE = re.compile(r"Could not resolve to a Repository|HTTP 404|Not Found", re.I)


def gh(*args, timeout=20, err=None):
    """stdout de `gh …`, o None si gh no está, falla o tarda (PJ_SIN_GH=1 lo apaga: pruebas, CI)."""
    if not shutil.which("gh") or os.environ.get("PJ_SIN_GH"):
        return None
    try:
        r = subprocess.run(["gh", *args], capture_output=True, text=True, timeout=timeout)
    except (subprocess.TimeoutExpired, OSError):
        return None
    if r.returncode and err is not None:
        err.append(r.stderr)
    return r.stdout if r.returncode == 0 else None


def limpio(t):
    t = re.sub(r"\*\*|__", "", t)
    t = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", t)
    return re.sub(r"\s+", " ", t).strip()


# --- hechos ---------------------------------------------------------------------------
def repos_nombrados(p):
    """Repos de GitHub que README.md y AGENTS.md del meta-repo nombran, con su nota, verificados con gh."""
    vistos, out = set(), []
    yo = {p["proyecto"].lower(), "pj-template"}
    for f in ("AGENTS.md", "README.md"):
        for l in leer(f).splitlines():
            for dueno, nombre in re.findall(r"github\.com/([A-Za-z0-9-]+)/([A-Za-z0-9._-]+?)(?:\.git)?(?=[\s)`'\"#/]|$)", l):
                repo = f"{dueno}/{nombre}"
                if nombre.lower() in yo or repo.lower() in vistos:
                    continue
                vistos.add(repo.lower())
                nota = limpio(re.sub(r"^\s*(?:[-*]|\d+\.)\s*", "", l).split(":")[0])
                out.append({"dir": nombre, "repo": repo, "rama": None, "nota": nota[:160] or None})
    return out


def completar_repo(r, p):
    """Rama por defecto con gh; None si gh dice que el repo no existe."""
    r = dict(r)
    if not r.get("rama"):
        err = []
        js = gh("repo", "view", r["repo"], "--json", "defaultBranchRef", err=err)
        if js is None and err and NO_EXISTE.search(err[0]):
            return None  # gh dice que no existe; si gh falla por otra cosa (sin red, sin login) sigue con la rama base
        r["rama"] = (json.loads(js)["defaultBranchRef"]["name"] if js else None) or p["rama_base"]
    r["dir"] = r.get("dir") or r["repo"].split("/", 1)[1]
    return {k: v for k, v in r.items() if v}


def archivos_de(r):
    """Nombres en la raíz del repo y objetivos del Makefile: del clon si está, si no de GitHub."""
    d = RAIZ / r["dir"]
    if (d / ".git").exists():
        nombres = [x.name for x in d.iterdir()]
        mk = (d / "Makefile").read_text() if (d / "Makefile").exists() else ""
        return nombres, mk
    js = gh("api", f"repos/{r['repo']}/contents?ref={r['rama']}", "--jq", ".[].name")
    if js is None:
        return None, ""  # ni clon ni gh: no se puede leer el stack
    mk = gh("api", f"repos/{r['repo']}/contents/Makefile?ref={r['rama']}", "-H", "Accept: application/vnd.github.raw") if "Makefile" in nombres else ""
    return nombres, mk or ""


def stack(nombres, mk, donde):
    probar, exige = [], []
    objetivos = re.findall(r"^([A-Za-z][A-Za-z0-9_-]*):(?!=)", mk, flags=re.M)
    utiles = [t for t in dict.fromkeys(objetivos) if t in ("check", "test", "verify", "lint", "audit") or t.startswith("test")]
    if utiles:
        probar.append(f"en {donde}: " + ", ".join(f"`make {t}`" for t in utiles[:3]) + " en verde, con la salida pegada en el PR")
    if any(n.startswith(".chezmoi") for n in nombres):
        probar.append(f"en {donde}: `chezmoi diff` sin sorpresas antes de `chezmoi apply`, y aplicado de verdad en la máquina")
    if "package.json" in nombres:
        probar.append(f"en {donde}: `npm test` (o el script de pruebas de package.json)")
    if "Cargo.toml" in nombres:
        probar.append(f"en {donde}: `cargo test` y `cargo clippy` sin advertencias nuevas")
    if "pyproject.toml" in nombres or "pytest.ini" in nombres:
        probar.append(f"en {donde}: `pytest` en verde")
    if any(n.endswith(".sh") or n in ("scripts", "bin") for n in nombres):
        exige.append(f"en {donde}: `shellcheck` limpio y `set -euo pipefail` en cada script que se toque")
    return probar, exige


def recomendaciones(p, actual):
    """Respuesta recomendada por campo. Si ya hay onboarding, lo actual manda."""
    readme, agents, notas = leer("README.md"), leer("AGENTS.md"), p["notas"]
    rec = {}
    # repos
    if p["repos"]:
        rec["repos"] = [dict(r) for r in p["repos"]]
    else:
        rec["repos"] = [x for x in (completar_repo(r, p) for r in repos_nombrados(p)) if x]
    # misión: la primera frase del primer párrafo del README (sin título), o el área.
    parrafo = next((b for b in re.split(r"\n\s*\n", readme) if b.strip() and not b.lstrip().startswith(("#", "```", "<"))), "")
    frase = re.split(r"(?<=[.!?])\s+", limpio(parrafo))[0] if parrafo else ""
    rec["mision"] = frase if len(frase) >= 20 else limpio(p["area"])
    # reglas y no_tocar: viñetas de las secciones de reglas de AGENTS.md; si no hay, frases de notas.
    vinetas, en_reglas = [], False
    for l in agents.splitlines():
        if l.startswith("#"):
            en_reglas = bool(re.search(r"regla|nunca|no toc|prohib", l, re.I)); continue
        m = re.match(r"^\s*(?:[-*]|\d+\.)\s+(.*)$", l)
        if en_reglas and m:
            t = limpio(m.group(1))
            if t and not t.endswith(":"):
                vinetas.append(t)
    if not vinetas:
        vinetas = [limpio(s) for s in re.split(r"(?<=[.])\s+", notas.replace("\n", " ")) if len(s.strip()) > 15][1:]
    prohibe = re.compile(r"^(nunca|no |prohib|jamás|sin )|prohibido", re.I)
    rec["no_tocar"] = [v for v in vinetas if prohibe.search(v)]
    rec["reglas_proyecto"] = [v for v in vinetas if not prohibe.search(v)]
    # primeros pasos
    if rec["repos"]:
        dirs = ", ".join(f"`{r['dir']}`" for r in rec["repos"])
        rec["primeros_pasos"] = [
            f"leer `README.md` y `AGENTS.md` de este meta-repo y de {dirs}",
            "revisar los issues abiertos de cada repo (`gh issue list`) y proponerte por cuál empezar",
        ]
    else:
        rec["primeros_pasos"] = ["leer `README.md` y `AGENTS.md` de este meta-repo",
                                 "revisar los issues abiertos (`gh issue list`) y proponerte por cuál empezar"]
    # WK y RV: según lo que hay en cada repo.
    probar, exige, sin_stack = ["en el meta-repo: `./pj check` da «todo bien»"], [], []
    for r in rec["repos"]:
        nombres, mk = archivos_de(r)
        if nombres is None:
            sin_stack.append(r["dir"]); continue
        a, b = stack(nombres, mk, f"`{r['dir']}`")
        probar += a; exige += b
    probar.append("cada criterio de aceptación con su prueba corrida de verdad en esta máquina y la salida o captura en el PR")
    if re.search(r"trailer|co-authored", notas + agents, re.I):
        exige.append("ningún commit con `Co-authored-by` ni firma o trailer de agente")
    exige.append("que lo de «cómo prueba el WK» esté corrido de verdad en el PR; si no, BLOQUEO")
    rec["wk.como_probar"], rec["rv.exige"] = probar, exige
    rec["sin_stack"] = sin_stack
    if ob.hecho(actual):  # lo ya decidido gana sobre lo recomendado
        for k, _, _ in CAMPOS[1:]:
            rec[k] = obtener(actual, k)
    return rec


# --- datos ----------------------------------------------------------------------------
def obtener(o, k):
    a, _, b = k.partition(".")
    return (o.get(a) or {}).get(b) if b else o.get(a)


def poner(o, k, v):
    a, _, b = k.partition(".")
    if b:
        o.setdefault(a, {})[b] = v
    else:
        o[a] = v


def fmt_repo(r):
    return f"`{r['dir']}` → {r['repo']} ({r['rama']})" + (f" — {r['nota']}" if r.get("nota") else "")


def aviso_stack(rec):
    if rec.get("sin_stack"):
        print(f"  aviso: sin las líneas de stack (Makefile, chezmoi, npm…) de {', '.join(rec['sin_stack'])}: no están "
              "clonados y gh no respondió. Las recomendaciones de «cómo prueba el WK» y «lo que exige el RV» quedan más "
              "pobres; para completarlas: ./pj clonar y después ./pj onboard → probar / exige.")


def resumen(o, repos, titulo):
    print(titulo)
    for k, t, tipo in CAMPOS:
        v = repos if k == "repos" else obtener(o, k)
        if tipo == "texto":
            print(f"  {t}:\n    {v or '(vacío)'}")
        else:
            print(f"  {t}:" + ("" if v else " (ninguno)"))
            for n, x in enumerate(v or [], 1):
                print(f"    {n}. {fmt_repo(x) if tipo == 'repos' else x}")


def normalizar_repos(xs, p):
    out = []
    for x in xs or []:
        r = {"repo": x} if isinstance(x, str) else dict(x)
        c = completar_repo(r, p)
        if c is None:
            sys.exit(f"onboard: {r['repo']} no existe en GitHub o gh no tiene acceso")
        out.append(c)
    return out


# --- preguntas ------------------------------------------------------------------------
def preguntar(prompt):
    try:
        return input(prompt)
    except EOFError:
        return ""


def editar(k, t, tipo, rec, p, n, total):
    print(f"\n[{n}/{total}] {t}")
    if tipo == "texto":
        print(f"  recomendada: {rec or '(vacía)'}")
        r = preguntar("  Enter acepta · o escribí la tuya > ").strip()
        return r or rec
    xs = list(rec)
    ayuda = ("Enter acepta · + dueño/repo [rama] agrega · -N quita · = deja ninguno" if tipo == "repos"
             else "Enter acepta · + texto agrega · -N quita · N texto reemplaza el N · = deja ninguno")
    while True:
        for i, x in enumerate(xs, 1):
            print(f"  {i}. {fmt_repo(x) if tipo == 'repos' else x}")
        if not xs:
            print("  (ninguno)")
        r = preguntar(f"  {ayuda} > ").strip()
        if not r:
            return xs
        if r == "=":
            xs = []
        elif r.startswith("+"):
            arg = r[1:].strip()
            if tipo == "repos":
                partes = arg.split()
                if not partes or not re.match(r"^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$", partes[0]):
                    print("  formato: + dueño/repo [rama]"); continue
                c = completar_repo({"repo": partes[0], "rama": partes[1] if len(partes) > 1 else None}, p)
                if c is None:
                    print(f"  {partes[0]} no existe en GitHub (o gh no tiene acceso)"); continue
                xs.append(c)
            elif arg:
                xs.append(arg)
        elif re.match(r"^-\d+$", r) and 1 <= int(r[1:]) <= len(xs):
            xs.pop(int(r[1:]) - 1)
        elif tipo != "repos" and re.match(r"^\d+\s+\S", r) and 1 <= int(r.split()[0]) <= len(xs):
            xs[int(r.split()[0]) - 1] = r.split(None, 1)[1]
        else:
            print("  no entendí; probá de nuevo")


# --- escribir -------------------------------------------------------------------------
def escribir(o, repos, p):
    o = dict(o, version=1, hecho=hoy())
    err = ob.validar(o)
    if err:
        sys.exit("onboard: no escribo, quedaría inválido:\n  - " + "\n  - ".join(err))
    pyml = RAIZ / "proyecto.yml"
    viejo = pyml.read_text()
    nuevo = ob.reemplazar_repos(viejo, repos) if [dict(r) for r in p["repos"]] != repos else viejo
    if nuevo != viejo:
        pyml.write_text(nuevo)
        try:
            proyecto_mod.cargar(RAIZ, RAIZ != TPL)
        except proyecto_mod.Invalido as e:
            pyml.write_text(viejo)
            sys.exit("onboard: proyecto.yml quedaría inválido, lo dejo como estaba:\n  - " + "\n  - ".join(e.args[0]))
        print("escrito proyecto.yml (repos)")
    (RAIZ / ob.ARCHIVO).write_text(ob.volcar(o, p["proyecto"]))
    print(f"escrito {ob.ARCHIVO}")
    r = subprocess.run([sys.executable, str(TPL / "scripts/generar.py")], env=dict(os.environ, PJ_RAIZ=str(RAIZ)))
    if r.returncode:
        sys.exit("onboard: generar.py falló")
    sigue = "" if os.environ.get("PJ_EN_LISTO") else f" Ahora: `./pj listo` (clona los repos y verifica) y `agy --agent PM-{p['proyecto']}` o Cursor."
    print(f"\nonboarding hecho el {o['hecho']}.{sigue}")


def main():
    ap = argparse.ArgumentParser(prog="./pj onboard", description=__doc__.split("\n")[0])
    ap.add_argument("--mostrar", action="store_true")
    ap.add_argument("--si", action="store_true")
    ap.add_argument("--respuestas")
    ap.add_argument("--rehacer", action="store_true")
    a = ap.parse_args()
    try:
        p = proyecto_mod.cargar(RAIZ, RAIZ != TPL)
    except proyecto_mod.Invalido as e:
        sys.exit("onboard: proyecto.yml no es válido:\n  - " + "\n  - ".join(e.args[0]))
    try:
        actual = ob.cargar(RAIZ) or ob.vacio()
    except ob.Invalido as e:
        sys.exit(f"onboard: {ob.ARCHIVO} no es válido:\n  - " + "\n  - ".join(e.args[0]))
    repos_act = [dict(r) for r in p["repos"]]
    proy = p["proyecto"]

    if a.mostrar:
        if ob.hecho(actual):
            resumen(actual, repos_act, f"onboarding de {proy}: hecho el {actual['hecho']}")
        else:
            print(f"onboarding de {proy}: sin hacer. Corré ./pj onboard")
        return 0

    no_interactivo = a.si or a.respuestas
    if ob.hecho(actual) and not (no_interactivo and a.rehacer):
        resumen(actual, repos_act, f"ya está hecho el {actual['hecho']}. Estos son los datos de {proy}:")
        if no_interactivo or not sys.stdin.isatty():
            print("nada cambió (para cambiar algo: ./pj onboard en una terminal, o --rehacer)")
            return 0
        campos = "/".join(["repos", "mision", "no_tocar", "reglas", "pasos", "probar", "exige", "todo"])
        r = preguntar(f"\n¿querés cambiar algo? [n/{campos}] > ").strip().lower()
        if r in ("", "n", "no"):
            print("nada cambió.")
            return 0
        clave = ALIAS.get(r)
        if not clave:
            print(f"no conozco «{r}»; nada cambió. Campos: {campos}")
            return 1
        elegidos = [c for c in CAMPOS if clave == "todo" or c[0] == clave]
    else:
        elegidos = CAMPOS
        if not no_interactivo and not sys.stdin.isatty():
            print(f"onboarding de {proy}: sin hacer. Necesita una terminal: corré ./pj onboard\n"
                  "(o ./pj onboard --si para aceptar las recomendaciones sin preguntas)")
            return 1

    print(f"Juntando los hechos de {proy} (proyecto.yml, README.md, AGENTS.md, repos nombrados y su stack)…")
    rec = recomendaciones(p, actual)
    o = {k: v for k, v in (actual if ob.hecho(actual) else ob.vacio()).items()}
    o["wk"], o["rv"] = dict(o.get("wk") or {}), dict(o.get("rv") or {})
    repos = repos_act if ob.hecho(actual) else rec["repos"]

    if no_interactivo:
        resp = {}
        if a.respuestas:
            resp = yaml.safe_load(pathlib.Path(a.respuestas).read_text()) or {}
            desconocidas = set(resp) - {"repos", "mision", "no_tocar", "reglas_proyecto", "primeros_pasos", "wk", "rv"}
            if desconocidas:
                sys.exit(f"onboard: {a.respuestas} tiene claves desconocidas: {sorted(desconocidas)}")
        if "repos" in resp:
            repos = normalizar_repos(resp["repos"], p)
            if not ob.hecho(actual):  # pasos y pruebas recomendados según los repos elegidos
                rec = recomendaciones(dict(p, repos=repos), actual)
        else:
            repos = rec["repos"]
        for k, _, _ in CAMPOS[1:]:
            v = obtener(resp, k)
            poner(o, k, v if v is not None else rec[k])
        resumen(o, repos, f"onboarding de {proy} (sin preguntas):")
        aviso_stack(rec)
        escribir(o, repos, p)
        return 0

    print("Te propongo cada campo; Enter acepta la recomendación.")
    for n, (k, t, tipo) in enumerate(elegidos, 1):
        if k == "repos":
            repos = editar(k, t, tipo, repos, p, n, len(elegidos))
            if [r["repo"] for r in repos] != [r["repo"] for r in rec["repos"]] and not ob.hecho(actual):
                rec = recomendaciones(dict(p, repos=repos), actual)  # pasos y pruebas según los repos elegidos
        else:
            poner(o, k, editar(k, t, tipo, obtener(o, k) if ob.hecho(actual) else rec[k], p, n, len(elegidos)))
    print()
    resumen(o, repos, "Resumen:")
    if not ob.hecho(actual) or any(c[0] in ("wk.como_probar", "rv.exige") for c in elegidos):
        aviso_stack(rec)
    r = preguntar("\n¿Lo escribo? [S/n] > ").strip().lower()
    if r not in ("", "s", "si", "sí", "y", "yes"):
        print("no escribí nada.")
        return 1
    escribir(o, repos, p)
    return 0


if __name__ == "__main__":
    sys.exit(main())
