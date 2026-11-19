#!/usr/bin/env bash
# Prueba de punta a punta de ./pj onboard y ./pj clean (ADR 0017) en un hijo de prueba, sin red.
# La corre check.sh en pj-template (y CI). Imprime ok/FALLA como check.sh; sale con 1 si algo falla.
set -euo pipefail
T="$(cd "$(dirname "$0")/.." && pwd)"
PY="${PY:-$(bash "$T/scripts/py.sh")}"
fallas=0; ok(){ echo "ok   $*"; }; mal(){ echo "FALLA $*"; fallas=$((fallas+1)); }
trap 'echo "FALLA prueba-onboarding: se cortó en la línea $LINENO"' ERR
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
# HOME de mentira (enlaces de agy y hooks); el python sigue viendo sus paquetes de usuario.
PYTHONUSERBASE="$("$PY" -m site --user-base || true)"; export PYTHONUSERBASE   # en un venv sale con 1
export HOME="$tmp/home" PJ_TEMPLATE_DIR="$T" PJ_SIN_GH=1 PJ_HOY=2026-01-02 PY
export GIT_CONFIG_GLOBAL="$tmp/gitconfig" GIT_AUTHOR_NAME=prueba GIT_AUTHOR_EMAIL=p@x GIT_COMMITTER_NAME=prueba GIT_COMMITTER_EMAIL=p@x
mkdir -p "$HOME"; git config --file "$GIT_CONFIG_GLOBAL" init.defaultBranch master

# Un "repo hijo" remoto (bare local) que el onboarding descubre en AGENTS.md.
git init -q --bare "$tmp/demo-hijo.git"
git clone -q "$tmp/demo-hijo.git" "$tmp/semilla" 2>/dev/null
printf 'check:\n\ttrue\n' > "$tmp/semilla/Makefile"; printf '#!/bin/sh\n' > "$tmp/semilla/x.sh"
git -C "$tmp/semilla" add -A && git -C "$tmp/semilla" commit -qm semilla && git -C "$tmp/semilla" push -q origin HEAD:master

h="$tmp/hijo"; mkdir -p "$h/.github/workflows" "$h/.agents"; cd "$h"; git init -q
cp "$T/plantillas/hijo/pj" pj; cp "$T/plantillas/hijo/Makefile" Makefile; cp "$T/plantillas/hijo/pj-template.yml" .github/workflows/; cp "$T/plantillas/hijo/gitignore" .gitignore
cat > proyecto.yml <<'YML'
proyecto: "demo"
area: "hijo de prueba del onboarding"
rama_base: "master"
template_ref: "0000000000000000000000000000000000000000"
repos: []
#  - dir: "ejemplo"
specs: []
notas: |
  Hijo de prueba. Nunca PRs a upstream. Los commits van sin trailers de agente.
extras:
  - ".agents/propio.md"
YML
cat > README.md <<'MD'
# demo

Meta-repo de prueba del onboarding: el PM de acá es la única puerta a demo-hijo.
MD
cat > AGENTS.md <<'MD'
# AGENTS.md — demo

## Reglas del proyecto
- Rama por defecto `master`.
- Nunca abrir PRs hacia upstream.

## Repos
- **demo-hijo** (el repo que se programa): clonar desde https://github.com/robert-flo/demo-hijo.git
MD
echo propio > .agents/propio.md
git add -A && git commit -qm inicial

./pj onboard --mostrar | grep -q "sin hacer" && ok "onboard --mostrar: sin hacer" || mal "onboard --mostrar no dice sin hacer"
if ./pj onboard </dev/null >"$tmp/o" 2>&1; then mal "onboard sin terminal ni --si no debería escribir"; else grep -q "Necesita una terminal" "$tmp/o" && ok "onboard sin terminal explica qué correr" || mal "onboard sin terminal: $(cat "$tmp/o")"; fi

git clone -q "$tmp/demo-hijo.git" demo-hijo   # con el clon al lado, el onboarding lee su stack de ahí
./pj onboard --si >"$tmp/o1" 2>&1 || { mal "onboard --si falló"; cat "$tmp/o1"; }
grep -q 'repo: "robert-flo/demo-hijo"' proyecto.yml && grep -q '^#  - dir: "ejemplo"' proyecto.yml \
  && ok "onboard llena repos: desde AGENTS.md y conserva los comentarios" || mal "onboard no llenó repos: bien"
grep -q 'hecho: "2026-01-02"' onboarding.yml && grep -q 'Meta-repo de prueba del onboarding' onboarding.yml \
  && grep -q 'Nunca abrir PRs hacia upstream' onboarding.yml && grep -q 'make check' onboarding.yml \
  && ok "onboard --si: misión del README, no_tocar de AGENTS.md, pruebas del Makefile" || { mal "onboard --si: datos recomendados"; cat onboarding.yml; }
