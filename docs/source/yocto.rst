.. role:: bash(code)
   :language: bash

Yocto
=====

Yocto is a framework for building customised embedded linux images for a device.

----

Nomenclature
------------

TODO, some of the terms and their meanings, e.g. recipe, layer ...

----

Bitbake Commands
----------------

.. note::
   Before running a lot of these commands, you might have to source the environment. e.g. :bash:`source poky/oe-init-build-env <build_dir>`

- :bash:`bitbake <image-name>`

   - This will build your linux image using the <image-name> as the root .bb file.

- :bash:`bitbake-layers create-layer meta-<name>`

   - This creates the basic directory structure for a layer. The name should start with *meta*.

- :bash:`bitbake -c <cmd> <image>`

   - Run a command from an image. The command is a task available to the image.
   - :bash:`bitbake -c cleanall my_image`
   - :bash:`bitbake -c clean my_image`
   - :bash:`bitbake -c compile my_image`

- :bash:`bitbake -e`

   - Shows the bitbake environment for the most recent build

- :bash:`bitbake -g <package_name>`

   - Creates a dependancy tree for the package, which you can view in *task-depends.dot*

----

Adding a custom C program/application
-------------------------------------

This section will describe adding a program (C) to *usr/bin*

Tutorials:
   1. `Basic C program <https://github.com/joaocfernandes/Learn-Yocto/blob/master/develop/Recipe-c.md>`_
   2. `Using CMake <https://github.com/joaocfernandes/Learn-Yocto/blob/master/develop/Recipe-CMake.md>`_

You will want something similar to this in your *CMakeLists.txt*, which installs the program in *usr/bin*

.. code-block:: cmake

   cmake_minimum_required(VERSION 1.9)
   project (hellocmake)
   add_executable(hellocmake helloworld.c)
   install(TARGETS hellocmake RUNTIME DESTINATION bin)

If you want pull files from GitHub for example, you something like in the example:

.. code-block:: bash

   SRCREV = "${AUTOREV}"
   PV = "0.1+git${SRCPV}"
   SRC_URI = "git://github.com/mcbemlogic/yocto_pull_test;protocol=http;branch=main"
   S = "${WORKDIR}/git"
   inherit cmake
   EXTRA_OECMAKE = ""

- `Pulling files from GitHub <https://docs.yoctoproject.org/bitbake/2.0/bitbake-user-manual/bitbake-user-manual-fetching.html#git-fetcher-git>`_
- ``AUTOREV`` will pull the latest commit from git. You can use this revision to update the package name too.
- You can also pull specific commits with something like: ``SRCREV = "01351f639907247a2ecd2309865dffcd11930d8f"``
- ``inherit cmake`` is required if your package is using CMake
- ``EXTRA_OECMAKE`` allows you to pass extra arguments to the CMake process

----

Appending to a Recipe
---------------------

TODO: describe how to append to a Recipe


Tasks / Adding Custom Tasks
---------------------------

Package Groups
--------------

Making your own Distro
----------------------

SystemD
-------

Could have its own page?

Patch Files
-----------




