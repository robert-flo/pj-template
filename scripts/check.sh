#!/usr/bin/env bash
# Verifica proyecto.yml (esquema), idempotencia, que no queden {{ }}, skills y la prueba de humo.
# En pj-template: make check. En un hijo en modo dependencia: ./pj check (PJ_RAIZ = el hijo).
set -euo pipefail
T="$(cd "$(dirname "$0")/.." && pwd)"; R="$(cd "${PJ_RAIZ:-$T}" && pwd)"; export PJ_RAIZ="$R"
DEP=0; [ "$R" != "$T" ] && DEP=1
cd "$R"
PY="${PY:-$(bash "$T/scripts/py.sh")}"; export PY
fallas=0; ok(){ echo "ok   $*"; }; mal(){ echo "FALLA $*"; fallas=$((fallas+1)); }
gen(){ "$PY" "$T/scripts/generar.py"; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

"$PY" "$T/scripts/proyecto.py" || fallas=$((fallas+1))
# onboarding.yml (ADR 0017): si falta o está sin hacer, aviso (los hijos viejos lo reciben con ./pj onboard);
# si existe y no cumple el esquema, falla.
"$PY" - "$T" <<'PY' || fallas=$((fallas+1))
import sys; sys.path.insert(0, sys.argv[1] + "/scripts")
import onboarding as ob
try:
    o = ob.cargar(".")
except ob.Invalido as e:
    for x in e.args[0]: print(f"FALLA onboarding.yml: {x}")
    sys.exit(1)
if o is None: print("aviso onboarding.yml no existe: el PM arranca sin alma; corré ./pj onboard")
elif not ob.hecho(o): print("aviso onboarding sin hacer (hecho vacío): corré ./pj onboard")
else: print(f"ok   onboarding.yml cumple schema/onboarding.schema.json (hecho el {o['hecho']})")
PY

snap(){ find . -path ./.git -prune -o -path ./.pj -prune -o -path ./.pj-sync -prune -o -path './rf-*' -prune -o -path './fo-*' -prune -o -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum; }
gen >/dev/null || { mal "generar.py falló"; echo "check: $fallas fallas"; exit 1; }
a="$(snap)"; gen >/dev/null; b="$(snap)"
[ "$a" = "$b" ] && ok "generar.py es idempotente" || { mal "generar.py cambió archivos en la segunda corrida"; diff <(echo "$a") <(echo "$b") || true; }

# Desde cero, en una copia: solo lo versionado + generar da los mismos bytes.
git ls-files -co --exclude-standard -z | xargs -0 -I{} cp --parents {} "$tmp/" 2>/dev/null || true
if [ "$DEP" = 1 ]; then rm -rf "$tmp/.agents" "$tmp/.cursor"; else xargs -I{} rm -f "$tmp/{}" < .agents/generados.txt; fi
if [ "$DEP" = 1 ]; then g="$T/scripts/generar.py"; else g="$tmp/scripts/generar.py"; fi
( cd "$tmp" && PJ_RAIZ="$tmp" "$PY" "$g" >/dev/null ) || mal "generar desde cero falló"
antes=$fallas
for f in $(cat .agents/generados.txt) .gitignore; do cmp -s "$f" "$tmp/$f" || mal "regenerar desde cero cambia $f"; done
[ "$fallas" -eq "$antes" ] && ok "regenerar desde cero da los mismos bytes"
rm -rf "${tmp:?}"/* "$tmp"/.[!.]* 2>/dev/null || true

if grep -rnE '\{\{|\}\}' --include='*.md' --include='*.mdc' .agents/agents .cursor .gitignore; then mal "quedan {{ }} en archivos generados"; else ok "sin {{ }} en lo generado"; fi
# extras: archivos a mano propios del hijo (proyecto.yml), que el check conserva y no revisa.
extras="$("$PY" -c 'import sys,yaml;[print(x) for x in (yaml.safe_load(open("proyecto.yml")) or {}).get("extras") or []]' 2>/dev/null || true)"
excl=(); while IFS= read -r x; do [ -n "$x" ] && excl+=(":!$x"); done <<< "$extras"
# Las líneas de extras: en proyecto.yml nombran esos archivos y tampoco cuentan.
sin_extras(){ local l x; while IFS= read -r l; do
  for x in $extras; do [[ "$l" =~ ^proyecto\.yml:[0-9]+:[[:space:]]*-[[:space:]]*[\"\']?"$x"[\"\']?[[:space:]]*$ ]] && continue 2; done; echo "$l"; done; }
refs="$(git grep -nIiE 'grok ?bot|robert-flo/fleet|fleet/bots' -- . ':!scripts/check.sh' ':!docs/adr-antigravity' "${excl[@]}" | sin_extras || true)"
[ -n "$refs" ] && echo "$refs" && mal "hay referencias a Grok Bot o fleet" || ok "sin referencias a Grok Bot ni fleet"
if [ -e .agents/grokbot.md ] && ! grep -qxF .agents/grokbot.md <<< "$extras"; then mal ".agents/grokbot.md no debe existir (salvo que esté en extras de proyecto.yml)"; fi

if [ "$DEP" = 1 ]; then
  # El hijo versiona solo sus archivos a mano (más .trio/, los handoffs de pj-trio); todo lo demás viene de pj-template.
  permitidos=$'.github/workflows/pj-template.yml\n.gitignore\nAGENTS.md\nMakefile\nREADME.md\nonboarding.yml\npj\nproyecto.yml'
  [ -n "$extras" ] && permitidos+=$'\n'"$extras"
  for x in $extras; do git ls-files --error-unmatch "$x" >/dev/null 2>&1 || mal "extras: $x no está versionado"; done
  extra="$({ git ls-files | grep -v '^\.trio/' || true; } | LC_ALL=C sort | LC_ALL=C comm -23 - <(echo "$permitidos" | LC_ALL=C sort))"
  [ -z "$extra" ] && ok "el hijo versiona solo $(git ls-files | wc -l) archivos a mano" || mal "archivos versionados que deberían venir de pj-template: $(echo $extra)"
  for f in $(cat .agents/generados.txt); do git ls-files --error-unmatch "$f" >/dev/null 2>&1 && mal "$f es generado y no debe versionarse"; done
  for f in pj:pj Makefile:Makefile .github/workflows/pj-template.yml:pj-template.yml; do
    cmp -s "${f%%:*}" "$T/plantillas/hijo/${f##*:}" && ok "${f%%:*} igual al de pj-template" || mal "${f%%:*} difiere de plantillas/hijo/${f##*:} de pj-template"
  done
  [ -x pj ] || mal "pj no es ejecutable"
else
  # Pruebas del molde: un hijo de mentira en modo dependencia y casos que generar tiene que rechazar.
  h="$tmp/hijo"; mkdir -p "$h/.github/workflows"
  cp "$T/plantillas/hijo/pj" "$h/pj"; cp "$T/plantillas/hijo/Makefile" "$h/Makefile"; cp "$T/plantillas/hijo/pj-template.yml" "$h/.github/workflows/"; cp "$T/plantillas/hijo/gitignore" "$h/.gitignore"
  cat > "$h/proyecto.yml" <<'YML'
proyecto: "demo"
area: "hijo de prueba del check"
rama_base: "main"
template_ref: "0000000000000000000000000000000000000000"
repos: []
specs:
  - ref: "robert-flo/demo#2"
    titulo: "segundo"
    orden: 2
    primero: false
  - ref: "robert-flo/demo#1"
    titulo: "uno (#1 primero)"
    orden: 1
    primero: true
notas: |
  Hijo de prueba.
extras:
  - ".agents/grokbot.md"
YML
  if PJ_RAIZ="$h" "$PY" "$T/scripts/generar.py" >/dev/null && PJ_RAIZ="$h" "$PY" "$T/scripts/humo.py" >/dev/null; then
    grep -q '1. robert-flo/demo#1 — uno (#1 primero) ← \*\*primer trabajo\*\*' "$h/.agents/agents/PM-demo.md" \
      && [ "$(grep -n 'demo#1 —' "$h/.agents/agents/PM-demo.md" | cut -d: -f1)" -lt "$(grep -n 'demo#2 —' "$h/.agents/agents/PM-demo.md" | cut -d: -f1)" ] \
      && ok "modo dependencia: hijo de prueba genera, ordena specs y marca el primer trabajo" || mal "modo dependencia: specs mal ordenados o sin primer trabajo"
  else mal "modo dependencia: el hijo de prueba no genera o no pasa humo"; fi
  rechaza(){ # $1 descripción, $2 sed sobre proyecto.yml o comando
    cp "$h/proyecto.yml" "$h/p.bak"; eval "$2"
    if PJ_RAIZ="$h" "$PY" "$T/scripts/generar.py" >/dev/null 2>&1; then mal "generar aceptó: $1"; else ok "generar rechaza: $1"; fi
    mv "$h/p.bak" "$h/proyecto.yml"; rm -f "$h/.agents/agents/PM-pj-template.md"
  }
  rechaza "# sin comillas en un título" "sed -i 's|titulo: \"segundo\"|titulo: segundo #2|' '$h/proyecto.yml'"
  rechaza "ref cortada por un # sin comillas" "sed -i 's|ref: \"robert-flo/demo#2\"|ref: robert-flo/demo #2|' '$h/proyecto.yml'"
  rechaza "dos specs con primero: true" "sed -i 's|primero: false|primero: true|' '$h/proyecto.yml'"
  rechaza "orden que no es entero" "sed -i 's|orden: 2|orden: \"2\"|' '$h/proyecto.yml'"
  rechaza "notas de pj-template en un hijo" "sed -i 's|Hijo de prueba.|Este repo es la plantilla de los meta-repos hijos|' '$h/proyecto.yml'"
  rechaza "hijo llamado pj-template" "sed -i 's|^proyecto: \"demo\"|proyecto: \"pj-template\"|' '$h/proyecto.yml'"
  rechaza "ficha sobrante del molde" "cp '$T/.agents/agents/PM-pj-template.md' '$h/.agents/agents/'"
  rechaza "extras que pisa un archivo del hijo" "sed -i 's|\".agents/grokbot.md\"|\"pj\"|' '$h/proyecto.yml'"
  rechaza "extras con .." "sed -i 's|\".agents/grokbot.md\"|\"../x\"|' '$h/proyecto.yml'"
  rechaza "sin template_ref" "sed -i '/^template_ref/d' '$h/proyecto.yml'"
  rechaza "onboarding hecho sin misión" "printf 'version: 1\nhecho: \"2026-01-01\"\nmision: \"\"\nno_tocar: []\nreglas_proyecto: []\nprimeros_pasos: [a]\nwk: {como_probar: [a]}\nrv: {exige: [a]}\n' > '$h/onboarding.yml'"
  rechaza "onboarding con clave desconocida" "printf 'version: 1\nhecho: \"\"\nmision: \"\"\nno_tocar: []\nreglas_proyecto: []\nprimeros_pasos: []\nwk: {como_probar: []}\nrv: {exige: []}\nalma: x\n' > '$h/onboarding.yml'"
  rm -f "$h/onboarding.yml"
  # Onboarding, ./pj onboard y ./pj clean de punta a punta en un hijo de prueba (sin red).
  bash "$T/scripts/prueba-onboarding.sh" || fallas=$((fallas+1))
  # ./pj agy y make a-* / make listo a-pm (ADR 0020) con mise y agy de mentira.
  bash "$T/scripts/prueba-agy.sh" || fallas=$((fallas+1))
  # ./pj cursor y make c-* / make listo c-pm (ADR 0022) con cursor-agent de mentira.
  bash "$T/scripts/prueba-cursor.sh" || fallas=$((fallas+1))
  # --dry-run / --no-clonar en clone-repos.sh, ./pj clonar y ./pj listo (incluyendo worktree).
  bash "$T/scripts/prueba-clonar-dry-run.sh" || fallas=$((fallas+1))
fi

"$PY" - "$T" <<'PY' || fallas=$((fallas+1))
import json, pathlib, sys, yaml
lock = json.load(open(pathlib.Path(sys.argv[1]) / "skills-lock.json"))["skills"]
d = pathlib.Path(".agents/skills")
en_disco = {p.name for p in d.iterdir() if p.is_dir()} if d.exists() else set()
err = []
if set(lock) != en_disco: err.append(f"lock y .agents/skills difieren: {sorted(set(lock) ^ en_disco)}")
for f in pathlib.Path(".agents/agents").glob("*.md"):
    fm = yaml.safe_load(f.read_text().split("---")[1])
    for s in fm.get("skills", []):
        if s.split("/", 1)[1] not in lock: err.append(f"{f}: skill {s} no está en el lock")
    if not fm.get("name") or not fm.get("tools"): err.append(f"{f}: frontmatter incompleto")
# Ruta de descubrimiento: agy y Cursor leen <raíz>/.agents/skills/<nombre>/SKILL.md y no muestran al
# modelo las que traen disable-model-invocation: true. Cada skill requerida (roles + skills_extra +
# fichas) tiene que estar ahí, con name igual a la carpeta y visible para el modelo.
roles = yaml.safe_load((pathlib.Path(sys.argv[1]) / "plantillas/roles.yml").read_text())["skills"]
req = {s for v in roles.values() for s in v}
py = pathlib.Path("proyecto.yml")
if py.exists():
    extra = (yaml.safe_load(py.read_text()) or {}).get("skills_extra") or {}
    req |= {s for v in extra.values() for s in (v or [])}
for f in pathlib.Path(".agents/agents").glob("*.md"):
    req |= {s.split("/", 1)[1] for s in yaml.safe_load(f.read_text().split("---")[1]).get("skills", [])}
for s in sorted(req):
    sk = d / s / "SKILL.md"
    if not sk.exists(): err.append(f"skill requerida {s} falta en .agents/skills/{s}/SKILL.md (agy y Cursor no la ven)"); continue
    fm = yaml.safe_load(sk.read_text().split("---")[1]) or {}
    if fm.get("name") != s: err.append(f"{sk}: name {fm.get('name')!r} distinto de la carpeta")
    if fm.get("disable-model-invocation") is True: err.append(f"{sk}: disable-model-invocation: true la esconde del modelo en agy y Cursor")
for e in err: print("FALLA", e)
print(f"ok   skills-lock, .agents/skills y fichas cuadran; {len(req)} skills requeridas visibles para agy y Cursor" if not err else "")
sys.exit(1 if err else 0)
PY
"$PY" "$T/scripts/humo.py" || fallas=$((fallas+1))
for f in "$T"/scripts/*.sh "$T"/clone-repos.sh "$T"/plantillas/hijo/pj; do bash -n "$f" || mal "sintaxis $f"; done; ok "sintaxis bash"
"$PY" -c 'import yaml,glob,os;[yaml.safe_load(open(f)) for f in glob.glob(".github/workflows/*.yml")+["family.yml","proyecto.yml"] if os.path.exists(f)]' && ok "YAML válido" || mal "YAML inválido"

[ "$fallas" -eq 0 ] && echo "check: todo bien" || { echo "check: $fallas fallas"; exit 1; }
