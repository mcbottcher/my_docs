⚡ Zephyr RTOS
==============

Zephyr is an open-source real-time operating system (RTOS) designed for resource-constrained embedded devices. It provides a rich set of kernel services — threading, scheduling, synchronisation, data passing, and memory management — while remaining highly configurable via its ``Kconfig`` build system.

.. note::
   Useful resources:

   - `Nordic Developer Academy — ncs-fund <https://github.com/NordicDeveloperAcademy/ncs-fund>`_
   - `Zephyr Scheduling Documentation <https://docs.zephyrproject.org/latest/kernel/services/scheduling/index.html>`_

----

Kconfig & Build System
-----------------------

Zephyr uses the Linux ``Kconfig`` system to manage compile-time configuration. Project-specific options live in ``prj.conf``; the full resolved configuration for a build is written to ``build/zephyr/.config``.

.. warning::
   The ``build/`` directory is deleted on a clean rebuild. Always commit custom options to ``prj.conf`` rather than relying on ``build/zephyr/.config``.

**Enabling options**

Add options to ``prj.conf`` using ``KEY=value`` syntax:

.. code-block:: kconfig

   CONFIG_LOG=y
   CONFIG_LED=y

**Interactive configuration**

``west build -t menuconfig`` opens a terminal UI for browsing and toggling all Kconfig symbols. Press ``?`` on any symbol to see its description, default, and dependency chain. Selections are written to ``build/zephyr/.config`` — copy important changes back to ``prj.conf`` to persist them across rebuilds.

**Multiple configuration files**

Maintain separate configs and select between them at build time with ``-DCONF_FILE``:

.. code-block:: bash

   west build -- -DCONF_FILE=prj_debug.conf
   west build -- -DCONF_FILE=prj_release.conf

This is useful for board-specific configurations or debug/release variants. ``prj.conf`` is the default when ``-DCONF_FILE`` is not specified.

**Custom Kconfig symbols**

Define your own symbols in a ``Kconfig`` file at the project root:

.. code-block:: kconfig

   config MY_SENSOR_MODULE
       bool "Enable my sensor module"
       default n
       help
         Enables the custom sensor driver and its dependencies.

Reference the symbol in ``CMakeLists.txt`` to conditionally compile source files — anything not needed is simply not built:

.. code-block:: cmake

   zephyr_library_sources_ifdef(CONFIG_MY_SENSOR_MODULE src/sensor.c)

**Zephyr modules**

Declare a directory as a Zephyr module by adding a ``zephyr/module.yml`` file. West discovers the module automatically and integrates its Kconfig, CMake, and DTS contributions into the build.

----

Devicetree
----------

Zephyr's devicetree describes the hardware topology — peripherals, memory regions, bus connections, and configuration properties — at compile time. Drivers consume the tree through generated C macros; no devicetree parsing happens at runtime.

Labels and Aliases
~~~~~~~~~~~~~~~~~~

A **label** is a shorthand reference to a devicetree node, avoiding the need to repeat its full path:

.. code-block:: dts

   /* Node with label "my_led" */
   my_led: led@0 {
       compatible = "gpio-leds";
       /* ... */
   };

   /* Reference by label in an overlay */
   &my_led {
       status = "okay";
   };

Node Bindings
~~~~~~~~~~~~~

For every ``compatible`` string used in a DTS node, Zephyr requires a matching **binding file** (``*.yaml``). The build system uses bindings to validate node properties and to generate the C macros your driver calls. To understand which properties are required or optional for a node, read its binding:

.. code-block:: bash

   # Built-in bindings live under:
   $ZEPHYR_BASE/dts/bindings/

   # Project-local bindings go here:
   dts/bindings/

Writing a custom binding:

.. code-block:: yaml

   # dts/bindings/myvendor,my-i2c-led.yaml
   description: My vendor I2C LED controller
   compatible: "myvendor,my-i2c-led"
   include: [base.yaml, i2c-device.yaml]

``include: [base.yaml, i2c-device.yaml]`` inherits standard properties (``status``, ``reg``, I2C address validation) so you do not have to redeclare them. A binding file is required even for trivial devices — without it the ``DT_HAS_<COMPAT>_ENABLED`` macros will not be generated and Kconfig dependencies that rely on them will silently fail.

