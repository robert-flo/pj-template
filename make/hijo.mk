.PHONY: clonar agy onboard clean

##@ Home Repos Hijos (./pj <target>)
clonar: ## Clona los repos de proyecto.yml
	$(call run_op,bash $(TPL)/clone-repos.sh)

agy: ## Enlaza las fichas en ~/.gemini/config/agents
	bash $(TPL)/scripts/instalar-agy.sh

onboard: ## Entrevista de onboarding (onboarding.yml, ADR 0017); idempotente. En un hijo: ./pj onboard [--mostrar|--si|--respuestas F]
	$(PY) $(TPL)/scripts/onboard.py $(ARGS)

clean: ## Deshace ./pj listo (y con --onboarding, el onboarding). Vive en ./pj porque borra el template: en un hijo, ./pj clean [--onboarding]
ifeq ($(PJ_RAIZ),$(TPL))
	@echo "make clean es de los hijos: ./pj clean [--onboarding] (borra .pj/, lo generado, hooks, enlaces de agy y clones limpios)"
else
	$(call run_op,cd "$(PJ_RAIZ)" && ./pj clean $(ARGS))
endif
