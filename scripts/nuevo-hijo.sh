#!/usr/bin/env bash
# Crea un meta-repo hijo de pj-template: make nuevo-hijo P=<nombre> [DIR=<carpeta>]
# Pasos: crea robert-flo/pj-<P> desde el template (si no existe), lo clona, llena proyecto.yml,
# corre make generar + check, commit/push, carga el secreto PJ_TEMPLATE_TOKEN en el hijo y
# abre un PR en pj-template que suma el hijo a family.yml. Se puede volver a correr.
# Necesita: gh autenticado y PJ_TEMPLATE_TOKEN en el entorno (nunca se imprime).
set -euo pipefail
P="${1:-}"; [ -n "$P" ] || { echo "uso: make nuevo-hijo P=<nombre> [DIR=<carpeta>]" >&2; exit 2; }
[[ "$P" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || { echo "nombre inválido: $P" >&2; exit 2; }
[ -n "${PJ_TEMPLATE_TOKEN:-}" ] || { echo "falta PJ_TEMPLATE_TOKEN en el entorno (exportalo antes; no se imprime)" >&2; exit 1; }
OWNER=robert-flo; TEMPLATE="$OWNER/pj-template"; REPO="$OWNER/pj-$P"
if [ -n "${2:-}" ]; then BASE="$2"; elif [ -d /z-drive/tries ]; then BASE=/z-drive/tries; else BASE="$PWD"; fi
DEST="$BASE/rf-pj-$P"

if gh repo view "$REPO" >/dev/null 2>&1; then echo "ya existe $REPO, no lo creo"
else gh repo create "$REPO" --private --template "$TEMPLATE"; sleep 5; fi

if [ -d "$DEST/.git" ]; then git -C "$DEST" pull --rebase --autostash -q
else for i in 1 2 3 4 5; do gh repo clone "$REPO" "$DEST" && break; sleep 5; done; fi
cd "$DEST"

if [ "$(python3 -c 'import yaml;print(yaml.safe_load(open("proyecto.yml"))["proyecto"])')" != "$P" ]; then
cat > proyecto.yml <<YML
# Datos del proyecto. Es el único archivo que llenás a mano; después: make generar.
proyecto: "$P"                 # nombre del trío: PM-<proyecto>, WK-<proyecto>, RV-<proyecto>
area: "pj-$P (completá en una frase)"
rama_base: "main"              # rama de los PR finales
# Repos hijos (vacío en proyectos de un solo repo). dir = carpeta local, ignorada en .gitignore.
repos: []
#  - dir: "rf-ejemplo"
#    repo: "robert-flo/ejemplo"
#    rama: "main"
#    nota: "qué es este repo en una frase"
# Specs en curso (texto libre o {ref, titulo}).
specs: []
notas: |
  Meta-repo de $P. Completá acá el contexto del proyecto.
# Skills extra por rol, además de plantillas/roles.yml.
skills_extra: {}
YML
fi
make generar && make check
git add -A
git diff --cached --quiet || git commit -q -m "feat: arranque de pj-$P desde pj-template"
git push -q origin HEAD

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
