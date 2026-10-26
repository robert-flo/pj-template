# 0010. robert-flo/Template es infraestructura: el lenguaje común

Fecha: 2026-10-26 · Estado: aceptado
Origen: fleet ADR 0021

## Contexto
`robert-flo/Template` le da a todos los repos de Roberto un lenguaje común: estructura, convenciones, `AGENTS.md`, `GLOSSARY.md`, etiquetas, quality gate y flujo de PR. A diferencia de este repo, es código con specs, tickets y PRs, donde el trío rinde.

## Decisión
- Template tiene su propio trío.
- Un cambio al lenguaje común (estructura, convenciones, `AGENTS.md`, `GLOSSARY.md`, `docs/agents/`, etiquetas, quality gate o flujo de PR) necesita un ADR en `docs/adr/` de Template, en el mismo spec. Su PM lo pide al armar el spec y su RV pone BLOQUEO al PR que cambie el lenguaje común sin ADR.
- Propagación: cuando se mergea un cambio así, el PM de Template se lo dice a Roberto con el ADR y lo que cambia. Roberto decide a qué repos se propaga, y cada uno entra a su PM como pedido nuevo, con su flujo normal.
- Lo que no toca el lenguaje común (bugs, scripts, docs internas) sigue el flujo de siempre, sin ADR.
