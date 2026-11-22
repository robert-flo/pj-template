#!/usr/bin/env python3
"""Prueba de humo del trío: ¿el PM/WK/RV arranca y encuentra sus reglas y skills?

Estático (siempre, también en CI):
- cada ficha de agy (.agents/agents/{PM,WK,RV}-<p>.md) existe, su frontmatter tiene name/tools/skills
  correctos y las secciones obligatorias;
- cada skill del frontmatter existe en .agents/skills/<s>/SKILL.md;
- toda ruta `.agents/...` o `.cursor/...` citada en fichas y adaptadores de Cursor existe;
- las cuatro reglas de rol en Cursor (pm/wk/rv/os) son alwaysApply false y no tienen description;
- plantillas/hijo/pj lanza cursor-agent con --yolo, --trust y la mención @.cursor/rules/;
- los subagentes wk/rv/os tienen el name que lanza el PM;
- si hay specs, la ficha del PM marca el primer trabajo.
- cada ficha manda a cargar logs.md, comun.md y su rol; la del PM trae su primer mensaje armado y, con
  onboarding hecho (ADR 0017), las tres fichas llevan la misión y cada rol su bloque (pasos, pruebas, exige).
Con HUMO_AGY=1 y `agy` en el PATH (make humo / ./pj humo): abre PM-<p> con «hola» (`agy --print`, sin
interacción) y exige el primer mensaje: autochequeo, log de §Lo primero, «soy PM-<p>» y, con onboarding,
la misión y el primer paso. Sin agy, lo avisa y sigue.
"""
import os, pathlib, re, shutil, subprocess, sys
import yaml

TPL = pathlib.Path(__file__).resolve().parent.parent
RAIZ = pathlib.Path(os.environ.get("PJ_RAIZ") or TPL).resolve()
sys.path.insert(0, str(TPL / "scripts"))
import proyecto as proyecto_mod  # noqa: E402
import onboarding as ob  # noqa: E402

SECCIONES = {"PM": ["## Cargás", "## Tus datos", "## El proyecto", "## Primeros pasos", "## Primer mensaje", "## Tus skills"],
             "WK": ["## Cargás", "## Tus datos", "## El proyecto", "## Al empezar", "## Tus skills"],
             "RV": ["## Cargás", "## Tus datos", "## El proyecto", "## Lo que exigís en este proyecto", "## Tus skills"],
             "OS": ["## Cargás", "## Tus datos", "## El proyecto", "## Al empezar", "## Tus skills"]}
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
o = ob.cargar(RAIZ)
ALMA = {"PM": ["primeros_pasos"], "WK": ["wk.como_probar"], "RV": ["rv.exige"], "OS": ["wk.como_probar"]}
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
    if ob.hecho(o):
        if o["mision"].strip()[:40] not in cuerpo: err.append(f"{f.name}: no trae la misión del onboarding")
        for k in ALMA[rol]:
            a, _, b = k.partition(".")
            xs = (o[a][b] if b else o[a]) or []
            if xs and xs[0].strip()[1:30] not in cuerpo: err.append(f"{f.name}: no trae {k} del onboarding")
    elif "Onboarding: **sin hacer**" not in cuerpo:
        err.append(f"{f.name}: sin onboarding y no lo dice")
    if rol == "PM" and f"Hola Roberto, soy PM-{proy}" not in cuerpo: err.append(f"{f.name}: sin primer mensaje armado")
    if f"[log: arranque · cargué .agents/agents/{rol}-{proy}.md ✔" not in cuerpo: err.append(f"{f.name}: sin la línea de autochequeo")
    for r in (".agents/reglas/logs.md", ".agents/reglas/comun.md", f".agents/reglas/{rol.lower()}.md"):
        if f"`{r}`" not in cuerpo: err.append(f"{f.name}: no manda a leer {r}")
    rutas(f, cuerpo)
    if rol == "PM" and p["specs"]:
        prim = next(s for s in p["specs"] if s["primero"])
        if "primer trabajo" not in cuerpo or prim["ref"] not in cuerpo:
            err.append(f"{f.name}: no marca el primer trabajo ({prim['ref']})")

