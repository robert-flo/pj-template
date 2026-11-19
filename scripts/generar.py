#!/usr/bin/env python3
"""Genera las fichas de agy y los adaptadores de Cursor desde plantillas/ y proyecto.yml.

Dos modos:
- molde: corre dentro de pj-template (PJ_RAIZ vacío o igual a este checkout).
- dependencia: corre desde .pj/tpl de un hijo con PJ_RAIZ=<raíz del hijo>. Además de las fichas
  copia al hijo las reglas, las skills y la regla de Cursor que manda el template (todo ignorado por git).

Idempotente: con la misma entrada produce los mismos bytes. Borra lo que generó antes y ya no
corresponde, usando .agents/generados.txt. Falla si quedan datos del molde en un hijo.
"""
import json, os, pathlib, re, sys
import yaml

TPL = pathlib.Path(__file__).resolve().parent.parent
RAIZ = pathlib.Path(os.environ.get("PJ_RAIZ") or TPL).resolve()
DEP = RAIZ != TPL
MANIFIESTO = RAIZ / ".agents/generados.txt"
sys.path.insert(0, str(TPL / "scripts"))
import proyecto as proyecto_mod  # noqa: E402
import onboarding as ob  # noqa: E402

# Marcadores del bloque generado de .gitignore; llevan el nombre del proyecto.
BLOQUE_RE = r"# >>> [^\n]*: repos \(generado\) >>>.*?# <<< [^\n]*: repos \(generado\) <<<"
# Lo que el template copia a un hijo en modo dependencia.
COPIAS = [".agents/reglas", ".agents/skills", ".cursor/rules/no-cursor-coauthor.mdc"]


def die(msg):
    sys.exit(f"generar: {msg}")


def cargar():
    try:
        return proyecto_mod.cargar(RAIZ, DEP)
    except proyecto_mod.Invalido as e:
        die("proyecto.yml no es válido:\n  - " + "\n  - ".join(e.args[0]))


def datos(p):
    out = ["## Tus datos", f"- Proyecto: {p['proyecto']} (área: {p['area']})"]
    if p["repos"]:
        out.append("- Repos del proyecto (clonados al lado con `./clone-repos.sh`; trabajás en el clon donde te abrieron):")
        for r in p["repos"]:
            nota = f" — {r['nota'].strip()}" if r.get("nota") else ""
            out.append(f"  - `{r['dir']}` → `{r['repo']}`, rama base `{r['rama']}`{nota}")
    else:
        out.append(f"- Repo único: este mismo meta-repo, rama base `{p['rama_base']}`.")
    if p["repos_externos"]:
        out.append("- Repos externos (referencia, clonados al lado, solo lectura):")
        for r in p["repos_externos"]:
            nota = f" — {r['nota'].strip()}" if r.get("nota") else ""
            out.append(f"  - `{r['dir']}` → `{r['repo']}`, rama `{r['rama']}`{nota}")
    out.append(f"- Rama de los PR finales: `{p['rama_base']}` (salvo que el repo que tocás diga otra arriba).")
    if p["specs"]:
        out.append("- Trabajo actual, en orden:")
        for s in p["specs"]:
            marca = " ← **primer trabajo**" if s["primero"] else ""
            out.append(f"  {s['orden']}. {s['ref']} — {s['titulo'].strip()}{marca}")
    else:
        out.append("- Trabajo actual: sin specs abiertos.")
    if p["notas"]:
        out.append("- Notas del proyecto:")
        out += [f"  {l}" if l.strip() else "" for l in p["notas"].splitlines()]
    out.append(f"- Trío: PM-{p['proyecto']}, WK-{p['proyecto']}, RV-{p['proyecto']}")
    out.append("- Roberto habla solo con el PM; el PM lanza al WK y al RV (`invoke_subagent` en agy; subagentes en Cursor).")
    return "\n".join(out)


def cargar_onboarding():
    try:
        return ob.cargar(RAIZ)
    except ob.Invalido as e:
        die("onboarding.yml no es válido:\n  - " + "\n  - ".join(e.args[0]))


def punto(t):
    t = t.strip()
    return t if t[-1:] in ".!?" else t + "."


def vinetas(xs, sangria=""):
    return "\n".join(f"{sangria}- {x}" for x in xs)


