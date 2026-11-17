#!/usr/bin/env bash
# Crea un meta-repo hijo de pj-template en modo dependencia: make nuevo-hijo P=<nombre> [DIR=<carpeta>]
# Pasos: crea robert-flo/pj-<P> vacío y privado (si no existe), lo clona, escribe sus 8 archivos
# (proyecto.yml con template_ref = main actual de pj-template, onboarding.yml sin hacer, AGENTS.md, README.md, .gitignore, ./pj y
# el caller .github/workflows/pj-template.yml), corre ./pj y ./pj check, commit/push, carga el secreto
# PJ_TEMPLATE_TOKEN en el hijo y abre un PR en pj-template que suma el hijo a family.yml.
# Se puede volver a correr: un hijo existente conserva sus archivos (para migrar uno viejo, PR a mano).
# Necesita: gh autenticado y PJ_TEMPLATE_TOKEN en el entorno (nunca se imprime).
set -euo pipefail
T="$(cd "$(dirname "$0")/.." && pwd)"
P="${1:-}"; [ -n "$P" ] || { echo "uso: make nuevo-hijo P=<nombre> [DIR=<carpeta>]" >&2; exit 2; }
[[ "$P" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || { echo "nombre inválido: $P" >&2; exit 2; }
[ "$P" != template ] || { echo "pj-template es el molde, no un hijo" >&2; exit 2; }
[ -n "${PJ_TEMPLATE_TOKEN:-}" ] || { echo "falta PJ_TEMPLATE_TOKEN en el entorno (exportalo antes; no se imprime)" >&2; exit 1; }
OWNER=robert-flo; TEMPLATE="$OWNER/pj-template"; REPO="$OWNER/pj-$P"
if [ -n "${2:-}" ]; then BASE="$2"; elif [ -d /z-drive/tries ]; then BASE=/z-drive/tries; else BASE="$PWD"; fi
DEST="$BASE/rf-pj-$P"
SHA="$(gh api "repos/$TEMPLATE/commits/main" --jq .sha)"

CREADO=0
if gh repo view "$REPO" >/dev/null 2>&1; then echo "ya existe $REPO, no lo creo"
else CREADO=1; gh repo create "$REPO" --private --description "Meta-repo pj-$P (hijo de pj-template)"; fi

if [ -d "$DEST/.git" ]; then git -C "$DEST" pull --rebase --autostash -q 2>/dev/null || true
else for i in 1 2 3 4 5; do gh repo clone "$REPO" "$DEST" -- -q 2>/dev/null && break; sleep 3; done; fi
mkdir -p "$DEST"; cd "$DEST"; [ -d .git ] || git init -q -b main
git config user.name "Roberto Flores"; git config user.email "25asab015@ujmd.edu.sv"

pon(){ [ -e "$1" ] && return 0; mkdir -p "$(dirname "$1")"; cat > "$1"; echo "escrito $1"; }
# Hijo nuevo = todavía no tiene proyecto.yml. Un hijo existente nunca recibe onboarding.yml desde acá (lo hace
# ./pj onboard en su clon) y nunca se llama a ./pj clean: no se tocan sus repos, clones ni .pj/.
NUEVO=0; [ -e proyecto.yml ] || NUEVO=1
pon proyecto.yml <<YML
# Datos del proyecto. Es el único archivo de datos que llenás a mano; después: ./pj
# Lo valida schema/proyecto.schema.json de pj-template. Los textos van entre comillas (un # sin comillas corta el valor).
proyecto: "$P"                 # nombre del trío: PM-<proyecto>, WK-<proyecto>, RV-<proyecto>
area: "pj-$P (completá en una frase)"
rama_base: "main"              # rama de los PR finales
template_ref: "$SHA"   # SHA de robert-flo/pj-template; lo sube el PR de sync
# Repos hijos (vacío en proyectos de un solo repo). dir = carpeta local, ignorada en .gitignore.
repos: []
#  - dir: "rf-ejemplo"
#    repo: "robert-flo/ejemplo"
#    rama: "main"
#    nota: "qué es este repo en una frase"
# Specs en curso: ref = dueño/repo#N, orden entero, exactamente uno con primero: true.
specs: []
#  - ref: "robert-flo/ejemplo#12"
#    titulo: "primer trabajo"
#    orden: 1
#    primero: true
notas: |
  Meta-repo de $P. Completá acá el contexto del proyecto.
# Skills extra por rol, además de plantillas/roles.yml de pj-template.
skills_extra: {}
YML
pon AGENTS.md <<MD
# AGENTS.md — pj-$P

Meta-repo del trío PM/WK/RV de **$P** para Cursor y agy. Si sos un agente: si no existe \`.agents/reglas/\`, corré \`./pj\` antes de nada.

## Qué hay acá
- \`proyecto.yml\`: los datos del proyecto (repos, specs en orden, notas). Lo llenás vos.
- \`onboarding.yml\`: lo propio del proyecto para el PM, el WK y el RV (misión, lo que no tocan, primeros pasos, cómo se prueba, qué exige el RV). Lo escribe \`./pj onboard\`.
- Todo lo demás (reglas, plantillas, skills, scripts) lo trae \`./pj\` desde \`robert-flo/pj-template\` al SHA de \`template_ref\`, en \`.pj/\`, y genera \`.agents/\` y \`.cursor/\`. Nada de eso se versiona ni se edita a mano.

## Arquitectura
Completá acá cómo se arma el proyecto.
MD
pon README.md <<MD
# pj-$P

Meta-repo del trío PM/WK/RV de $P (hijo de \`robert-flo/pj-template\`, modo dependencia).

\`\`\`bash
./pj listo      # todo de una: pull, template, genera, hooks, onboarding (si falta), agy, clonar, check
make agy-pm     # pull + ./pj listo y abre el PM en agy (make agy-wk, make agy-rv; = ./pj agy pm|wk|rv)
./pj onboard    # la entrevista del PM (onboarding.yml); la segunda vez muestra lo que hay y pregunta qué cambiar
./pj clean      # deshace ./pj listo (--onboarding: también el onboarding) para volver a probar
./pj            # solo trae pj-template al template_ref y genera .agents/ y .cursor/
./pj check      # esquema de proyecto.yml, idempotencia y prueba de humo
./pj clonar     # clona los repos de proyecto.yml al lado
./pj enlazar    # solo enlaza las fichas en agy (./pj listo ya lo hace)
\`\`\`

Necesitás \`python3\` (PyYAML y jsonschema van solos a \`.pj/venv\`), \`gh\`, \`git\` y \`make\`.
MD
pon .gitignore < "$T/plantillas/hijo/gitignore"
pon pj < "$T/plantillas/hijo/pj"; chmod +x pj
pon Makefile < "$T/plantillas/hijo/Makefile"
pon .github/workflows/pj-template.yml < "$T/plantillas/hijo/pj-template.yml"
if [ "$NUEVO" = 1 ]; then
  pon onboarding.yml <<YML
# Onboarding del trío de $P: lo propio del proyecto que reciben PM, WK y RV en su ficha.
# Lo escribe \`./pj onboard\` (entrevista); se puede editar a mano y correr \`./pj\`.
# hecho vacío = onboarding sin hacer. Esquema: schema/onboarding.schema.json de pj-template.
version: 1
hecho: ""
mision: ""
no_tocar: []
reglas_proyecto: []
primeros_pasos: []
wk:
  como_probar: []
rv:
  exige: []
YML
fi
PJ_TEMPLATE_TOKEN="$PJ_TEMPLATE_TOKEN" ./pj && ./pj check
if [ "$NUEVO" = 1 ]; then
  # Hijo nuevo: el primer commit del repo vacío.
  git add -A
  git diff --cached --quiet || git commit -q -m "feat: arranque de pj-$P desde pj-template (modo dependencia)"
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$REPO.git"
  git push -q -u origin HEAD
else
  # Hijo existente: nada directo a la rama por defecto. No commitea ni empuja; lo que haya cambiado va por PR a mano.
  if [ -n "$(git status --porcelain)" ]; then
    echo "hijo existente: no commiteo ni empujo. Cambios locales en $DEST (llevalos por PR si sirven):"; git status --short
  else echo "hijo existente: sin cambios, no empujo nada"; fi
fi

printf '%s' "$PJ_TEMPLATE_TOKEN" | gh secret set PJ_TEMPLATE_TOKEN -R "$REPO" >/dev/null && echo "secreto PJ_TEMPLATE_TOKEN cargado en $REPO"

# family.yml de pj-template, por PR.
if gh api "repos/$TEMPLATE/contents/family.yml" --jq .content | base64 -d | grep -qx "  - $REPO"; then
  echo "$REPO ya está en family.yml"; exit 0
fi
RAMA="family/pj-$P"
if gh pr list -R "$TEMPLATE" --head "$RAMA" --state open --json url --jq '.[0].url' | grep -q .; then
  echo "ya hay PR abierto para $RAMA"; exit 0
fi
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
gh repo clone "$TEMPLATE" "$tmp/t" -- -q
cd "$tmp/t"; git checkout -q -B "$RAMA"
printf '  - %s\n' "$REPO" >> family.yml
git commit -q -am "chore: suma $REPO a family.yml"
git push -q -u origin "$RAMA"
gh pr create -R "$TEMPLATE" --head "$RAMA" --title "family: suma $REPO" --body "Hijo creado con \`make nuevo-hijo P=$P\`."
