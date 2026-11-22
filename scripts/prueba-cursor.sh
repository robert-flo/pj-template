#!/usr/bin/env bash
# Prueba de ./pj cursor y make c-*/cursor-* (ADR 0022) en un hijo de prueba, sin red, con
# mise y cursor-agent de mentira. La corre check.sh en pj-template (y CI). Imprime ok/FALLA; sale con 1 si algo falla.
set -euo pipefail
T="$(cd "$(dirname "$0")/.." && pwd)"
PY="${PY:-$(bash "$T/scripts/py.sh")}"
fallas=0; ok(){ echo "ok   $*"; }; mal(){ echo "FALLA $*"; fallas=$((fallas+1)); }
trap 'echo "FALLA prueba-cursor: se cortó en la línea $LINENO"' ERR
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
PYTHONUSERBASE="$("$PY" -m site --user-base || true)"; export PYTHONUSERBASE
export HOME="$tmp/home" PJ_TEMPLATE_DIR="$T" PJ_SIN_GH=1 PY
export GIT_CONFIG_GLOBAL="$tmp/gitconfig" GIT_AUTHOR_NAME=prueba GIT_AUTHOR_EMAIL=p@x GIT_COMMITTER_NAME=prueba GIT_COMMITTER_EMAIL=p@x
mkdir -p "$HOME"; git config --file "$GIT_CONFIG_GLOBAL" init.defaultBranch master

# PATH sin mise ni cursor-agent reales. mise de mentira en $tmp/bin; cursor-agent suelto en $tmp/bin-cursor.
# Carpetas del PATH que los tienen se cambian por $tmp/herr con enlaces a todo lo demás (make, git…).
mkdir -p "$tmp/herr"
base="$(tr : '\n' <<< "$PATH" | while IFS= read -r d; do
  [ -n "$d" ] && [ -d "$d" ] || continue
  if [ -e "$d/mise" ] || [ -e "$d/cursor-agent" ]; then
    for x in "$d"/*; do case "${x##*/}" in mise|cursor-agent) ;; *) [ -x "$x" ] && [ ! -e "$tmp/herr/${x##*/}" ] && ln -s "$x" "$tmp/herr/${x##*/}" ;; esac; done
    echo "$tmp/herr"
  else echo "$d"; fi
done | awk '!v[$0]++' | paste -sd:)"
log="$tmp/log"; export PRUEBA_LOG="$log"
mkdir -p "$tmp/bin" "$tmp/bin-cursor" "$tmp/vacio"
cat > "$tmp/bin/mise" <<'M'
#!/usr/bin/env bash
# mise de mentira: anota la llamada y, en `x … -- cmd args`, lo que vería cursor-agent al arrancar.
case "$1" in
  use) echo "mise $* · MISE_MINIMUM_RELEASE_AGE=${MISE_MINIMUM_RELEASE_AGE:-}" >> "$PRUEBA_LOG" ;;
  x) while [ "$1" != -- ]; do shift; done; shift
     echo "exec $*" >> "$PRUEBA_LOG" ;;
  *) echo "mise de mentira: $*" >&2; exit 1 ;;
esac
M
printf '#!/usr/bin/env bash\necho "cursor-suelto $*" >> "$PRUEBA_LOG"\n' > "$tmp/bin-cursor/cursor-agent"
chmod +x "$tmp/bin/mise" "$tmp/bin-cursor/cursor-agent"

# Hijo de prueba con remoto (bare local), para que ./pj listo tenga algo que traer con el pull.
git init -q --bare "$tmp/hijo.git"
h="$tmp/hijo"; git clone -q "$tmp/hijo.git" "$h" 2>/dev/null; cd "$h"
mkdir -p .github/workflows
cp "$T/plantillas/hijo/pj" pj; cp "$T/plantillas/hijo/Makefile" Makefile; cp "$T/plantillas/hijo/pj-template.yml" .github/workflows/; cp "$T/plantillas/hijo/gitignore" .gitignore
cat > proyecto.yml <<'YML'
proyecto: "demo"
area: "hijo de prueba de ./pj cursor"
rama_base: "master"
template_ref: "0000000000000000000000000000000000000000"
repos: []
specs: []
notas: |
  Hijo de prueba.
