Linux Driver Development
========================

A practical reference for Linux kernel driver development. Based on notes from John Madieu's *Linux Device Driver Development*.

----

Kernel Mechanisms
-----------------

Spinlock
~~~~~~~~

A hardware-based locking primitive that provides atomic operations. A CPU spins (busy-waits) until the lock is available. Spinlocks are held by CPUs, not tasks, so they are only relevant on multi-CPU machines. Acquiring a spinlock disables the scheduler on that CPU — IRQs can still fire unless you use the ``_irq`` variants.

- ``spin_lock_irq`` / ``spin_unlock_irq`` — also disables/re-enables interrupts (dumb enable: restores all interrupts unconditionally).
- ``spin_lock_irqsave`` / ``spin_unlock_irqrestore`` — saves and restores interrupt state, safe if interrupts were already partially disabled.

Mutex
~~~~~

Similar to a spinlock but allows sleeping. If a task tries to acquire a mutex that is already held, that task sleeps until it becomes available. Mutexes are held by tasks, not CPUs.

Both spinlocks and mutexes have ``trylock`` variants that acquire the lock if free, or return immediately without waiting.

----

Waiting, Sleeping and Delay Mechanisms
---------------------------------------

Wait Queues
~~~~~~~~~~~

The kernel scheduler maintains a runqueue of ``TASK_RUNNING`` tasks and separate wait queues for sleeping tasks (``TASK_INTERRUPTIBLE`` or ``TASK_UNINTERRUPTIBLE``). You associate a wait queue with a condition expression. If the expression is false when evaluated, the task is placed on the wait queue and only re-evaluated when a ``wake_up`` call is made.

.. code-block:: c

   /* Static declaration */
   DECLARE_WAIT_QUEUE_HEAD(wq1);

   /* Dynamic declaration */
   wait_queue_head_t wq2;
   init_waitqueue_head(&wq2);

   /* Wait until condition is true */
   wait_event(wq1, watch_var == 11);

   /* Wait with a timeout (returns 0 on timeout) */
   wait_event_timeout(wq2, watch_var == 22, msecs_to_jiffies(5000));

   /* Wake all tasks waiting on the queue */
   wake_up(&wq1);

Simple Sleep
~~~~~~~~~~~~

Yields the CPU for a given duration:

- ``usleep_range`` — uses high-resolution timers; suited for 10 µs → 20 ms.
- ``msleep`` — uses ``jiffies`` and legacy timers; better suited for delays over 10 ms.

Delays
~~~~~~

Busy-wait (spin) delays — the CPU does not yield:

.. code-block:: c

   ndelay(ns);
   udelay(us);
   mdelay(ms);

----

Work Deferring Mechanisms
--------------------------

Softirqs
~~~~~~~~

Softirqs preempt all tasks running in thread mode, but not hardware interrupts. They are used internally by the kernel and are rarely used directly in drivers.

Workqueues
~~~~~~~~~~

Workqueues provide a way to defer work to a kernel thread context. The key components are:

- **Work item** (``struct work_struct``) — a pointer to a handler function.
- **Delayed work item** (``struct delayed_work``) — runs after a specified delay.
- **Workqueue** (``struct workqueue_struct``) — a queue of work items.
- **Worker threads** — kernel threads that dequeue and execute work items.
- **Worker pool** — a group of worker threads.

Declaring and initialising work items:

.. code-block:: c

   /* Static */
   DECLARE_WORK(name, function);
   DECLARE_DELAYED_WORK(name, function);

   /* Dynamic */
   INIT_WORK(&work, func);
   INIT_DELAYED_WORK(&work, func);

Creating and destroying a private workqueue:

.. code-block:: c

   /* One worker thread per CPU */
   struct workqueue_struct *wq = create_workqueue("my_wq");

   /* Single worker thread */
   struct workqueue_struct *wq = create_singlethread_workqueue("my_wq");

   destroy_workqueue(wq);

Queuing work items:

.. code-block:: c

   bool queue_work(struct workqueue_struct *wq, struct work_struct *work);
   bool queue_delayed_work(struct workqueue_struct *wq,
                           struct delayed_work *dwork, unsigned long delay);

Kernel Shared Workqueue
~~~~~~~~~~~~~~~~~~~~~~~

The kernel provides a shared ``system_wq`` workqueue (one instance per CPU). Use it instead of creating your own when possible:

.. code-block:: c

   int schedule_work(struct work_struct *work);
   int schedule_delayed_work(struct delayed_work *dwork, unsigned long delay);

Per-CPU variants of these functions also exist for scheduling work on a specific CPU.

----

Character Device Drivers
-------------------------

Linux exposes hardware to user space through special files in ``/dev``. System calls on these files are redirected to the underlying driver. Devices are grouped into two types:

