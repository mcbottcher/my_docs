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

Step 4: Configure Git (``~/.gitconfig``)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Set work as the global default. Use ``includeIf`` to override identity
for the personal folder.

.. code-block:: ini
    :caption: ~/.gitconfig

    [user]
      name = Work Name
      email = work@email.com

    [url "git@github-work:"]
      insteadOf = git@github.com:

    [includeIf "gitdir:~/personal/"]
      path = ~/.gitconfig-personal

.. code-block:: ini
    :caption: ~/.gitconfig-personal

    [user]
      name = Personal Name
      email = personal@email.com

    [url "git@github-personal:"]
      insteadOf = git@github.com:

Create the file as your own user so that Git can read it:

.. code-block:: bash
    :caption: Create ~/.gitconfig-personal with correct ownership and permissions

    $ touch ~/.gitconfig-personal
    $ chmod 644 ~/.gitconfig-personal

.. note::

    The ``includeIf`` directive requires a separate file — overrides cannot
    be inlined directly in ``~/.gitconfig``. This is a Git limitation.
    The file must be owned by your user; if it was created by root (e.g. via
    ``sudo``), Git will silently ignore it. Fix with:
    ``sudo chown $USER:$USER ~/.gitconfig-personal``

Step 5: Create Folders
^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

    $ mkdir ~/personal ~/work

How It Works
^^^^^^^^^^^^^

``includeIf`` matches repos by their location on disk. Any repo inside
``~/personal/`` will use the personal Git identity. Anything else on the
filesystem uses the global (work) identity. Only one ``includeIf`` is needed
— the other account is the default.

``insteadOf`` rewrites remote URLs transparently. When you clone using
``git@github.com:``, Git silently rewrites the URL to use the correct SSH
host alias based on which folder you are in. This means you never have to
type the alias manually.

This matters especially for public repos — cloning always works without
authentication, but pushing requires the correct key. The rewrite ensures
the remote URL is set up correctly from the start.

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
