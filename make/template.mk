.PHONY: check generar humo skills nuevo-hijo deriva

##@ Template (pj-template)
check: ## Esquema de proyecto.yml, idempotencia, sin {{ }}, skills y prueba de humo
	bash $(TPL)/scripts/check.sh

generar: ## Regenera fichas y adaptadores desde proyecto.yml
	$(PY) $(TPL)/scripts/generar.py

humo: ## Prueba de humo del trío; con agy instalado, además arranca PM-<proyecto> sin interacción
	$(call run_op,HUMO_AGY=$${HUMO_AGY:-1} $(PY) $(TPL)/scripts/humo.py)

skills: ## (pj-template) Sincroniza skills desde un checkout local: make skills SKILLS=../fo-skills
	$(call run_op,bash $(TPL)/scripts/sync-skills.sh $(SKILLS) && $(PY) $(TPL)/scripts/generar.py)

nuevo-hijo: ## (pj-template) Crea robert-flo/pj-<P> en modo dependencia: make nuevo-hijo P=<nombre> [DIR=<carpeta>]
	$(call run_op,bash $(TPL)/scripts/nuevo-hijo.sh "$(P)" "$(DIR)")

deriva: ## (pj-template) Informe de deriva de los hijos de family.yml
	bash $(TPL)/scripts/deriva.sh