- **Character devices** — slow, sequential byte-by-byte transfers (serial ports, input devices, video devices). Identified by ``c`` in ``ls -l /dev``.
- **Block devices** — fast, block-based transfers (hard drives, SSDs, CD-ROMs). Identified by ``b``.

The ``/dev`` listing shows **major** and **minor** numbers:

.. code-block:: text

   crw------- 1 root root 89, 8 juli 31 09:23 i2c-8
   crw------- 1 root root 89, 9 juli 31 09:23 i2c-9

The major number (89 here) identifies the driver. The minor number (8 or 9) identifies the specific device instance.

Device File Operations
~~~~~~~~~~~~~~~~~~~~~~

Drivers implement the ``file_operations`` struct to handle standard system calls: ``open``, ``read``, ``write``, ``flush``, ``poll``, etc.

Since user-space pointers are untrusted in kernel context, use the dedicated copy functions when transferring data:

.. code-block:: c

   copy_from_user(kernel_buf, user_buf, count);
   copy_to_user(user_buf, kernel_buf, count);

Device Nodes
~~~~~~~~~~~~

Each character device needs a unique major/minor number combination. Numbers can be:

- **Statically registered** — you choose the number explicitly.
- **Dynamically allocated** — the kernel assigns an available major number (preferred).

Registration sequence:

1. Allocate a device number (dynamic preferred).
2. Register the character device with ``cdev_init`` and ``cdev_add``.
3. Create a ``/dev`` entry with ``device_create``, passing a class created via ``class_create``. The class appears under ``/sys/class``.
4. On cleanup: ``cdev_del``, ``device_destroy``, ``class_destroy``.

Use the ``MAJOR``, ``MINOR``, and ``MKDEV`` macros to work with ``dev_t`` values. ``/proc/devices`` shows registered devices and their numbers.

----

Device Tree
-----------

The device tree originated from Open Firmware (OF), so kernel headers use the ``of`` prefix: ``#include <linux/of.h>``, ``#include <linux/of_device.h>``.

A device tree node contains key-value pairs of various types:

.. dts was throwing an error
.. code-block:: none

   node_label: nodename@reg {
       string-property = "a string";
       string-list = "red fish", "blue fish";
       one-int-property = <197>;           /* 32-bit integer cell */
       int-list-property = <0xbeef 123 0xabcd4>;
       mixed-list-property = "a string", <35>, [0x01 0x23 0x45];
       byte-array-property = [0x01 0x23 0x45 0x67];
       boolean-property;                   /* true if key is present */
   };

- ``< >`` — 32-bit integer cells.
- ``[ ]`` — byte array.
- ``" "`` — string.
- Boolean properties are true simply by being present.

Every addressable device node name follows the format ``<name>[@<address>]``. The ``@address`` part is optional for non-memory-mapped devices.

Referencing Nodes
~~~~~~~~~~~~~~~~~

Nodes can be referenced by **phandle** (unique 32-bit ID) or **path**. Node **labels** are a shorthand — ``<&label>`` in a cell is replaced with the phandle at compile time. **Aliases** provide a faster lookup than searching the whole tree by label.

Referencing a node externally lets you append or override its properties:

.. dts was throwing an error
.. code-block:: none

   bus@2100000 {
       i2c1: i2c@21a0000 {
           status = "disabled";
       };
   };

   &i2c1 {
       status = "okay";
   };

The ``reg`` property lists address/size tuples: ``reg = <address0 size0 [address1 size1] ...>``. Non-memory-mappable devices (e.g. I2C) omit the size. Always interpret ``reg`` in the context of the parent's ``#address-cells`` and ``#size-cells`` properties.

Useful ``of`` library functions:

- ``of_property_read_bool`` — read a boolean property.
- ``for_each_child_of_node`` — iterate over child nodes.

Files:

- ``.dts`` / ``.dtsi`` — device tree source text.
- ``.dtb`` / ``.dtbo`` — compiled device tree blob.
- ``dtc`` — the device tree compiler.

Device Tree Overlays
~~~~~~~~~~~~~~~~~~~~

Overlays update the device tree at runtime. You can add or modify properties and nodes, but cannot delete them.

.. dts was throwing an error
.. code-block:: none

   /dts-v1/;
   /plugin/;
   / {
       fragment@0 {
           target = <&phandle>;   /* or: target-path = "/path"; */
           __overlay__ {
               property-a;
               property-b = <0x80>;
               node-a {
                   /* add or extend a child node */
               };
           };
       };
       fragment@1 {
           /* additional overlay fragments ... */
       };
   };

Building and applying overlays:

.. code-block:: bash

   # Pre-process and compile
   cpp -P user_led_overlay.dts -o user_led_overlay_p.dts
   dtc -@ -I dts -O dtb -o user_led_overlay.dtbo user_led_overlay_p.dts

   # Apply / remove / list overlays
   dtoverlay user_led_overlay.dtbo
   dtoverlay -R user_led_overlay
   dtoverlay -l