pj_hijo = (TPL / "plantillas/hijo/pj").read_text()
for frag in ("--yolo", "--trust", "@.cursor/rules/"):
    if frag not in pj_hijo:
        err.append(f"plantillas/hijo/pj: falta {frag}")
for rol in ("pm", "wk", "rv", "os"):
    mdc = RAIZ / f".cursor/rules/{rol}-{slug}.mdc"
    if not mdc.exists():
        err.append(f"falta {mdc.relative_to(RAIZ)}"); continue
    fm, cuerpo = frontmatter(mdc)
    if fm.get("alwaysApply") is not False: err.append(f"{mdc.name}: alwaysApply no es false")
    if "description" in fm: err.append(f"{mdc.name}: tiene description")
    if rol == "pm":
        # ADR 0023 / HR-CLAVIS#73: default Cursor→Cursor + override + atajos c-*/cursor-*
        for frag in ("make c-pm", "make cursor-pm", "pj-trio", "Override", ".cursor/agents/"):
            if frag not in cuerpo:
                err.append(f"{mdc.name}: falta despacho Cursor→Cursor («{frag}»; ADR 0023)")
        if "no** `pj-trio`" not in cuerpo and "no** pj-trio" not in cuerpo and "**no** `pj-trio`" not in cuerpo:
            err.append(f"{mdc.name}: no deja claro que el default NO es pj-trio→agy")
    rutas(mdc, cuerpo)
for rol in ("wk", "rv", "os"):
    f = RAIZ / f".cursor/agents/{rol}-{slug}.md"
    if not f.exists(): err.append(f"falta {f.relative_to(RAIZ)}"); continue
    fm, cuerpo = frontmatter(f)
    if fm.get("name") != f"{rol}-{slug}": err.append(f"{f.name}: name={fm.get('name')!r}")
    rutas(f, cuerpo)
for r in ("logs", "comun", "pm", "wk", "rv", "os"):
    if not (RAIZ / f".agents/reglas/{r}.md").exists(): err.append(f"falta .agents/reglas/{r}.md")

for e in err: print("FALLA humo:", e)
if err: sys.exit(1)
print(f"ok   humo estático: PM/WK/RV/OS-{proy} encuentran reglas, skills y adaptadores de Cursor")

if os.environ.get("HUMO_AGY") == "1":
    agy = shutil.which("agy")
    if not agy:
        print("aviso humo: agy no está en el PATH; solo corrió la parte estática"); sys.exit(0)
    pedido = os.environ.get("HUMO_PEDIDO", "hola")
    try:
        r = subprocess.run([agy, "--agent", f"PM-{proy}", "--print", pedido, "--print-timeout", "300s"],
                           cwd=RAIZ, capture_output=True, text=True, timeout=360)
        out = (r.stdout + r.stderr).strip()
    except subprocess.TimeoutExpired:
        out, r = "(timeout)", None
    print("agy dijo:\n" + out[-2500:])
    espera = ["[log: arranque · cargué", "pm.md §Lo primero", f"soy PM-{proy}"]
    if ob.hecho(o):
        espera += [o["mision"].strip()[:40], o["primeros_pasos"][0].strip()[1:30]]
    else:
        espera += ["./pj onboard"]
    faltan = [e for e in espera if e.lower() not in out.lower()]
    if r is None or r.returncode != 0 or faltan:
        print(f"FALLA humo agy: el primer mensaje de PM-{proy} no trae {faltan} (¿./pj listo? ¿agy logueado?)")
        sys.exit(1)
    print(f"ok   humo agy: PM-{proy} abrió con autochequeo, §Lo primero y su primer mensaje")
