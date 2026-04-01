|:electric_plug:| udev Rules
============================

When Rules Are Checked
----------------------

udev rules are checked every time a device event occurs — this includes when a
device is added, removed, or changed. For most rules this means when you plug
in hardware, but it also applies to virtual devices being registered by drivers
at boot, like a keyboard backlight.

When an event fires, udev scans all rules files and applies every rule that
matches — it doesn't stop at the first match.

----

File Numbering
--------------

Rules files are loaded from ``/etc/udev/rules.d/`` (and a few other locations)
in strict numerical order based on the prefix. So ``10-foo.rules`` is processed
before ``90-bar.rules``.

The number lets you control priority and ordering:

- **Low numbers (10–49)** — early, often used by the system or distro
- **Mid numbers (50–74)** — general purpose rules
- **High numbers (75–99)** — late-stage overrides and user customisations

If two rules conflict, the last one applied wins, so higher-numbered files take
precedence. The convention of using ``90-`` for local rules is deliberate — it
ensures your custom rules run after the distro's defaults.

----

Anatomy of a Rule Line
----------------------

Each line is a comma-separated list of key-operator-value triplets, split into
two categories.

Match Keys
~~~~~~~~~~

Conditions that must be true for the rule to apply:

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Key
     - What it matches
   * - ``SUBSYSTEM==``
     - The device subsystem e.g. ``leds``, ``usb``, ``block``
   * - ``KERNEL==``
     - The kernel name of the device
   * - ``ATTR{file}==``
     - A sysfs attribute value of the device. For example, to match a USB
       device by vendor and product ID:

       .. code-block::

           SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c52b"

   * - ``ENV{var}==``
     - A udev environment variable

Assignment Keys
~~~~~~~~~~~~~~~

Actions to take if all conditions match:

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Key
     - What it does
   * - ``RUN+=``
     - Execute a command
   * - ``MODE=``
     - Set file permissions on the device node
   * - ``OWNER=``
     - Set the owning user. Note: this only applies to ``/dev`` device nodes.
       It has no effect on sysfs nodes (under ``/sys``), such as LED backlight
       devices — use ``RUN+=`` with ``chmod`` instead.
   * - ``GROUP=``
     - Set the owning group
   * - ``SYMLINK+=``
     - Create a symlink to the device
   * - ``NAME=``
     - Rename the device node

Operators
~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Operator
     - Meaning
   * - ``==``
     - Match/compare
   * - ``!=``
     - Negative match
   * - ``=``
     - Assign a value
   * - ``+=``
     - Append to a list

A complete rule reads as: *if all the match conditions are true, apply all the
assignment actions.*

----

Example: ThinkPad Keyboard Backlight
-------------------------------------

The following rule grants all users write access to the ThinkPad keyboard
backlight brightness control. Because ``tpacpi::kbd_backlight`` is a sysfs
node rather than a ``/dev`` node, ``OWNER=`` cannot be used — instead
``RUN+=`` calls ``chmod`` directly on the sysfs brightness file:

.. code-block::
   :caption: 90-kbd-backlight.rules

   SUBSYSTEM=="leds", KERNEL=="tpacpi::kbd_backlight", RUN+="/bin/chmod a+w /sys/class/leds/%k/brightness"

The ``%k`` is a udev substitution variable that expands to the kernel name of
the matched device — in this case ``tpacpi::kbd_backlight``.
