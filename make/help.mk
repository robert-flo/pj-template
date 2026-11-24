.PHONY: help

##@ Ayuda
help: ## Muestra esta ayuda categorizada
	@echo -e "$(BOLD)$(CYAN)$(DIVIDER)$(RESET)"
	@echo -e "$(BOLD)$(CYAN)  pj-template — Plantilla única de tríos PM / WK / RV / OS$(RESET)"
	@echo -e "$(BOLD)$(CYAN)$(DIVIDER)$(RESET)"
	@awk 'BEGIN {FS = ":.*## "} \
		/^##@/ {printf "\n$(BOLD)$(BLUE)%s$(RESET)\n", substr($$0, 5); next} \
		/^[a-zA-Z0-9_-]+:.*## / {printf "  $(GREEN)%-14s$(RESET) %s\n", $$1, $$2}' \
		$(MAKEFILE_LIST)
	@echo ""
	@echo -e "$(BOLD)$(YELLOW)Quick Actions:$(RESET)"
	@echo -e "  $(CYAN)make check$(RESET)              Valida esquema, idempotencia, skills y humo"
	@echo -e "  $(CYAN)make generar$(RESET)            Regenera fichas y adaptadores desde proyecto.yml"
	@echo -e "  $(CYAN)./pj <target>$(RESET)           Invoca un target desde un Home Repo hijo"
	@echo -e "  $(CYAN)DRY_RUN=1 make <target>$(RESET) Simula targets operacionales (skills, humo, clonar, clean, nuevo-hijo)"
	@echo -e "$(BOLD)$(CYAN)$(DIVIDER)$(RESET)"
