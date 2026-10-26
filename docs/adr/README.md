# ADRs de pj-template

Decisiones vigentes de los tríos PM/WK/RV, para cualquier plataforma (Cursor y agy). Cada ADR dice de dónde viene con una línea `Origen:`. Las reglas que siguen los agentes están en `.agents/reglas/`; si un ADR y una regla chocan, se corrige la regla por PR. Los términos están en `GLOSSARY.md` de la raíz.

| ADR | Decisión | Origen |
| --- | --- | --- |
| [0001](0001-trio-fijo-por-proyecto.md) | Un trío fijo por proyecto: el PM planifica, el WK programa, el RV revisa | fleet 0001, 0019 |
| [0002](0002-plantillas-y-robert-flo-template.md) | Los agentes siguen plantillas y los repos parten de robert-flo/Template | fleet 0002, 0006 |
| [0003](0003-un-spec-por-repo.md) | Un spec por repo, enlazados | fleet 0004 |
| [0004](0004-guardarrailes-del-pm.md) | Guardarraíles del PM: contrato de entrega, sin rutinas, escalar | fleet 0005 |
| [0005](0005-flujo-de-pedidos-y-skills-del-pm.md) | Flujo de pedidos y skills del PM | fleet 0008, 0009, 0010 |
| [0006](0006-rama-del-spec-y-modelo-de-terminado.md) | Rama del spec y cuándo algo está hecho | fleet 0011 |
| [0007](0007-el-wk.md) | El WK: el Engineer Bot de Lingxi, adaptado | fleet 0012 |
| [0008](0008-primer-mensaje-y-restate.md) | Primer mensaje fijo y un restate que para y pregunta | fleet 0013 |
| [0009](0009-rv-en-el-pr-final.md) | El RV revisa el PR final | fleet 0017 |
| [0010](0010-robert-flo-template-es-infraestructura.md) | robert-flo/Template es infraestructura | fleet 0021 |
| [0011](0011-trabajo-sobre-la-maquina.md) | El trío también opera la máquina donde corre | fleet 0022 |
| [0012](0012-forks-personal-y-upstream.md) | En cada fork: `personal` y espejo `upstream` | fleet 0024 |
| [0013](0013-etiqueta-spec.md) | Etiqueta `spec` y etiquetas sincronizadas | — |

Las decisiones propias de antigravity-fleet (archivado) siguen en `docs/adr-antigravity/`.

Un ADR nuevo toma el número siguiente, lleva `Fecha`, `Estado` y, si viene de otro lado, `Origen`.
