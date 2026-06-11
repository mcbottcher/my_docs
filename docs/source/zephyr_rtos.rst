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

Bus Disambiguation
~~~~~~~~~~~~~~~~~~

When a device supports both I2C and SPI, two binding files exist with the same ``compatible`` string. The ``on-bus: i2c`` / ``on-bus: spi`` field tells the resolver which file applies based on the parent node type in the DTS (``&i2c1`` vs ``&spi1``).

The ``on-bus`` value can be inherited through ``include:`` — including ``i2c-device.yaml`` implicitly brings in ``on-bus: i2c``. Filename suffixes like ``-i2c.yaml`` / ``-spi.yaml`` are a human-readable convention only; the build system uses ``on-bus`` (direct or inherited) for actual disambiguation.

The common pattern for dual-bus sensors separates bus-specific and shared properties into three files:

.. code-block:: text

   st,lis2dh-i2c.yaml  →  includes i2c-device.yaml + st,lis2dh-common.yaml
   st,lis2dh-spi.yaml  →  includes spi-device.yaml + st,lis2dh-common.yaml

The ``-common.yaml`` holds all shared sensor properties (ODR, full-scale range, interrupts, etc.) avoiding duplication between bus variants.

The matched binding and DTS node together generate ``devicetree_generated.h``, producing macros like ``DT_HAS_ST_LIS2DH_ENABLED``. Kconfig uses these via ``$(dt_compat_on_bus,...)`` to conditionally enable bus subsystems — ``CONFIG_I2C`` or ``CONFIG_SPI`` is selected automatically when a sensor is added to the DTS.

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

Deleting Properties in Overlays
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To remove a property defined in the base board DTS, use the ``/delete-property/`` directive in a board overlay:

.. code-block:: dts

   &some_node {
       /delete-property/ property-name;
   };

This is useful for stripping a property that is not applicable to your hardware variant.

----

Bare-Metal vs. RTOS
-------------------

A bare-metal application runs sequentially. The only exception to this sequential flow is when an ISR or exception interrupts the main program. This approach works for simple to medium complexity programs, but becomes difficult to manage as application complexity grows.

An RTOS allows multiple concurrent execution units called **threads** to run within a single application. The core of an RTOS is called the **kernel**, which controls everything in the system.

----

Kernel Initialisation
---------------------

Zephyr initialises drivers and subsystems in a fixed sequence controlled by **initialisation levels**, assigned when each driver or library is registered with ``DEVICE_DT_INST_DEFINE`` or ``SYS_INIT``:

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Level
     - Typical content
   * - ``PRE_KERNEL_1``
     - Clock driver and serial driver for early debug output
   * - ``PRE_KERNEL_2``
     - System timer
   * - ``POST_KERNEL``
     - Libraries, RTOS subsystems, and services that require kernel services (e.g. semaphores, workqueues) during their setup
   * - ``APPLICATION``
     - Main thread starts, calling ``main()``; if ``main()`` is absent the main thread terminates and the scheduler dispatches the next ready thread

The scheduler and both system threads (main and idle) are active before the ``POST_KERNEL`` stage runs, so drivers initialised at ``POST_KERNEL`` can safely use kernel synchronisation primitives.

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

Threads must be **allocated statically** — Zephyr does not support fully dynamic thread creation at runtime. ``K_THREAD_DEFINE`` is the recommended approach as it handles stack allocation automatically. ``k_thread_create()`` is also available but requires a separate ``K_THREAD_STACK_DEFINE`` declaration:

.. code-block:: c

   K_THREAD_STACK_DEFINE(my_stack, STACKSIZE);
   struct k_thread my_thread_data;

   k_thread_create(&my_thread_data, my_stack, STACKSIZE,
                   my_entry, NULL, NULL, NULL,
                   MY_PRIORITY, 0, K_NO_WAIT);

**Delayed start**: pass a non-zero timeout as the last argument to defer placing the thread in the ready queue. A delay of ``K_FOREVER`` means the thread will not start until another thread explicitly calls ``k_thread_start()``:

.. code-block:: c

   K_THREAD_DEFINE(my_thread, STACKSIZE, my_entry, NULL, NULL, NULL,
                   MY_PRIORITY, 0, K_FOREVER);  /* dormant until started */

   /* Elsewhere: */
   k_thread_start(my_thread);

Thread Lifecycle
~~~~~~~~~~~~~~~~

Beyond the three scheduler-visible states (Running / Ready / Not-runnable), threads can reach terminal or suspended states:

