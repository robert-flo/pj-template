#!/usr/bin/env python3
"""Prueba de humo del trío: ¿el PM/WK/RV arranca y encuentra sus reglas y skills?

Estático (siempre, también en CI):
- cada ficha de agy (.agents/agents/{PM,WK,RV}-<p>.md) existe, su frontmatter tiene name/tools/skills
  correctos y las secciones obligatorias;
- cada skill del frontmatter existe en .agents/skills/<s>/SKILL.md;
- toda ruta `.agents/...` o `.cursor/...` citada en fichas y adaptadores de Cursor existe;
- la regla del PM en Cursor es alwaysApply y los subagentes wk/rv tienen el name que lanza el PM;
- si hay specs, la ficha del PM marca el primer trabajo.
Con HUMO_AGY=1 y `agy` en el PATH (make humo): corre `agy --agent PM-<p> --print` sin interacción
y exige que responda con el marcador de la primera línea de su regla. Sin agy, lo avisa y sigue.
"""
import os, pathlib, re, shutil, subprocess, sys
import yaml

TPL = pathlib.Path(__file__).resolve().parent.parent
RAIZ = pathlib.Path(os.environ.get("PJ_RAIZ") or TPL).resolve()
sys.path.insert(0, str(TPL / "scripts"))
import proyecto as proyecto_mod  # noqa: E402

SECCIONES = {"PM": ["## Tus datos", "## Primeros pasos", "## Tus skills"],
             "WK": ["## Tus datos", "## Al empezar", "## Tus skills"],
             "RV": ["## Tus datos", "## Tus skills"]}
RUTA = re.compile(r"`(\.(?:agents|cursor)/[^`*<>{} ]+)`")
err = []


def frontmatter(f):
    t = f.read_text()
    if not t.startswith("---\n"):
        err.append(f"{f.relative_to(RAIZ)}: sin frontmatter"); return {}, t
    _, fm, cuerpo = t.split("---", 2)
    return yaml.safe_load(fm) or {}, cuerpo


def rutas(f, cuerpo):
    for r in RUTA.findall(cuerpo):
        if not (RAIZ / r.rstrip("/")).exists():
            err.append(f"{f.relative_to(RAIZ)}: cita `{r}` y no existe")


p = proyecto_mod.cargar(RAIZ, RAIZ != TPL)
proy, slug = p["proyecto"], p["proyecto"].lower()
for rol, secs in SECCIONES.items():
    f = RAIZ / f".agents/agents/{rol}-{proy}.md"
    if not f.exists():
        err.append(f"falta {f.relative_to(RAIZ)}"); continue
    fm, cuerpo = frontmatter(f)
    if fm.get("name") != f"{rol}-{proy}": err.append(f"{f.name}: name={fm.get('name')!r}")
    if not fm.get("tools"): err.append(f"{f.name}: sin tools")
    if rol == "PM" and fm.get("mainAgent") is not True: err.append(f"{f.name}: el PM no es mainAgent")
    for s in fm.get("skills") or []:
        if not (RAIZ / ".agents" / s / "SKILL.md").exists(): err.append(f"{f.name}: skill {s} sin .agents/{s}/SKILL.md")
    for s in secs:
        if s not in cuerpo: err.append(f"{f.name}: falta la sección «{s}»")
    for r in (".agents/reglas/comun.md", f".agents/reglas/{rol.lower()}.md"):
        if f"`{r}`" not in cuerpo: err.append(f"{f.name}: no manda a leer {r}")
    rutas(f, cuerpo)
    if rol == "PM" and p["specs"]:
        prim = next(s for s in p["specs"] if s["primero"])
        if "primer trabajo" not in cuerpo or prim["ref"] not in cuerpo:
            err.append(f"{f.name}: no marca el primer trabajo ({prim['ref']})")

mdc = RAIZ / f".cursor/rules/pm-{slug}.mdc"
if not mdc.exists(): err.append(f"falta {mdc.relative_to(RAIZ)}")
else:
    fm, cuerpo = frontmatter(mdc)
    if fm.get("alwaysApply") is not True: err.append(f"{mdc.name}: no es alwaysApply")
    rutas(mdc, cuerpo)
for rol in ("wk", "rv"):
    f = RAIZ / f".cursor/agents/{rol}-{slug}.md"
    if not f.exists(): err.append(f"falta {f.relative_to(RAIZ)}"); continue
    fm, cuerpo = frontmatter(f)
    if fm.get("name") != f"{rol}-{slug}": err.append(f"{f.name}: name={fm.get('name')!r}")
    rutas(f, cuerpo)
for r in ("comun", "pm", "wk", "rv"):
    if not (RAIZ / f".agents/reglas/{r}.md").exists(): err.append(f"falta .agents/reglas/{r}.md")

for e in err: print("FALLA humo:", e)
if err: sys.exit(1)
print(f"ok   humo estático: PM/WK/RV-{proy} encuentran reglas, skills y adaptadores de Cursor")

if os.environ.get("HUMO_AGY") == "1":
    agy = shutil.which("agy")
    if not agy:
        print("aviso humo: agy no está en el PATH; solo corrió la parte estática"); sys.exit(0)
    pedido = ("Prueba de humo. Leé .agents/reglas/pm.md y respondé SOLO con tu nombre de agente "
              "y la ruta de la primera regla que leíste, en una línea.")
    try:
        r = subprocess.run([agy, "--agent", f"PM-{proy}", "--print", pedido, "--print-timeout", "240s"],
                           cwd=RAIZ, capture_output=True, text=True, timeout=300)
        out = (r.stdout + r.stderr).strip()
    except subprocess.TimeoutExpired:
        out, r = "(timeout)", None
    print("agy dijo:", out[-400:])
    if r is None or r.returncode != 0 or f"pm-{slug}" not in out.lower():
        print(f"FALLA humo agy: PM-{proy} no respondió con su nombre (¿corriste `./pj agy` / `make agy`? ¿agy logueado?)")
        sys.exit(1)
    print(f"ok   humo agy: PM-{proy} arrancó y respondió")
