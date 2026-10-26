#!/usr/bin/env bash
# Verifica que la generación sea idempotente, que no queden {{ }} y que todo cuadre.
set -euo pipefail
raiz="$(cd "$(dirname "$0")/.." && pwd)"; cd "$raiz"
fallas=0; ok(){ echo "ok   $*"; }; mal(){ echo "FALLA $*"; fallas=$((fallas+1)); }

snap(){ find . -path ./.git -prune -o -path './rf-*' -prune -o -path './fo-*' -prune -o -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum; }
python3 scripts/generar.py >/dev/null
a="$(snap)"; python3 scripts/generar.py >/dev/null; b="$(snap)"
[ "$a" = "$b" ] && ok "generar.py es idempotente" || { mal "generar.py cambió archivos en la segunda corrida"; diff <(echo "$a") <(echo "$b") || true; }

# Idempotencia también desde cero, en una copia: borrar lo generado y regenerar da lo mismo.
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
git ls-files -co --exclude-standard -z | xargs -0 -I{} cp --parents {} "$tmp" 2>/dev/null || cp -R . "$tmp"
( cd "$tmp" && xargs rm -f < .agents/generados.txt && python3 scripts/generar.py >/dev/null )
antes=$fallas
for f in $(cat .agents/generados.txt) .gitignore; do cmp -s "$f" "$tmp/$f" || mal "regenerar desde cero cambia $f"; done
[ "$fallas" -eq "$antes" ] && ok "regenerar desde cero da los mismos bytes"

if grep -rnE '\{\{|\}\}' --include='*.md' --include='*.mdc' .agents/agents .cursor .gitignore; then mal "quedan {{ }} en archivos generados"; else ok "sin {{ }} en lo generado"; fi
grep -rniE 'grok ?bot|robert-flo/fleet|fleet/bots' --exclude-dir=.git --exclude-dir='rf-*' --exclude=check.sh . && mal "hay referencias a Grok Bot o fleet" || ok "sin referencias a Grok Bot ni fleet"
[ -e .agents/grokbot.md ] && mal ".agents/grokbot.md no debe existir" || true

# Las notas del molde no pueden quedar en un hijo.
if [ "$(python3 -c 'import yaml;print(yaml.safe_load(open("proyecto.yml"))["proyecto"])')" != pj-template ] \
   && grep -qE 'Este repo es la plantilla de los meta-repos hijos|llegan a los hijos por PR' proyecto.yml; then
  mal "proyecto.yml: las notas todavía tienen el texto de pj-template"
else ok "notas de proyecto.yml propias"; fi

python3 - <<'PY' || fallas=$((fallas+1))
import json, pathlib, sys, yaml
lock = json.load(open("skills-lock.json"))["skills"]
d = pathlib.Path(".agents/skills")
en_disco = {p.name for p in d.iterdir() if p.is_dir()} if d.exists() else set()
err = []
if set(lock) != en_disco: err.append(f"lock y .agents/skills difieren: {sorted(set(lock) ^ en_disco)}")
for f in pathlib.Path(".agents/agents").glob("*.md"):
    fm = yaml.safe_load(f.read_text().split("---")[1])
    for s in fm.get("skills", []):
        if s.split("/", 1)[1] not in lock: err.append(f"{f}: skill {s} no está en el lock")
    if not fm.get("name") or not fm.get("tools"): err.append(f"{f}: frontmatter incompleto")
for e in err: print("FALLA", e)
print("ok   skills-lock, .agents/skills y fichas cuadran" if not err else "")
sys.exit(1 if err else 0)
PY
for f in scripts/*.sh clone-repos.sh; do bash -n "$f" || mal "sintaxis $f"; done; ok "sintaxis bash"
python3 -c 'import yaml,glob;[yaml.safe_load(open(f)) for f in glob.glob(".github/workflows/*.yml")+["family.yml","proyecto.yml","plantillas/roles.yml"] if __import__("os").path.exists(f)]' && ok "YAML válido" || mal "YAML inválido"

[ "$fallas" -eq 0 ] && echo "check: todo bien" || { echo "check: $fallas fallas"; exit 1; }