def alma(p, o):
    """Bloque «El proyecto» que reciben las tres fichas (ADR 0017)."""
    if not ob.hecho(o):
        out = ("## El proyecto\n- Onboarding: **sin hacer**. Faltan la misión, lo que no tocás, los primeros pasos, "
               "cómo prueba el WK y lo que exige el RV; Roberto los completa con `./pj onboard` en la terminal del meta-repo.")
    else:
        out = [f"## El proyecto (onboarding del {o['hecho']}, `onboarding.yml`)", f"- Misión: {punto(o['mision'])}"]
        if o["no_tocar"]:
            out += ["- Lo que no tocás nunca:", vinetas(o["no_tocar"], "  ")]
        if o["reglas_proyecto"]:
            out += ["- Reglas del proyecto (mandan sobre tu criterio; `AGENTS.md` manda en la arquitectura):",
                    vinetas(o["reglas_proyecto"], "  ")]
        out = "\n".join(out)
    # Reglas duras de los repos de terceros: las fija el template, no el onboarding.
    if p["repos_externos"]:
        out += "\n- Repos externos de referencia (solo lectura):"
        for r in p["repos_externos"]:
            out += f"\n  - Nunca empujar a `{r['repo']}`. Nunca abrir PRs hacia upstream `{r['repo']}`."
    return out


GENERICOS = ["Identificá el repo donde cae el pedido y su rama base (lista de arriba).",
             "Si hay specs en curso, seguí con ellos en el orden de la lista antes de abrir trabajo nuevo.",
             "Las notas y las reglas del proyecto de arriba mandan sobre tu criterio; `AGENTS.md` manda en la arquitectura."]


def primeros_pasos(o):
    pasos = [punto(x[:1].upper() + x[1:]) for x in (o["primeros_pasos"] if ob.hecho(o) else [])] + GENERICOS
    return "\n".join(f"{n}. {x}" for n, x in enumerate(pasos, 1))


def repos_txt(p):
    if not p["repos"]:
        return "Trabajo sobre este mismo repo."
    return "Superviso " + ", ".join(f"`{r['repo']}`" for r in p["repos"]) + "."


def primer_mensaje(p, o):
    proy = p["proyecto"]
    if ob.hecho(o):
        paso = o["primeros_pasos"][0].strip().rstrip(".")
        paso = paso[:1].lower() + paso[1:]
        mision, falta = f" Mi misión acá: {punto(o['mision'])}", "[FALTA]"
    else:
        paso, mision = "leer `README.md` y `AGENTS.md` de este meta-repo", ""
        falta = "Falta el onboarding del proyecto: corré `./pj onboard` en la terminal del meta-repo y volvé a abrirme."
    return (f"> Hola Roberto, soy PM-{proy}, el PM de {p['area'].strip()} en {proy}. Convierto lo que me pedís en specs y "
            f"tickets `ready-for-agent` con el flujo de Matt, sigo cada spec hasta su PR final a `{p['rama_base']}` y lo "
            f"mergeo yo cuando el RV publica `APRUEBO` sobre el head exacto.{mision} {repos_txt(p)}\n>\n"
            f"> Para arrancar, voy a {paso} y a leer el repo para aprender las buenas prácticas de su stack y seguirlas "
            f"en cada spec. {falta}")


def bloque_rol(o, rol, clave, titulo):
    """Viñetas del onboarding para la sección de un rol, o vacío si no hay onboarding."""
    xs = ((o or {}).get(rol) or {}).get(clave) if ob.hecho(o) else None
    return f"{titulo}\n{vinetas(xs)}\n\n" if xs else ""


def primer_trabajo(p):
    s = next((s for s in p["specs"] if s["primero"]), None)
    if not s:
        return "Sin specs abiertos: esperá el pedido de Roberto."
    return f"Empezá por **{s['ref']}** ({s['titulo'].strip()}); después seguí el orden de la lista."


def render(plantilla, vals):
    t = (TPL / plantilla).read_text()
    for k, v in vals.items():
        t = t.replace("{{" + k + "}}", v)
    resto = re.findall(r"\{\{[^}]*\}\}", t)
    if resto:
        die(f"{plantilla}: marcadores sin reemplazar {sorted(set(resto))}")
    return (t if t.endswith("\n") else t + "\n").encode()


def copias():
    """Archivos que el template copia tal cual al hijo: ruta -> (bytes, modo)."""
    out = {}
    for c in COPIAS:
        src = TPL / c
        files = [src] if src.is_file() else sorted(x for x in src.rglob("*") if x.is_file())
        for x in files:
            out[str(x.relative_to(TPL))] = (x.read_bytes(), 0o755 if os.access(x, os.X_OK) else 0o644)
    return out