.. note::
   Node names (e.g. ``leds``, ``gpio_keys``) are arbitrary. Driver binding is determined entirely by the ``compatible`` string, not the node name.

Custom I2C Device
~~~~~~~~~~~~~~~~~

Expose a device on an I2C bus by nesting its node under the bus node in a board overlay. The bus relationship is expressed by tree structure, not by a property:

.. code-block:: dts

   &i2c0 {
       my_led: my-i2c-led@40 {
           compatible = "myvendor,my-i2c-led";
           reg = <0x40>;        /* I2C address */
           status = "okay";
       };
   };

In the driver, ``I2C_DT_SPEC_INST_GET()`` walks the tree to locate the parent bus automatically.

The ``chosen`` Node
~~~~~~~~~~~~~~~~~~~

The ``chosen`` node maps well-known system-wide roles to specific hardware nodes. Values are node labels or aliases. It is consumed entirely at compile time:

.. code-block:: dts

   / {
       chosen {
           zephyr,console        = &usart1;          /* UART for printk() */
           zephyr,shell-uart     = &usart1;          /* UART for the interactive shell */
           zephyr,sram           = &sram0;           /* Main RAM (heap, stacks, BSS) */
           zephyr,flash          = &flash0;          /* Flash device */
           zephyr,code-partition = &slot0_partition; /* App image partition (MCUboot) */
           zephyr,canbus         = &can1;            /* Default CAN bus */
           zephyr,dtcm           = &ccm0;            /* Tightly Coupled Memory (zero wait-state) */
       };
   };

``console`` and ``shell-uart`` can point to different UARTs. When both point to the same one, kernel log output and the interactive shell share a single serial port.

``slot0_partition`` implies MCUboot is in use — flash is partitioned and slot 0 holds the primary application image.

``ccm0`` (DTCM on STM32) is CPU-only access memory with zero wait-state speed. DMA cannot access it.

Access a chosen node in C with:

.. code-block:: c

   const struct device *dev = DEVICE_DT_GET(DT_CHOSEN(zephyr_console));

Zephyr subsystems (console, shell) wire up their chosen node automatically — no manual assignment needed in C.

----

Bare-Metal vs. RTOS
-------------------

A bare-metal application runs sequentially. The only exception to this sequential flow is when an ISR or exception interrupts the main program. This approach works for simple to medium complexity programs, but becomes difficult to manage as application complexity grows.

An RTOS allows multiple concurrent execution units called **threads** to run within a single application. The core of an RTOS is called the **kernel**, which controls everything in the system.

----

Threads
-------

Threads are the smallest logical unit of execution managed by the RTOS scheduler. A thread exists in one of three states:

- **Running** — currently executing on the CPU; its context is loaded into the CPU registers.
- **Runnable/Ready** — waiting to be allocated CPU time; has no outstanding dependencies.
- **Not-runnable** — waiting on something before it can run; not considered by the scheduler.

System Threads
~~~~~~~~~~~~~~

These are threads spawned by Zephyr during initialisation. Two default threads exist:

- **Main thread** — runs RTOS initialisations, calls ``main()``, then exits normally.
- **Idle thread** — runs when there is no other work to do; can invoke power-saving features.

User-Created Threads
~~~~~~~~~~~~~~~~~~~~

These are threads created by the application using ``K_THREAD_DEFINE``:

.. code-block:: c

   K_THREAD_DEFINE(thread0_id, STACKSIZE, thread0, NULL, NULL, NULL,
           THREAD0_PRIORITY, 0, 0);

``STACKSIZE`` is the stack size for the thread (power of 2, e.g. 1024). A priority level and an entry function must also be provided.

Common thread management functions:

.. code-block:: c

   k_yield();        // change state from Running to Ready
   k_msleep(5);      // change state from Running to Not-runnable for N ms
   k_wakeup(tid);    // wake a sleeping thread early from another thread

Workqueue Threads
~~~~~~~~~~~~~~~~~

