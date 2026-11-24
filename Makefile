# En pj-template: make <target>. En un hijo (modo dependencia): ./pj <target> (usa este Makefile desde .pj/tpl).
SHELL := /bin/bash
.DEFAULT_GOAL := help

TPL := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
export PJ_RAIZ ?= $(TPL)
# Python del venv .pj/venv (PyYAML + jsonschema de requirements.txt); nunca el del sistema.
PY ?= $(shell bash $(TPL)/scripts/py.sh)
export PY

DRY_RUN ?= 0

ifndef NO_COLOR
BOLD   := \033[1m
DIM    := \033[2m
CYAN   := \033[36m
BLUE   := \033[34m
GREEN  := \033[32m
YELLOW := \033[33m
RED    := \033[31m
RESET  := \033[0m
else
BOLD   :=
DIM    :=
CYAN   :=
BLUE   :=
GREEN  :=
YELLOW :=
RED    :=
RESET  :=
endif

DIVIDER := ================================================================================

include $(TPL)/make/*.mk