def main():
    p = cargar()
    roles = yaml.safe_load((TPL / "plantillas/roles.yml").read_text())
    lockf = TPL / "skills-lock.json"
    lock = json.loads(lockf.read_text())["skills"] if lockf.exists() else {}
    proy, slug = p["proyecto"], p["proyecto"].lower()
    o = cargar_onboarding()
    base = {"proyecto": proy, "slug": slug, "datos": datos(p), "primer_trabajo": primer_trabajo(p),
            "tools_yaml": "\n".join(f"  - {t}" for t in roles["tools"]),
            "alma": alma(p, o), "primeros_pasos": primeros_pasos(o), "primer_mensaje": primer_mensaje(p, o),
            "como_probar": bloque_rol(o, "wk", "como_probar", "Cómo probás en este proyecto (onboarding):"),
            "exige": bloque_rol(o, "rv", "exige", "En este proyecto exigís (onboarding):"),
            "mision_corta": punto(o["mision"]) if ob.hecho(o) else "onboarding sin hacer (`./pj onboard`)."}
    salida = {}
    for rol in ("pm", "wk", "rv", "os"):
        skills = list(dict.fromkeys(roles["skills"][rol] + (p["skills_extra"].get(rol) or [])))
        faltan = [s for s in skills if lock and s not in lock]
        if faltan:
            die(f"skills de {rol} que no están en skills-lock.json: {faltan}")
        v = dict(base, skills_yaml="\n".join(f"  - skills/{s}" for s in skills),
                 skills_inline=", ".join(f"`{s}`" for s in skills))
        salida[f".agents/agents/{rol.upper()}-{proy}.md"] = (render(f"plantillas/agents/{rol.upper()}.md", v), 0o644)
    salida[f".cursor/rules/pm-{slug}.mdc"] = (render("plantillas/cursor/pm.mdc", base), 0o644)
    for rol in ("wk", "rv", "os"):
        salida[f".cursor/agents/{rol}-{slug}.md"] = (render(f"plantillas/cursor/{rol}.md", base), 0o644)
    if DEP:
        salida.update(copias())

    viejos = MANIFIESTO.read_text().split() if MANIFIESTO.exists() else []
    for v in viejos:
        if v not in salida and (RAIZ / v).exists():
            (RAIZ / v).unlink()
            print(f"borrado {v}")
    # Fichas del molde que no salen del manifiesto (por ejemplo, copiadas a mano o de un template viejo).
    if proy != "pj-template":
        sobras = [str(x.relative_to(RAIZ)) for d in (".agents/agents", ".cursor/agents", ".cursor/rules")
                  for x in (RAIZ / d).glob("*pj-template*") if x.is_file()]
        if sobras:
            die(f"quedan fichas del molde pj-template: {sobras}; borralas (git rm) y volvé a correr")
    for ruta, (txt, modo) in salida.items():
        f = RAIZ / ruta
        f.parent.mkdir(parents=True, exist_ok=True)
        if not f.exists() or f.read_bytes() != txt:
            f.write_bytes(txt)
            if not DEP or not ruta.startswith(".agents/skills/"):
                print(f"escrito {ruta}")
        if (f.stat().st_mode & 0o777) != modo:
            f.chmod(modo)
    MANIFIESTO.parent.mkdir(parents=True, exist_ok=True)
    nuevo = "".join(f"{r}\n" for r in sorted(salida))
    if not MANIFIESTO.exists() or MANIFIESTO.read_text() != nuevo:
        MANIFIESTO.write_text(nuevo)

    # Bloque de .gitignore: carpetas de repos hijos y, en modo dependencia, todo lo que trae el template.
    gi = RAIZ / ".gitignore"
    txt = gi.read_text() if gi.exists() else ""
    INICIO, FIN = f"# >>> {proy}: repos (generado) >>>", f"# <<< {proy}: repos (generado) <<<"
    extra = ["/.pj/", "/.agents/", "/.cursor/", "/.bares/", "/repos/"] if DEP else []
    bloque = "\n".join([INICIO, "/.pj-sync/"] + extra + [f"/{r['dir']}/" for r in p["repos"]] + [f"/{r['dir']}/" for r in p["repos_externos"]] + [FIN])
    if re.search(BLOQUE_RE, txt, flags=re.S):
        txt = re.sub(BLOQUE_RE, lambda _: bloque, txt, count=1, flags=re.S)
    else:
        txt = txt.rstrip("\n") + ("\n\n" if txt else "") + bloque + "\n"
    if not gi.exists() or gi.read_text() != txt:
        gi.write_text(txt)
        print("escrito .gitignore")


if __name__ == "__main__":
    main()
