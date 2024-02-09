Rust
====

Installing Rust
---------------

On linux:

.. code-block:: shell
    :caption: Command for installing rust

    curl --proto "=https" --tlsv1.3 https://sh.rustup.rs -sSf | sh

You will also need a linker/C-compiler, which you can install with for example:

.. code-block:: shell
    :caption: Install GCC on Ubuntu

    sudo apt install build-essential

Updating rust
^^^^^^^^^^^^^

.. code-block:: shell
    :caption: Updating rust

    rustup update

----

Basic Hello World
-----------------

1. Create a file called ``main.rs``
2. Enter code:

.. code-block:: rust
    :caption: Hello World program

    fn main() {
        println!("Hello World!");
    }

3. Compile with ``rustc main.rs``
4. Run with ``./main``

----

Cargo
-----

Cargo is rust's build system and package manager.

Create a new cargo project with:

.. code-block:: shell
    :caption: Creating a new cargo project

    cargo new <project_name>

This will initialise a project, and also by default creates a new git repo (unless you are 
already in a git repo).

You will have a ``Cargo.toml`` file where you keep your project configurations and dependancies,
and a ``src`` directory where your source code should live.

Build you project with ``cargo build``. This will create a few files:

1. ``Cargo.lock``: Tracks exact versions of project dependancies
2. ``target/``: Where your executable is stored.

By default cargo builds in debug mode, so your executable will be in ``target/debug``.

You can combine both building and running with just ``cargo run``. If no files have changed,
cargo will skip the build stage and just run the executable.

``cargo check`` is another command you can use. This will simply check that your code compiles
but doesn't produce an executable. This is faster than ``cargo build`` since it can miss some steps,
so it is useful when developing to check that your code still compiles.

Release build
^^^^^^^^^^^^^

When your project is ready for release, build it with ``cargo build --release`` to compile with
optimisations. This will place the executable in ``target/release``. The compilation time will be longer,
but the executable will run faster. 

