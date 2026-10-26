#!/usr/bin/env bash
# Paso de sync de pj-sync.yml. Se corre desde la raíz del repo que llama.
# Uso: ci-sync.sh <checkout-de-pj-template@main> <checkout-de-robert-flo/skills>
# Modos:
#   dependencia (hay ./pj y template_ref): sube template_ref al SHA de main de pj-template y
#     actualiza ./pj y el caller; ./pj check con el SHA nuevo. Nada más se versiona.
#   molde (pj-template): sincroniza skills desde robert-flo/skills y regenera.
#   copia (hijos viejos, sin template_ref): copia template-paths.txt, sincroniza skills, regenera.
# Escribe MENSAJE y TITULO en $GITHUB_ENV para el commit y el PR.
set -euo pipefail
tpl="$(cd "$1" && pwd)"; skills="$(cd "$2" && pwd)"
env_out="${GITHUB_ENV:-/dev/null}"
sha="$(git -C "$tpl" rev-parse HEAD)"; skills_sha="$(git -C "$skills" rev-parse --short HEAD)"
if [ -x pj ] && grep -qE '^template_ref:' proyecto.yml; then
  viejo="$(sed -nE 's/^template_ref:[[:space:]]*["'\'']?([0-9a-f]{40}).*/\1/p' proyecto.yml)"
  if [ "$viejo" != "$sha" ]; then
    sed -i -E "s/^(template_ref:[[:space:]]*[\"']?)[0-9a-f]{40}/\1$sha/" proyecto.yml
  fi
  cp "$tpl/plantillas/hijo/pj" pj; chmod +x pj
  mkdir -p .github/workflows; cp "$tpl/plantillas/hijo/pj-template.yml" .github/workflows/pj-template.yml
  ./pj check
  echo "TITULO=pj-template: template_ref → ${sha:0:12}" >> "$env_out"
  echo "MENSAJE=chore(pj-template): template_ref ${viejo:0:12} → ${sha:0:12}" >> "$env_out"
elif [ "$tpl" = "$(pwd)" ]; then
  bash scripts/sync-skills.sh "$skills"; python3 scripts/generar.py; bash scripts/check.sh
  echo "TITULO=pj-template: sync de skills" >> "$env_out"
  echo "MENSAJE=chore(pj-template): sync de skills (robert-flo/skills@$skills_sha)" >> "$env_out"
else
  bash "$tpl/scripts/sync-template.sh" "$tpl"
  bash scripts/sync-skills.sh "$skills"; python3 scripts/generar.py; bash scripts/check.sh
  echo "TITULO=pj-template: sync de reglas y skills" >> "$env_out"
  echo "MENSAJE=chore(pj-template): sync de reglas, plantillas y skills (pj-template@${sha:0:7} · skills@$skills_sha)" >> "$env_out"
fi