- **Suspended** — paused with ``k_thread_suspend()``; invisible to the scheduler until ``k_thread_resume()`` is called. Unlike sleeping, suspension has no timeout.
- **Terminated** — the thread's entry function returned normally.
- **Aborted** — the thread encountered a fatal error (e.g. a ``NULL`` pointer dereference). The thread enters the ``ABORTED`` state. Distinguishing a terminated thread from an aborted one is a useful debugging signal when inspecting a crash.

.. code-block:: c

   k_thread_suspend(tid);   /* thread stops running */
   k_thread_resume(tid);    /* thread becomes ready again */

Meta-IRQ Threads
~~~~~~~~~~~~~~~~

Meta-IRQ threads are a special class of **cooperative** thread used exclusively in device drivers. They solve a specific timing problem: after an ISR completes its urgent work, the driver's "bottom half" (e.g. the Bluetooth stack's event processing) needs to run in thread context immediately — before any other preemptive thread.

The guarantee: when a Meta-IRQ thread is made ready by an ISR, the scheduler runs it immediately after the ISR returns, ahead of any preemptive thread that was interrupted, regardless of that thread's priority. The cooperative thread that was running before the interrupt resumes afterward.

This is how the Zephyr BLE stack and similar drivers decouple ISR work from heavier processing without incurring scheduling latency.

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

To protect a critical section from other **threads** (but not ISRs):

.. code-block:: c

   k_sched_lock();
   /* critical section — scheduler disabled, ISRs can still run */
   k_sched_unlock();

To protect a critical section from **both threads and ISRs**:

.. code-block:: c

   unsigned int key = irq_lock();
   /* critical section — scheduler disabled, interrupts disabled */
   irq_unlock(key);

``irq_lock()`` / ``irq_unlock()`` disable all interrupts at the CPU level. Reserve these for very short, time-critical sections — extended use increases interrupt latency.

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
   * - 0 - 9
     - High priority (time-critical tasks)
   * - 10 - 49
     - Medium priority (general application work)
   * - 50 - 127
     - Low priority (background tasks)

Default priorities for Zephyr's built-in threads:

.. list-table::
   :header-rows: 1
   :widths: 45 55

   * - Thread
     - Default priority
   * - System workqueue thread
     - -1 (cooperative)
   * - Main thread
     - 0 (preemptive)
   * - Logger thread (deferred mode)
     - 14 (preemptive)
   * - Idle thread
     - 15 (lowest preemptive, ``CONFIG_NUM_PREEMPT_PRIORITIES - 1``)

Thread priority can be changed at runtime with ``k_thread_priority_set()``, which can shift a thread between preemptive and cooperative:

.. code-block:: c

   k_thread_priority_set(k_current_get(), -1);  /* shift current thread to cooperative */

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

Earliest Deadline First (EDF)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Within a priority level, Zephyr supports **Earliest Deadline First (EDF)** scheduling as an alternative to FIFO ordering. Each thread declares how much time it needs to complete its work; the scheduler picks the thread with the closest deadline first.

.. code-block:: c

   k_thread_deadline_set(tid, deadline_cycles);

EDF must be configured per-thread by the application — it is not enabled by default. Threads without a deadline set are ordered by the standard ready-time rule.

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

Unlike a message queue (which uses a statically sized ring buffer with fixed-size items), a FIFO stores only **pointers** — items are typically heap-allocated, giving it variable-size capability. Static allocation is also possible: the item struct's first field must be reserved for the FIFO's internal linked-list pointer.

.. code-block:: c

   K_FIFO_DEFINE(my_fifo);

   k_fifo_put(&my_fifo, &data_item);
   struct item *rx = k_fifo_get(&my_fifo, K_FOREVER);

.. warning::
   A FIFO is a linked list — adding the same data entry twice corrupts the list. Ensure each item appears in the FIFO at most once at any given time.

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

Each module registers itself with the logging subsystem exactly once, in a single source file:

.. code-block:: c

   #include <zephyr/logging/log.h>
   LOG_MODULE_REGISTER(foo, CONFIG_FOO_LOG_LEVEL);

If the module spans several files, every other file uses ``LOG_MODULE_DECLARE`` instead — this references the existing registration rather than creating a duplicate:

.. code-block:: c

   #include <zephyr/logging/log.h>
   /* In all files comprising the module but the one that registers it */
   LOG_MODULE_DECLARE(foo, CONFIG_FOO_LOG_LEVEL);

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

Exposing Public Functions from a Driver
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

There are three ways to expose a public API from a Zephyr driver:

- **Subsystem API** (standard class) — use when the driver fits an existing Zephyr class (sensor, GPIO, UART, etc.). Callers use the generic subsystem functions (e.g. ``sensor_sample_fetch(dev)``); Zephyr dispatches to the implementation via function pointer.
- **Custom public header** (single implementation) — declare functions in a public header, implement them in the driver ``.c``. Callers include the header and call directly; no indirection involved.
- **Custom API struct** (multiple implementations) — define a vtable struct with function pointers in the header; each driver fills it in. Callers use inline dispatch helpers. This is how Zephyr's own subsystems work internally.

The subsystem API call chain for a sensor looks like:

.. code-block:: text

   sensor_sample_fetch(dev)
     → dev->api->sample_fetch(dev)    /* function pointer dispatch */
       → my_sensor_fetch(dev)         /* concrete implementation */

A subsystem is effectively an interface contract — the API header defines it, the driver fills it. Function pointer slots left as ``NULL`` will fault at runtime (some subsystems return ``-ENOSYS`` via NULL checks instead of crashing). Always obtain the device handle via ``DEVICE_DT_GET(DT_NODELABEL(my_dev))``.

Writing a Custom Driver
~~~~~~~~~~~~~~~~~~~~~~~

A Zephyr device is represented by a ``struct device`` containing ``config`` (compile-time constants), ``data`` (runtime state), and ``api`` (function pointer table). ``DEVICE_DT_INST_DEFINE`` wires these together for every enabled devicetree instance:

.. code-block:: c

   #define DT_DRV_COMPAT vendor_mysensor  /* matches "vendor,mysensor" in DTS */

   #define MYSENSOR_DEFINE(inst)                                         \
       static struct mysensor_data data_##inst;                          \
       static const struct mysensor_config config_##inst = {             \
           .spi = SPI_DT_SPEC_INST_GET(inst, SPIOP, 0),                 \
       };                                                                \
       DEVICE_DT_INST_DEFINE(inst,                                       \
                             mysensor_init,                              \
                             NULL,                                       \
                             &data_##inst,                               \
                             &config_##inst,                             \
                             POST_KERNEL,                                \
                             CONFIG_SENSOR_INIT_PRIORITY,                \
                             &mysensor_api);

   DT_INST_FOREACH_STATUS_OKAY(MYSENSOR_DEFINE)

``DT_INST_FOREACH_STATUS_OKAY`` expands ``MYSENSOR_DEFINE`` once for each devicetree node with a matching ``compatible`` and ``status = "okay"``. Dots and commas in the ``compatible`` string are replaced with underscores in ``DT_DRV_COMPAT`` — so ``"vendor,mysensor"`` becomes ``vendor_mysensor``.

Supporting Multiple Bus Types
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A driver can support both I2C and SPI by using a function-pointer table for bus operations and selecting the correct implementation at compile time with ``COND_CODE_1`` and ``DT_INST_ON_BUS``. The ``lis2dh`` accelerometer driver is a canonical example:

.. code-block:: c

   #define LIS2DH_DEFINE(inst)                              \
       COND_CODE_1(DT_INST_ON_BUS(inst, spi),               \
               (LIS2DH_DEFINE_SPI(inst)),                    \
               (LIS2DH_DEFINE_I2C(inst)))

   DT_INST_FOREACH_STATUS_OKAY(LIS2DH_DEFINE)

``DT_INST_ON_BUS(inst, spi)`` expands to ``1`` if the DTS node for that instance is a child of an SPI bus node, ``0`` otherwise. ``COND_CODE_1`` selects the SPI or I2C variant accordingly — the correct binding file (via ``on-bus:``) and the correct driver implementation are therefore both resolved from the same DTS placement.

Each bus variant registers its own transfer functions through a ``hw_tf`` pointer in the driver data struct:

.. code-block:: c

   /* I2C init: */
   data->hw_tf = &lis2dh_i2c_transfer_fn;

   /* SPI init: */
   data->hw_tf = &lis2dh_spi_transfer_fn;

``hw_tf`` points to a struct of function pointers for bus-specific reads and writes. The rest of the driver calls these indirectly — all bus knowledge is confined to the init path.

Sensor Triggers
~~~~~~~~~~~~~~~

Zephyr's sensor subsystem has a standardised interrupt pipeline that routes hardware GPIO interrupts all the way to a user-supplied callback. The ``lis2dh`` driver is a good example to trace end-to-end.

**1. DTS: declaring the interrupt GPIOs**

The sensor node lists its interrupt lines under ``irq-gpios``:

.. code-block:: dts

   lsm303dlhc_accel: lsm303dlhc-accel@19 {
       compatible = "st,lis2dh", "st,lsm303dlhc-accel";
       reg = <0x19>;
       irq-gpios = <&gpioe 4 GPIO_ACTIVE_HIGH>,
               <&gpioe 5 GPIO_ACTIVE_HIGH>;
   };

