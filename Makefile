.PHONY: check generar skills clonar agy
check:      ## Verifica idempotencia, sin {{ }} y coherencia de skills
	bash scripts/check.sh
generar:    ## Regenera fichas y adaptadores desde proyecto.yml
	python3 scripts/generar.py
skills:     ## Sincroniza skills desde un checkout local: make skills SKILLS=../fo-skills
	bash scripts/sync-skills.sh $(SKILLS) && python3 scripts/generar.py
clonar:     ## Clona los repos de proyecto.yml
	./clone-repos.sh
agy:        ## Enlaza las fichas en ~/.gemini/config/agents
	bash scripts/instalar-agy.sh
