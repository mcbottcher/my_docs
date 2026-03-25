# MyDocs

**MyDocs** is a place where I can store documentation on knowledge I have aquired over the years to refer back to.

[![Sphinx build](https://github.com/mcbottcher/my_docs/actions/workflows/sphinx.yml/badge.svg)](https://github.com/mcbottcher/my_docs/actions/workflows/sphinx.yml)

## Building Docs Locally

Requires [Poetry](https://python-poetry.org/docs/#installation).

```bash
poetry install
poetry run make -C docs html
```

Output will be in `docs/build/html/`. Open `docs/build/html/index.html` in a browser to view.

Alternatively, use the helper script to build and open in Firefox automatically:

```bash
./build_docs.sh
```
