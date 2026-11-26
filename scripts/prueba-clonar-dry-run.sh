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
export RAVN_HOME_REPOS_ROOT="$tmp/central"
export GIT_CONFIG_GLOBAL="$tmp/gitconfig" GIT_AUTHOR_NAME=prueba GIT_AUTHOR_EMAIL=p@x GIT_COMMITTER_NAME=prueba GIT_COMMITTER_EMAIL=p@x
mkdir -p "$HOME" "$tmp/bin" "$tmp/central"
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
repos_externos:
  - dir: omarchy-ext
    repo: omacom/omarchy-pkgs
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
  if grep -qF "[dry-run] clonaría robert-flo/repo-uno en $tmp/central/.bare/repo-uno.git y $tmp/central/repos/repo-uno (rama main)" "$out" \
     && grep -qF '[dry-run] verificaría/actualizaría rf-dos (robert-flo/repo-dos -> master); sugeriría limpiar clon viejo con ./pj clean' "$out"; then
    ok "$desc"
  else
    mal "$desc"
    cat "$out"
  fi
}

# 0) .gitignore generado en el hijo incluye /.bares/ y /repos/
if grep -qxF '/.bares/' "$h/.gitignore" && grep -qxF '/repos/' "$h/.gitignore"; then
  ok ".gitignore generado del hijo incluye /.bares/ y /repos/"
else
  mal ".gitignore generado del hijo no incluye /.bares/ y /repos/"
  cat "$h/.gitignore"
fi

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

# 6) Stub de ravn-git-bare-clone con PJ_CLONAR_CMD: verifica BARE_HOME, WORKTREES_HOME, aviso de clon viejo y sin borrarlo
cat > "$tmp/bin/stub-bare" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "CALL BARE_HOME=$BARE_HOME WORKTREES_HOME=$WORKTREES_HOME ARGS=$*" >> "$STUB_LOG"
repo="${2##*/}"
mkdir -p "$BARE_HOME/$repo.git" "$WORKTREES_HOME/$repo"
STUB
chmod +x "$tmp/bin/stub-bare"
export STUB_LOG="$tmp/stub.log"
: > "$STUB_LOG"
PJ_RAIZ="$h" PJ_CLONAR_CMD="$tmp/bin/stub-bare" bash "$T/clone-repos.sh" >"$tmp/o10" 2>&1
if grep -qxF "CALL BARE_HOME=$tmp/central/.bare WORKTREES_HOME=$tmp/central/repos ARGS=clone robert-flo/repo-uno" "$STUB_LOG" \
   && grep -qxF "CALL BARE_HOME=$tmp/central/.bare WORKTREES_HOME=$tmp/central/repos ARGS=clone robert-flo/repo-dos" "$STUB_LOG" \
   && grep -qF "Aviso: existe un clon viejo en 'rf-dos/.git'" "$tmp/o10" \
   && grep -qF "./pj clean" "$tmp/o10" \
   && [ -d "$h/rf-dos/.git" ] \
   && [ -d "$tmp/central/.bare/repo-uno.git" ] \
   && [ -d "$tmp/central/repos/repo-uno" ]; then
  ok "stub ravn-git-bare-clone usa .bare/ y repos/ centrales, avisa clon viejo sin borrarlo"
else
  mal "stub ravn-git-bare-clone"
  cat "$STUB_LOG"
  cat "$tmp/o10"
fi

# 7) dry-run cuando ya existe .bare/repo-uno.git
PJ_RAIZ="$h" bash "$T/clone-repos.sh" --dry-run >"$tmp/o11" 2>&1
if grep -qF "[dry-run] verificaría/actualizaría robert-flo/repo-uno en $tmp/central/.bare/repo-uno.git y $tmp/central/repos/repo-uno (rama main)" "$tmp/o11"; then
  ok "--dry-run detecta .bare/repo-uno.git existente"
else
  mal "--dry-run no detectó .bare/repo-uno.git existente"
  cat "$tmp/o11"
fi

# 8) repos_externos: se clonan como los demás y generan reglas duras de solo lectura
PJ_RAIZ="$h" bash "$T/clone-repos.sh" --dry-run >"$tmp/o12" 2>&1
if grep -qF "[dry-run] verificaría/actualizaría omacom/omarchy-pkgs en $tmp/central/.bare/omarchy-pkgs.git y $tmp/central/repos/omarchy-pkgs (rama master)" "$tmp/o12" \
   && grep -qxF "CALL BARE_HOME=$tmp/central/.bare WORKTREES_HOME=$tmp/central/repos ARGS=clone omacom/omarchy-pkgs" "$STUB_LOG"; then
  ok "clone-repos --dry-run incluye los repos_externos"
else
  mal "clone-repos --dry-run no incluye los repos_externos"
  cat "$tmp/o12"
fi
f="$h/.agents/agents/PM-demo.md"
if grep -qF 'Nunca empujar a `omacom/omarchy-pkgs`' "$f" \
   && grep -qF 'Nunca abrir PRs hacia upstream `omacom/omarchy-pkgs`' "$f" \
   && grep -qF 'solo lectura' "$f"; then
  ok "generar mete las reglas duras de solo lectura de los repos externos en las fichas"
else
  mal "generar no metió las reglas duras de los repos externos en las fichas"
  grep -n "omarchy\|upstream\|externo" "$f" || echo "(sin rastros en la ficha)"
fi

[ "$fallas" -eq 0 ] || exit 1
