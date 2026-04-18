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

Memory Management
~~~~~~~~~~~~~~~~~

Linux manages memory through a hierarchy of address spaces:

**Physical Address** — an actual RAM location.

**Virtual Address** — a logical address used by processes and the kernel. The MMU (Memory Management Unit) translates virtual addresses to physical addresses.

**Logical Address** — a virtual address within the kernel's linear mapping (above ``PAGE_OFFSET``). Logical addresses have a fixed offset from their physical addresses.

**Virtual Page** — a ``PAGE_SIZE`` unit of virtual memory.

**Frame** (Page Frame) — a ``PAGE_SIZE`` unit of physical memory. Virtual pages map onto frames, which are identified by Page Frame Numbers (PFN).

**Page Table** — stores the mappings between virtual and physical addresses.

The virtual address space is split between kernel space (high addresses) and user space (low addresses). This separation provides memory protection and isolation between user processes and the kernel.

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

Raspberry Pi Device Tree Parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

On Raspberry Pi, ``dtparams`` can override certain device tree properties. Raspberry Pi uses aliases for some device tree status values: ``on`` → ``okay`` for example.

Reference: https://github.com/raspberrypi/linux/blob/rpi-6.6.y/arch/arm64/boot/dts/broadcom/bcm2712-rpi.dtsi#L195

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

Industrial IO Drivers
---------------------

Industrial IO is a kernel subsystem dedicated to analog-to-digital converters (ADCs) and digital-to-analog converters (DACs). It supports various sensors including accelerometers, gyroscopes, current/voltage measurement chips, light sensors, and pressure sensors.

Device and Channel Architecture
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The device is the chip itself. A channel is a single acquisition line of the device, such as the x, y, or z axis of a gyroscope.

User-Space Interaction
~~~~~~~~~~~~~~~~~~~~~~

Two interfaces are available to interact with IIO devices from user space:

- ``/sys/bus/iio`` — sysfs directory representing the device and its channels.
- ``/dev/iio:devicex`` — character device that exports the device's events and data buffer.

Channel Configuration
~~~~~~~~~~~~~~~~~~~~~

Channel specifications are defined using ``iio_chan_spec``. The type indicates what type of measurement the channel makes (e.g., ``IIO_VOLTAGE``, ``IIO_ACCEL``). Possible types are found in ``include/uapi/linux/iio/types.h``.

``iio_chan_info_enum`` specifies the channel sysfs attributes exposed to user space. These attributes are defined in ``include/linux/iio/types.h``.

Channels can be indexed by setting the indexed field in the channel spec and specifying the channel number.

Module Loading
~~~~~~~~~~~~~~

Load the industrialio module before loading your kernel module that uses the IIO framework:

.. code-block:: bash

   sudo modprobe industrialio

----

SPI Drivers
-----------

Serial Peripheral Interface (SPI) is a synchronous serial bus for communication between a master (controller) and one or more slave devices. Messages are handled by a dedicated thread named after your SPI bus device (e.g., visible via ``ps | grep spi``). Messages are queued and processed atomically — no other message can use the bus until the current one completes.

Core Data Structures
~~~~~~~~~~~~~~~~~~~~

- **spi_controller** — the master device that controls the bus.
- **spi_device** — a slave device on the bus.
- **spi_driver** — driver for a slave SPI device.
- **spi_transfer** — a single operation between master and slave (read, write, or bidirectional).
- **spi_message** — an atomic sequence of transfers; the entire message keeps the bus exclusive until completion.

SPI Modes
~~~~~~~~~

SPI mode is determined by two clock parameters:

- **CPOL** — clock polarity (high or low initial state).
- **CPHA** — clock phase; determines which clock edge the data is sampled on.

These combine to create four SPI modes (0, 1, 2, 3).

Messages and Transfers
~~~~~~~~~~~~~~~~~~~~~~

Initialize a message and add transfers to it:

.. code-block:: c

   void spi_message_init(struct spi_message *message);
   spi_message_add_tail(struct spi_transfer *t, struct spi_message *m);

For frequently used messages, pre-allocate and pre-fill to avoid initialization overhead:

.. code-block:: c

   struct spi_message *spi_message_alloc(unsigned ntrans, gfp_t flags);
   void spi_message_free(struct spi_message *m);

Starting Transactions
~~~~~~~~~~~~~~~~~~~~~

**Synchronous (blocking):**

.. code-block:: c

   int spi_sync(struct spi_device *spi, struct spi_message *message);

The chip select (CS) is activated for the entire message and deactivated between messages. This function may sleep while waiting for the transaction to complete.

**Asynchronous (non-blocking):**

.. code-block:: c

   int spi_async(struct spi_device *spi, struct spi_message *message);

Only submission is done; processing is asynchronous. The completion callback is invoked when finished. The message status is stored in ``message->status`` (0 on success, negative error code on failure). No other message can be submitted until the completion callback is complete.

Module Driver Macro
~~~~~~~~~~~~~~~~~~~

Use this macro to handle init and exit function registration:

.. code-block:: c

   module_spi_driver(foo_driver);

Device Tree Support
~~~~~~~~~~~~~~~~~~~

SPI device nodes must be children of the SPI controller node. Required entries are:

