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