**2. Driver config: consuming the DTS properties**

A macro expands the ``irq-gpios`` phandle array into ``gpio_drdy`` and ``gpio_int`` fields in the driver's static config struct. ``GPIO_DT_SPEC_INST_GET_BY_IDX_COND`` resolves each entry to a ``gpio_dt_spec`` at compile time:

.. code-block:: c

   #define LIS2DH_CFG_INT(inst)                                              \
       .gpio_drdy =                                                          \
           COND_CODE_1(ANYM_ON_INT1(inst),                                   \
           ({.port = NULL, .pin = 0, .dt_flags = 0}),                        \
           (GPIO_DT_SPEC_INST_GET_BY_IDX_COND(inst, irq_gpios, 0))),         \
       .gpio_int =                                                           \
           COND_CODE_1(ANYM_ON_INT1(inst),                                   \
           (GPIO_DT_SPEC_INST_GET_BY_IDX_COND(inst, irq_gpios, 0)),          \
           (GPIO_DT_SPEC_INST_GET_BY_IDX_COND(inst, irq_gpios, 1))),

**3. Init: registering the GPIO callback**

During device initialisation, the driver registers a callback with the GPIO subsystem. The GPIO driver owns the EXTI/pin-change ISR and walks its registered callback list when the interrupt fires:

.. code-block:: c

   gpio_init_callback(&lis2dh->gpio_int1_cb,
              lis2dh_gpio_int1_callback,
              BIT(cfg->gpio_drdy.pin));

   gpio_add_callback(cfg->gpio_drdy.port, &lis2dh->gpio_int1_cb);

**4. The GPIO callback: ISR context**

Because the interrupt is level-triggered, the callback immediately disables the interrupt line to avoid re-entry. It then signals deferred work — either a semaphore for a dedicated thread or a work item for the system workqueue:

.. code-block:: c

   static void lis2dh_gpio_int1_callback(const struct device *dev,
                         struct gpio_callback *cb, uint32_t pins)
   {
       struct lis2dh_data *lis2dh =
           CONTAINER_OF(cb, struct lis2dh_data, gpio_int1_cb);

       atomic_set_bit(&lis2dh->trig_flags, TRIGGED_INT1);
       setup_int1(lis2dh->dev, false);   /* disable until processed */

   #if defined(CONFIG_LIS2DH_TRIGGER_OWN_THREAD)
       k_sem_give(&lis2dh->gpio_sem);
   #elif defined(CONFIG_LIS2DH_TRIGGER_GLOBAL_THREAD)
       k_work_submit(&lis2dh->work);
   #endif
   }

**5. Deferred processing: own thread or system workqueue**

Both modes converge on the same ``lis2dh_thread_cb`` function, which calls the user-registered handler:

.. code-block:: c

   /* Own-thread mode */
   static void lis2dh_thread(void *p1, void *p2, void *p3)
   {
       struct lis2dh_data *lis2dh = p1;
       while (1) {
           k_sem_take(&lis2dh->gpio_sem, K_FOREVER);
           lis2dh_thread_cb(lis2dh->dev);
       }
   }

   /* System workqueue mode */
   static void lis2dh_work_cb(struct k_work *work)
   {
       struct lis2dh_data *lis2dh =
           CONTAINER_OF(work, struct lis2dh_data, work);
       lis2dh_thread_cb(lis2dh->dev);
   }

Inside ``lis2dh_thread_cb``, the stored handler pointer is invoked:

.. code-block:: c

   if (likely(lis2dh->handler_drdy != NULL)) {
       lis2dh->handler_drdy(dev, lis2dh->trig_drdy);
   }

**6. Registering a handler: the sensor subsystem API**

``handler_drdy`` is populated via ``lis2dh_trigger_set``, which is exposed through the sensor driver API struct and dispatches on trigger type:

.. code-block:: c

   int lis2dh_trigger_set(const struct device *dev,
                  const struct sensor_trigger *trig,
                  sensor_trigger_handler_t handler)
   {
       if (trig->type == SENSOR_TRIG_DATA_READY &&
           trig->chan == SENSOR_CHAN_ACCEL_XYZ) {
           return lis2dh_trigger_drdy_set(dev, trig->chan, handler, trig);
       } else if (trig->type == SENSOR_TRIG_DELTA) {
           return lis2dh_trigger_anym_set(dev, handler, trig);
       } else if (trig->type == SENSOR_TRIG_TAP) {
           return lis2dh_trigger_tap_set(dev, handler, trig);
       }
       return -ENOTSUP;
   }

   static DEVICE_API(sensor, lis2dh_driver_api) = {
       .attr_set     = lis2dh_attr_set,
   #if CONFIG_LIS2DH_TRIGGER
       .trigger_set  = lis2dh_trigger_set,
   #endif
       .sample_fetch = lis2dh_sample_fetch,
       .channel_get  = lis2dh_channel_get,
   };