A workqueue thread executes user-defined work items pulled from a kernel workqueue object in FIFO order. Workqueues are a lighter choice than creating a dedicated thread because they share a single stack.

The system workqueue is available to all application code. You can also define your own:

.. code-block:: c

   /* Define a work item struct */
   struct work_info {
       struct k_work work;
       char name[25];
   } my_work;

   void offload_function(struct k_work *work_item)
   {
       emulate_work();
   }

   /* Start the workqueue and initialise the work item */
   k_work_queue_start(&offload_work_q, my_stack_area,
                      K_THREAD_STACK_SIZEOF(my_stack_area), WORKQ_PRIORITY,
                      NULL);

   k_work_init(&my_work.work, offload_function);

   /* Submit the work item whenever needed */
   k_work_submit_to_queue(&offload_work_q, &my_work.work);

----

Scheduler
---------

The scheduler determines which thread gets CPU time using a configurable scheduling algorithm. Zephyr is by default a **tickless RTOS** — it is entirely event-driven rather than relying on periodic timer interrupts.

A **rescheduling point** is an event that causes the scheduler to re-evaluate thread states. Examples:

- A thread calls ``k_yield()`` — state changes from Running to Ready.
- A kernel synchronisation object (semaphore, mutex) is given/sent — unblocks a waiting thread.
- A thread receives data from a data-passing kernel object — state changes from Waiting to Ready.
- Time-slicing is enabled and the thread has exhausted its time slice — state changes from Running to Ready.

Scheduler algorithms can be selected to trade memory overhead against scheduling overhead:

.. code-block:: kconfig

   CONFIG_SCHED_DUMB    # simple list, low overhead, suitable for few threads
   CONFIG_SCHED_MULTIQ  # multiple run queues, better for many threads

To protect a critical section from the scheduler:

.. code-block:: c

   k_sched_lock();
   /* critical section */
   k_sched_unlock();

Priority System
~~~~~~~~~~~~~~~

**Lower priority number = higher priority.** Priorities span from ``-CONFIG_NUM_COOP_PRIORITIES`` through ``CONFIG_NUM_PREEMPT_PRIORITIES - 1``. The sign of the priority value determines the thread's scheduling policy:

.. list-table::
   :header-rows: 1
   :widths: 20 20 60

   * - Priority range
     - Policy
     - Behaviour
   * - Negative (< 0)
     - Cooperative
     - Never preempted by other threads; only yields on an explicit block or ``k_yield()``
   * - Zero and positive (≥ 0)
     - Preemptive
     - Immediately switched out when a higher-priority thread becomes ready

Conventional priority bands (not enforced by the kernel):

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Range
     - Typical use
   * - 0 – 9
     - High priority (time-critical tasks)
   * - 10 – 49
     - Medium priority (general application work)
   * - 50 – 127
     - Low priority (background tasks)

Cooperative Threads (priority < 0)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A cooperative thread will **not** be switched out even if a higher-priority thread becomes ready — the higher-priority thread simply waits until the cooperative thread voluntarily gives up the CPU by:

- Blocking on a kernel object (``k_sem_take``, ``k_mutex_lock``, ``k_msgq_get``, etc.)
- Calling ``k_yield()``
- Sleeping with ``k_msleep()``

Blocking on a kernel object is itself a reschedule point, so no separate ``k_yield()`` call is needed — for example, ``k_sem_give()`` that unblocks a higher-priority thread will transfer the CPU to it immediately when the current cooperative thread next blocks.

.. warning::
   A cooperative thread that never blocks or yields will starve all other threads indefinitely. No timeslicing applies — there is no forced preemption.

Preemptive Threads (priority ≥ 0)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A preemptive thread is switched out **immediately** when a higher-priority thread becomes ready. Causes include:

- Another thread or ISR calling ``k_sem_give()``, ``k_mutex_unlock()``, ``k_msgq_put()``, or any unblocking API.
- An ISR submitting a work item with ``k_work_submit()``.
- A timer expiry unblocking a waiting thread.
- The running thread blocking itself.

Without time-slicing, an equal-priority thread does not preempt — the running thread holds the CPU until it blocks or a strictly higher-priority thread becomes ready.

