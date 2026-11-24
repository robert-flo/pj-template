.PHONY: check generar humo skills deriva

##@ Template (pj-template)
check: ## Esquema de proyecto.yml, idempotencia, sin {{ }}, skills y prueba de humo
	bash $(TPL)/scripts/check.sh

generar: ## Regenera fichas y adaptadores desde proyecto.yml
	$(PY) $(TPL)/scripts/generar.py

humo: ## Prueba de humo del trío; con agy instalado, además arranca PM-<proyecto> sin interacción
ifeq ($(DRY_RUN),1)
	@echo -e "$(YELLOW)[DRY_RUN]$(RESET) HUMO_AGY=$${HUMO_AGY:-1} $(PY) $(TPL)/scripts/humo.py"
else
	HUMO_AGY=$${HUMO_AGY:-1} $(PY) $(TPL)/scripts/humo.py
endif

skills: ## (pj-template) Sincroniza skills desde un checkout local: make skills SKILLS=../fo-skills
ifeq ($(DRY_RUN),1)
	@echo -e "$(YELLOW)[DRY_RUN]$(RESET) bash $(TPL)/scripts/sync-skills.sh $(SKILLS) && $(PY) $(TPL)/scripts/generar.py"
else
	bash $(TPL)/scripts/sync-skills.sh $(SKILLS) && $(PY) $(TPL)/scripts/generar.py
endif

deriva: ## (pj-template) Informe de deriva de los hijos de family.yml
	bash $(TPL)/scripts/deriva.sh