grep -q "Mi misión acá: Meta-repo de prueba del onboarding" .agents/agents/PM-demo.md && grep -q "make check" .agents/agents/WK-demo.md \
  && grep -q "shellcheck" .agents/agents/RV-demo.md && grep -q "Misión del proyecto: Meta-repo" .cursor/rules/pm-demo.mdc \
  && ok "generar inyecta el onboarding en PM, WK, RV y la regla de Cursor" || mal "las fichas no traen el onboarding"
"$PY" "$T/scripts/humo.py" >/dev/null && ok "humo con onboarding hecho" || mal "humo con onboarding hecho"

a="$(sha256sum onboarding.yml proyecto.yml; find .agents .cursor -type f -print0 | sort -z | xargs -0 sha256sum)"
./pj onboard --si >"$tmp/o2" 2>&1 && grep -q "ya está hecho el 2026-01-02" "$tmp/o2" && grep -q "nada cambió" "$tmp/o2" \
  && ok "onboard por segunda vez: «ya está hecho» con los datos" || { mal "onboard 2ª vez"; cat "$tmp/o2"; }
./pj onboard </dev/null >/dev/null 2>&1 && ok "onboard ya hecho sin terminal sale con 0" || mal "onboard ya hecho sin terminal no sale con 0"
if command -v script >/dev/null; then
  printf 'n\n' | script -qec "./pj onboard" /dev/null >"$tmp/o3" 2>&1 || true
  grep -q "querés cambiar algo" "$tmp/o3" && grep -q "nada cambió" "$tmp/o3" && ok "onboard en terminal: pregunta y con n no toca nada" || { mal "onboard en terminal con n"; cat "$tmp/o3"; }
fi
b="$(sha256sum onboarding.yml proyecto.yml; find .agents .cursor -type f -print0 | sort -z | xargs -0 sha256sum)"
[ "$a" = "$b" ] && ok "onboard es idempotente (mismos bytes)" || mal "onboard cambió archivos en la segunda corrida"
./pj onboard --si --rehacer >/dev/null 2>&1 && [ "$a" = "$(sha256sum onboarding.yml proyecto.yml; find .agents .cursor -type f -print0 | sort -z | xargs -0 sha256sum)" ] \
  && ok "onboard --rehacer con las mismas respuestas da los mismos bytes" || mal "onboard --rehacer cambió bytes"

# clean: hooks, enlaces de agy y, por cada forma de trabajo local en un clon, que el clon se quede (sale con 1).
git add onboarding.yml proyecto.yml && git commit -qm onboarding   # como en un hijo real: el onboarding se commitea
./pj hooks >/dev/null; ./pj enlazar >/dev/null
se_queda(){ # $1 descripción, $2 texto esperado en el aviso; el estado ya está armado en demo-hijo
  if ./pj clean >"$tmp/c" 2>&1; then mal "clean borró o aceptó un clon que $1"
  elif [ -d demo-hijo/.git ] && grep -q "demo-hijo ($2" "$tmp/c"; then ok "clean no borra un clon que $1 y avisa"
  else mal "clean con un clon que $1: $(cat "$tmp/c")"; fi
}
echo x > demo-hijo/sucio;                                       se_queda "tiene cambios sin commitear" "tiene cambios sin commitear"; rm demo-hijo/sucio
echo .env >> demo-hijo/.git/info/exclude; echo SECRETO=1 > demo-hijo/.env
se_queda "tiene archivos ignorados (.env)" "tiene archivos ignorados"
[ -f demo-hijo/.env ] || mal "clean borró el .env ignorado"; rm demo-hijo/.env
git -C demo-hijo worktree add -q ../demo-hijo-wt-1-x -b wt-1 2>/dev/null; echo y > demo-hijo-wt-1-x/en-stage; git -C demo-hijo-wt-1-x add en-stage
se_queda "tiene un worktree enlazado con trabajo en stage" "tiene worktrees enlazados"
git -C demo-hijo-wt-1-x diff --cached --quiet && mal "clean rompió el worktree enlazado" || true
git -C demo-hijo worktree remove -f ../demo-hijo-wt-1-x; git -C demo-hijo branch -qD wt-1
git -C demo-hijo checkout -q --detach; git -C demo-hijo commit -q --allow-empty -m "en detached HEAD"
se_queda "tiene un commit en detached HEAD" "tiene commits sin subir"; git -C demo-hijo checkout -q master 2>/dev/null
se_queda "tiene un commit de un detached HEAD abandonado (solo en el reflog)" "tiene commits sin subir"
git -C demo-hijo reflog expire --expire-unreachable=now --all && git -C demo-hijo gc -q --prune=now
git -C demo-hijo tag local-1
se_queda "tiene un tag local sin subir" "tiene el tag local local-1"; git -C demo-hijo tag -d local-1 >/dev/null
git -C demo-hijo tag v1x0 && git -C demo-hijo push -q origin v1x0 && git -C demo-hijo tag v1.0
se_queda "tiene el tag local v1.0 y el remoto solo v1x0 (sin regex)" "tiene el tag local v1.0 sin subir"; git -C demo-hijo tag -d v1.0 >/dev/null

