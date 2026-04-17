⚡ Zephyr RTOS
==============

Zephyr is an open-source real-time operating system (RTOS) designed for resource-constrained embedded devices. It provides a rich set of kernel services — threading, scheduling, synchronisation, data passing, and memory management — while remaining highly configurable via its ``Kconfig`` build system.

.. note::
   Useful resources:

   - `Nordic Developer Academy — ncs-fund <https://github.com/NordicDeveloperAcademy/ncs-fund>`_
   - `Zephyr Scheduling Documentation <https://docs.zephyrproject.org/latest/kernel/services/scheduling/index.html>`_

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

Time-Slicing
~~~~~~~~~~~~

Time-slicing allows threads of equal priority to share CPU time. Enable it with:

.. code-block:: kconfig

   CONFIG_TIMESLICING=y
   CONFIG_TIMESLICE_SIZE=10     # maximum time slice in ms before forced preemption
   CONFIG_TIMESLICE_PRIORITY=0  # threads at or below this priority are subject to slicing

.. note::
   Lower priority numbers mean **higher** priority. Priority 0 is the highest.

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
