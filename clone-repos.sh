#!/usr/bin/env bash
# clone-repos.sh — clona y alinea los repos hijos listados en proyecto.yml. Seguro e idempotente.
# Nunca destruye cambios locales: si un clon tiene cambios, se queda en su rama y avisa.
# Flags: --dry-run | -n (o PJ_CLONAR_DRY_RUN=1) simula sin ejecutar gh/git sobre los repos.
set -euo pipefail

dry_run="${PJ_CLONAR_DRY_RUN:-0}"
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|-n) dry_run=1 ;;
    *) echo "clone-repos: opción desconocida: $1" >&2; exit 2 ;;
  esac
  shift
done

PY="${PY:-$(bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/py.sh")}"; export PY
cd "${PJ_RAIZ:-$(dirname "${BASH_SOURCE[0]}")}"

mapfile -t REPOS < <("$PY" -c '
import yaml
p = yaml.safe_load(open("proyecto.yml")) or {}
for r in (p.get("repos") or []) + (p.get("repos_externos") or []):
    print(r["dir"], r["repo"], r["rama"], sep="\t")
')

if [ "${#REPOS[@]}" -eq 0 ]; then
  echo "proyecto.yml no lista repos hijos: este proyecto es de un solo repo. Nada que clonar."
  exit 0
fi

for entry in "${REPOS[@]}"; do
  IFS=$'\t' read -r dir repo rama <<< "$entry"
  repo_name="${repo##*/}"
  if [ "$dry_run" = 1 ]; then
    if [ -d ".bares/$repo_name.git" ]; then
      echo "[dry-run] verificaría/actualizaría $repo en .bares/$repo_name.git y repos/$repo_name (rama $rama)"
      [ -d "$dir/.git" ] && echo "[dry-run] aviso: existe clon viejo en $dir/.git; podés limpiarlo cuando no tenga cambios locales con ./pj clean"
    elif [ -d "$dir/.git" ]; then
      echo "[dry-run] verificaría/actualizaría $dir ($repo -> $rama); sugeriría limpiar clon viejo con ./pj clean"
    else
      echo "[dry-run] clonaría $repo en .bares/$repo_name.git y repos/$repo_name (rama $rama)"
    fi
    continue
  fi
  echo ""
  echo "--- [$dir] ($repo -> $rama) ---"
  if [ -d "$dir/.git" ]; then
    echo "Aviso: existe un clon viejo en '$dir/.git'; cuando no tenga cambios locales podés limpiarlo con './pj clean'."
  fi
  bare_cmd="${PJ_CLONAR_CMD:-}"
  if [ -z "$bare_cmd" ] && command -v ravn-git-bare-clone >/dev/null 2>&1; then
    bare_cmd="ravn-git-bare-clone"
  fi
  if [ -n "$bare_cmd" ]; then
    BARE_HOME="$PWD/.bares" WORKTREES_HOME="$PWD/repos" "$bare_cmd" clone "$repo"
    echo "OK: $repo en .bares/$repo_name.git y repos/$repo_name"
    continue
  fi
  echo "Aviso: ravn-git-bare-clone no está instalado; usando fallback con gh repo clone."
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
if [ "$dry_run" = 1 ]; then
  echo "==> [dry-run] Repos del proyecto simulados (sin cambios en disco)."
else
  echo "==> Repos del proyecto verificados."
fi
