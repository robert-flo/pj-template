.PHONY: clonar agy onboard clean nuevo-hijo

##@ Home Repos Hijos (./pj <target>)
clonar: ## Clona los repos de proyecto.yml
ifeq ($(DRY_RUN),1)
	@echo -e "$(YELLOW)[DRY_RUN]$(RESET) bash $(TPL)/clone-repos.sh"
else
	bash $(TPL)/clone-repos.sh
endif

agy: ## Enlaza las fichas en ~/.gemini/config/agents
	bash $(TPL)/scripts/instalar-agy.sh

onboard: ## Entrevista de onboarding (onboarding.yml, ADR 0017); idempotente. En un hijo: ./pj onboard [--mostrar|--si|--respuestas F]
	$(PY) $(TPL)/scripts/onboard.py $(ARGS)

clean: ## Deshace ./pj listo (y con --onboarding, el onboarding). Vive en ./pj porque borra el template: en un hijo, ./pj clean [--onboarding]
ifeq ($(DRY_RUN),1)
	@if [ "$(PJ_RAIZ)" = "$(TPL)" ]; then \
		echo -e "$(YELLOW)[DRY_RUN]$(RESET) make clean es de los hijos: ./pj clean [--onboarding]"; \
	else \
		echo -e "$(YELLOW)[DRY_RUN]$(RESET) cd \"$(PJ_RAIZ)\" && ./pj clean $(ARGS)"; \
	fi
else
	@if [ "$(PJ_RAIZ)" = "$(TPL)" ]; then echo "make clean es de los hijos: ./pj clean [--onboarding] (borra .pj/, lo generado, hooks, enlaces de agy y clones limpios)"; else cd "$(PJ_RAIZ)" && ./pj clean $(ARGS); fi
endif

nuevo-hijo: ## (pj-template) Crea robert-flo/pj-<P> en modo dependencia: make nuevo-hijo P=<nombre> [DIR=<carpeta>]
ifeq ($(DRY_RUN),1)
	@echo -e "$(YELLOW)[DRY_RUN]$(RESET) bash $(TPL)/scripts/nuevo-hijo.sh \"$(P)\" \"$(DIR)\""
else
	bash $(TPL)/scripts/nuevo-hijo.sh "$(P)" "$(DIR)"
endif
