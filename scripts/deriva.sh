#!/usr/bin/env bash
# Informe de deriva: para cada hijo de family.yml, regenera desde el pj-template actual y compara
# los archivos que manda el template con los que el hijo tiene hoy.
#   modo dependencia: «hoy» = ./pj al template_ref del hijo; «actual» = mismo hijo con este checkout.
#   modo copia (hijos viejos): «hoy» = lo versionado; «actual» = sync-template.sh con este checkout.
# Salida: tabla markdown en stdout (y en $DERIVA_MD si está). Termina 0 aunque haya deriva;
# escribe DERIVA=<hijos con deriva> en $GITHUB_ENV. Uso: scripts/deriva.sh [hijo…] (gh autenticado).
set -euo pipefail
PY="${PY:-$(bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../scripts/py.sh")}"; export PY
T="$(cd "$(dirname "$0")/.." && pwd)"
mapfile -t HIJOS < <(if [ $# -gt 0 ]; then printf '%s\n' "$@"; else "$PY" -c 'import yaml;print("\n".join(yaml.safe_load(open("'"$T"'/family.yml"))["hijos"]))'; fi)
w="$(mktemp -d)"; trap 'rm -rf "$w"' EXIT
tsha="$(git -C "$T" rev-parse --short HEAD)"
out="$w/informe.md"; con_deriva=0
{ echo "## Deriva de los hijos frente a pj-template@$tsha"; echo
  echo "| Hijo | Modo | Idénticos | Distintos | Solo hoy | Solo nuevo |"; echo "| --- | --- | --- | --- | --- | --- |"; } > "$out"
detalle="$w/detalle.md"; : > "$detalle"
export PJ_TEMPLATE_TOKEN="${PJ_TEMPLATE_TOKEN:-${GH_TOKEN:-}}"
for h in "${HIJOS[@]}"; do
  d="$w/${h//\//_}"; mkdir -p "$d"
  if ! gh repo clone "$h" "$d/hoy" -- -q 2>"$d/err"; then echo "| \`$h\` | ? | no pude clonar | | | |" >> "$out"; continue; fi
  rm -rf "$d/hoy/.git"; cp -a "$d/hoy" "$d/nuevo"
  if [ -x "$d/hoy/pj" ] && grep -qE '^template_ref:' "$d/hoy/proyecto.yml"; then
    modo=dependencia
    ok=1
    ( cd "$d/hoy" && ./pj >/dev/null 2>"$d/err" ) || ok=0
    ( cd "$d/nuevo" && cp "$T/plantillas/hijo/pj" pj && cp "$T/plantillas/hijo/pj-template.yml" .github/workflows/ \
      && PJ_TEMPLATE_DIR="$T" ./pj >/dev/null 2>>"$d/err" ) || ok=0
    lista(){ cat "$1/.agents/generados.txt" 2>/dev/null; echo pj; echo .github/workflows/pj-template.yml; echo .gitignore; }
  else
    modo=copia
    ok=1
    ( cd "$d/nuevo" && bash "$T/scripts/sync-template.sh" "$T" >/dev/null 2>"$d/err" ) || ok=0
    lista(){ cat "$1/.agents/generados.txt" 2>/dev/null; echo .gitignore
             ( cd "$1" && grep -vE '^\s*(#|$)' "$T/template-paths.txt" | while read -r p; do [ -e "$p" ] && find "$p" -type f; done ) 2>/dev/null; }
  fi
  if [ "$ok" = 0 ]; then
    echo "| \`$h\` | $modo | no regenera | | | |" >> "$out"
    { echo "### $h"; echo '```'; tail -n 15 "$d/err"; echo '```'; } >> "$detalle"; con_deriva=$((con_deriva+1)); continue
  fi
  mapfile -t todos < <({ lista "$d/hoy"; lista "$d/nuevo"; } | sed 's|^\./||' | LC_ALL=C sort -u)
  igual=0; dif=(); solo_hoy=(); solo_nuevo=()
  for f in "${todos[@]}"; do
    if [ -f "$d/hoy/$f" ] && [ -f "$d/nuevo/$f" ]; then cmp -s "$d/hoy/$f" "$d/nuevo/$f" && igual=$((igual+1)) || dif+=("$f")
    elif [ -f "$d/hoy/$f" ]; then solo_hoy+=("$f"); else solo_nuevo+=("$f"); fi
  done
  n=${#todos[@]}; pct=$(( n ? igual*100/n : 100 ))
  echo "| \`$h\` | $modo | $igual/$n ($pct %) | ${#dif[@]} | ${#solo_hoy[@]} | ${#solo_nuevo[@]} |" >> "$out"
  if [ $(( ${#dif[@]} + ${#solo_hoy[@]} + ${#solo_nuevo[@]} )) -gt 0 ]; then
    con_deriva=$((con_deriva+1))
    { echo "### $h ($pct % idéntico)"; echo '```'
      for f in "${dif[@]}"; do printf '~ %s  %s\n' "$f" "$(diff "$d/hoy/$f" "$d/nuevo/$f" | grep -c '^[<>]' || true) líneas"; done | head -n 25
      for f in "${solo_hoy[@]}"; do echo "- $f"; done | head -n 15
      for f in "${solo_nuevo[@]}"; do echo "+ $f"; done | head -n 15
      echo '```'; } >> "$detalle"
  fi
done
{ echo; echo "Hijos con deriva: $con_deriva de ${#HIJOS[@]}."; echo; cat "$detalle"
  echo; echo "Leyenda: ~ distinto · - solo en el hijo hoy · + solo al regenerar con el template actual."; } >> "$out"
cat "$out"
[ -n "${DERIVA_MD:-}" ] && cp "$out" "$DERIVA_MD"
[ -n "${GITHUB_ENV:-}" ] && echo "DERIVA=$con_deriva" >> "$GITHUB_ENV"
exit 0
