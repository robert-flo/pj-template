#!/usr/bin/env bash
# Enlaza las fichas de este meta-repo en ~/.gemini/config/agents (una vez por máquina y proyecto).
# agy en modo interactivo resuelve `--agent` solo con los agentes globales al arrancar; si no
# encuentra el nombre, cae al agente default sin herramientas. Aprendido en antigravity-fleet.
set -euo pipefail
raiz="$(cd "$(dirname "$0")/.." && pwd)"
dst="$HOME/.gemini/config/agents"
mkdir -p "$dst"
for a in "$raiz"/.agents/agents/*.md; do
  n="$(basename "$a")"
  if [ -e "$dst/$n" ] && [ ! -L "$dst/$n" ]; then echo "salto $n (existe y no es enlace)"; continue; fi
  ln -sfn "$a" "$dst/$n"; echo "enlazado $n"
done
