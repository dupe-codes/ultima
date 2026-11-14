# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ultima is a Lua-based static site generator that builds multiple content-rich websites from markdown files. Run `make list-sites` to list the available sites.

## Runtime and Local Dependencies

Ultima requires Lua 5.5, LuaRocks configured for Lua 5.5, and Pandoc. Install these tools before you install project dependencies. The runtime rejects other Lua versions before it configures module paths.

Run these commands from the repository root:

```bash
make install-local
make check
make list-sites
make build-all
make build-all
```

`install-local` runs `luarocks --lua-version=5.5 --tree "$PWD/lua_modules" install --deps-only ultima-dev-1.rockspec`. It does not install Pandoc or change global packages. It compiles native dependencies against Lua 5.5. Do not copy native modules from a Lua 5.4 tree.

The rockspec pins argparse to `0.7.2-1`, dkjson to `2.8-2`, date to `2.2.1-2`, and LuaFileSystem to `1.9.0-1` for Lua 5.5 compatibility. It does not require the unused ltui dependency.

The Makefile selects `lua5.5` and `luac5.5` by default. Use `make LUA=/path/to/lua5.5 LUAC=/path/to/luac5.5 LUAROCKS=/path/to/luarocks check` to select explicit executables. The installation target always selects Lua 5.5 for LuaRocks.

`make check` checks Lua syntax, tests the runtime guard, and runs dependency smoke checks. The smoke checks exercise argument parsing, JSON, dates, TOML, filesystem access, and MD5.

Build and run targets load `project.env`, which sets `LUA_INIT=@src/setup.lua`. For direct execution, use `LUA_INIT=@src/setup.lua lua5.5 src/ultima.lua dupe_sh`. The setup file resolves modules from `lua_modules/share/lua/5.5` and `lua_modules/lib/lua/5.5` first.

`make build-all` builds development output without publishing. Production build targets write to `deploy/`. The deployment targets publish output. Do not run them for verification. The existing `make install` target also runs `brew install pandoc`; use `make install-local` when Pandoc is already available.

## Build Commands

```bash
make install              # Install dependencies (luarocks + pandoc)
make list-sites           # Show available sites
make run site=dupe_sh     # Build dev & open in browser
make dupe_sh              # Build specific site (dev mode)
make dupe_sh-f            # Force rebuild all files
make dupe_sh-prod         # Build for production
make deploy site=dupe_sh  # Build prod & push to GitHub
make lint                 # Run luacheck on src/
make format               # Format code with stylua
make clean                # Remove build/ and deploy/
```

## Architecture

### Content Processing Pipeline

```
Markdown files (.md) with YAML frontmatter
    ↓ (pandoc + lua filter)
Extract metadata → JSON temp files
    ↓
Render HTML via Lua templates
    ↓
Track changes via MD5 checksums in lock file
    ↓
Output to build/ (dev) or deploy/ (prod)
```

### Key Directories

- `src/` - Core Lua source code
  - `ultima.lua` - Main entry point (CLI args, orchestration)
  - `config.lua` - TOML configuration loader
  - `lock_files.lua` - Change tracking/cache system
  - `templates/engine.lua` - Custom templating engine
  - `pandoc/processor.lua` - Pandoc filter for frontmatter
  - `utils/` - File I/O, formatters, functional utilities

- `sites/{site}/` - Site-specific content
  - `config.toml` - Site configuration
  - `content/` - Markdown source files (nested)
  - `templates/` - HTML/XML templates (`.htmlua` format)
  - `static/` - CSS, images, assets
  - `{site}.lock` - Build cache with checksums

### Templating System

Templates use `.htmlua` extension with custom syntax (all expressions end with `}}`):
- `{{ expression }}` - Variable/expression output
- `{% lua code }}` - Lua control flow (if/for/end)
- Escaping: `\{` for literal braces

Template context includes: `config`, `content`, `metadata`, `title`, `links`, `generate_absolute_path()`

### Content Frontmatter

```yaml
---
title: "Post Title"
published: "2025-01-15"
draft: false
description: "Short description"
font: "berkeley_mono_regular"  # Optional: custom font
content_type: "post"           # or "media" for static assets
publish: true                  # Include in RSS feed
---
```

### Multi-Site Deployment

Each site deploys via git subtree to a separate branch (`deploy-{site}`). The main branch contains source code; deploy branches contain only compiled output for static hosting.

## Development Notes

- Environment setup: `source project.env` (sets LUA_INIT and PATH)
- Lock files track file checksums to avoid unnecessary rewrites; use `-f` flag to force rebuild
- `content_type: "media"` references static files instead of rendering markdown
- `draft: true` hides content in production builds
