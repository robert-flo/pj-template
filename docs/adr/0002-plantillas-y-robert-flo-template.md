# 0002. Los agentes siguen plantillas y los repos parten de robert-flo/Template

Fecha: 2026-10-26 · Estado: aceptado
Origen: fleet ADR 0002, fleet ADR 0006

## Contexto
Roberto quiere que todos sus repos y proyectos se vean igual. Un agente que improvisa estructura (carpetas, etiquetas, tableros) crea un dialecto nuevo en cada repo.

## Decisión
- Los agentes aplican las plantillas que da Roberto; nunca inventan estructura. La plantilla de los meta-repos es este repo; la de los repos de código es `robert-flo/Template`.
- **Repos Bash:** se crean con «Use this template» de `robert-flo/Template` (historia nueva), y después `make repository-bootstrap` y `make verify`.
- **Otro stack** (Android, iOS, Rust…): se copian solo los archivos para agentes: `docs/agents/` (`issue-tracker.md`, `triage-labels.md`, `domain.md`), `AGENTS.md`, `COMMIT_MESSAGE_GUIDELINES.md` y `RELEASE_POLICY.md`. Las secciones de Bash de `AGENTS.md` se adaptan al stack; la de skills queda igual.
- **Referencia:** para CI, lint, Makefile, pre-commit, releases o plantillas de issue y PR, primero se mira `robert-flo/Template`.
- Esos archivos ya configuran las skills de Matt Pocock (GitHub Issues con `gh`, etiquetas de triage, `GLOSSARY.md` + `docs/adr/`), así que no se corre `setup-matt-pocock-skills` a ciegas: se copian o verifican. Títulos de issue `<número> - <título>` (crear y renombrar) y dependencias nativas de GitHub para los bloqueos.

## Consecuencias
- El setup de un repo entra como trivial con `ready-for-agent` y lo hace el WK (`.agents/reglas/pm.md` §Setup).
