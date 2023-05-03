.. role:: bash(code)
   :language: bash

Yocto
=====

Yocto is a framework for building customised embedded linux images for a device.

----

Nomenclature
------------

- Bitbake: a generic task executor
- OpenEmbedded: a metadata set used by bitbake
- Metadata: files containing information about how to build an image
- Recipe: file with instructions to build one or more packages
- Layer: directory containing grouped meta-data
- BSP: board support package, layer that deefines how to build for a board
- Distribution: specific implementation of Linux, kernel version, rootfs etc.
- Machine: defines the architecture, pins, buses, BSP etc.
- Image: output of build process (bootable and executable Linux OS)

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

- :bash:`BBDEBUG=3 bitbake custom-image`

   - Prints debug information from your build

- :bash:`bitbake -c devshell <target>`

   - This is a shell where you can run bitbake commands, and see environment variables like ``$CC``

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

This is achieved using the *.bbappend* where the name of the file is the same
as the recipe file you want to append to.

The append file can overwrite or add new things to an existing *.bb* file.

Use the ``%`` in the name so that it disregards the version number of the *.bb* file.

e.g. ``hello_0.1.bb`` can be appended with both ``hello_%.bbappend`` and ``hello_0.1.bbappend``

Tasks / Adding Custom Tasks
---------------------------

You can write a task in a *.bb* file with either regular or python syntax:

.. code-block::
   :caption: Regular syntax

   do_custom_task(){
   echo "CUSTOM TASK is running!"
   }

   addtask custom_task

.. code-block::
   :caption: Python syntax

   python do_custom_task(){
      import time
      bb.plain("Hello")
      time.sleep(3)
   }

You can specify where the task should run within the recipe's task list by using the
*before* and *after* keywords.

.. code-block::

   addtask custom_task after do_fetch before do_compile

.. warning::
   The task you are adding doesn't need the the *do_* prefix, but the tasks specified
   by *before* and *after* need the *do_* prefix to be registered correctly.

From the python task you can print various levels of information:

.. code-block::

   bb.plain("Hello")
   bb.note("Note")
   bb.warn("Oh no a warning")
   bb.error("Oh no an error!!!")
   bb.fatal("Crash and burn")

.. note::
   You can look into *log.taskorder* to check the order of tasks

Package Groups
--------------

A package group is a group of packages (recipes) that achieve the same/similar things.

Adding a package group
^^^^^^^^^^^^^^^^^^^^^^^

.. code-block::
   :caption: Example in a *packagegroup-custom.bb* file

   PACKAGE_ARCH = "${MACHINE_ARCH}"

   inherit packagegroup

   PACKAGES = "\
      ${PN}-helloworld \
   "

   RDEPENDS:${PN}-helloworld = " \
      hello \
   "

``${PN}`` is 'packagegroup-custom', or the package name. You can have multiple
images included in the ``RDEPENDS`` section.

.. code-block::
   :caption: Example including package-group in *.bb* file

   IMAGE_INSTALL += " packagegroup-custom-helloworld"

Making your own Distro
----------------------

To make your own distro, you will need to create a new layer. In this layer,
create a file in *conf/distro* called *<my_distro>.conf*.

.. code-block::
   :caption: Example distro.conf file, based on the Poky distro

   require conf/distro/poky.conf

   DISTRO_NAME = "mydistro"
   DISTRO_VERSION = "0.1"

Add ``DISTRO ?= "mydistro"`` to your *local.conf* to implement your distro.


SystemD
-------

If you want to use SystemD instead of Sysvinit, you can add the following lines to distro
configuration file.

.. code-block::
   :caption: Example addition to Distro config file

   DISTRO_FEATURES:append = " systemd"
   DISTRO_FEATURES:remove = "sysvinit"
   VIRTUAL-RUNTIME_init_manager = "systemd"
   DISTRO_FEATURES_BACKFILL_CONSIDERED = "sysvinit"
   VIRTUAL-RUNTIME_initscripts = ""

Adding a Service
^^^^^^^^^^^^^^^^

- Create a new layer:

   ::
      └── systemd
         ├── files
         │   └── hello.service
         └── hellosystemd.bb

- In the *.bb* file, you'll want something like this:

.. code-block::

   LICENSE = "CLOSED"
   inherit systemd

   SYSTEMD_AUTO_ENABLE = "enable"
   SYSTEMD_SERVICE:${PN} = "hello.service"

   SRC_URI:append = " file://hello.service "
   FILES:${PN} += "${systemd_unitdir}/system/hello.service"

   do_install:append() {
   install -d ${D}/${systemd_unitdir}/system
   install -m 0644 ${WORKDIR}/hello.service ${D}/${systemd_unitdir}/system
   }

- In the service file, you specify your service config. Here we specify what program
  this service runs and to print to the standard output

.. code-block::

   [Unit]
   Description=GNU Hello World startup script for KOAN training course

   [Service]
   ExecStart=/usr/bin/hellocmake
   StandardOutput=tty

   [Install]
   WantedBy=multi-user.target

- Inlude it in your final image, with *IMAGE_INSTALL_append* or add it to a package group

Patch Files
-----------

