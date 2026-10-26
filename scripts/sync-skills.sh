#!/usr/bin/env bash
# Regenera .agents/skills/ y skills-lock.json desde un checkout de robert-flo/skills (rama personal).
# Uso: scripts/sync-skills.sh <ruta-al-checkout-de-skills>
# Promovidas: skills/{engineering,productivity,in-progress}/*. Quedan fuera misc/ y deprecated/.
set -euo pipefail
PY="${PY:-$(bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../scripts/py.sh")}"; export PY
raiz="$(cd "$(dirname "$0")/.." && pwd)"
src="${1:?uso: sync-skills.sh <checkout-de-robert-flo/skills>}"
src="$(cd "$src" && pwd)"
[ -d "$src/skills" ] || { echo "No encuentro $src/skills" >&2; exit 1; }
dst="$raiz/.agents/skills"
rm -rf "$dst"; mkdir -p "$dst"
entradas=()
for d in "$src"/skills/{engineering,productivity,in-progress}/*/; do
  [ -f "$d/SKILL.md" ] || continue
  n="$(basename "$d")"
  [ -e "$dst/$n" ] && { echo "Skill duplicada: $n" >&2; exit 1; }
  cp -R "${d%/}" "$dst/$n"
  # agy y Cursor esconden del modelo las skills con `disable-model-invocation: true` (solo quedan como
  # /comando manual), y el trío PM/WK/RV no podría seguir el flujo de Matt Pocock solo. La copia del
  # template las deja invocables; robert-flo/skills sigue siendo la única fuente.
  "$PY" - "$dst/$n/SKILL.md" <<'PYX'
import pathlib, re, sys
f = pathlib.Path(sys.argv[1]); t = f.read_text()
m = re.match(r"(---\n.*?\n)(---\n)", t, re.S)
if m: f.write_text(re.sub(r"(?m)^disable-model-invocation:[ \t]*true[ \t]*\n", "", m.group(1)) + t[len(m.group(1)):])
PYX
  rel="${d#"$src"/}"; rel="${rel%/}"
  hash="$(cd "$dst/$n" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum | cut -d' ' -f1)"
  entradas+=("$n"$'\t'"$rel/SKILL.md"$'\t'"$hash")
done
printf '%s\n' "${entradas[@]}" | LC_ALL=C sort | "$PY" -c '
import json, sys
s = {}
for l in sys.stdin.read().splitlines():
    n, p, h = l.split("\t")
    s[n] = {"source": "robert-flo/skills", "sourceType": "github", "ref": "personal", "skillPath": p, "computedHash": h}
print(json.dumps({"version": 1, "skills": s}, indent=2, ensure_ascii=False))
' > "$raiz/skills-lock.json"
echo "skills: ${#entradas[@]} sincronizadas desde $(git -C "$src" rev-parse --short HEAD 2>/dev/null || echo '?')"
