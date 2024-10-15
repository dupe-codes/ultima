# TODO: also add the package to the .rockspec file
.PHONY: add
add: ## Add a lua dependency to the local project, usage: make add package=package-name
	luarocks install --tree lua_modules $(package)

.PHONY: install
install: ## Install project dependencies
	luarocks install --tree lua_modules --deps-only ultima-dev-1.rockspec

.PHONY: build-f
build-f: ## Force build the ultima site
	@source $(CURDIR)/project.env && ./src/ultima.lua -f

.PHONY: build
build: ## Build the ultima site
	@source $(CURDIR)/project.env && ./src/ultima.lua

.PHONY: build-deploy
build-deploy: ## Build the ultima deployment version
	@source $(CURDIR)/project.env && ./src/ultima.lua -f --env prod

.PHONY: deploy
deploy: ## Build & deploy the ultima site to production
	rm -rf deploy/
	@source $(CURDIR)/project.env && ./src/ultima.lua -f --env prod
	./scripts/deploy.sh

.PHONY: run
run: build ## Run the ultima application
	xdg-open build/index.html

.PHONY: clean
clean: ## Clean compiled artifacts
	rm -rf build/
	rm -rf deploy/

.PHONY: lint
lint: ## Lint lua source files
	@luacheck src/

.PHONY: format
format: ## Format lua source files
	@stylua -v src/

.PHONY: docs
docs: ## Generate documentation
	@./lua_modules/bin/ldoc src/

.PHONY: help
help: ## Show this help
	@grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