**7. Application code**

From the application's perspective only the generic sensor API is needed — the entire pipeline above is hidden inside the driver:

.. code-block:: c

   struct sensor_trigger trig = {
       .type = SENSOR_TRIG_DATA_READY,
       .chan = SENSOR_CHAN_ACCEL_XYZ,
   };
   sensor_trigger_set(accel, &trig, drdy_handler);

.. note::
   The choice between ``CONFIG_LIS2DH_TRIGGER_OWN_THREAD`` and ``CONFIG_LIS2DH_TRIGGER_GLOBAL_THREAD`` is a latency/resource trade-off. A dedicated thread has its own stack and priority, giving lower and more predictable latency. The system workqueue is lighter (shared stack, no extra thread) but shares time with all other work items submitted to it.

Power Management in Drivers
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Zephyr's device power management subsystem defines four device states:

- ``PM_DEVICE_STATE_ACTIVE`` — device is fully powered and operational.
- ``PM_DEVICE_STATE_SUSPENDED`` — device is in a low-power state; operations are unavailable.
- ``PM_DEVICE_STATE_SUSPENDING`` — transition in progress toward suspended.
- ``PM_DEVICE_STATE_OFF`` — device has no power.

To support PM, implement a ``pm_action`` callback and pass it to ``DEVICE_DT_INST_DEFINE`` as the third argument (replacing ``NULL``). The callback receives ``PM_DEVICE_ACTION_SUSPEND`` or ``PM_DEVICE_ACTION_RESUME`` and applies the appropriate hardware state.

**Runtime PM** lets a driver manage its own power state. Call ``pm_device_runtime_get()`` before using the peripheral (the subsystem wakes it via the callback if needed) and ``pm_device_runtime_put()`` when done (the subsystem may then suspend it):

.. code-block:: c

   pm_device_runtime_get(dev);
   /* ... perform operation ... */
   pm_device_runtime_put(dev);   /* may trigger PM_DEVICE_ACTION_SUSPEND */

The get/put functions use a reference count. Consider an I2C bus with two devices attached:

- Device A calls ``pm_device_runtime_get()`` → count 0→1, the I2C bus resume callback fires.
- Device B calls ``pm_device_runtime_get()`` → count is already >0, no callback.
- Device A calls ``pm_device_runtime_put()`` → count drops to 1, still >0, no suspend callback.
- Device B calls ``pm_device_runtime_put()`` → count drops to 0, the I2C bus suspend callback fires.

PM Device Actions
~~~~~~~~~~~~~~~~~

The PM callback receives one of four actions:

.. list-table::
   :header-rows: 1
   :widths: 30 30 40

   * - Action
     - Triggered by
     - Notes
   * - ``PM_DEVICE_ACTION_SUSPEND``
     - PM subsystem (software)
     - Device enters low-power state; hardware power may remain on
   * - ``PM_DEVICE_ACTION_RESUME``
     - PM subsystem (software)
     - State is preserved; wake the device
   * - ``PM_DEVICE_ACTION_TURN_OFF``
     - Parent power domain
     - Power is about to be physically cut
   * - ``PM_DEVICE_ACTION_TURN_ON``
     - Parent power domain
     - Power was physically cut and restored; re-initialise hardware from scratch

``TURN_ON`` / ``TURN_OFF`` are only triggered via ``pm_device_children_action_run()`` from a parent power domain. If your device has no parent domain, these actions will never fire — implement only ``SUSPEND`` / ``RESUME`` and ignore the others.

When implementing a parent domain, child propagation is **not** automatic. Call ``pm_device_children_action_run()`` yourself and control the ordering:

- **Suspend**: send ``TURN_OFF`` to children first, then power down the domain.
- **Resume**: power up the domain first, then send ``TURN_ON`` to children.

Power Domains
~~~~~~~~~~~~~

A power domain is a regular Zephyr device that manages the physical power supply for a group of child devices. The PM core uses reference counting: when the last child suspends the domain powers off; when the first child resumes the domain powers on. Always target the child device via ``pm_device_runtime_get/put`` — never call the domain directly.

**Kconfig**:

.. code-block:: kconfig

   CONFIG_PM_DEVICE=y
   CONFIG_PM_DEVICE_POWER_DOMAIN=y
   CONFIG_PM_DEVICE_RUNTIME=y

