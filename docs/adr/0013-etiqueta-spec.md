# 0013 - Etiqueta `spec` y etiquetas sincronizadas

## Contexto
El spec padre se publicaba con `ready-for-agent`, la misma señal que sus tickets, así que un WK podía tomarlo como trabajo. Además ningún repo creaba las etiquetas de triage: dependían de que alguien corriera `gh label create` a mano.

## Decisión
- El issue del spec lleva `spec` y nunca `ready-for-agent`; solo sus sub-issues llevan `ready-for-agent`.
- Las etiquetas viven en `schema/etiquetas.tsv`. `scripts/etiquetas.sh` las crea o actualiza con `gh label create --force`, y pj-sync lo corre en cada repo que lo llama (cada hijo en cada aviso y a diario), sin esperar el merge del PR de sync.

## Consecuencias
- El token `PJ_TEMPLATE_TOKEN` de cada hijo necesita Issues: write; si no lo tiene, el paso deja un warning y no rompe el sync.
