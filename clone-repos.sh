#!/usr/bin/env bash
# clone-repos.sh — clona y alinea los repos hijos listados en proyecto.yml. Seguro e idempotente.
# Nunca destruye cambios locales: si un clon tiene cambios, se queda en su rama y avisa.
set -euo pipefail
cd "${PJ_RAIZ:-$(dirname "${BASH_SOURCE[0]}")}"

mapfile -t REPOS < <(python3 -c '
import yaml
p = yaml.safe_load(open("proyecto.yml")) or {}
for r in p.get("repos") or []:
    print(r["dir"], r["repo"], r["rama"], sep="\t")
')

if [ "${#REPOS[@]}" -eq 0 ]; then
  echo "proyecto.yml no lista repos hijos: este proyecto es de un solo repo. Nada que clonar."
  exit 0
fi

for entry in "${REPOS[@]}"; do
  IFS=$'\t' read -r dir repo rama <<< "$entry"
  echo ""
  echo "--- [$dir] ($repo -> $rama) ---"
  if [ ! -d "$dir/.git" ]; then
    gh repo clone "$repo" "$dir"
  else
    git -C "$dir" fetch --prune origin
  fi
  if ! git -C "$dir" show-ref --verify --quiet "refs/heads/$rama"; then
    if git -C "$dir" show-ref --verify --quiet "refs/remotes/origin/$rama"; then
      git -C "$dir" branch --track "$rama" "origin/$rama"
    else
      echo "Aviso: $repo no tiene la rama $rama."; continue
    fi
  fi
  actual="$(git -C "$dir" branch --show-current || true)"
  if [ "$actual" != "$rama" ]; then
    if git -C "$dir" diff --quiet && git -C "$dir" diff --cached --quiet; then
      git -C "$dir" checkout -q "$rama"
    else
      echo "Aviso: $dir está en '$actual' con cambios locales; no lo muevo."; continue
    fi
  fi
  if git -C "$dir" diff --quiet && git -C "$dir" diff --cached --quiet; then
    git -C "$dir" pull --rebase --autostash -q || echo "Aviso: no pude actualizar $dir."
  fi
  echo "OK: $dir en $(git -C "$dir" branch --show-current)"
done
echo ""
echo "==> Repos del proyecto verificados."
