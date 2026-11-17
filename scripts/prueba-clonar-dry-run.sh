#!/usr/bin/env bash
# Prueba de --dry-run / -n en clone-repos.sh, ./pj clonar, ./pj listo (--dry-run, --no-clonar,
# PJ_SIN_CLONAR=1) y detección automática de worktree (.git como archivo), con gh falso en PATH.
set -euo pipefail
T="$(cd "$(dirname "$0")/.." && pwd)"
PY="${PY:-$(bash "$T/scripts/py.sh")}"
fallas=0; ok(){ echo "ok   $*"; }; mal(){ echo "FALLA $*"; fallas=$((fallas+1)); }
trap 'echo "FALLA prueba-clonar-dry-run: se cortó en la línea $LINENO"' ERR
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
PYTHONUSERBASE="$("$PY" -m site --user-base || true)"; export PYTHONUSERBASE
export HOME="$tmp/home" PJ_TEMPLATE_DIR="$T" PJ_SIN_GH=1 PY
export GIT_CONFIG_GLOBAL="$tmp/gitconfig" GIT_AUTHOR_NAME=prueba GIT_AUTHOR_EMAIL=p@x GIT_COMMITTER_NAME=prueba GIT_COMMITTER_EMAIL=p@x
mkdir -p "$HOME" "$tmp/bin"
git config --file "$GIT_CONFIG_GLOBAL" init.defaultBranch master

cat > "$tmp/bin/gh" <<'GH'
#!/usr/bin/env bash
echo "FALLA: se invocó gh $*" >&2
exit 99
GH
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH"

git init -q --bare "$tmp/hijo.git"
h="$tmp/hijo"; git clone -q "$tmp/hijo.git" "$h" 2>/dev/null
cd "$h"
mkdir -p .github/workflows rf-dos/.git
cp "$T/plantillas/hijo/pj" pj
cp "$T/plantillas/hijo/Makefile" Makefile
cp "$T/plantillas/hijo/pj-template.yml" .github/workflows/
cp "$T/plantillas/hijo/gitignore" .gitignore
cat > proyecto.yml <<'YML'
proyecto: "demo"
area: "hijo de prueba de dry-run"
rama_base: "master"
template_ref: "0000000000000000000000000000000000000000"
repos:
  - dir: rf-uno
    repo: robert-flo/repo-uno
    rama: main
  - dir: rf-dos
    repo: robert-flo/repo-dos
    rama: master
specs: []
notas: |
  Hijo de prueba.
YML
printf '# demo\n\nHijo de prueba.\n' > README.md
printf '# AGENTS.md — demo\n' > AGENTS.md
PJ_RAIZ="$h" "$PY" "$T/scripts/generar.py" >/dev/null
git add -A && git commit -qm inicial && git push -q origin HEAD:master 2>/dev/null

esperar_dry_run(){
  local desc="$1" out="$2"
  if grep -qF '[dry-run] clonaría robert-flo/repo-uno en rf-uno (rama main)' "$out" \
     && grep -qF '[dry-run] verificaría/actualizaría rf-dos (robert-flo/repo-dos -> master)' "$out"; then
    ok "$desc"
  else
    mal "$desc"
    cat "$out"
  fi
}

# 1) clone-repos.sh --dry-run, -n, PJ_CLONAR_DRY_RUN=1
PJ_RAIZ="$h" bash "$T/clone-repos.sh" --dry-run >"$tmp/o1" 2>&1
esperar_dry_run "clone-repos.sh --dry-run simula sin llamar a gh" "$tmp/o1"

PJ_RAIZ="$h" bash "$T/clone-repos.sh" -n >"$tmp/o2" 2>&1
esperar_dry_run "clone-repos.sh -n simula sin llamar a gh" "$tmp/o2"

PJ_RAIZ="$h" PJ_CLONAR_DRY_RUN=1 bash "$T/clone-repos.sh" >"$tmp/o3" 2>&1
esperar_dry_run "PJ_CLONAR_DRY_RUN=1 clone-repos.sh simula sin llamar a gh" "$tmp/o3"

# 2) ./pj clonar --dry-run y -n
./pj clonar --dry-run >"$tmp/o4" 2>&1
esperar_dry_run "./pj clonar --dry-run simula sin llamar a gh" "$tmp/o4"

./pj clonar -n >"$tmp/o5" 2>&1
esperar_dry_run "./pj clonar -n simula sin llamar a gh" "$tmp/o5"

# 3) ./pj listo --dry-run
./pj listo --dry-run </dev/null >"$tmp/o6" 2>&1
esperar_dry_run "./pj listo --dry-run simula clonar sin llamar a gh" "$tmp/o6"
grep -q "check: todo bien" "$tmp/o6" && ok "./pj listo --dry-run corre check hasta todo bien" || { mal "./pj listo --dry-run: check"; cat "$tmp/o6"; }

# 4) ./pj listo --no-clonar y PJ_SIN_CLONAR=1
./pj listo --no-clonar </dev/null >"$tmp/o7" 2>&1
if ! grep -q '\[dry-run\]' "$tmp/o7" && ! grep -q 'Repos del proyecto' "$tmp/o7" && grep -q 'salto clonar' "$tmp/o7" && grep -q 'check: todo bien' "$tmp/o7"; then
  ok "./pj listo --no-clonar salta clonar"
else
  mal "./pj listo --no-clonar"
  cat "$tmp/o7"
fi

PJ_SIN_CLONAR=1 ./pj listo </dev/null >"$tmp/o8" 2>&1
if ! grep -q '\[dry-run\]' "$tmp/o8" && ! grep -q 'Repos del proyecto' "$tmp/o8" && grep -q 'salto clonar' "$tmp/o8" && grep -q 'check: todo bien' "$tmp/o8"; then
  ok "PJ_SIN_CLONAR=1 ./pj listo salta clonar"
else
  mal "PJ_SIN_CLONAR=1 ./pj listo"
  cat "$tmp/o8"
fi

# 5) Worktree (.git como archivo): ./pj listo sin flags detecta worktree y corre clonar en --dry-run
git -C "$h" worktree add -q "$tmp/wt" -b wt-test
[ -f "$tmp/wt/.git" ] || { mal "no se creó .git como archivo en el worktree"; exit 1; }
mkdir -p "$tmp/wt/rf-dos/.git"
( cd "$tmp/wt" && ./pj listo </dev/null ) >"$tmp/o9" 2>&1
if grep -q "worktree detectado" "$tmp/o9" && grep -q "check: todo bien" "$tmp/o9"; then
  esperar_dry_run "worktree (.git archivo): ./pj listo detecta worktree y corre clonar en --dry-run" "$tmp/o9"
else
  mal "worktree (.git archivo): ./pj listo no avisó o falló check"
  cat "$tmp/o9"
fi

[ "$fallas" -eq 0 ] || exit 1