**DTS setup**:

.. code-block:: dts

   / {
       my_domain: my-power-domain {
           compatible = "power-domain-gpio";
           enable-gpios = <&gpio0 5 GPIO_ACTIVE_HIGH>;
           startup-delay-us = <2000>;
           #power-domain-cells = <0>;
       };
   };

   &i2c1 {
       sensor_a: sensor@48 {
           /* ... */
           power-domains = <&my_domain>;
           zephyr,pm-device-runtime-auto;
       };
       sensor_b: sensor@49 {
           /* ... */
           power-domains = <&my_domain>;
           zephyr,pm-device-runtime-auto;
       };
   };

``power-domains`` is defined in ``base.yaml`` and available on every node. ``#power-domain-cells = <0>`` is required on the domain node (zero extra phandle cells). ``zephyr,pm-device-runtime-auto`` calls ``pm_device_runtime_enable()`` during init and immediately calls ``put()``, so the device starts suspended and the domain can power off at boot.

**How it works internally**: ``PM_DEVICE_DT_INST_DEFINE`` in the child driver creates a static ``pm_device`` struct with a ``domain`` pointer resolved at compile time from the DTS phandle. The PM core follows ``dev->pm->domain`` when managing the domain. All wiring is compile-time — no runtime registration.

With two sensors sharing a domain, the per-domain reference count reaches 2 when both are active. The GPIO rail only drops when both have called ``put()``.

System Power Management
~~~~~~~~~~~~~~~~~~~~~~~~

Zephyr provides two device PM strategies:

- **System-managed** (``CONFIG_PM_DEVICE_SYSTEM_MANAGED``): devices are suspended automatically when the CPU enters a low-power state.
- **Runtime PM** (``CONFIG_PM_DEVICE_RUNTIME``): explicit ``get``/``put`` reference counting per device; preferred method.

To shut down the system cleanly (Zephyr 3.4+):

.. code-block:: c

   #include <zephyr/sys/poweroff.h>

   sys_poweroff();   /* requires CONFIG_POWEROFF=y */

On older targets or when fine-grained control is needed, force a low-power state and yield to the idle thread:

.. code-block:: c

   pm_state_force(0, &(struct pm_state_info){PM_STATE_SOFT_OFF, 0, 0});
   k_sleep(K_FOREVER);

.. warning::
   Frequent suspend/resume cycles can consume more energy than staying active due to switching overhead and wake-up latency. Profile real current on real hardware before assuming that suspending always saves power. ``pm_device_runtime_put_async()`` defers the suspend by a configurable delay — a simpler equivalent to Linux's autosuspend — giving the device time to be reacquired without cycling power.

.. note::
   Some drivers do not implement PM callbacks and return ``-ENOSYS`` from ``pm_device_action_run()``. As a workaround, write power-down commands directly to the hardware registers.

----

Filesystems
-----------

A filesystem is an organisational layer between application code and raw storage hardware. Raw storage is just a flat array of bytes; the filesystem imposes structure on top of it. It does three jobs: **space management** (deciding where data lives), **metadata** (filenames, sizes, directories), and a **consistent API** (``open``, ``read``, ``write``, ``close``) that hides the hardware details from the application.

The stack runs from the application down to the physical medium:

.. code-block:: text

   Application
       │  open / read / write / close
   Filesystem Layer    organises data into files & directories
       │
   Storage Driver      talks to the hardware
       │
   Physical Storage    flash, SD card, RAM, ...

Virtual Filesystem Switch (VFS)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Zephyr's VFS lets multiple filesystems be mounted at different mount points at the same time — for example ``/lfs`` (LittleFS on internal flash) and ``/fatfs`` (FAT on an SD card). The application works purely in terms of paths; the VFS routes each operation to the filesystem that owns that path. Filesystems can be registered and unregistered at runtime.

Mount Points
~~~~~~~~~~~~

A mount point is the path at which a filesystem becomes accessible. It is declared in code with a filesystem type, a mount path, an ``fs_data`` pointer, and the storage partition the filesystem lives on. After ``fs_mount()`` succeeds, every path under that prefix is handled by that filesystem. Several filesystems can be mounted simultaneously at different points.

Comparison to Linux
~~~~~~~~~~~~~~~~~~~~

In Linux the filesystem abstraction covers storage *and* hardware — ``/dev``, ``/proc``, ``/sys`` all expose devices and kernel state as files ("everything is a file"). In Zephyr the filesystem is purely a storage abstraction; hardware access goes through separate subsystems (the GPIO API, UART API, and so on) rather than through filesystem paths.

Embedded Constraints
~~~~~~~~~~~~~~~~~~~~~