ISRs and Thread Preemption
~~~~~~~~~~~~~~~~~~~~~~~~~~~

ISRs run entirely outside the scheduler — they interrupt any thread, including cooperative ones. On ISR exit, Zephyr checks whether a higher-priority thread is now ready. A cooperative thread reclaims the CPU regardless, because cooperative threads always have lower priority numbers than preemptive ones and cannot be preempted by them. The cooperative thread continues until it next blocks or calls ``k_yield()``, at which point any unblocked higher-priority preemptive thread gets to run.

**The cooperative guarantee is: other threads cannot preempt it. ISRs always can.**

Time-Slicing
~~~~~~~~~~~~

Time-slicing forces rotation between **preemptive** threads of exactly equal priority on each scheduler tick. It does not apply to cooperative threads, which cannot be forcibly switched out regardless of this setting.

Enable it with:

.. code-block:: kconfig

   CONFIG_TIMESLICING=y
   CONFIG_TIMESLICE_SIZE=10     # maximum time slice in ms before forced preemption
   CONFIG_TIMESLICE_PRIORITY=0  # threads at or below this priority are subject to slicing

Without time-slicing, a preemptive thread holds the CPU until it blocks or a higher-priority thread becomes ready. This can look similar to cooperative behaviour, but the distinction remains: a preemptive thread **can** be immediately taken off the CPU by a higher-priority thread becoming ready; a cooperative thread cannot. Timeslicing is an additional rotation mechanism — it is not what separates the two policies.

----

ISRs
----

ISRs (Interrupt Service Routines) are triggered asynchronously by hardware devices — they are not scheduled. An ISR preempts the currently running thread with very low latency. The scheduler only takes over after all pending ISRs have completed.

Keep ISRs as short as possible. To offload non-critical work, signal a thread or submit to a workqueue from inside the ISR:

- Use a kernel object (FIFO, LIFO, semaphore) to signal a thread.
- Submit a work item to the system workqueue with ``k_work_submit()``.

----

Synchronisation
---------------

Semaphores
~~~~~~~~~~

A semaphore is a counter variable indicating the availability of a shared resource. Any thread or ISR can give or take a semaphore (though ``k_sem_take`` blocks and should not be called from an ISR).

.. code-block:: c

   K_SEM_DEFINE(my_sem, 10, 10);   // initial count 10, max 10

   k_sem_take(&my_sem, K_FOREVER); // decrement; block if count is zero
   /* access shared resource */
   k_sem_give(&my_sem);            // increment

Mutexes
~~~~~~~

A mutex has **ownership** — only the thread that locked it can unlock it. Locking increments an internal lock count; the mutex is not fully released until it has been unlocked the same number of times it was locked. Mutexes support **priority inheritance**: if a higher-priority thread waits on a locked mutex, the kernel temporarily elevates the locking thread's priority.

Mutexes must not be used in ISRs.

.. code-block:: c

   K_MUTEX_DEFINE(my_mutex);

   k_mutex_lock(&my_mutex, K_FOREVER);
   /* access shared resource */
   k_mutex_unlock(&my_mutex);

Condition Variables
~~~~~~~~~~~~~~~~~~~

A condition variable allows a thread to wait until a particular condition is true. ``k_condvar_wait()`` atomically releases the associated mutex and parks the calling thread. Another thread signals readiness with ``k_condvar_signal()`` (wake one) or ``k_condvar_broadcast()`` (wake all), after which ``k_condvar_wait()`` re-acquires the mutex and returns.

Events
~~~~~~

An event object holds a bitmask of event flags. Many threads can wait on one or more flags simultaneously; when the condition is met all waiting threads become ready at once. ISRs and threads can both post/set events.

.. code-block:: c

   K_EVENT_DEFINE(my_event);

   k_event_post(&my_event, 0x01);              // bitwise OR into the event flags
   k_event_set(&my_event, 0x01);               // overwrite event flags

   k_event_wait(&my_event, 0x01, false, K_FOREVER);     // wait for any of the flags
   k_event_wait_all(&my_event, 0x03, false, K_FOREVER); // wait for all flags

