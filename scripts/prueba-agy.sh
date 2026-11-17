#!/usr/bin/env bash
# Prueba de ./pj agy y make agy-pm/agy-wk/agy-rv (ADR 0020) en un hijo de prueba, sin red, con mise y agy
# de mentira. La corre check.sh en pj-template (y CI). Imprime ok/FALLA; sale con 1 si algo falla.
set -euo pipefail
T="$(cd "$(dirname "$0")/.." && pwd)"
PY="${PY:-$(bash "$T/scripts/py.sh")}"
fallas=0; ok(){ echo "ok   $*"; }; mal(){ echo "FALLA $*"; fallas=$((fallas+1)); }
trap 'echo "FALLA prueba-agy: se cortó en la línea $LINENO"' ERR
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
PYTHONUSERBASE="$("$PY" -m site --user-base || true)"; export PYTHONUSERBASE
export HOME="$tmp/home" PJ_TEMPLATE_DIR="$T" PJ_SIN_GH=1 PY
export GIT_CONFIG_GLOBAL="$tmp/gitconfig" GIT_AUTHOR_NAME=prueba GIT_AUTHOR_EMAIL=p@x GIT_COMMITTER_NAME=prueba GIT_COMMITTER_EMAIL=p@x
mkdir -p "$HOME"; git config --file "$GIT_CONFIG_GLOBAL" init.defaultBranch master
# PATH sin mise ni agy reales; los de mentira van en $tmp/bin (mise) y $tmp/bin-agy (agy suelto).
# Las carpetas del PATH que tienen mise o agy se cambian por $tmp/herr con enlaces a todo lo demás (make, git…).
mkdir -p "$tmp/herr"
base="$(tr : '\n' <<< "$PATH" | while IFS= read -r d; do
  [ -n "$d" ] && [ -d "$d" ] || continue
  if [ -e "$d/mise" ] || [ -e "$d/agy" ]; then
    for x in "$d"/*; do case "${x##*/}" in mise|agy) ;; *) [ -x "$x" ] && [ ! -e "$tmp/herr/${x##*/}" ] && ln -s "$x" "$tmp/herr/${x##*/}" ;; esac; done
    echo "$tmp/herr"
  else echo "$d"; fi
done | awk '!v[$0]++' | paste -sd:)"
log="$tmp/log"; export PRUEBA_LOG="$log"
mkdir -p "$tmp/bin" "$tmp/bin-agy"
cat > "$tmp/bin/mise" <<'M'
#!/usr/bin/env bash
# mise de mentira: anota la llamada y, en `x … -- cmd args`, lo que vería el agente al arrancar.
case "$1" in
  use) echo "mise $* · MISE_MINIMUM_RELEASE_AGE=${MISE_MINIMUM_RELEASE_AGE:-}" >> "$PRUEBA_LOG" ;;
  x) while [ "$1" != -- ]; do shift; done; shift
     echo "exec $* · pull=$(grep -q "traído por el pull" README.md && echo si || echo no) · ficha=$([ -L "$HOME/.gemini/config/agents/PM-demo.md" ] && echo si || echo no)" >> "$PRUEBA_LOG" ;;
  *) echo "mise de mentira: $*" >&2; exit 1 ;;
esac
M
printf '#!/usr/bin/env bash\necho "agy-suelto $*" >> "$PRUEBA_LOG"\n' > "$tmp/bin-agy/agy"
chmod +x "$tmp/bin/mise" "$tmp/bin-agy/agy"

# Hijo de prueba con remoto (bare local), para que ./pj listo tenga algo que traer con el pull.
git init -q --bare "$tmp/hijo.git"
h="$tmp/hijo"; git clone -q "$tmp/hijo.git" "$h" 2>/dev/null; cd "$h"
mkdir -p .github/workflows
cp "$T/plantillas/hijo/pj" pj; cp "$T/plantillas/hijo/Makefile" Makefile; cp "$T/plantillas/hijo/pj-template.yml" .github/workflows/; cp "$T/plantillas/hijo/gitignore" .gitignore
cat > proyecto.yml <<'YML'
proyecto: "demo"
area: "hijo de prueba de ./pj agy"
rama_base: "master"
template_ref: "0000000000000000000000000000000000000000"
repos: []
specs: []
notas: |
  Hijo de prueba.
