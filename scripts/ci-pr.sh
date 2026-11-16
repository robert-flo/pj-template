#!/usr/bin/env bash
# Paso de PR de pj-sync: si ci-sync.sh dejó cambios, los sube en una rama y abre el PR
# (cierra los PR de sync viejos). Usa MENSAJE y TITULO de ci-sync.sh y GH_TOKEN.
set -euo pipefail
if [ -z "$(git status --porcelain)" ]; then echo "Sin cambios."; exit 0; fi
base="$(git rev-parse --abbrev-ref HEAD)"
rama="pj-template/sync-${GITHUB_RUN_ID}"
git config user.name "Roberto Flores"
git config user.email "25asab015@ujmd.edu.sv"
git switch -c "$rama"
git add -A
git commit -q -m "$MENSAJE" -m "Generado por pj-sync; no se edita a mano."
git push -q origin "$rama"
body="$(mktemp)"
{
  echo "## Summary"
  echo "$MENSAJE"
  echo; echo '```'; git show --stat --format= HEAD | tail -n 40; echo '```'
  echo; echo "## Evidence"; echo "El check pasó en el run ${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}."
  echo; echo "## Merge Danger"; echo "Door: de dos vías (revertible). Blast radius: reglas, skills y fichas del trío de este repo."
} > "$body"
url="$(gh pr create --base "$base" --head "$rama" --title "$TITULO" --body-file "$body")"
echo "PR: $url"
gh pr list --state open --json number,headRefName --jq '.[] | select(.headRefName|startswith("pj-template/sync-")) | select(.headRefName != "'"$rama"'") | .number' |
  while read -r n; do gh pr close "$n" --delete-branch --comment "Reemplazado por $url"; done
