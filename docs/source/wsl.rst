WSL (Windows Subsystem for Linux)
==================================

Tips and notes for working with WSL.

----

Attaching a USB Device
-----------------------

USB devices are not automatically forwarded into a WSL instance. The ``usbipd`` tool handles the attachment.

**One-time setup** — bind the device as Administrator in PowerShell:

.. code-block:: powershell

   usbipd bind --busid <BUSID>

This survives host reboots but only needs to be done once per device.

**Each WSL session** — attach the device as a regular user in PowerShell:

.. code-block:: powershell

   usbipd attach --wsl --busid <BUSID>

Find the ``BUSID`` with ``usbipd list``.

.. note::
   The bind step requires an Administrator shell. The attach step works from a regular user shell because the WSL instance runs under your local user account.