Polling API
~~~~~~~~~~~

``k_poll()`` allows a thread to wait concurrently on multiple kernel objects (semaphores, FIFOs, poll signals) without checking each one individually. Define an array of ``k_poll_event`` structs, one per condition, and pass the array to ``k_poll()``.

Busy Wait
~~~~~~~~~

``k_busy_wait()`` spins the CPU for a short time without yielding to the scheduler. Useful when the wait duration is short enough that a context switch would cost more than the wait itself.

----

Data Passing
------------

Queues / FIFO / LIFO
~~~~~~~~~~~~~~~~~~~~

A Zephyr queue is a linked-list kernel object. FIFO and LIFO are built on top of it. Any thread or ISR can add items; only threads should remove items (removal blocks if the queue is empty).

.. code-block:: c

   K_FIFO_DEFINE(my_fifo);

   k_fifo_put(&my_fifo, &data_item);
   struct item *rx = k_fifo_get(&my_fifo, K_FOREVER);

Stacks
~~~~~~

A stack kernel object implements a LIFO queue for integer-sized values (32-bit or 64-bit depending on architecture).

.. code-block:: c

   K_STACK_DEFINE(my_stack, MAX_ITEMS);

   k_stack_push(&my_stack, value);
   k_stack_pop(&my_stack, &value, K_FOREVER);

Message Queues
~~~~~~~~~~~~~~

A message queue transfers fixed-size data items through a ring buffer. Items can be sent from threads or ISRs; receipt is thread-only (blocks if empty).

.. code-block:: c

   K_MSGQ_DEFINE(my_msgq, sizeof(struct data_item_type), 10, 4);

   k_msgq_put(&my_msgq, &tx_data, K_FOREVER);
   k_msgq_get(&my_msgq, &rx_data, K_FOREVER);
   k_msgq_peek(&my_msgq, &rx_data);  // inspect first item without removing it

Mailboxes
~~~~~~~~~

Mailboxes provide advanced message passing between threads (not ISRs). Messages can be of any size and are non-anonymous — both sender and receiver identify each other (or use ``K_ANY``). Sending can be synchronous (sender blocks until the receiver processes the message) or asynchronous.

.. code-block:: c

   K_MBOX_DEFINE(my_mailbox);

Pipes
~~~~~

A pipe sends a byte stream from one thread to another. It is given a ring buffer of a configured size (zero means unbuffered/synchronous).

.. code-block:: c

   K_PIPE_DEFINE(my_pipe, 100, 4);

----

Memory Management
-----------------

Heap
~~~~

The **system heap** is available automatically:

.. code-block:: c

   void *p = k_malloc(size);
   k_free(p);

You can also define your own named heap:

.. code-block:: c

   K_HEAP_DEFINE(my_heap, 4096);

   void *p = k_heap_alloc(&my_heap, size, K_FOREVER);
   k_heap_free(&my_heap, p);

Multiple discontiguous heaps can be combined using ``sys_multi_heap``.

Memory Slabs
~~~~~~~~~~~~

A memory slab allocates fixed-size blocks from a pre-allocated region. All blocks are the same size, so allocation and release are O(1) and fragmentation is avoided.

Memory Blocks Allocator
~~~~~~~~~~~~~~~~~~~~~~~

Similar to memory slabs but allows multiple blocks to be allocated or freed at once. Blocks within a group do not need to be contiguous, and bookkeeping is kept outside the buffer — useful when memory regions can be powered down to conserve energy.

Demand Paging
~~~~~~~~~~~~~

Demand paging treats RAM as a cache for flash. Only a subset of the program's pages are loaded into RAM at any time. When the processor accesses a page not currently in RAM, the kernel evicts another page (writing it back to flash if it was modified) and loads the requested page in its place.

----

Timing
------

Kernel Timing
~~~~~~~~~~~~~

Zephyr tracks time in several units:

- **Real-time** — milliseconds or microseconds via ``k_msleep()`` and similar APIs.
- **Cycles** — raw hardware counter via ``k_cycle_get_32()`` / ``k_cycle_get_64()``; frequency is constant and readable with ``sys_clock_hw_cycles_per_sec()``.
- **Ticks** — internal kernel unit; configure with ``CONFIG_SYS_CLOCK_TICKS_PER_SEC`` (typical range 100 Hz – 10 kHz).

Conversion functions between these units are provided by the kernel with configurable rounding modes.

.. code-block:: c

   int64_t uptime_ms = k_uptime_get();       // ms since boot
   int64_t delta_ms  = k_uptime_delta(&uptime_ms);  // ms since last call; updates reference

Timers
~~~~~~

A timer object measures elapsed time using the kernel clock. It has a **duration** (first expiry), a **period** (subsequent expiries), an **expiry function**, and a **stop function**. The **status** field records how many times the timer has expired since it was last read.

----

Multiple Processors
-------------------

Zephyr supports symmetric multiprocessing (SMP) — more than one thread can execute simultaneously across CPUs:

.. code-block:: kconfig

   CONFIG_SMP=y

Use spin locks to protect resources shared between CPUs:

.. code-block:: c

   k_spin_lock(&my_lock, &key);
   /* critical section */
   k_spin_unlock(&my_lock, key);

Pin a thread to a specific CPU with ``CONFIG_SCHED_CPU_MASK``. Send inter-processor interrupts with ``arch_sched_ipi()``.

----

Other Kernel Services
---------------------

Atomic Operations
~~~~~~~~~~~~~~~~~

Atomic variables are read and modified in a single uninterruptible instruction. They are 32-bit on 32-bit machines and 64-bit on 64-bit machines, backed by hardware atomic instructions where available.

Logging
~~~~~~~

Zephyr's logging subsystem supports four severity levels: **error**, **warning**, **info**, and **debug**. Log macros come in several families:

- ``LOG_<LEVEL>(...)`` — standard printf-style messages (e.g. ``LOG_ERR``, ``LOG_INF``).
- ``LOG_HEXDUMP_<LEVEL>(...)`` — binary data dumps (e.g. ``LOG_HEXDUMP_WRN``).
- ``LOG_INST_<LEVEL>(...)`` — message tied to a specific module instance (e.g. ``LOG_INST_INF``).
- ``LOG_INST_HEXDUMP_<LEVEL>(...)`` — binary dump tied to a specific instance (e.g. ``LOG_HEXDUMP_INST_DBG``).

Before using log macros, register the logging instance in each source module with ``LOG_MODULE_REGISTER``.

Enable logging with:

.. code-block:: kconfig

   CONFIG_LOG=y

Key options include backend selection (UART, RTT, SPI), ``CONFIG_LOG_BACKEND_SHOW_COLOR``, and ``CONFIG_LOG_PRINTK`` to route ``printk`` output through the logger.

In error conditions where the scheduler cannot be relied on, call ``log_panic()`` to flush all pending log messages to the backends immediately.

Dictionary Logging
~~~~~~~~~~~~~~~~~~

Dictionary logging is Zephyr's compressed logging mode. Instead of formatting a full string on the target and writing it to the backend, the target stores only a small integer message ID plus the raw bytes of any variables. The host-side parser reconstructs the full message from a dictionary file generated at build time.

The benefits over standard string logging:

- Drastically lower RAM and bandwidth usage — a message with one variable might be 5–6 bytes instead of 40+.
- Variables are still included; they are serialised as raw bytes and expanded by the parser.
- The backend is not fixed — dictionary logging works over UART, RTT, or any other transport.

Enable it with:

.. code-block:: kconfig

   CONFIG_LOG_MODE_DICTIONARY=y

The build system generates ``build/zephyr/log_dictionary.json``, which maps message IDs back to their format strings and type information. Pass this file to the host-side parser along with the captured log output:

.. code-block:: bash

   ./scripts/logging/dictionary/log_parser.py \
       build/zephyr/log_dictionary.json /tmp/serial.log --hex

A full working example is in ``samples/subsys/logging/dictionary``.

Fatal Errors
~~~~~~~~~~~~

Zephyr provides several ways to trigger errors:

.. code-block:: c

   /* Runtime assertion */
   __ASSERT(foo == 0xF0CACC1A, "Invalid value of foo, got 0x%x", foo);

   /* Build-time assertion */
   BUILD_ASSERT(FOO == 2000, "Invalid value of FOO");

   k_oops();   // user-mode application error
   k_panic();  // kernel-level error

Kernel Version
~~~~~~~~~~~~~~

.. code-block:: c

   uint32_t ver = sys_kernel_version_get();

----

Driver Model & Device API
--------------------------

Zephyr's driver model is borrowed from the Linux kernel. Each driver exposes a subsystem API through a struct of function pointers. Only operations the hardware actually supports need to be filled in — any pointer left ``NULL`` means "not implemented".

API Struct (Table of Function Pointers)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The LED subsystem API struct, for example, lists ``set_brightness``, ``blink``, ``on``, ``off``, and similar. A driver only fills the fields it can meaningfully implement:

.. code-block:: c

   static const struct led_driver_api gpio_led_api = {
       .on             = gpio_led_on,
       .off            = gpio_led_off,
       .set_brightness = gpio_led_set_brightness,
       /* .blink is left NULL — GPIO LEDs have no hardware timer */
   };

Dispatch Pattern
~~~~~~~~~~~~~~~~

Calling a Zephyr subsystem API goes through a wrapper that checks for ``NULL`` before dispatching:

.. code-block:: c

   /* Simplified z_impl_led_blink() */
   int led_blink(const struct device *dev, uint32_t id,
                 uint32_t delay_on, uint32_t delay_off)
   {
       const struct led_driver_api *api = dev->api;
       if (api->blink == NULL) {
           return -ENOSYS;   /* operation not supported */
       }
       return api->blink(dev, id, delay_on, delay_off);
   }

An unimplemented operation returns ``-ENOSYS``, not a crash. **Always check return values** — ``-ENOSYS`` means "this driver doesn't support that operation."

Three Common Patterns
~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 15 45 40

   * - Pattern
     - Description
     - Example
   * - Hard ``-ENOSYS``
     - The subsystem cannot fake the operation; the driver leaves the pointer ``NULL``.
     - ``led_blink()`` on a GPIO LED
   * - Fallback
     - The subsystem synthesises the operation from other ops the driver does implement.
     - ``led_on()`` → ``set_brightness(MAX)`` if ``on`` pointer is ``NULL``
   * - Optional
     - The feature is exposed only if the hardware supports it.
     - Sensor triggers, ``pm_action``

Read the driver ``.c`` file to see exactly what is wired up — the API header shows what is *possible*, the driver shows what is *implemented*.

----

User Space
----------

Zephyr can run threads in unprivileged CPU mode, enforced by hardware. The primary motivation is damage containment — a bug in a user space thread cannot corrupt kernel data structures. The MPU catches any violation and the kernel terminates only that thread.

User Space Threads
~~~~~~~~~~~~~~~~~~

Create a user space thread with the ``K_USER`` flag:

.. code-block:: c

   K_THREAD_DEFINE(my_thread_id, STACKSIZE, my_thread, NULL, NULL, NULL,
                   THREAD_PRIORITY, K_USER, 0);

User space suits any thread that does not need hardware access: data processing, protocol parsing, business logic, UI updates.

ARM CPU Modes and the MPU
~~~~~~~~~~~~~~~~~~~~~~~~~

ARM Cortex-M has two privilege levels (**privileged** / **unprivileged**) and two execution modes (**thread mode** / **handler mode**). Dropping a thread into user space sets the CPU to unprivileged thread mode — a hardware state, not a software flag.

The MPU sits between the CPU and the memory bus. Each region is programmed with a base address, size, and access permissions. Every memory access is checked against these regions; a violation raises a **MemManage fault** before the access completes. Cortex-M typically has 8–16 MPU regions. Cortex-A replaces the MPU with a full MMU that provides finer-grained virtual addressing.

Memory Domains and Partitions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A **memory domain** is a collection of **partitions** that defines what memory a user space thread can see. Kernel RAM and code outside the domain are invisible to the user thread — enforced by hardware, not convention.

