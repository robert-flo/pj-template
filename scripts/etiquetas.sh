#!/usr/bin/env bash
# Crea o actualiza en un repo las etiquetas de schema/etiquetas.tsv. Idempotente (gh label create --force).
# Uso: etiquetas.sh [owner/repo]   (sin argumento, el repo de la carpeta actual)
set -euo pipefail
tsv="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/schema/etiquetas.tsv"
repo=(); [ -n "${1:-}" ] && repo=(-R "$1")
grep -vE '^(#|$)' "$tsv" | while IFS=$'\t' read -r nombre color desc; do
  gh label create "$nombre" --color "$color" --description "$desc" --force "${repo[@]}" >/dev/null
  echo "etiqueta: $nombre"
done
