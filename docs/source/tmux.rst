🖥️ tmux
=======

tmux is a terminal multiplexer — it lets you run multiple terminal sessions inside a single window, split the screen into panes, and detach/reattach to sessions so work keeps running in the background.

----

Core Concepts
-------------

- **Session** — a collection of windows. You can detach from a session and reattach later; everything keeps running.
- **Window** — like a tab inside a session. Each window fills the full terminal.
- **Pane** — a split within a window. Multiple panes can be visible side-by-side or stacked.

All tmux commands are prefixed with a key combination called the **prefix key**. The default is ``Ctrl+B``.

----

Sessions
--------

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - Command
     - Description
   * - ``tmux``
     - Start a new session
   * - ``tmux new-session -s <name>``
     - Start a named session
   * - ``tmux list-sessions`` / ``tmux ls``
     - List all sessions
   * - ``tmux attach``
     - Re-attach to the most recent session
   * - ``tmux attach -t <name>``
     - Re-attach to a named session
   * - ``Ctrl+B, D``
     - Detach from the current session
   * - ``Ctrl+B, $``
     - Rename the current session
   * - ``Ctrl+B, S``
     - Show an interactive session list to switch between sessions
   * - Inside session: ``tmux rename-session <new-name>``
     - Rename session from the command line

----

Windows
-------

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - Command
     - Description
   * - ``Ctrl+B, C``
     - Create a new window
   * - ``tmux new-window``
     - Create a new window (from the command line inside a session)
   * - ``Ctrl+B, N``
     - Switch to the next window
   * - ``Ctrl+B, P``
     - Switch to the previous window
   * - ``Ctrl+B, ,``
     - Rename the current window
   * - ``exit`` or ``Ctrl+B, &``
     - Close the current window

----

Panes
-----

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - Command
     - Description
   * - ``Ctrl+B, %``
     - Split pane vertically (side by side)
   * - ``Ctrl+B, "``
     - Split pane horizontally (top and bottom)
   * - ``Ctrl+B, <arrow>``
     - Move focus to the pane in that direction
   * - ``Ctrl+B`` (hold), ``<arrow>``
     - Resize the current pane in that direction
   * - ``exit``
     - Close the current pane

----

Configuration
-------------

tmux reads its configuration from ``~/.tmux.conf`` at startup.

.. note::
   Good resource for customization: `Learn tmux Part 5 — How to Customize tmux and Make it Your Own <https://www.learnlinux.tv/learn-tmux-part-5-how-to-customize-tmux-and-make-it-your-own/>`_

**Enable mouse support:**

.. code-block:: text

   set -g mouse on

With mouse support enabled you can click to focus a pane or window, and drag pane borders to resize them.

----

Scripting
---------

tmux is scriptable, which makes it useful for launching reproducible development environments.
The example below sets up a three-pane layout — a common pattern for running a broker alongside two clients.

.. code-block:: bash
   :caption: Example: launch a multi-pane tmux session from a script

   #!/bin/bash

   SESSION="my-session"

   # Kill any existing session to start clean
   tmux kill-session -t $SESSION 2>/dev/null

   # Create a new detached session (200 cols × 50 rows)
   tmux new-session -d -s $SESSION -x 200 -y 50

   # Split right: creates pane 2
   tmux split-window -t $SESSION -h -l 100

   # Split pane 2 vertically: creates pane 3 below
   tmux split-window -t $SESSION:1.2 -v -l 25

   # Send commands to each pane
   tmux send-keys -t $SESSION:1.1 "echo 'hello from pane 1'" Enter
   tmux send-keys -t $SESSION:1.2 "echo 'hello from pane 2'" Enter
   tmux send-keys -t $SESSION:1.3 "echo 'hello from pane 3'" Enter

   # Attach to the session
   tmux attach-session -t $SESSION

Key scripting commands:

- ``tmux new-session -d -s <name> -x <cols> -y <rows>`` — create a detached session with a given size
- ``tmux split-window -t <target> -h -l <cols>`` — split horizontally, new pane on the right
- ``tmux split-window -t <target> -v -l <rows>`` — split vertically, new pane below
- ``tmux send-keys -t <target> "<command>" Enter`` — send a command to a pane
- ``tmux attach-session -t <name>`` — attach to a session
- ``tmux set-hook -t <name> session-closed 'run-shell "<cmd>"'`` — run a shell command when the session closes

The ``<target>`` format is ``<session>:<window>.<pane>`` (e.g. ``my-session:1.2`` means window 1, pane 2 of session ``my-session``).