Filesystems on a microcontroller face constraints a desktop filesystem does not:

- **Limited write endurance** — flash cells survive only 10k–100k erase cycles, so writes must be spread out (wear levelling) rather than hammering the same block.
- **Unexpected power loss** — power can cut at any moment, so the filesystem must avoid corruption mid-write (power-loss safety).
- **Scarce RAM** — the filesystem must have a small memory footprint.

The two common choices reflect this: **LittleFS** is flash-safe and wear-aware, while **FAT** is chosen mainly for PC interoperability.

Key Terms
~~~~~~~~~

- **Mount point** — the path where a filesystem is attached.
- **Partition** — the defined region of physical storage a filesystem lives on.
- **Formatting** — initialising storage so a filesystem can use it.
- **Wear levelling** — spreading writes to avoid burning out individual flash cells.
- **Power-loss safety** — guaranteeing no corruption if power cuts mid-write.

Typical Use Cases
~~~~~~~~~~~~~~~~~

- **Config/state** — WiFi credentials, calibration values, application state persisted across reboots.
- **Logging** — buffering sensor readings or event logs to flash.
- **Firmware updates** — staging a downloaded image before applying it.
- **Assets** — audio clips, certificates, or lookup tables too large to keep in ROM.
- **PC interop** — a FAT-formatted SD card users can read and write on a PC.

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

----

Debugging
---------

Useful Kconfig Options
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: kconfig

   CONFIG_DEBUG_THREAD_INFO=y       # adds debug info to thread objects (visible in GDB)
   CONFIG_DEBUG_OPTIMIZATIONS=y     # disables optimisations that hinder single-stepping
   CONFIG_ASSERT=y                  # enables __ASSERT() runtime checks
   CONFIG_THREAD_NAME=y             # enables named threads (visible in a debugger)
   CONFIG_DEBUG=y                   # general debug build switch
   CONFIG_I2C_DUMP_MESSAGES=y       # dumps I2C transactions to the log

Breakpoints in VS Code
~~~~~~~~~~~~~~~~~~~~~~

Rather than halting execution unconditionally, VS Code supports richer breakpoint types. Right-click a breakpoint to choose:

- **Conditional expression** — only breaks when an expression evaluates to true.
- **Hit count** — only breaks after the breakpoint has been reached N times.
- **Log message** — prints a message to the debug console without stopping execution; useful for tracing without halting the target.

Halt Mode vs Monitor Mode
~~~~~~~~~~~~~~~~~~~~~~~~~~

When a breakpoint is hit, the processor can debug in two modes:

**Halt mode** (default)
   The entire processor is stopped. All threads, ISRs, and timers are frozen. The cleanest state for general debugging.

**Monitor mode**
   The breakpoint triggers the ``DebugMon`` exception instead of halting the core. A handler communicates with the debugger, allowing register and memory inspection. Because this runs in an exception handler, interrupts can still preempt it — time-critical ISRs continue to execute. Thread-mode code is paused.

   Enable with:

   .. code-block:: kconfig

      CONFIG_CORTEX_M_DEBUG_MONITOR_HOOK=y
      CONFIG_SEGGER_DEBUGMON=y

addr2line
~~~~~~~~~

``addr2line`` is a GCC tool that maps a raw memory address to a source file and line number — useful when a crash dump provides only a PC value:

.. code-block:: bash

   addr2line -e build/zephyr/zephyr.elf 0x08001234

Pass the ``.elf`` file and the address; the tool prints the corresponding source location.

Core Dumps
~~~~~~~~~~

Core dumps capture a snapshot of CPU registers and memory at the moment of a crash. Enable them with:

.. code-block:: kconfig

   CONFIG_DEBUG_COREDUMP=y
   CONFIG_DEBUG_COREDUMP_BACKEND_LOGGING=y   # output via Zephyr logging backend

Alternatively use ``CONFIG_DEBUG_COREDUMP_BACKEND_FLASH`` to store the dump on flash (requires a devicetree flash partition node). The device can transfer the dump over its communication interface on the next boot.

Analyse a captured dump with the provided GDB server script:

.. code-block:: bash

   python3 scripts/debug/coredump_gdbserver.py --elf build/zephyr/zephyr.elf dump.bin
   # In GDB: bt

.. note::
   Core dumps consume flash and RAM. The cost is more acceptable near production when a hardware debugger is unavailable. Tools like Memfault can collect and manage dumps from a fleet of devices in the field.

----

Shell
-----

Key Kconfig Symbols
~~~~~~~~~~~~~~~~~~~

