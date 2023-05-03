.. role:: bash(code)
   :language: bash

U-Boot
======

Enter U-Boot environment on startup by hitting enter when it is doing its countdown.
It will also enter automatically if you haven't specified a default *bootcmd*.

Some U-Boot Commands
--------------------

You can see a list of U-Boot commands and their uses `here <https://u-boot.readthedocs.io/en/latest/usage/index.html#shell-commands>`_
and `there <https://www.mediawiki.compulab.com/w/index.php?title=U-Boot:_Quick_reference#Memory_commands>`_.

You can also type ``help`` in your uboot environment to view available commands. Type ``printenv`` to show the environment.

- ``bootd``: This is the same as running ``run bootcmd``
-  ``md 0``: Displays the memory at address 0
- ``mm 0``: Memory modify, starting at address 0 and autoincrement until you write something invalid
- ``mmc``: Info on the mmc device (SD for example)
- ``mw 0 bbbbaaaa``: Memory write, write a given value (bbbbaaaa) to given address (0)
- ``gpio toggle portb24``: Toggle user LED from UBOOT (for de10nano, where LED is connected to portb24)
- ``loadb``: This waits to receive files to load to a memory address you specifiy

   - You can find out what transfer type to use by looking at the Download commands section of the `U-Boot Command Descriptions <https://www.mediawiki.compulab.com/w/index.php?title=U-Boot:_Quick_reference#Memory_commands>`_.
     For example loadb uses kermit.
   - On TeraTerm you can send a file using the specified protocol from *file/transfer/<transfer_type>/Send*

- ``mmc info``: Shows info about mmc device
- ``mmc part``: Shows info on mmc partitions

Booting using TFTP
------------------

Trivial File Transfer Protocol (TFTP) is a really basic file transfer protocol that is best suited to use over a LAN since it is not secure.

`This tutorial <https://www.rocketboards.org/foswiki/Documentation/BootingAlteraSoCFPGAFromNetworkUsingTFTPAndNFS>`_ was very useful in working out how to do this.

Setting up the host server
^^^^^^^^^^^^^^^^^^^^^^^^^^

You can use several implementations, this is one:

.. code-block:: bash
   :caption: Installing the TFTP server

   sudo apt install tftp-hpa

After this you can check the config for your server, such as the directory to keep your files in

.. code-block:: bash

   cat /etc/default/tftpd-hpa

Change the owner of the TFTP home directory to your user:

.. code-block:: bash

   sudo chown -R $USER /srv/tftp

Check the status, start/stop/restart your tftp server service using the following command:

.. code-block:: bash

   sudo systemctl status tftpd-hpa

You can store files you want available over TFTP in the */srv/tftp* directory

Setting up the U-Boot Client
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. note::
   The steps used here might be specific to DE10-Nano board 

.. note::
   For the DE10-Nano, the ethernet connection wouldn't work unless ``CONFIG_NET_RANDOM_ETHERNET=y`` was added
   to the ``socfpga_de10_nano_defconfig``

Using these parameters, I can set the default boot command for uboot to setup the environment, and pull a script from TFTP, which I can customise to make uboot boot the way I want.

The *ipaddr* is the one that the DE10nano will use, and the *serverip* is the one of the machine hosting the TFTP server.

.. code-block::
   :caption: Example updating Yocto build file for U-Boot config. This example pulls a setup script using TFTP

   CONFIG_USE_BOOTCOMMAND=y
   CONFIG_BOOTCOMMAND="setenv ipaddr 192.168.0.67; setenv serverip 192.168.0.64; tftp ${scriptaddr} tftp_boot.scr; source ${scriptaddr}""

.. warning::
   It seemed that the script had to end with *.scr* to function correctly

The script will contain something like this:

.. code-block:: shell
   :caption: Script that pulls the Kenrel Image and Device tree, and boots using these

   tftp ${kernel_addr_r} zImage
   tftp ${fdt_addr_r} system.dtb

   setenv bootargs root=/dev/mmcblk0p2 rootwait rw earlyprintk console=ttyS0,115200n8

   bootz ${kernel_addr_r} - ${fdt_addr_r}

This script gets the kernel image and the device tree. It sets the linux boot arguments including
``root=`` which tells the kernel where to find the rootfs (SD card partition 2), and then bootz the zImage (without initrd: "-" in the middle).

Creating U-Boot files on the host
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To make a script into a U-Boot readable script, use the *mkimage* utility:

.. code-block:: shell
   :caption: Example making a script execuable by uboot

   sudo apt install u-boot-tools

   sudo mkimage -A arm -O u-boot -T script -C none -a 0 -e 0 -n "TFTP Boot Script" -d tftp_boot.script.txt /srv/tftp/tftp_boot.scr

You can also use the *mkimage* utility to make other uboot files.

Updating the rootfs
^^^^^^^^^^^^^^^^^^^

The file system is mounted during boot. This can be mounted from the SD card, but could also be mounted from an external device, e.g. using a NFS server.

So far all I have done is copy the rootfs.etx3 file to RAM using TFTP, then load it to the SD card using a command like:

.. code-block::

   mmc write <address_to_write_from> <starting_block_offset> <block_count>

You can find info about a device like block size and staring blocks of different partitions with ``mmc info``

Use ``mmc part`` to see the SD card partitions.

Booting using a FIT image
-------------------------

`This FIT tutorial <https://www.thegoodpenguin.co.uk/blog/u-boot-fit-image-overview/>`_ will give some insight into using a FIT image.
A FIT image is basically a bundled together kernel image, initramfs and device tree.