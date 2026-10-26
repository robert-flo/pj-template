#!/usr/bin/env bash
# Trae a este meta-repo hijo los archivos que manda pj-template y regenera.
# Uso (desde la raíz del hijo): bash <tpl>/scripts/sync-template.sh <ruta-a-un-checkout-de-robert-flo/pj-template>
# Lo corre el workflow reutilizable pj-sync.yml; también sirve a mano.
set -euo pipefail
raiz="$(pwd)"   # se corre desde la raíz del meta-repo hijo
tpl="$(cd "${1:?uso: sync-template.sh <checkout-de-pj-template>}" && pwd)"
[ "$tpl" = "$raiz" ] && { echo "Este es pj-template: nada que traer."; exit 0; }
while IFS= read -r ruta; do
  ruta="${ruta%%#*}"; ruta="$(echo "$ruta" | xargs)"; [ -n "$ruta" ] || continue
  if [ -d "$tpl/$ruta" ]; then
    rm -rf "${raiz:?}/$ruta"; mkdir -p "$(dirname "$raiz/$ruta")"; cp -R "$tpl/$ruta" "$raiz/$ruta"
  elif [ -f "$tpl/$ruta" ]; then
    mkdir -p "$(dirname "$raiz/$ruta")"; cp -p "$tpl/$ruta" "$raiz/$ruta"
  fi
done < "$tpl/template-paths.txt"
python3 "$raiz/scripts/generar.py"