YML
printf '# demo\n\nHijo de prueba de ./pj agy.\n' > README.md; printf '# AGENTS.md — demo\n' > AGENTS.md
git add -A && git commit -qm inicial && git push -q origin HEAD:master 2>/dev/null
git clone -q "$tmp/hijo.git" "$tmp/otro" 2>/dev/null
echo "traído por el pull" >> "$tmp/otro/README.md" && git -C "$tmp/otro" add -A && git -C "$tmp/otro" commit -qm "cambio remoto" && git -C "$tmp/otro" push -q 2>/dev/null

corre(){ : > "$log"; PATH="$1:$base" bash -c "${*:2}" </dev/null >"$tmp/out" 2>&1; }

# 1) make agy-pm: pull y ./pj listo primero, después mise con el PM.
if corre "$tmp/bin" make agy-pm; then
  grep -qx "mise use -g --quiet antigravity-cli · MISE_MINIMUM_RELEASE_AGE=0" "$log" \
    && ok "make agy-pm: mise use -g --quiet antigravity-cli con MISE_MINIMUM_RELEASE_AGE=0" || { mal "make agy-pm: mise use"; cat "$log"; }
  grep -qx "exec agy --dangerously-skip-permissions --agent PM-demo · pull=si · ficha=si" "$log" \
    && ok "make agy-pm: abre PM-demo con --dangerously-skip-permissions después del pull y de ./pj listo" || { mal "make agy-pm: exec"; cat "$log" "$tmp/out"; }
  grep -q "check: todo bien" "$tmp/out" && ok "make agy-pm: ./pj check del hijo da todo bien" || { mal "make agy-pm: check"; cat "$tmp/out"; }
else mal "make agy-pm falló"; cat "$tmp/out"; fi
primera="$(cat "$log")"

# 2) Idempotente: la segunda vez, lo mismo y sin cambios en el repo.
snap(){ git status --porcelain; find .agents .cursor -type f -print0 | sort -z | xargs -0 sha256sum; }
a="$(snap)"
corre "$tmp/bin" make agy-pm && [ "$(cat "$log")" = "$primera" ] && [ "$a" = "$(snap)" ] \
  && ok "make agy-pm dos veces: misma llamada y mismos bytes" || { mal "make agy-pm no es idempotente"; cat "$log"; }

# 3) Rol y argumentos: wk/rv y lo que sobra va tal cual a agy.
corre "$tmp/bin" make agy-wk ARGS="'--print hola'" && grep -qx "exec agy --dangerously-skip-permissions --agent WK-demo --print hola · pull=si · ficha=si" "$log" \
  && ok "make agy-wk ARGS=…: WK-demo con los argumentos" || { mal "make agy-wk"; cat "$log" "$tmp/out"; }
corre "$tmp/bin" ./pj agy rv --modelo "dos palabras" && grep -qx "exec agy --dangerously-skip-permissions --agent RV-demo --modelo dos palabras · pull=si · ficha=si" "$log" \
  && ok "./pj agy rv args…: RV-demo con los argumentos" || { mal "./pj agy rv"; cat "$log"; }
corre "$tmp/bin" ./pj agy --print x && grep -qx "exec agy --dangerously-skip-permissions --agent PM-demo --print x · pull=si · ficha=si" "$log" \
  && ok "./pj agy sin rol: PM por defecto y pasa los argumentos" || { mal "./pj agy sin rol"; cat "$log"; }

# 4) Sin mise: el agy del PATH; sin ninguno: error claro, sale con 127.
corre "$tmp/bin-agy" ./pj agy wk && grep -qx "agy-suelto --dangerously-skip-permissions --agent WK-demo" "$log" && grep -q "no hay mise" "$tmp/out" \
  && ok "sin mise: usa el agy del PATH y avisa" || { mal "sin mise"; cat "$log" "$tmp/out"; }
if corre "$tmp/vacio" ./pj agy; then mal "sin mise ni agy salió con 0"
else grep -q "no encuentro mise ni agy" "$tmp/out" && ok "sin mise ni agy: error claro" || { mal "sin mise ni agy"; cat "$tmp/out"; }; fi

# 5) Si ./pj listo falla, no abre nada.
echo basura > sobrante.txt && git add sobrante.txt && git commit -qm sobrante
if corre "$tmp/bin" ./pj agy; then mal "./pj agy abrió con ./pj listo fallando"
else ! grep -q '^exec' "$log" && grep -q "no abro agy" "$tmp/out" && ok "./pj listo falla (archivo sobrante): no abre agy" || { mal "listo falla"; cat "$log" "$tmp/out"; }; fi

[ "$fallas" -eq 0 ] || exit 1