- **compatible** — driver match string.
- **reg** — chip select (CS) index of the device.
- **spi-max-frequency** — maximum clock frequency in Hz.

Optional entries include configuration properties for SPI mode, CS polarity, and other device-specific settings.

----

Resources
---------

- `Raspberry Pi Linux Kernel Cross-Compilation <https://www.raspberrypi.com/documentation/computers/linux_kernel.html>`_ — comprehensive guide to building and cross-compiling the Linux kernel for Raspberry Pi.

----

Practical Reference
-------------------

Meta Information
~~~~~~~~~~~~~~~~

.. code-block:: c

   MODULE_LICENSE("GPL");
   MODULE_AUTHOR("Mikkel Caschetto-Bottcher <mcb@emlogic.no>");
   MODULE_DESCRIPTION("GPIO driver for LED");

Device Numbers (dev_t)
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: c

   dev_t device_number = MKDEV(24, 0);
   unsigned int major_number = MAJOR(device_number);
   unsigned int minor_number = MINOR(device_number);

   int register_chrdev_region(dev_t first, unsigned int count, char *name);
   int alloc_chrdev_region(dev_t *dev, unsigned int firstminor,
                           unsigned int count, char *name);
   void unregister_chrdev_region(dev_t from, unsigned count);

Character Device Drivers
~~~~~~~~~~~~~~~~~~~~~~~~

Register device with kernel:

.. code-block:: c

   void cdev_init(struct cdev *cdev, const struct file_operations *fops);
   int cdev_add(struct cdev *p, dev_t dev, unsigned count);
   void cdev_del(struct cdev *p);

Make device physically present:

.. code-block:: c

   struct device *device_create(struct class *class, struct device *parent,
                                dev_t devt, void *drvdata, const char *fmt, ...);
   void device_destroy(const struct class *class, dev_t devt);

Create a device class (if not already in one):

.. code-block:: c

   struct class *class_create(const char *name);
   void class_destroy(const struct class *cls);

Interrupts
~~~~~~~~~~

.. code-block:: c

   int devm_request_irq(struct device *dev, unsigned int irq, irq_handler_t handler,
                        unsigned long irqflags, const char *devname, void *dev_id);

   typedef irqreturn_t (*irq_handler_t)(int, void *);

   irq_number = gpiod_to_irq(my_button); /* get IRQ number for a GPIO */

IOCTL
~~~~~

Input/Output control allows devices to implement custom functionality not available through standard system calls.

Prototype:

.. code-block:: c

   long ioctl(struct file *f, unsigned int cmd, unsigned long arg);

The ``cmd`` parameter is a unique identifier. Use these macros to generate it (depending on data transfer direction):

- ``_IO(MAGIC, SEQ_NO)`` — no data transfer
- ``_IOR(MAGIC, SEQ_NO, TYPE)`` — kernel to user space (read)
- ``_IOW(MAGIC, SEQ_NO, TYPE)`` — user to kernel (write)
- ``_IORW(MAGIC, SEQ_NO, TYPE)`` — bidirectional transfer

``MAGIC`` is an 8-bit identifier unique to your driver. ``SEQ_NO`` is an 8-bit sequence or command ID. ``TYPE`` is the structure name or data type being transferred; the macro uses it to determine size.

The ``arg`` parameter is a pointer to user-space memory; use ``copy_to_user`` and ``copy_from_user`` to transfer data.

Return ``-ENOTTY`` for unregistered commands. Generate IOCTL numbers in a dedicated header file (usable from user space too). Refer to ``Documentation/ioctl/ioctl-number.txt`` in the kernel sources for existing commands and ``Documentation/ioctl/ioctl-decoding.txt`` for detailed documentation.

User-space usage:

.. code-block:: c

   #include <sys/ioctl.h>

   ioctl(fd, EEP_ERASE); /* fd is the file descriptor to the character device */

Regmap
~~~~~~

Regmap unifies register accesses across I2C, SPI, and memory-mapped devices, reducing duplicated code. A device accessible over both I2C and SPI can use the same driver logic, changing only the initialization function.

.. code-block:: c

   #include <linux/regmap>

``struct regmap_config`` stores the register map configuration for the driver's lifetime, determining how read and write operations are performed. It includes callbacks for validating which registers are readable, writable, and cacheable.

Initialize regmap based on bus type:

.. code-block:: c

   struct regmap *devm_regmap_init_spi(struct spi_device *spi,
                                       const struct regmap_config *config);
   struct regmap *devm_regmap_init_i2c(struct i2c_client *i2c,
                                       const struct regmap_config *config);

Register read/write operations:

.. code-block:: c

   int regmap_read(struct regmap *map, unsigned int reg, unsigned int *val);
   int regmap_write(struct regmap *map, unsigned int reg, unsigned int val);
   int regmap_update_bits(struct regmap *map, unsigned int reg,
                          unsigned int mask, unsigned int val);

Bulk register operations:

.. code-block:: c

   int regmap_multi_reg_write(struct regmap *map, const struct reg_sequence *regs,
                              int num_regs);
   int regmap_bulk_read(struct regmap *map, unsigned int reg, void *val,
                        size_t val_count);
   int regmap_bulk_write(struct regmap *map, unsigned int reg, const void *val,
                         size_t val_count);

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