YML
printf '# demo\n\nHijo de prueba de ./pj cursor.\n' > README.md; printf '# AGENTS.md — demo\n' > AGENTS.md
git add -A && git commit -qm inicial && git push -q origin HEAD:master 2>/dev/null
git clone -q "$tmp/hijo.git" "$tmp/otro" 2>/dev/null
echo "traído por el pull" >> "$tmp/otro/README.md" && git -C "$tmp/otro" add -A && git -C "$tmp/otro" commit -qm "cambio remoto" && git -C "$tmp/otro" push -q 2>/dev/null

corre(){ : > "$log"; PATH="$1:$base" bash -c "${*:2}" </dev/null >"$tmp/out" 2>&1; }

# 0) make -n / help: los ocho targets Cursor y fleet/watch intactos; pm sigue = agy.
ayuda="$(PATH="$tmp/bin:$base" make help)"
for t in c-pm c-wk c-rv c-os cursor-pm cursor-wk cursor-rv cursor-os fleet watch; do
  grep -q "^$t	" <<< "$ayuda" || grep -q "^$t " <<< "$ayuda" \
    && ok "make help lista $t" || { mal "make help no lista $t"; echo "$ayuda"; }
done
PATH="$tmp/bin:$base" make -n c-pm | grep -q './pj cursor pm --solo' \
  && ok "make -n c-pm → ./pj cursor pm --solo" || { mal "make -n c-pm"; PATH="$tmp/bin:$base" make -n c-pm; }
PATH="$tmp/bin:$base" make -n cursor-pm | grep -Eq './pj cursor pm( |$)' \
  && ! PATH="$tmp/bin:$base" make -n cursor-pm | grep -q -- '--solo' \
  && ok "make -n cursor-pm → ./pj cursor pm (sin --solo)" || { mal "make -n cursor-pm"; PATH="$tmp/bin:$base" make -n cursor-pm; }
PATH="$tmp/bin:$base" make -n c-wk | grep -q './pj cursor wk --solo' \
  && ok "make -n c-wk → ./pj cursor wk --solo" || mal "make -n c-wk"
PATH="$tmp/bin:$base" make -n cursor-os | grep -Eq './pj cursor os( |$)' \
  && ok "make -n cursor-os → ./pj cursor os" || mal "make -n cursor-os"
PATH="$tmp/bin:$base" make -n pm | grep -q './pj agy pm --solo' \
  && ok "make -n pm sigue = ./pj agy pm --solo" || mal "make -n pm cambió"
PATH="$tmp/bin:$base" make -n fleet | grep -q 'pj-trio fleet' \
  && PATH="$tmp/bin:$base" make -n watch | grep -q 'pj-trio watch' \
  && ok "make -n fleet/watch intactos" || mal "make -n fleet/watch"

# 1) make cursor-pm: pull y ./pj listo primero, después mise con la regla del PM.
if corre "$tmp/bin" make cursor-pm; then
  grep -qx "mise use -g --quiet cursor-agent · MISE_MINIMUM_RELEASE_AGE=0" "$log" \
    && ok "make cursor-pm: mise use -g --quiet cursor-agent con MISE_MINIMUM_RELEASE_AGE=0" || { mal "make cursor-pm: mise use"; cat "$log"; }
  grep -qx "exec cursor-agent --yolo --trust --workspace $h @.cursor/rules/pm-demo.mdc" "$log" \
    && ok "make cursor-pm: mise x cursor-agent --yolo --trust y @.cursor/rules/pm-demo.mdc" || { mal "make cursor-pm: exec"; cat "$log" "$tmp/out"; }
  grep -q "check: todo bien" "$tmp/out" && ok "make cursor-pm: ./pj check del hijo da todo bien" || { mal "make cursor-pm: check"; cat "$tmp/out"; }
  grep -q "traído por el pull" README.md && ok "make cursor-pm: corrió el pull de listo" || { mal "make cursor-pm: pull"; cat "$tmp/out"; }
