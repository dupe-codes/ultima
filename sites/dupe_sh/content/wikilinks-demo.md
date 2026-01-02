---
title: "Wiki-style Links Demo"
draft: true
drafted: 2026-01-01
description: "Demonstrating the wiki-link syntax for easy internal linking"
toc: true
---

# Wiki-style Links

Ultima now supports wiki-style links for easy internal linking between posts.

## Basic Syntax

Link to another post using double brackets:

- [[/manuscripts/on art]] - displays as "on art"
- [[/manuscripts/off on a coding adventure]] - displays as "off on a coding adventure"

## Custom Display Text

Use the pipe character to set custom display text:

- [[/bookshelf/snippets|my code snippets]]
- [[/manuscripts/2025 - an artistic and personal retrospective|my 2025 retrospective]]

## Directory Links

Add a trailing slash to link to a directory's index page:

- [[/bookshelf/on programming/|programming notes]] - links to `/bookshelf/on programming/index.html`
- [[/bookshelf/curriculums/|curriculums]]

## Inline Usage

You can use wiki-links inline: check out [[/about|the about page]] for more info, or browse [[/bookshelf/on programming/|programming notes]].

## Paths

All paths are relative to the site content root:

- `/manuscripts/post` maps to `content/manuscripts/post.md`
- `/bookshelf/curriculums/deep systems programming` maps to `content/bookshelf/curriculums/deep systems programming.md`