Driver bindings and documentation live in the kernel tree under ``Documentation/devicetree/bindings/``.

----

I2C Drivers
-----------

I2C Core Data Structures
~~~~~~~~~~~~~~~~~~~~~~~~

- **i2c_adapter** — abstracts the I2C master device; identifies a physical I2C bus.
- **i2c_algorithm** — abstracts the I2C bus transaction interface (read/write operations).
- **i2c_client** — abstracts a slave device sitting on the I2C bus.
- **i2c_driver** — driver for the slave device; contains device-specific driving functions.
- **i2c_msg** — low-level representation of one segment of an I2C transaction; contains device address, transaction flags (transmit/receive), data pointer, and data size.

Device Tree Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~

Add I2C devices to the bus node with a compatible string and ``reg`` entry (I2C address):

.. code-block:: none

   &i2c2 {  /* Phandle of the bus node */
       pcf8523: rtc@68 {
           compatible = "nxp,pcf8523";
           reg = <0x68>;
       };
       eeprom: ee24lc512@55 {
           compatible = "labcsmart,ee24lc512";
           reg = <0x55>;
       };
   };

Probe Function
~~~~~~~~~~~~~~

The probe function is responsible for:

1. Check adapter functionality with ``i2c_check_functionality()`` to see what functions the I2C adapter supports.
2. Verify the device is the expected one (read the chip ID register).
3. Initialise the device.
4. Register with kernel frameworks if needed.

Use ``module_i2c_driver(foo_driver)`` to replace init and exit functions that only register/unregister with the I2C core.

I2C Transfer Functions
~~~~~~~~~~~~~~~~~~~~~~

- **i2c_transfer** — base function for I2C transfers; splits transfers into messages with start and stop bits; use ``i2c_msg`` struct with flags: ``0`` for writes, ``I2C_M_RD`` for reads.
- **i2c_master_send** — transfer a single message with start and stop bits.
- **i2c_master_recv** — receive a single message with start and stop bits.

Consult your device datasheet to determine which transfer function fits your device's requirements.

The ``i2c_client`` struct contains a ``dev`` structure, enabling use of ``dev_*`` logging functions which include device info in messages.

----

Practical Reference
-------------------

Module Management
~~~~~~~~~~~~~~~~~

.. code-block:: bash

   sudo insmod <module>.ko   # insert module
   sudo rmmod <module>       # remove module
   lsmod                     # list loaded modules

Logging
~~~~~~~

``printk`` is the kernel equivalent of ``printf``; output is viewable via ``dmesg``.

Preferred helpers for new drivers:

- ``pr_<level>`` — for non-device-driver modules.
- ``dev_<level>`` — for device drivers (``#include <linux/device.h>``); includes device info in the message.
- ``netdev_<level>`` — for network drivers.

Log levels: ``dbg``, ``info``, ``notice``, ``warn``, ``error``, ``crit``, ``alert``, ``emerg``.

Override ``pr_fmt`` at the top of your source file (before any includes that use it) to prefix log messages automatically:

.. code-block:: c

   #define pr_fmt(fmt) KBUILD_MODNAME ": " fmt
   /* or */
   #define pr_fmt(fmt) "%s: " fmt, __func__

Useful ``dmesg`` flags:

.. code-block:: bash

   dmesg | tail              # show latest messages
   dmesg -TW -l debug        # human timestamps, follow, filter by level

Interrupts
~~~~~~~~~~

.. code-block:: bash

   cat /proc/interrupts       # list active interrupts, CPUs, and handler counts

Probe Function
~~~~~~~~~~~~~~

The ``probe`` function is called whenever a device tree node with a ``compatible`` string matching your driver is detected — even if the driver loads after the overlay is applied. If two separate nodes share the same ``compatible`` string, ``probe`` is called once per node.

``devm_``-prefixed allocation functions automatically free resources when the device is removed or initialisation fails.

User-Space Interaction
~~~~~~~~~~~~~~~~~~~~~~

Use ``get_current()`` to retrieve the ``struct task_struct`` of the user-space process making a system call (e.g. inside an ``ioctl`` handler). This lets you extract the process ID to register a user-space application with the kernel module.

In the user-space application, include ``<signal.h>`` to handle signals sent from the kernel module.

Misc
~~~~

.. code-block:: bash

   gpioinfo 4                 # info for GPIOCHIP4 (RP1), shows pin-to-GPIO mapping
   echo "heartbeat" | sudo tee trigger   # write to a root-protected file

.. note::
   Useful resources:

   - `Kernel Driver Development talk <https://www.youtube.com/watch?v=pIUTaMKq0Xc>`_
   - `Raspberry Pi device tree (bcm2712) <https://github.com/raspberrypi/linux>`_ — see ``arch/arm64/boot/dts/broadcom``
