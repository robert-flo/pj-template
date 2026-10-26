#!/usr/bin/env bash
# Imprime la ruta de un python con PyYAML y jsonschema. Primero prueba /usr/bin/python3 y el python3
# del PATH: si ya importan ambos en versiones >= las de requirements.txt, usa ese. Si no, usa el venv
# de pj (.pj/venv), que crea si falta.
# Nunca instala nada en el sistema ni usa sudo: todo queda en <raíz>/.pj/venv.
#   raíz = PJ_RAIZ (hijo) o pj-template; PJ_VENV=<dir> lo cambia.
# Reinstala cuando cambia el hash de requirements.txt (sello en .pj/venv/.pj-req.sha256).
# Uso: PY="$(bash scripts/py.sh)"; "$PY" scripts/generar.py
set -euo pipefail
T="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
R="${PJ_RAIZ:-$T}"
v="${PJ_VENV:-$R/.pj/venv}"
req="$T/requirements.txt"
h="$(sha256sum "$req" | cut -d' ' -f1)"
sirve(){ "$1" - "$req" 2>/dev/null <<'PYEOF'
import sys, re, importlib.metadata as md
import yaml, jsonschema  # noqa: F401
def t(v): return tuple(int(x) for x in re.findall(r"\d+", v)[:3])
for l in open(sys.argv[1]):
    l = l.split("#")[0].strip()
    if not l: continue
    n, _, v = l.partition("==")
    if t(md.version(n.strip())) < t(v): sys.exit(1)
PYEOF
}
if [ -z "${PJ_VENV:-}" ]; then
  for c in /usr/bin/python3 "$(command -v python3 || true)"; do
    [ -n "$c" ] && [ -x "$c" ] && sirve "$c" && { echo "$c"; exit 0; }
  done
fi
if [ -x "$v/bin/python" ] && [ "$(cat "$v/.pj-req.sha256" 2>/dev/null)" = "$h" ]; then echo "$v/bin/python"; exit 0; fi
if [ ! -x "$v/bin/python" ]; then
  base=python3; [ -x /usr/bin/python3 ] && base=/usr/bin/python3
  echo "pj: creando venv en $v (con $base)" >&2
  mkdir -p "$(dirname "$v")"
  "$base" -m venv "$v" >&2 || { echo "pj: no pude crear el venv con $base -m venv (¿falta el paquete python-venv?)" >&2; rm -rf "$v"; exit 1; }
fi
echo "pj: instalando $(tr '\n' ' ' < "$req")en $v" >&2
"$v/bin/python" -m pip install -q --disable-pip-version-check -r "$req" >&2
echo "$h" > "$v/.pj-req.sha256"
echo "$v/bin/python"