- ``CONFIG_SHELL`` — the core shell subsystem (transport, parser, tab completion, history). Required by everything else.
- ``CONFIG_DEVICE_SHELL`` — adds ``device list`` / ``device info`` commands. Depends on ``CONFIG_SHELL``.

Architecture
~~~~~~~~~~~~

- Shell runs in its **own thread per backend instance** (UART, USB-CDC, RTT).
- Default stack: **2048 bytes**. Default priority: **0** (highest preemptive).
- Tunable via ``CONFIG_SHELL_STACK_SIZE``, ``CONFIG_SHELL_THREAD_PRIORITY``.
- Your **PC terminal is dumb** — it just sends raw bytes and renders what comes back.
- All intelligence (tab completion, history, line editing, command parsing) runs **on the device**.

Line Redraw
~~~~~~~~~~~

Device sends ``\r`` (CR, no LF) + ``\033[K`` (VT100 erase-to-end-of-line) then redraws the line. Terminal just executes the VT100 sequences blindly.

Shell vs Logging on Same UART
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- **Don't** use ``CONFIG_LOG_BACKEND_UART`` + shell on the same UART — output will interleave/corrupt.
- **Do** use ``CONFIG_SHELL_LOG_BACKEND=y`` — shell owns the UART and queues log messages, redrawing the prompt cleanly around them.

Splitting Shell and Logging onto Different UARTs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Done via the devicetree ``chosen`` node, typically in a board overlay:

.. code-block:: dts

   / {
       chosen {
           zephyr,shell-uart = &uart0;
           zephyr,console    = &uart1;
       };
   };

``LOG_BACKEND_UART`` is then safe — it writes to ``uart1``, shell owns ``uart0``.

Registering Shell Commands
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: c

   SHELL_STATIC_SUBCMD_SET_CREATE(sub_sensor,
       SHELL_CMD_ARG(read,  NULL, "Read sensor value", cmd_sensor_read,  1, 1),
       SHELL_CMD_ARG(reset, NULL, "Reset sensor",      cmd_sensor_reset, 1, 0),
       SHELL_SUBCMD_SET_END
   );
   SHELL_CMD_REGISTER(sensor, &sub_sensor, "Sensor commands", NULL);

- Uses **linker sections** — no registration call needed in ``main()``.
- Use ``shell_print(sh, ...)`` not ``printk`` inside handlers.
- Last two args of ``SHELL_CMD_ARG``: mandatory + optional arg counts (excluding command name).

Debug-Only Shell
~~~~~~~~~~~~~~~~

**Option 1 — conf overlay** (simplest):

.. code-block:: bash

   west build -- -DEXTRA_CONF_FILE=overlays/debug.conf

**Option 2 — custom Kconfig symbol** (best for large codebases):

.. code-block:: kconfig

   config MYAPP_DEBUG_SHELL
       bool "Enable debug shell"
       default n
       select SHELL
       select SHELL_BACKEND_SERIAL

Use ``SHELL_COND_CMD_REGISTER(CONFIG_MYAPP_DEBUG_SHELL, ...)`` in command files — no ``#ifdef`` needed.

----

nRF Platform Notes
------------------

Pin Control and UART Power Management
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

On nRF chips, peripherals are not hardwired to physical pins. ``pinctrl`` assigns pins to a peripheral's signals (TX, RX, CTS, RTS, etc.) by programming the peripheral's ``PSEL`` registers, and manages two pin states: **default** (active) and **sleep** (idle).

The sleep state applies ``low-power-enable``, which disconnects the pin's input buffer (``PIN_CNF.INPUT = Disconnect``). This prevents leakage current on floating or mid-voltage lines when the peripheral is inactive.

When runtime PM suspends a UART, the ``uarte_nrfx`` driver handles the transition in ``uarte_nrfx_pm_action()``:

- **Suspend**: disables the peripheral and calls ``pinctrl_apply_state(PINCTRL_STATE_SLEEP)``.
- **Resume**: calls ``pinctrl_apply_state(PINCTRL_STATE_DEFAULT)`` and re-enables the peripheral.

The same pattern applies to the SPI, I2C, and PWM nrfx drivers.

DPPI / PPI — Peripheral-to-Peripheral Connections
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Zephyr does not currently have a driver for nRF's DPPI (nRF53/nRF91) or PPI (nRF52) systems, which allow peripherals to trigger each other without CPU involvement. If you need peripheral-to-peripheral connections you must use the lower-level **nrfx** drivers directly.

.. warning::
   When using nrfx drivers instead of Zephyr drivers, Zephyr's automatic power management (``pm_device_runtime_get`` / ``pm_device_runtime_put``) does not run. You are responsible for managing peripheral power state manually.