# --onboarding no pisa cambios sin commitear y, si se niega, no borra nada.
./pj >/dev/null; ./pj hooks >/dev/null; ./pj enlazar >/dev/null   # los clean de arriba ya borraron lo generado
echo "# nota mía sin commitear" >> onboarding.yml
if ./pj clean --onboarding >"$tmp/c" 2>&1; then mal "clean --onboarding pisó onboarding.yml con cambios sin commitear"
elif grep -q "nota mía sin commitear" onboarding.yml && [ -d demo-hijo ] && [ -f .agents/agents/PM-demo.md ] && grep -q "onboarding.yml tiene cambios sin commitear" "$tmp/c"
then ok "clean --onboarding se niega si onboarding.yml tiene cambios sin commitear, sin borrar nada"
else mal "clean --onboarding con onboarding.yml modificado: $(cat "$tmp/c")"; fi
git checkout -q -- onboarding.yml

# Lo propio en .cursor/ y .agents/ (ignorado por git, fuera del manifiesto) se queda.
echo '{}' > .cursor/mcp.json; echo notas > .agents/mis-notas.md
./pj clean --onboarding >"$tmp/c2" 2>&1 || { mal "clean --onboarding falló"; cat "$tmp/c2"; }
[ ! -e demo-hijo ] && [ ! -e .pj ] && [ ! -e .agents/agents ] && [ ! -e .cursor/rules ] && [ -f .agents/propio.md ] \
  && [ -z "$(ls "$HOME/.gemini/config/agents")" ] && [ ! -e .git/hooks/post-merge ] \
  && ok "clean borra .pj, lo generado, hooks, enlaces de agy y el clon limpio; deja los extras" || { mal "clean dejó cosas"; cat "$tmp/c2"; ls -a . .agents; }
[ -f .cursor/mcp.json ] && [ -f .agents/mis-notas.md ] && grep -q "dejé 2 archivos propios" "$tmp/c2" \
  && ok "clean deja los archivos propios de .cursor/ y .agents/ y avisa" || { mal "clean y archivos propios"; cat "$tmp/c2"; }
"$PY" -c "import sys; sys.path.insert(0,'$T/scripts'); import onboarding as ob; sys.exit(open('onboarding.yml').read() != ob.volcar(ob.vacio(), 'demo'))" \
  && grep -qx 'repos: \[\]' proyecto.yml && grep -q '^#  - dir: "ejemplo"' proyecto.yml \
  && ok "clean --onboarding deja onboarding.yml y repos: sin hacer (mismos bytes que onboard.py)" || { mal "clean --onboarding: estado sin hacer"; cat onboarding.yml; }
./pj clean --onboarding 2>&1 | grep -qx "pj: nada que limpiar" && ok "clean por segunda vez: nada que limpiar (ya sin hacer, no se niega)" || mal "clean no es idempotente"
git diff --quiet -- AGENTS.md README.md && ok "clean no toca los archivos versionados de mano" || mal "clean tocó archivos versionados"
# Sin clon y sin gh, el resumen avisa que faltan las líneas de stack.
./pj onboard --si >"$tmp/o4" 2>&1 && grep -q "aviso: sin las líneas de stack (Makefile, chezmoi, npm…) de demo-hijo" "$tmp/o4" \
  && ok "onboard avisa en el resumen cuando no pudo leer el stack (sin clon ni gh)" || { mal "onboard sin stack no avisa"; cat "$tmp/o4"; }

# nuevo-hijo con un gh de mentira: sobre un hijo existente sin onboarding.yml no toca repos ni clones; uno nuevo
# recibe onboarding.yml «sin hacer».
mkdir -p "$tmp/bin" "$tmp/nh"
cat > "$tmp/bin/gh" <<'GH'
#!/usr/bin/env bash
case "$1 $2" in
  "api repos/robert-flo/pj-template/commits/main") echo 0000000000000000000000000000000000000000 ;;
  "repo view") exit 0 ;;
  "secret set") cat >/dev/null ;;
  "api repos/robert-flo/pj-template/contents/family.yml") printf '  - robert-flo/pj-%s\n' "$NH_P" | base64 -w0; echo ;;
  "repo clone") git clone -q "$NH_REMOTO" "$4" ;;
  *) echo "gh de mentira: $*" >&2; exit 1 ;;
