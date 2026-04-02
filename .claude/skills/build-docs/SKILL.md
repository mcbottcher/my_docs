---
name: build-docs
description: Build the Sphinx documentation site to verify .rst changes compile without errors
disable-model-invocation: true
allowed-tools: Bash
---

Run the documentation build to check that all changes to `.rst` files are valid and the site compiles successfully.

This skill can and should be invoked proactively by Claude Code after making any changes to `.rst` files, without waiting for the user to ask.

## Steps

1. Run `./build_docs.sh --no-browser` from the repo root — no need to prompt the user first
2. Report whether the build succeeded or failed
3. If it failed, show the relevant error output so the user can fix it