Shared kernel objects (semaphores, queues, buffers) must be placed in a partition and explicitly granted to the thread's domain before the user thread can use them.

Syscalls
~~~~~~~~

User space threads can still use most kernel synchronisation primitives (mutexes, semaphores, queues) via the syscall layer. The ``SVC`` instruction triggers a controlled CPU exception; the kernel validates and executes the call in privileged mode, then returns to unprivileged mode.

What user space threads **cannot** do:

- Direct hardware register access
- Calling drivers directly
- Creating kernel objects
- Modifying IRQ or MPU configuration

TrustZone
~~~~~~~~~

TrustZone is a hardware mechanism that divides the system into a **secure world** and a **non-secure world** at the bus level. Its threat model is stronger than MPU privilege levels — it assumes the entire normal-world OS could be compromised and still protects secure-world resources.

Typical secure-world content: cryptographic keys, secure boot, attestation, payment credentials. The normal world requests services via the ``SMC`` instruction; the secure world returns only results, never raw sensitive data. On Cortex-M23/M33, the SAU (Security Attribution Unit) statically marks memory regions as secure or non-secure.

TrustZone vs Zephyr User Space
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

TrustZone and MPU-based user space operate at different layers and complement each other:

.. list-table::
   :header-rows: 1
   :widths: 35 65

   * - Mechanism
     - Protects against
   * - TrustZone (secure vs non-secure world)
     - A compromised OS — the secure world does not trust even the kernel
   * - Zephyr user space (privileged vs unprivileged threads)
     - Buggy or untrusted application threads — the kernel does not fully trust user threads

Zephyr should run in the **non-secure world**. The standard pattern is **TF-M** (Trusted Firmware-M) in the secure world and Zephyr in the non-secure world. Running a full RTOS in the secure world unnecessarily enlarges the attack surface.

Vendor / Customer Architecture
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Zephyr's user space model supports a vendor/customer split:

- A vendor ships a product image in one flash partition (managed by MCUboot + partition manager); the customer flashes their application into a separate partition independently.
- The memory domain is defined by the vendor at build time — MPU rules are baked into the vendor image, so customer code is automatically sandboxed regardless of what they flash.
- The LLEXT subsystem supports dynamically loadable extensions at runtime.

This gives vendors IP protection (their kernel threads are inaccessible to customer code) and stability guarantees (customer bugs cannot affect the kernel).

Enabling the ``gpio-leds`` Driver: a Kconfig Dependency Gotcha
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When using ``compatible = "gpio-leds"`` in the devicetree, the linker will throw an undefined reference error resembling:

.. code-block:: text

   undefined reference to `__device_dts_ord_XX`

even though the DTS node is correctly defined and ``CONFIG_DT_HAS_GPIO_LEDS_ENABLED=y`` is set.

**Why**: ``drivers/led/Kconfig`` wraps all LED drivers in a ``menuconfig LED … if LED … endif`` block. ``LED_GPIO`` has ``default y`` and depends on ``DT_HAS_GPIO_LEDS_ENABLED``, but because it lives inside the ``if LED`` block it is never evaluated unless the parent ``LED`` switch is explicitly enabled:

.. code-block:: kconfig

   # Fix: add to prj.conf
   CONFIG_LED=y

**Diagnosing missing Kconfig symbols**:

.. code-block:: bash

   grep "CONFIG_LED" build/zephyr/.config
   # Look for: # CONFIG_LED is not set

   west build -t menuconfig   # then press / and search LED to see the dependency tree

.. tip::
   When a driver Kconfig symbol has ``default y`` but is not enabling, check the parent ``Kconfig`` file for a wrapping ``if … endif`` or ``menuconfig`` block.

How ``CONFIG_LED_GPIO`` wires into the build:

- The LED driver's ``CMakeLists.txt`` calls ``zephyr_library_sources_ifdef(CONFIG_LED_GPIO led_gpio.c)`` — the file is only compiled when the symbol is set.
- Inside ``led_gpio.c``: ``#define DT_DRV_COMPAT gpio_leds`` — this string is matched against the ``compatible`` property in the DTS node to bind the driver.