esac
GH
chmod +x "$tmp/bin/gh"
git init -q --bare "$tmp/pj-viejo.git"; v="$tmp/nh/rf-pj-viejo"; git clone -q "$tmp/pj-viejo.git" "$v" 2>/dev/null
cp pj Makefile AGENTS.md README.md .gitignore "$v/"; mkdir -p "$v/.github/workflows"; cp .github/workflows/pj-template.yml "$v/.github/workflows/"
sed -e 's/^proyecto: "demo"/proyecto: "viejo"/' -e '/^extras:/,$d' proyecto.yml > "$v/proyecto.yml"
"$PY" -c "import sys; sys.path.insert(0,'$T/scripts'); import onboarding as ob, pathlib; p=pathlib.Path('$v/proyecto.yml'); p.write_text(ob.reemplazar_repos(p.read_text(), [{'dir':'demo-hijo','repo':'robert-flo/demo-hijo','rama':'master'}]))"
git -C "$v" add -A && git -C "$v" commit -qm viejo && git -C "$v" push -q origin HEAD:master
git clone -q "$tmp/demo-hijo.git" "$v/demo-hijo"; echo local > "$v/demo-hijo/trabajo"
antes="$(sha256sum "$v/proyecto.yml")"; remoto_antes="$(git -C "$tmp/pj-viejo.git" rev-parse master)"
if (cd "$tmp" && PATH="$tmp/bin:$PATH" NH_P=viejo NH_REMOTO="$tmp/pj-viejo.git" PJ_TEMPLATE_TOKEN=x bash "$T/scripts/nuevo-hijo.sh" viejo "$tmp/nh") >"$tmp/n1" 2>&1 \
  && [ ! -e "$v/onboarding.yml" ] && [ "$antes" = "$(sha256sum "$v/proyecto.yml")" ] && [ -f "$v/demo-hijo/trabajo" ]; then
  ok "nuevo-hijo sobre un hijo existente sin onboarding.yml no toca repos:, clones ni onboarding"
else mal "nuevo-hijo sobre un hijo existente"; tail -20 "$tmp/n1"; fi
[ "$remoto_antes" = "$(git -C "$tmp/pj-viejo.git" rev-parse master)" ] && [ "$(git -C "$v" rev-parse HEAD)" = "$remoto_antes" ] && grep -q "hijo existente: no commiteo ni empujo" "$tmp/n1" \
  && ok "nuevo-hijo re-ejecutado sobre un hijo existente no commitea ni empuja a la rama por defecto" || { mal "nuevo-hijo empujó o commiteó en un hijo existente"; tail -5 "$tmp/n1"; }
git init -q --bare "$tmp/pj-nuevo.git"
if (cd "$tmp" && PATH="$tmp/bin:$PATH" NH_P=nuevo NH_REMOTO="$tmp/pj-nuevo.git" PJ_TEMPLATE_TOKEN=x bash "$T/scripts/nuevo-hijo.sh" nuevo "$tmp/nh") >"$tmp/n2" 2>&1 \
  && "$PY" -c "import sys; sys.path.insert(0,'$T/scripts'); import onboarding as ob; sys.exit(open('$tmp/nh/rf-pj-nuevo/onboarding.yml').read() != ob.volcar(ob.vacio(), 'nuevo'))"; then
  ok "nuevo-hijo crea onboarding.yml «sin hacer» en un hijo nuevo (sin llamar a clean)"
else mal "nuevo-hijo en un hijo nuevo"; grep -E "FALLA|rror" "$tmp/n2"; fi


# Sin clon pero CON gh de mentira: el stack debe venir de GitHub, no reventar por una variable sin asignar.
git checkout -q -- onboarding.yml proyecto.yml
./pj clean --onboarding >/dev/null 2>&1
mkdir -p "$tmp/bin2"
cat > "$tmp/bin2/gh" <<'GH'
#!/usr/bin/env bash
case "$*" in
  *"repos/robert-flo/demo-hijo/contents/Makefile"*) printf 'check:\n\ttrue\n' ;;
  *"repos/robert-flo/demo-hijo/contents"*) printf 'AGENTS.md\nMakefile\nx.sh\n' ;;
  *"repo view"*) printf '{"defaultBranchRef":{"name":"master"}}' ;;
  *) echo "gh de mentira: $*" >&2; exit 1 ;;
esac
GH
chmod +x "$tmp/bin2/gh"
if env -u PJ_SIN_GH PATH="$tmp/bin2:$PATH" ./pj onboard --si >"$tmp/o5" 2>&1 \
  && grep -q 'repo: "robert-flo/demo-hijo"' proyecto.yml \
  && grep -q '`make check`' onboarding.yml; then
  ok "onboard con gh de mentira: lee el stack del repo remoto (sin clon) y llena las pruebas del Makefile"
else mal "onboard con gh de mentira (repo remoto sin clon)"; cat "$tmp/o5"; fi

[ "$fallas" -eq 0 ] || exit 1
