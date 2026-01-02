# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ultima is a Lua-based static site generator that builds multiple content-rich websites from markdown files. It manages three sites: dupe.sh, rorschach.me, and whathavewegained.com.

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
  - `template_engine.lua` - Custom templating engine
  - `pandoc/processor.lua` - Pandoc filter for frontmatter
  - `templates/` - Shared default templates (fallback for sites)
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
- Escaping: `\{` for literal opening braces (closing braces `}` don't need escaping)

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

## Documentation Conventions

- Use first person plural ("we", "our") rather than second person ("you", "your")
- Keep documentation concise and focused on implementation details
- Place project documentation in `docs/` directory
