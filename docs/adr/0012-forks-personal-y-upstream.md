# 0012. En cada fork: rama larga `personal` y espejo `upstream`

Fecha: 2026-10-26 · Estado: aceptado
Origen: fleet ADR 0024

## Decisión
1. En cada fork personal, los cambios de Roberto viven en una rama larga **`personal`**, que es la rama por defecto de GitHub y está protegida: todo entra por PR.
2. El espejo de la línea que se sigue del proyecto de origen es una **rama** llamada **`upstream`** (no solo el remoto git), que avanza solo por fast-forward.
3. Sincronizar es: fast-forward de `upstream` → rebase de `personal` sobre él → push, o un issue `[Conflicto Rebase]` si hay conflicto. Lo hace un workflow programado (diario, 04:00 UTC-6), nunca el trío por su cuenta; el trío actúa sobre un conflicto solo cuando Roberto lo pide.
4. En un fork que sigue el modelo, la rama del spec, el PR final y la revisión del RV apuntan a `personal` (ADR 0006, 0009). El RV del trío de ese proyecto revisa los PRs a `personal`.
5. **Excepción:** `robert-flo/omarchy-pkgs`, donde `personal` es un pin curado y no un overlay de `master`; su default sigue en `master` y no lleva el workflow de sincronización.

## Consecuencias
- Diferencia con el origen: la reescritura de `personal` en el rebase es del workflow de sincronización, no de un agente; los agentes siguen sin `--force` (`comun.md` §Git).
