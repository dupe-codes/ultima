SHELL := /bin/bash
LUA_VERSION := 5.5
LUA ?= lua5.5
LUAC ?= luac5.5
LUAROCKS ?= luarocks
LUA_TREE := $(CURDIR)/lua_modules

# TODO: also add the package to the .rockspec file
.PHONY: add
add: ## Add a lua dependency to the local project, usage: make add package=package-name
	$(LUAROCKS) --lua-version=$(LUA_VERSION) --tree "$(LUA_TREE)" install $(package)

.PHONY: install
install: ## Install project dependencies
	# sudo pacman -Sy pandoc
	brew install pandoc
	$(MAKE) install-local

.PHONY: install-local
install-local:
	$(LUA) -e 'assert(_VERSION == "Lua $(LUA_VERSION)", "Ultima requires Lua $(LUA_VERSION)")'
	$(LUAROCKS) --lua-version=$(LUA_VERSION) --tree "$(LUA_TREE)" install --deps-only ultima-dev-1.rockspec

.PHONY: check
check:
	@find src scripts -type f -name '*.lua' -exec $(LUAC) -p {} +
	@$(LUA) scripts/check-runtime.lua
	@LUA_INIT=@src/setup.lua $(LUA) scripts/check-dependencies.lua

SITES := $(shell find sites -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)

.PHONY: list-sites
list-sites: ## List all available sites
	@echo "Available sites:"
	@for site in $(SITES); do \
		echo "  - $$site"; \
	done

.PHONY: build-all
build-all: $(SITES) ## Build all sites

.PHONY: $(SITES)
$(SITES): ## Build a specific site
	@echo ""
	@echo "Building site: $@"
	@source $(CURDIR)/project.env && $(LUA) src/ultima.lua $@

# Site-specific targets with force flag
.PHONY: $(addsuffix -f,$(SITES))
$(addsuffix -f,$(SITES)): ## Force build a specific site
	@echo "Force building site: $(subst -f,,$@)"
	@source $(CURDIR)/project.env && $(LUA) src/ultima.lua -f $(subst -f,,$@)

# Site-specific targets for production
.PHONY: $(addsuffix -prod,$(SITES))
$(addsuffix -prod,$(SITES)): ## Build a specific site for production
	@echo "Building site for production: $(subst -prod,,$@)"
	@source $(CURDIR)/project.env && $(LUA) src/ultima.lua -f --env prod $(subst -prod,,$@)

.PHONY: deploy
deploy: ## Build & deploy a specific site to production, usage: make deploy site=site-name
	@if [ -z "$(site)" ]; then \
		echo "Error: site parameter is required. Usage: make deploy site=site-name"; \
		exit 1; \
	fi
	rm -rf deploy/$(site)
	@echo ""
	@echo "Building $(site) for production..."
	@echo ""
	@source $(CURDIR)/project.env && $(LUA) src/ultima.lua -f --env prod $(site)
	@echo ""
	@./scripts/deploy.sh $(site)

.PHONY: deploy-all
deploy-all: ## Build & deploy all sites to production
	@for site in $(SITES); do \
		echo ""; \
		echo "=== Deploying $$site ==="; \
		$(MAKE) deploy site=$$site; \
	done

.PHONY: run
run: ## Run a specific site with local server, usage: make run site=site-name
	@if [ -z "$(site)" ]; then \
		echo "Error: site parameter is required. Usage: make run site=site-name"; \
		exit 1; \
	fi
	@source $(CURDIR)/project.env && $(LUA) src/ultima.lua $(site)
	@echo "Starting local server at http://localhost:8000"
	@cd build/$(site) && python3 -m http.server 8000

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
	@echo ""
	@echo "Site-specific targets are available:"
	@echo "  make <site>       - Build a specific site"
	@echo "  make <site>-f     - Force build a specific site"
	@echo "  make <site>-prod  - Build a specific site for production"
	@echo ""
	@echo "Available sites:"
	@for site in $(SITES); do \
		echo "  - $$site"; \
	done
