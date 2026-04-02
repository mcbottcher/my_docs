.. role:: bash(code)
   :language: bash

.. role:: toml(code)
   :language: toml


|:package:| Python Build Tools
==============================

Python has several tools for managing dependencies and virtual environments.
This page covers two of the most popular modern options: **Poetry** and **uv**.

----

Poetry
------

Poetry is a dependency management and packaging tool for Python. It handles virtual environments,
dependency resolution, and publishing packages to PyPI — all from a single tool.

Configuration is stored in ``pyproject.toml``, and a ``poetry.lock`` file pins exact dependency
versions for reproducible installs.

Common Commands
^^^^^^^^^^^^^^^

- :bash:`poetry install` — installs all dependencies from ``pyproject.toml`` into the venv (creates the venv if it doesn't exist yet).
- :bash:`poetry add <package>` / :bash:`poetry remove <package>` — adds or removes a package. Both operations update the venv, ``pyproject.toml``, and ``poetry.lock`` together.
- :bash:`poetry add --group dev <package>` — adds to a named dependency group (e.g. ``dev``) instead of the main dependencies.
- :bash:`poetry run <command>` — runs a command inside the venv. Works for arbitrary commands
  (e.g. ``poetry run python main.py``), for scripts installed by packages (e.g. ``poetry run pytest``),
  or for scripts defined in your own project via ``[tool.poetry.scripts]`` in ``pyproject.toml``
  (e.g. ``poetry run my-script``). You can also launch VS Code via ``poetry run code .``, which gives
  VS Code access to the venv — enabling Go to Definition on installed packages.

pyproject.toml
^^^^^^^^^^^^^^

.. code-block:: toml

   [tool.poetry]
   name = "my-project"
   version = "0.1.0"
   description = "A short description"
   authors = ["Your Name <you@example.com>"]

   [tool.poetry.scripts]
   my-script = "my_package.module:main"

   [tool.poetry.dependencies]
   python = "^3.11"
   requests = "^2.31"
   my-lib = {path = "../my-lib"}
   my-lib-dev = {path = "../my-lib", develop = true}

   [tool.poetry.group.dev.dependencies]
   pytest = "^8.0"

   [build-system]
   requires = ["poetry-core"]
   build-backend = "poetry.core.masonry.api"

- ``[tool.poetry]``: Project metadata — name, version, description, authors. The ``name`` field is the
  distribution name (used for publishing), not related to ``poetry run``.
- ``[tool.poetry.scripts]``: Defines entrypoints for the project. The key is the script name and the
  value points to a Python callable (``module:function``). The key is what you pass to ``poetry run``
  (e.g. ``my-script = ...`` is run with ``poetry run my-script``).
- ``[tool.poetry.dependencies]``: Runtime dependencies. The ``python`` key sets the required interpreter
  version. Version constraints use ``^`` (compatible release, e.g. ``^3.11`` means ``>=3.11, <4.0``).
  Local packages can be referenced by path; adding ``develop = true`` makes it an editable install so
  changes to the local package are reflected immediately without reinstalling.
- ``[tool.poetry.group.<name>.dependencies]``: Dependency groups for non-runtime packages. Group names
  are arbitrary — ``dev``, ``test``, ``lint`` etc. are all conventions. There are no built-in special
  group names. Exclude a group at install time with ``poetry install --without dev``.
- ``[build-system]``: Tells build frontends how to build the package. Always points to ``poetry-core``
  for Poetry projects.

----

uv
--

``uv`` is an extremely fast Python package and project manager written in Rust, developed by Astral
(the team behind ``ruff``). It can act as a drop-in replacement for ``pip``, ``pip-tools``, and
``virtualenv``, and also supports full project management similar to Poetry.

Common Commands
^^^^^^^^^^^^^^^

- :bash:`uv sync` — installs all dependencies into the venv (creates ``.venv`` if needed). This is the
  equivalent of ``poetry install``.
- :bash:`uv init my-project` — scaffolds a new project with a ``pyproject.toml``. Not needed if you
  already have one.
- :bash:`uv add <package>` / :bash:`uv remove <package>` — adds or removes a dependency, updating
  ``pyproject.toml`` and ``uv.lock``.
- :bash:`uv add --dev <package>` — adds to the ``dev`` dependency group (``[dependency-groups]``),
  keeping it separate from runtime dependencies.
- :bash:`uv run <command>` — runs a command inside the venv. Works for scripts and arbitrary commands,
  including ``uv run code .`` to launch VS Code with Go to Definition support (same as Poetry).


Managing Python Versions
^^^^^^^^^^^^^^^^^^^^^^^^^

``uv`` can manage Python interpreter installations without a separate tool like ``pyenv``:

- :bash:`uv python install 3.12` — downloads and installs a specific Python version, managed by ``uv``.
- :bash:`uv python pin 3.12` — writes a ``.python-version`` file to the project directory. All ``uv``
  commands run there will use that interpreter, downloading it automatically if not already installed.

pyproject.toml
^^^^^^^^^^^^^^

.. code-block:: toml

   [project]
   name = "my-project"
   version = "0.1.0"
   requires-python = ">=3.11"
   dependencies = [
       "requests>=2.31",
       "my-lib",
   ]

   [project.scripts]
   my-script = "my_package.module:main"

   [dependency-groups]
   dev = [
       "pytest>=8.0",
   ]

   [tool.uv.sources]
   my-lib = { path = "../my-lib", editable = true }

- ``[project]``: Standard PEP 621 metadata table. Used by ``uv`` and any other PEP 517-compliant tool.
  ``requires-python`` sets the minimum interpreter version.
- ``[project.dependencies]``: Runtime dependencies declared as a list of PEP 508 strings
  (e.g. ``"requests>=2.31"``). Local packages are listed by name here, with their source declared
  separately in ``[tool.uv.sources]``.
- ``[project.scripts]``: Defines entrypoints for the project. The key is the script name and the
  value points to a Python callable (``module:function``). The key is what you pass to ``uv run``
  (e.g. ``my-script = ...`` is run with ``uv run my-script``). This is a standard PEP 621 field,
  so the scripts are also installed when the package is installed via ``pip``.
- ``[tool.uv.sources]``: Specifies where uv should fetch a dependency from. Setting ``editable = true``
  makes changes to the local package reflect immediately without reinstalling. Any build backend is
  supported, including Poetry projects.
- ``[dependency-groups]``: Optional groups for non-runtime dependencies (PEP 735). Equivalent to
  Poetry's groups — install with ``uv sync --group dev`` or exclude with ``uv sync --no-group dev``.
- ``[build-system]``: Only needed if you are building a distributable package. ``uv`` defaults to
  ``hatchling`` but any PEP 517 backend works.

.. note::
   Because ``uv`` uses the standard ``[project]`` table, the same ``pyproject.toml`` works with other
   tools like ``pip install .``, ``build``, or ``hatch`` without any changes — you are not locked in
   to ``uv`` to build or install the project.

----

Comparison
----------

Both tools cover the same core workflow: dependency management, virtual environments, and packaging.
The main differences are:

- **Speed**: ``uv`` is significantly faster at resolving and installing packages due to being written in Rust.
- **Python management**: ``uv`` can install and pin Python versions itself; Poetry relies on an external tool like ``pyenv``.
- **pip compatibility**: ``uv`` can act as a drop-in replacement for ``pip`` via ``uv pip``, making it easy to adopt incrementally.
- **Config format**: ``uv`` uses the standard PEP 621 ``[project]`` table; Poetry uses its own ``[tool.poetry]`` table.
- **Maturity**: Poetry has a larger established ecosystem; ``uv`` is newer but rapidly adopted.

Both are solid choices. ``uv`` has the edge for new projects due to speed and built-in Python management.
Poetry remains a good choice if you are already familiar with it or need its publishing workflow.

----

Sources
-------

- https://python-poetry.org/docs/
- https://docs.astral.sh/uv/
