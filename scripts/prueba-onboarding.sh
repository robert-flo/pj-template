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
cp "$T/plantillas/hijo/pj" pj; cp "$T/plantillas/hijo/pj-template.yml" .github/workflows/; cp "$T/plantillas/hijo/gitignore" .gitignore
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

# clean: hooks, enlaces de agy, clon sucio (se queda) y clon limpio (se borra).
./pj hooks >/dev/null; ./pj agy >/dev/null
echo x > demo-hijo/sucio
if ./pj clean >"$tmp/c1" 2>&1; then mal "clean borró o aceptó un clon con cambios"; else
  [ -d demo-hijo ] && grep -q "demo-hijo (tiene cambios sin commitear)" "$tmp/c1" && ok "clean no borra un clon con cambios y avisa" || mal "clean con clon sucio: $(cat "$tmp/c1")"; fi
rm demo-hijo/sucio
./pj clean --onboarding >"$tmp/c2" 2>&1 || { mal "clean --onboarding falló"; cat "$tmp/c2"; }
[ ! -e demo-hijo ] && [ ! -e .pj ] && [ ! -e .agents/agents ] && [ ! -e .cursor ] && [ -f .agents/propio.md ] \
  && [ -z "$(ls "$HOME/.gemini/config/agents")" ] && [ ! -e .git/hooks/post-merge ] \
  && ok "clean borra .pj, lo generado, hooks, enlaces de agy y el clon limpio; deja los extras" || { mal "clean dejó cosas"; cat "$tmp/c2"; ls -a . .agents; }
"$PY" -c "import sys; sys.path.insert(0,'$T/scripts'); import onboarding as ob; sys.exit(open('onboarding.yml').read() != ob.volcar(ob.vacio(), 'demo'))" \
  && grep -qx 'repos: \[\]' proyecto.yml && grep -q '^#  - dir: "ejemplo"' proyecto.yml \
  && ok "clean --onboarding deja onboarding.yml y repos: sin hacer (mismos bytes que onboard.py)" || { mal "clean --onboarding: estado sin hacer"; cat onboarding.yml; }
./pj clean --onboarding 2>&1 | grep -qx "pj: nada que limpiar" && ok "clean por segunda vez: nada que limpiar" || mal "clean no es idempotente"
git diff --quiet -- AGENTS.md README.md && ok "clean no toca los archivos versionados de mano" || mal "clean tocó archivos versionados"

[ "$fallas" -eq 0 ] || exit 1