`Example patch of device tree <https://www.youtube.com/watch?v=srM6u8e4tyw&list=PLEBQazB0HUyTpoJoZecRK6PpDG31Y7RPB&index=6>`_.

The basic idea of a patch is that you create a diff file for the file you want to patch.
The name of the patch file doesn't matter too much. The file it targets is named within the file.
There are some conventions though of the naming of patch files that you can look up.

.. code-block:: bash
   :caption: Example creating a diff file 

   git diff --no-index socfpga_common.h.orig socfpga_common.h > 0001-add-uboot-bootcmd.patch

The patch is applied by including it in the SRC variable. Yocto/Bitbake automatically
will search for and apply patch files.

.. code-block:: bash
   :caption: Adding the patch file

   FILESEXTRAPATHS:prepend := "${THISDIR}:"
   SRC_URI += "file://0001-add-uboot-bootcmd.patch"

This could go in a *.bbappend* file, pointing to the recipe which fetches the source
you want to patch.

In Bitbake, the workflow of tasks is like this:

1. Fetch - get the source code
2. Extract - unpack the sources
3. Patch - apply patches for bug fixes and new capability
4. Configure - set up your environment specifications
5. Build - compile and link
6. Install - copy files to target directories
7. Package - bundle files for installation

Patching Device Tree
^^^^^^^^^^^^^^^^^^^^

Device tree files are .dtsi and .dts files. .dtsi files are include files, and are used generally. .dts
files are the ones that are used in the end, so these are the ones you want to patch if working on device tree.
Device tree also have a function to override certain attributes, by using a reference to the device tree tag.
This example updates the watchdog0 node to have status okay:

.. code-block:: dts
   :caption: Example overriding status attribute

   &watchdog0 {
	   status = "okay";
   };

You can find more info `here <https://www.devicetree.org/>`_ about device trees.

Editing Bitbake Files
---------------------

Assigning Values
^^^^^^^^^^^^^^^^

- Soft assignment: value is only assigned if not already, it can be overriden later
  by a hard assignment

  ``IMAGE_ROOTFS_SIZE ?= "204800"``

- Hard assignment: Cannot be overriden

   ``IMAGE_ROOTFS_SIZE = "204800"``

Adding Packages
^^^^^^^^^^^^^^^

You can add packages to the final image by using: ``IMAGE_INSTALL += <package_name>``

The package could also be a package_group, with a list of packages to be installed.

Include and Require
^^^^^^^^^^^^^^^^^^^

You can include some more info in your *.bb* files. You can either use include - which includes
the file in your *.bb file* - or require - which will check the file
exists first before processing the *.bb* file. If the file doesn't 
exist require will throw an error.

.. code-block::

   require recipes-extended/hello-extend.bb

Avoiding recipe name clashes
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block::

   BBFILE_PRIORITY_custom = "6"

This can be assinged in the *conf/layer.conf* file. The higher the number,
the higher the priority. This helps resolve cases where two recipes have the same
name.

Using Python
^^^^^^^^^^^^

.. code-block::
   :caption: Example removing '-frename-registers' from CFLAGS

   CFLAGS := "${@'${CFLAGS}'.replace('-frename-registers', '')}"

The ``@`` symbol allows you to use python within an expression

You can also use python functions:

.. code-block::

   python do_compile(){
      bb.plain("Hello from Python")
      bb.note("Hello from a note")
      bb.warn("Hello from a warn")
      bb.error("Hello from a error")
      bb.fatal("Hello from a fatal")
   }

Optomising Image Size
^^^^^^^^^^^^^^^^^^^^^

Turning on buildhistory will help track parameters we can tweak

.. code-block::

   INHERIT += " buildhistory"
   BUILDHISTORY_COMMIT = "1"

This turns on buildhistory and allows it be version controlled.
There will be some useful files like: image_info.txt, depends.dot, installed-package-sizes.txt

Use these to help you determine which packages you can remove:

.. code-block::

   IMAGE_INSTALL_remove += " <package_name>"

Creating an SDK
---------------

An SDK (Software Development Kit) provides all the utilities for building and compiling
software for a target.

There is an SDK *bbclass* in the poky classes-recipes directory. It can be included in your
build by using: ``inherit populate-sdk``

This will create files in *build/tmp/deploy/sdk* where you can run a script to install on your machine.

An example of using an SDK after it is installed is given here. This sources the environment
variables which will point to the correct tools and environment variables to build
software for your target.

:bash:`. /opt/poky/4.1.3/environment-setup-cortexa9t2hf-neon-poky-linux-gnueabi`

Recipe Naming 
-------------

Recipes are built using their name. They can optionally include a version number
at the end of their name, e.g. ``my_recipe_0.1.bb``

You can reference specific recipe versions or take the latest by using just the name.

You can make append files and other files ignore the version of the recipe too by using the
``%`` symbol. e.g. ``my_recipe_%.bbappend`` will apply to all versions of ``my_recipe``

Updating Bitbake Syntax
-----------------------

Bitbake has changed it syntax recently so sometimes if you copy something that uses the
old syntax bitbake will throw an error.

There is a script that helps update old syntax:

.. code-block:: bash

   cd poky
   scripts/contrib/convert-overrides.py <your-layer>
