# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a **Sphinx documentation site** — a personal knowledge base covering topics like bash, git, docker, python, rust, yocto, and more. All content lives in `docs/source/` as `.rst` (reStructuredText) files.

The site is built via Docker and deployed to GitHub Pages on pushes to `main`.

## Build

The build runs inside Docker:

```bash
# Build the Docker image and run Sphinx
./.github/actions/script.sh
```

Or manually (requires Sphinx and dependencies installed):

```bash
pip install -r docs/requirements.txt
cd docs && make html
# Output: docs/build/html/
```

## Adding Content

- Add new `.rst` files to `docs/source/`
- Register them in `docs/source/index.rst` under the `.. toctree::` directive
- Dependencies for Sphinx extensions: `docs/requirements.txt`

## CI/CD

- **Push to `main`**: builds and deploys to GitHub Pages
- **Pull requests**: builds and posts a comment to check build passes before merge
- The GitHub Action at `.github/actions/` wraps the Docker build script
