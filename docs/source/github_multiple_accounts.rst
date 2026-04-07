.. role:: bash(code)
    :language: bash

Multiple GitHub Accounts on One Machine
========================================

If you have both a personal and a work GitHub account, you need a way to
use each from the same machine without logging in and out. The solution is to
give each account its own SSH key and tell Git which key to use based on
where your repos live on disk.

Two separate concerns need to be managed:

- **Commit identity** (name/email) — controlled by Git config
- **Authentication** (which account) — controlled by SSH keys

The two are independent. Commits carry your name/email as a label.
Pushes authenticate via SSH keys, which GitHub uses to identify your account.

Step 1: Create Two SSH Keys
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash
    :caption: Generate one key per GitHub account

    $ ssh-keygen -t ed25519 -C "personal@email.com" -f ~/.ssh/id_ed25519_personal
    $ ssh-keygen -t ed25519 -C "work@email.com" -f ~/.ssh/id_ed25519_work

- ``ed25519`` is the recommended algorithm for GitHub — modern, secure, and fast.
- The ``-C`` flag is just a comment/label on the key. It has no functional effect.
- The ``-f`` flag sets the output filename.

Step 2: Configure SSH (``~/.ssh/config``)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: text
    :caption: ~/.ssh/config

    Host github-personal
      HostName github.com
      User git
      IdentityFile ~/.ssh/id_ed25519_personal

    Host github-work
      HostName github.com
      User git
      IdentityFile ~/.ssh/id_ed25519_work

- ``User git`` is required — GitHub's SSH server only accepts the user ``git``.
  Your GitHub account is identified by the key, not the username.
- The ``Host`` aliases (``github-personal``, ``github-work``) tell SSH exactly
  which key to use, rather than guessing.

Step 3: Upload Public Keys to GitHub
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Copy each public key and add it under
**GitHub → Settings → SSH and GPG keys → New SSH key**.

.. code-block:: bash
    :caption: Print public keys to copy

    $ cat ~/.ssh/id_ed25519_personal.pub   # add to personal GitHub account
    $ cat ~/.ssh/id_ed25519_work.pub       # add to work GitHub account

Step 4: Configure Git
^^^^^^^^^^^^^^^^^^^^^^

Keep shared config (aliases, etc.) in ``~/.gitconfig``. Create separate
files for each account that include it, then override identity and SSH URL.

.. code-block:: ini
    :caption: ~/.gitconfig — shared config only, no identity

    [alias]
      co = checkout
      br = branch
      ci = commit
      st = status

.. code-block:: ini
    :caption: ~/.gitconfig-work

    [include]
      path = ~/.gitconfig

    [user]
      name = Work Name
      email = work@email.com

    [url "git@github-work:"]
      insteadOf = git@github.com:

.. code-block:: ini
    :caption: ~/.gitconfig-personal

    [include]
      path = ~/.gitconfig

    [user]
      name = Personal Name
      email = personal@email.com

    [url "git@github-personal:"]
      insteadOf = git@github.com:

.. code-block:: bash
    :caption: Create the files with correct ownership and permissions

    $ touch ~/.gitconfig-work ~/.gitconfig-personal
    $ chmod 644 ~/.gitconfig-work ~/.gitconfig-personal

.. note::

    Do not put identity (``[user]``) or ``[url]`` rewrites in ``~/.gitconfig``
    itself — those belong only in the account-specific files. The base file
    is included by both, so anything there applies everywhere.

Step 5: Create Personal Folder
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

    $ mkdir ~/personal

.. note::

    Only the personal folder needs to be created. Any path outside of ``~/personal``
    will automatically use the work config.

Step 6: Set Up Shell Hook (``~/.bashrc``)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

``GIT_CONFIG_GLOBAL`` overrides the path Git uses as its global config.
Override ``cd`` to update this variable whenever you change directories.

.. code-block:: bash
    :caption: ~/.bashrc

    _update_git_config() {
        if [[ "$PWD" == ~/personal* ]]; then
            export GIT_CONFIG_GLOBAL=~/.gitconfig-personal
        else
            export GIT_CONFIG_GLOBAL=~/.gitconfig-work
        fi
    }

    cd() {
        builtin cd "$@"
        _update_git_config
    }

    _update_git_config   # run once on shell startup

After editing ``~/.bashrc``, reload it:

.. code-block:: bash

    $ source ~/.bashrc

.. note::

    The hook runs on ``cd``, not on repo operations directly. This means
    identity and URL rewriting are applied based on which directory you are
    in when you run the Git command — including when cloning into a new
    folder that is not yet a git repo.

How It Works
^^^^^^^^^^^^^

``GIT_CONFIG_GLOBAL`` tells Git which file to use as its global config.
The shell hook keeps it pointed at the right account-specific file based
on your current directory. Both account files include ``~/.gitconfig`` for
shared settings, then add their own identity and URL rewrite on top.

Why not use ``includeIf "gitdir:..."``? That directive only activates inside
an existing git repo. When you run ``git clone`` from ``~/personal/`` — which
is not itself a repo — Git reads the global config before the repo exists,
so ``includeIf`` never fires and the work identity is used instead. The
``GIT_CONFIG_GLOBAL`` approach works at the directory level regardless.

``insteadOf`` rewrites remote URLs transparently. When you clone using
``git@github.com:``, Git silently rewrites the URL to use the correct SSH
host alias. This means you never have to type the alias manually.

.. code-block:: bash
    :caption: Git rewrites the URL automatically based on your current folder

    $ cd ~/personal && git clone git@github.com:someuser/repo.git
    # becomes: git@github-personal:someuser/repo.git

+-------------------+----------------------+-------------------+
| Folder            | SSH Host Used        | Git Identity      |
+===================+======================+===================+
| ``~/personal``    | ``github-personal``  | personal@email    |
+-------------------+----------------------+-------------------+
| Everything else   | ``github-work``      | work@email        |
+-------------------+----------------------+-------------------+
