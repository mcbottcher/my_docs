.. role:: bash(code)
   :language: bash

Git
===

Git Hooks
---------

You can checkout the ``.git/hooks`` directory in your git repo to see which hooks are
available. This gives some sample options for hooks.

Pre-commit
^^^^^^^^^^

In the ``.git/hooks/pre-commit`` file you can specify a script that will run when you try
and commit something.

It is common to use the *pre-commit* framework to organise your pre-commits.
In this way, the ``.git/hooks/pre-commit`` points to a ``pre-commit-config.yaml``.

In this yaml file, you can use pre-defined pre-commits from different repos.

.. code-block:: yaml
    :caption: Example of pre-commit in other repos

      - repo: https://github.com/psf/black
        rev: 23.3.0
        hooks:
        - id: black

Some other hooks to consider could be: pylint, isort, mirrors-prettier ...
 
The *https://github.com/pre-commit/pre-commit-hooks* repo also has a lot of
options for pre-commits you can run. You can choose them based on the ``id`` tag.

You can also use pre-commits specified only in your repository:

.. code-block:: yaml
    :caption: Example using local repo hook

    - repo: local
        hooks:
        - id: pytest-check
            name: pytest-check
            # you can specify your own script here
            # if the script returns 0, then the hook passes
            entry: ./run_tests_hook.sh
            language: system

Other Hooks
^^^^^^^^^^^

You can also run the other hook types using the pre-commit module.

.. code-block:: yaml
  :caption: Install hook configs

  default_install_hook_types: [pre-commit, post-commit]

With this in the ``.pre-commit-config.yaml``, when you run ``pre-commit install``,
it will install scripts for both pre-commit and post-commit in this case.

To make a hook run in a particular stage, set ``stages: [post-commit]``
to the stage or stages you want it to run in.

You can also specify a deafult for all hooks specified with ``default_stages: [commit]``.

Run a particular hook stage with ``pre-commit run --hook-stage post-commit``

Commit Messages
---------------

Different people like to have different formats for commit messaging.

One of the common ones is Conventional Commits: https://www.conventionalcommits.org/en/v1.0.0/

Conventional commit requires a format as such:

.. code-block::
  :caption: Example commit format

  <type>[optional scope]: <description>

Some types:
  - ``fix``: patches a bug in the code base
  - ``feat``: introduces a new feature to the code base
  - ``chore``: updating dependancies
  - ``refactor``: resturcture of code, no functional change
  - ``style``: code styling, e.g. black formatter changes
  - ``docs``: updates to documentation e.g. READMEs
  - ``ci``: changes to CI 
  - ``test``: adding/correcting tests

.. code-block::
  :caption: Example commit message

  docs(git.rst): Added commit messages section