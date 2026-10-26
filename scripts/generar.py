#!/usr/bin/env python3
"""Genera las fichas de agy y los adaptadores de Cursor desde plantillas/ y proyecto.yml.

Idempotente: con la misma entrada produce los mismos bytes. Borra lo que generó antes
y ya no corresponde (por ejemplo, al renombrar el proyecto), usando .agents/generados.txt.
"""
import json, pathlib, re, sys
import yaml

RAIZ = pathlib.Path(__file__).resolve().parent.parent
MANIFIESTO = RAIZ / ".agents/generados.txt"
INICIO, FIN = "# >>> pj-template: repos (generado) >>>", "# <<< pj-template: repos (generado) <<<"


def die(msg):
    sys.exit(f"generar: {msg}")


def cargar():
    p = yaml.safe_load((RAIZ / "proyecto.yml").read_text()) or {}
    for k in ("proyecto", "area", "rama_base"):
        if not p.get(k):
            die(f"proyecto.yml: falta `{k}`")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", p["proyecto"]):
        die("proyecto.yml: `proyecto` solo admite letras, números, punto, guion y guion bajo")
    p.setdefault("repos", [])
    p["repos"] = p["repos"] or []
    for r in p["repos"]:
        for k in ("dir", "repo", "rama"):
            if not r.get(k):
                die(f"proyecto.yml: un repo no tiene `{k}`: {r}")
    p["specs"] = p.get("specs") or []
    p["notas"] = (p.get("notas") or "").strip()
    p["skills_extra"] = p.get("skills_extra") or {}
    return p


def datos(p):
    out = ["## Tus datos", f"- Proyecto: {p['proyecto']} (área: {p['area']})"]
    if p["repos"]:
        out.append("- Repos del proyecto (clonados al lado con `./clone-repos.sh`; trabajás en el clon donde te abrieron):")
        for r in p["repos"]:
            nota = f" — {r['nota'].strip()}" if r.get("nota") else ""
            out.append(f"  - `{r['dir']}` → `{r['repo']}`, rama base `{r['rama']}`{nota}")
    else:
        out.append(f"- Repo único: este mismo meta-repo, rama base `{p['rama_base']}`.")
    out.append(f"- Rama de los PR finales: `{p['rama_base']}` (salvo que el repo que tocás diga otra arriba).")
    if p["specs"]:
        out.append("- Trabajo actual:")
        for s in p["specs"]:
            if isinstance(s, dict):
                out.append(f"  - {s.get('ref', '')} — {s.get('titulo', '').strip()}".rstrip(" —"))
            else:
                out.append(f"  - {s}")
    else:
        out.append("- Trabajo actual: sin specs abiertos.")
    if p["notas"]:
        out.append("- Notas del proyecto:")
        out += [f"  {l}" if l.strip() else "" for l in p["notas"].splitlines()]
    out.append(f"- Trío: PM-{p['proyecto']}, WK-{p['proyecto']}, RV-{p['proyecto']}")
    out.append("- Roberto habla solo con el PM; el PM lanza al WK y al RV (`invoke_subagent` en agy; subagentes en Cursor).")
    return "\n".join(out)


def render(plantilla, vals):
    t = (RAIZ / plantilla).read_text()
    for k, v in vals.items():
        t = t.replace("{{" + k + "}}", v)
    resto = re.findall(r"\{\{[^}]*\}\}", t)
    if resto:
        die(f"{plantilla}: marcadores sin reemplazar {sorted(set(resto))}")
    return t if t.endswith("\n") else t + "\n"


def main():
    p = cargar()
    roles = yaml.safe_load((RAIZ / "plantillas/roles.yml").read_text())
    lock = json.loads((RAIZ / "skills-lock.json").read_text())["skills"] if (RAIZ / "skills-lock.json").exists() else {}
    proy, slug = p["proyecto"], p["proyecto"].lower()
    base = {"proyecto": proy, "slug": slug, "datos": datos(p),
            "tools_yaml": "\n".join(f"  - {t}" for t in roles["tools"])}
    salida = {}
    for rol in ("pm", "wk", "rv"):
        skills = list(dict.fromkeys(roles["skills"][rol] + (p["skills_extra"].get(rol) or [])))
        faltan = [s for s in skills if lock and s not in lock]
        if faltan:
            die(f"skills de {rol} que no están en skills-lock.json: {faltan}")
        v = dict(base, skills_yaml="\n".join(f"  - skills/{s}" for s in skills),
                 skills_inline=", ".join(f"`{s}`" for s in skills))
        salida[f".agents/agents/{rol.upper()}-{proy}.md"] = render(f"plantillas/agents/{rol.upper()}.md", v)
    salida[f".cursor/rules/pm-{slug}.mdc"] = render("plantillas/cursor/pm.mdc", base)
    for rol in ("wk", "rv"):
        salida[f".cursor/agents/{rol}-{slug}.md"] = render(f"plantillas/cursor/{rol}.md", base)

    viejos = MANIFIESTO.read_text().split() if MANIFIESTO.exists() else []
    for v in viejos:
        if v not in salida and (RAIZ / v).exists():
            (RAIZ / v).unlink()
            print(f"borrado {v}")
    for ruta, txt in salida.items():
        f = RAIZ / ruta
        f.parent.mkdir(parents=True, exist_ok=True)
        if not f.exists() or f.read_text() != txt:
            f.write_text(txt)
            print(f"escrito {ruta}")
    MANIFIESTO.write_text("".join(f"{r}\n" for r in sorted(salida)))

    # Bloque de .gitignore con las carpetas de los repos hijos.
    gi = RAIZ / ".gitignore"
    txt = gi.read_text() if gi.exists() else ""
    bloque = "\n".join([INICIO, "/.pj-sync/"] + [f"/{r['dir']}/" for r in p["repos"]] + [FIN])
    if INICIO in txt:
        txt = re.sub(re.escape(INICIO) + r".*?" + re.escape(FIN), lambda _: bloque, txt, flags=re.S)
    else:
        txt = txt.rstrip("\n") + ("\n\n" if txt else "") + bloque + "\n"
    if not gi.exists() or gi.read_text() != txt:
        gi.write_text(txt)
        print("escrito .gitignore")


if __name__ == "__main__":
    main()
