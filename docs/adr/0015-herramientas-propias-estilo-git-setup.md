# 0015. Las herramientas propias siguen el diseño de git-setup

Fecha: 2026-10-26 · Estado: aceptado

## Contexto
Las herramientas de Roberto que salen de rf-tools a duos `ravn-<tool>` + `ravn-<tool>-arch` se escribían cada una a su manera, a veces como un bash monolítico. git-setup (`robert-flo/pj-domina-rf-git-setup` + `-arch`) ya tiene un diseño modular y un lenguaje visual que Roberto quiere en todas.

## Decisión
- Toda herramienta propia nueva (de git-setup, de shared_dir o en un duo `ravn-<tool>`) se arma con el diseño modular de git-setup. Nunca un bash monolítico.
- Usa el mismo lenguaje visual: colores, banners, helpers de mensajes y formato de `--help`.
- Se copia de git-setup (y el `-arch` de `git-setup-arch`) cambiando lo mínimo.
- El RV pone **BLOQUEO** a un PR de herramienta propia que no siga esto.

## Consecuencias
- Regla en `.agents/reglas/comun.md`, sección «Herramientas propias: el estilo de git-setup» (PR #12).
