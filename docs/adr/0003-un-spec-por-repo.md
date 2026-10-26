# 0003. Un spec por repo, enlazados

Fecha: 2026-10-26 · Estado: aceptado
Origen: fleet ADR 0004

## Decisión
Cada repo es una historia independiente con sus issues. Si una función toca varios repos del mismo proyecto, el PM escribe un spec en cada repo, cada uno enlazado a los otros, y publica los tickets en el repo al que pertenecen. Los mantiene alineados el PM, no un repo compartido.

## Consecuencias
- Regla en `.agents/reglas/pm.md` §Reglas de GitHub.
