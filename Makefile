# En pj-template: make <target>. En un hijo (modo dependencia): ./pj <target> (usa este Makefile desde .pj/tpl).
TPL := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
export PJ_RAIZ ?= $(TPL)
# Python del venv .pj/venv (PyYAML + jsonschema de requirements.txt); nunca el del sistema.
PY ?= $(shell bash $(TPL)/scripts/py.sh)
export PY
.PHONY: check generar humo skills clonar agy nuevo-hijo deriva
check:      ## Esquema de proyecto.yml, idempotencia, sin {{ }}, skills y prueba de humo
	bash $(TPL)/scripts/check.sh
generar:    ## Regenera fichas y adaptadores desde proyecto.yml
	$(PY) $(TPL)/scripts/generar.py
humo:       ## Prueba de humo del trío; con agy instalado, además arranca PM-<proyecto> sin interacción
	HUMO_AGY=$${HUMO_AGY:-1} $(PY) $(TPL)/scripts/humo.py
skills:     ## (pj-template) Sincroniza skills desde un checkout local: make skills SKILLS=../fo-skills
	bash $(TPL)/scripts/sync-skills.sh $(SKILLS) && $(PY) $(TPL)/scripts/generar.py
clonar:     ## Clona los repos de proyecto.yml
	bash $(TPL)/clone-repos.sh
agy:        ## Enlaza las fichas en ~/.gemini/config/agents
	bash $(TPL)/scripts/instalar-agy.sh
nuevo-hijo: ## (pj-template) Crea robert-flo/pj-<P> en modo dependencia: make nuevo-hijo P=<nombre> [DIR=<carpeta>]
	bash $(TPL)/scripts/nuevo-hijo.sh "$(P)" "$(DIR)"
deriva:     ## (pj-template) Informe de deriva de los hijos de family.yml
	bash $(TPL)/scripts/deriva.sh