else mal "make cursor-pm falló"; cat "$tmp/out"; fi

# 2) Los cuatro roles: el prompt es solo @.cursor/rules/<rol>-<slug>.mdc
corre "$tmp/bin" make cursor-wk && grep -qx "exec cursor-agent --yolo --trust --workspace $h @.cursor/rules/wk-demo.mdc" "$log" \
  && ok "make cursor-wk: prompt @.cursor/rules/wk-demo.mdc" || { mal "make cursor-wk"; cat "$log" "$tmp/out"; }
corre "$tmp/bin" ./pj cursor rv && grep -qx "exec cursor-agent --yolo --trust --workspace $h @.cursor/rules/rv-demo.mdc" "$log" \
  && ok "./pj cursor rv: prompt @.cursor/rules/rv-demo.mdc" || { mal "./pj cursor rv"; cat "$log"; }
corre "$tmp/bin" make cursor-os ARGS="'--print hola'" && grep -qx "exec cursor-agent --yolo --trust --workspace $h --print hola @.cursor/rules/os-demo.mdc" "$log" \
  && ok "make cursor-os ARGS=…: pasa args y prompt de OS" || { mal "make cursor-os"; cat "$log" "$tmp/out"; }

# 3) Atajos rápidos c-* / --solo: no corren pull ni listo.
echo "cambio remoto pendiente" >> "$tmp/otro/README.md" && git -C "$tmp/otro" add -A && git -C "$tmp/otro" commit -qm "remoto pendiente" && git -C "$tmp/otro" push -q 2>/dev/null
corre "$tmp/bin" make c-pm && grep -qx "exec cursor-agent --yolo --trust --workspace $h @.cursor/rules/pm-demo.mdc" "$log" \
  && ! grep -q "check: todo bien" "$tmp/out" && ! grep -q "cambio remoto pendiente" README.md \
  && ok "make c-pm: abre al instante sin pull ni listo" || { mal "make c-pm"; cat "$log" "$tmp/out"; }
corre "$tmp/bin" make c-os ARGS="'--print rápido'" && grep -qx "exec cursor-agent --yolo --trust --workspace $h --print rápido @.cursor/rules/os-demo.mdc" "$log" \
  && ! grep -q "check: todo bien" "$tmp/out" \
  && ok "make c-os ARGS=…: al instante sin listo" || { mal "make c-os"; cat "$log" "$tmp/out"; }

corre "$tmp/bin" ./pj cursor --print x && grep -qx "exec cursor-agent --yolo --trust --workspace $h --print x @.cursor/rules/pm-demo.mdc" "$log" \
  && ok "./pj cursor sin rol: PM por defecto y @.cursor/rules/pm-demo.mdc" || { mal "./pj cursor sin rol"; cat "$log"; }

# 4) Sin mise: el cursor-agent del PATH; sin ninguno: error claro, sale con 127.
corre "$tmp/bin-cursor" ./pj cursor wk && grep -qx "cursor-suelto --yolo --trust --workspace $h @.cursor/rules/wk-demo.mdc" "$log" && grep -q "no hay mise" "$tmp/out" \
  && ok "sin mise: usa el cursor-agent del PATH y avisa" || { mal "sin mise"; cat "$log" "$tmp/out"; }
if corre "$tmp/vacio" ./pj cursor; then mal "sin mise ni cursor-agent salió con 0"
else grep -q "no encuentro mise ni cursor-agent" "$tmp/out" && ok "sin mise ni cursor-agent: error claro (exit ≠ 0)" || { mal "sin mise ni cursor-agent"; cat "$tmp/out"; }; fi

# 5) Si ./pj listo falla, no abre nada.
echo basura > sobrante.txt && git add sobrante.txt && git commit -qm sobrante
if corre "$tmp/bin" ./pj cursor; then mal "./pj cursor abrió con ./pj listo fallando"
else ! grep -q '^exec' "$log" && grep -q "no abro cursor" "$tmp/out" && ok "./pj listo falla (archivo sobrante): no abre cursor" || { mal "listo falla"; cat "$log" "$tmp/out"; }; fi

[ "$fallas" -eq 0 ] || exit 1
