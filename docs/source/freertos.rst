FreeRTOS
========

FreeRTOS is a lightweight, open-source real-time operating system kernel for microcontrollers and small processors. It provides task scheduling, synchronisation primitives, and inter-task communication while remaining small enough to run on devices with kilobytes of RAM.

----

Task States
-----------

FreeRTOS tracks four task states: **Running**, **Ready**, **Blocked**, and **Suspended**.
The scheduler only considers tasks in the Ready state when deciding what to run next.

Running
~~~~~~~

The task currently executing on the CPU. Only one task can be in this state at a time.

If an interrupt fires, the interrupted task **remains in the Running state** from the
scheduler's perspective. The CPU saves the task's context, executes the ISR, then
restores the context. FreeRTOS has no "interrupted" state.

The only exception is if the ISR unblocks a higher-priority task and calls
``portYIELD_FROM_ISR()``, which causes a context switch and moves the interrupted
task to the Ready state.

Ready
~~~~~

Tasks that are able to run but are waiting for the CPU. FreeRTOS maintains one ready
list per priority level. The scheduler picks the highest-priority non-empty ready list
and runs the task at its head.

Blocked
~~~~~~~

A task waiting for a specific condition to be met. It unblocks **automatically** when
that condition is satisfied — no manual intervention required.

A task blocks itself by calling a FreeRTOS API function:

.. code-block:: c

   vTaskDelay(pdMS_TO_TICKS(1000));              // wait for time delay
   xQueueReceive(xQueue, &data, portMAX_DELAY);  // wait for queue data
   xSemaphoreTake(xSemaphore, portMAX_DELAY);    // wait for semaphore

The second argument to most blocking calls is a timeout. ``portMAX_DELAY`` means
wait indefinitely.

**Unblocking** happens in two ways:

- *Time delay expired* — the tick interrupt fires on every tick and checks the delay
  list. When a task's timeout has expired it is moved back to the ready list automatically.
- *Resource became available* — when another task or ISR calls ``xSemaphoreGive()``,
  ``xQueueSend()``, etc., FreeRTOS immediately checks the resource's waiting list and
  moves the waiting task to the ready list. This happens synchronously inside the give/send
  call itself, not on the next tick.

A blocked task consumes **zero CPU time** while waiting.

Suspended
~~~~~~~~~

A task that has been indefinitely paused with no condition to wake it up. It remains
suspended until explicitly resumed by another task or ISR.

.. code-block:: c

   vTaskSuspend(NULL);              // suspend yourself
   vTaskSuspend(xTaskHandle);       // suspend another task
   vTaskResume(xTaskHandle);        // resume from a task
   xTaskResumeFromISR(xTaskHandle); // resume from an ISR

Any task can suspend any other task regardless of priority — there is no priority
checking. This makes suspend a blunt instrument that must be used carefully.

Internal Data Structures
~~~~~~~~~~~~~~~~~~~~~~~~

FreeRTOS uses separate lists to track tasks in each state:

.. code-block:: text

   Ready Lists          (one per priority level)
   ├── priority 5: [taskA]
   ├── priority 3: [taskB → taskC]
   └── priority 1: [taskD]

   Delay Lists          (time-blocked tasks, sorted by expiry time)
   ├── pxDelayedTaskList:         [taskE(t=150) → taskF(t=300)]
   └── pxOverflowDelayedTaskList: [taskG]

   Per-Resource Lists   (embedded inside each queue/semaphore/mutex)
   ├── Queue1.waitingToReceive:  [taskH]
   └── Semaphore1.waiting:       [taskI]

   Suspended List
   └── [taskJ, taskK]

Every task is on exactly one of these lists at any given moment. The scheduler only
ever looks at the ready lists.

----

Synchronisation Primitives
--------------------------

Queues
~~~~~~

A queue is a thread-safe FIFO buffer for passing data between tasks.

- Created with a fixed capacity and fixed item size
- Sender blocks if full; receiver blocks if empty (with configurable timeout)
- Safe to use from ISRs via ``xQueueSendFromISR`` / ``xQueueReceiveFromISR``

.. code-block:: c

   QueueHandle_t xQueue = xQueueCreate(10, sizeof(int));
   xQueueSend(xQueue, &value, portMAX_DELAY);
   xQueueReceive(xQueue, &received, portMAX_DELAY);

**Multiple tasks on one queue:** Only one task unblocks per item received —
the highest priority waiter, then FIFO among equals. Give each consumer its
own queue if they need different data.

**Broadcast to all tasks:** Use an Event Group instead.

Semaphores
~~~~~~~~~~

A semaphore carries no data — it is purely a signalling mechanism.

Binary semaphore
^^^^^^^^^^^^^^^^

Acts as a flag (0 or 1). Ideal for ISR-to-task signalling, where one entity
gives and a different entity takes.

.. code-block:: c

   SemaphoreHandle_t xSem = xSemaphoreCreateBinary();
   xSemaphoreGiveFromISR(xSem, &xHigherPriorityTaskWoken); // from ISR
   xSemaphoreTake(xSem, portMAX_DELAY);                    // in task

Counting semaphore
^^^^^^^^^^^^^^^^^^

Tracks N available resources (e.g. 3 DMA buffers). Take to claim one,
Give to release it.

.. code-block:: c

   SemaphoreHandle_t xSem = xSemaphoreCreateCounting(3, 3);

Mutexes
~~~~~~~

A mutex is a binary semaphore with **ownership**: the task that takes it
must be the one to give it back. Use for protecting shared resources, not
for signalling.

.. code-block:: c

   SemaphoreHandle_t xMutex = xSemaphoreCreateMutex();
   xSemaphoreTake(xMutex, portMAX_DELAY);
   // access shared resource
   xSemaphoreGive(xMutex); // same task gives it back

Priority Inheritance
^^^^^^^^^^^^^^^^^^^^

FreeRTOS mutexes implement priority inheritance to prevent priority
inversion.

**The problem (priority inversion):**

1. Low-priority task takes the mutex
2. High-priority task blocks waiting for the mutex
3. Medium-priority task pre-empts the low-priority task
4. High-priority task is now starved by a medium-priority task

**The fix (priority inheritance):**

When the high-priority task blocks, FreeRTOS temporarily boosts the
low-priority task's priority to match, preventing the medium-priority task
from pre-empting it. Once the mutex is released the priority is restored.

Binary semaphores do **not** have priority inheritance — use a mutex
whenever protecting a shared resource.

Event Groups
~~~~~~~~~~~~

An event group is a set of binary flags (bits) that tasks can set, clear, and wait on.
Each bit represents a condition. Tasks block until their condition is satisfied, then
the scheduler moves them to the ready state.

- ``xEventGroupCreate()`` — create a group, returns a handle
- ``xEventGroupSetBits()`` — set one or more bits
- ``xEventGroupClearBits()`` — clear one or more bits
- ``xEventGroupWaitBits()`` — block until bits are satisfied
- ``xEventGroupSync()`` — barrier synchronisation (see below)

``xEventGroupWaitBits()`` supports two modes:

- **AND** — task unblocks only when *all* specified bits are set
- **OR** — task unblocks when *any* specified bit is set

When a task calls ``xEventGroupWaitBits()`` and the condition is not met:

1. The task is removed from the ready list and placed on the event group's waiting list.
2. When ``xEventGroupSetBits()`` is called, FreeRTOS walks the waiting list **once**,
   evaluating each waiter against the new bit state in priority order.
3. Satisfied tasks are moved to the ready list. The scheduler then runs.

Clear-on-exit
^^^^^^^^^^^^^

If ``xClearOnExit`` is set, the bits are cleared **inline during the list walk**,
before any unblocked task actually runs:

- The bit is cleared before the unblocked task executes a single instruction.
- Lower priority tasks waiting on the same bit are evaluated against the already-cleared
  state and remain blocked.
- No task ever needs to manually clear the bit.

If the bit is set again before the unblocked task runs, the task does not re-wait —
its ``xEventGroupWaitBits()`` call has already returned. The task has no visibility of
the second set event. For this reason, event groups represent **current state**, not
occurrences.

Event groups vs queues
^^^^^^^^^^^^^^^^^^^^^^

Use a **queue** when the value matters and every occurrence must be processed
(e.g. passing a sensor reading to a logger — each value must be recorded).

Use an **event group** when you only need to know the current state, and missed
intermediate transitions are acceptable (e.g. is WiFi connected right now?).

Event groups vs semaphores
^^^^^^^^^^^^^^^^^^^^^^^^^^

- **Binary semaphore** — one task signals one other task. Simple ping, no conditions.
- **Counting semaphore** — tracks how many times something has occurred.
- **Event group** — wait for combinations of conditions simultaneously (AND/OR logic).

If you find yourself taking multiple semaphores in sequence to combine conditions,
switch to an event group.

Barrier synchronisation
^^^^^^^^^^^^^^^^^^^^^^^

``xEventGroupSync()`` is used when a group of tasks must all reach a point before any
of them continue. Each task sets its own bit and waits for all other tasks' bits:

.. code-block:: c

   xEventGroupSync(
       barrierGroup,
       BIT_MY_TASK,                            /* bit this task sets        */
       BIT_TASK_A | BIT_TASK_B | BIT_TASK_C,  /* bits to wait for          */
       portMAX_DELAY
   );
   /* all tasks proceed from here together */

When the last task calls ``xEventGroupSync()``, FreeRTOS clears all barrier bits
atomically as part of unblocking everyone — no manual clearing required, no race
conditions.

----

Stream Buffers and Message Buffers
------------------------------------

Stream buffers and message buffers are lightweight, lock-free primitives for
passing data between exactly **one writer** and **one reader**. Because they are
lock-free by design they are safe to use directly from ISRs without any
additional protection.

Stream Buffers
~~~~~~~~~~~~~~

A stream buffer is a continuous byte-stream FIFO with no message framing. Data
is written and read in arbitrary chunk sizes — the receiver reassembles meaning
from the raw stream.

Key properties:

- Single-reader / single-writer only (enforced by the lock-free design)
- ISR-safe via ``xStreamBufferSendFromISR()``
- No message boundaries
- Trigger level controls when the receiver task unblocks

Trigger Level
^^^^^^^^^^^^^

The trigger level is set at creation time (or via
``xStreamBufferSetTriggerLevel()``), not per receive call. The receiver task
blocks until at least this many bytes are available — it is a property of the
buffer, not of individual calls.

.. code-block:: c

   /* 256-byte buffer, unblock receiver when >= 16 bytes are ready */
   xSB = xStreamBufferCreate(256, 16);

   /* unblocks at trigger level, reads up to 64 bytes */
   received = xStreamBufferReceive(xSB, rxBuf, 64, portMAX_DELAY);

The receive call can return fewer bytes than requested — always check the
return value.

Sending from an ISR
^^^^^^^^^^^^^^^^^^^

``xStreamBufferSendFromISR()`` never blocks. If the buffer is full it writes as
many bytes as it can and returns immediately; the return value indicates how
many bytes were actually written, which may be zero.

.. code-block:: c

   void UART_IRQHandler(void) {
       uint8_t byte = UART->DR;
       xStreamBufferSendFromISR(xSB, &byte, 1, &xHigherPriorityTaskWoken);
       portYIELD_FROM_ISR(xHigherPriorityTaskWoken);
   }

Blocking is forbidden in ISRs because the scheduler cannot context-switch inside
one. All ``FromISR`` FreeRTOS functions follow this contract.

Message Buffers
~~~~~~~~~~~~~~~

A message buffer is built on top of a stream buffer. It prepends a **4-byte
length header** to each write, preserving message boundaries so that each
``xMessageBufferReceive()`` call dequeues exactly one complete message.

.. code-block:: text

   Underlying storage:
   [ 0x05 0x00 0x00 0x00 | H e l l o | 0x03 0x00 0x00 0x00 | A C K ]
     |←— 4B length ————>| |←— msg —>| |←— 4B length ————>| |<msg>|

Key properties:

- Each ``xMessageBufferReceive()`` returns exactly one message
- Receiver unblocks as soon as one complete message is available
- Receive buffer must be large enough for the largest possible message
- 4-byte overhead per message

If several messages have accumulated while a task was busy processing, subsequent
receive calls return immediately as long as the buffer is non-empty. A common
drain pattern:

.. code-block:: c

   while (1) {
       /* block until at least one message arrives */
       received = xMessageBufferReceive(xMB, rxBuf, sizeof(rxBuf), portMAX_DELAY);
       processMessage(rxBuf, received);

       /* drain any further messages without blocking */
       while ((received = xMessageBufferReceive(xMB, rxBuf, sizeof(rxBuf), 0)) > 0) {
           processMessage(rxBuf, received);
       }
   }

A Typical Real-World Architecture
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A common pattern for UART-based protocols layers both primitives:

.. code-block:: text

   UART hardware (1 byte at a time)
        │
   [ISR] xStreamBufferSendFromISR()
        │
   Stream buffer  ← raw bytes, no framing
        │
   [Parser task]  ← accumulates bytes, hunts for delimiters,
        │            validates checksums, assembles complete frames
   xMessageBufferSend()
        │
   Message buffer  ← clean, validated, complete frames
        │
   [Application task] xMessageBufferReceive()
                  ← one call = one complete command, no parsing needed

The parser task acts as the boundary between the raw-bytes world and the
structured-messages world, shielding application logic from hardware-level
concerns and making each layer independently testable.

When to use each
^^^^^^^^^^^^^^^^

- Use a **stream buffer** when data comes from hardware and message boundaries
  are your problem to figure out.
- Use a **message buffer** when data comes from another task and message
  boundaries are already known.

----

Software Timers
---------------

Software timers execute a callback function at a future point in time, or
periodically, without consuming a hardware timer peripheral. They are managed
entirely by the FreeRTOS **daemon task** (also called the Timer Service task).

Two modes:

- **One-shot** -- fires callback once, then goes dormant.
- **Auto-reload** -- automatically restarts after each expiry, firing periodically.

Architecture
~~~~~~~~~~~~

Timer API calls (``xTimerStart``, ``xTimerStop``, etc.) never act directly on
a timer. Instead they post a command to the **timer command queue**. The daemon
task wakes up, reads the command, and acts on it.

.. code-block:: text

   App task  →  [command queue]  →  Daemon task  →  callback()

Key implications:

- API calls are non-blocking (return immediately).
- Callbacks run inside the daemon task context -- never in the calling task.
- Callbacks must not block or call blocking APIs.
- All callbacks run sequentially -- a slow callback delays all others.

How Timers Are Decremented
~~~~~~~~~~~~~~~~~~~~~~~~~~

FreeRTOS does **not** count down timers in a loop. The mechanism is tick-based:

1. A hardware timer (e.g. SysTick on ARM Cortex-M) fires a periodic ISR.
2. The ISR increments the global ``xTickCount`` counter.
3. If SW timers are enabled (``configUSE_TIMERS = 1``), the ISR peeks at the
   **head** of a sorted expiry list.
4. If the head timer has expired, the ISR unblocks the daemon task via the
   command queue. The ISR then returns immediately -- O(1) cost.
5. The daemon task wakes up and walks the list, firing all expired callbacks
   and reloading any auto-reload timers.

Timers are stored by **absolute expiry tick** (``xTickCount + period`` at
start time), not by a remaining countdown. The list is sorted ascending, so
the ISR only ever needs to check the head.

Multiple timers expiring on the same tick
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The ISR still only checks the head and unblocks the daemon once. The daemon
then handles all expired timers in sequence. Callback order among same-tick
timers is an implementation detail and must not be relied upon.

Accuracy and Jitter
~~~~~~~~~~~~~~~~~~~

SW timers are **not cycle-accurate**. Two sources of jitter:

1. **Tick granularity** -- resolution is one tick. At ``configTICK_RATE_HZ = 1000``
   this is 1 ms. Jitter is 0--1 tick depending on when ``xTimerStart`` was
   called within the current tick period.

2. **Daemon task scheduling delay** -- even after the ISR flags an expiry, the
   daemon must be scheduled before the callback runs. A higher-priority running
   task delays the callback by however long it holds the CPU.

When to use what
^^^^^^^^^^^^^^^^

+-------------------------------+------------------------------------------+
| Requirement                   | Approach                                 |
+===============================+==========================================+
| ±1--2 ms accuracy (timeouts,  | SW timers -- fine                        |
| debounce, LED blink)          |                                          |
+-------------------------------+------------------------------------------+
| Sub-millisecond / hard        | Hardware timer peripheral + ISR directly |
| real-time                     |                                          |
+-------------------------------+------------------------------------------+
| Periodic task at exact rate   | ``vTaskDelayUntil()`` in a dedicated     |
|                               | task -- more predictable                 |
+-------------------------------+------------------------------------------+

Key Configuration (FreeRTOSConfig.h)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: c

   #define configUSE_TIMERS              1
   #define configTIMER_TASK_PRIORITY     (configMAX_PRIORITIES - 1)
   #define configTIMER_QUEUE_LENGTH      10
   #define configTIMER_TASK_STACK_DEPTH  256

----

How an Interrupt Is Handled
----------------------------

**1. Hardware responds immediately**

The CPU finishes its current instruction (not its current task — just the single instruction), saves its registers, and jumps to the Interrupt Service Routine (ISR). This happens in hardware, in a handful of CPU cycles. FreeRTOS has nothing to do with this part — it's purely the CPU.

**2. The ISR runs**

The ISR should do as little as possible — read the hardware register, clear the interrupt flag, and signal a task to do the real work. In FreeRTOS you use the ``FromISR`` API variants here:

.. code-block:: c

   void UART_IRQHandler(void) {
       char received = UART->DATA;
       xQueueSendFromISR(xQueue, &received, &xHigherPriorityTaskWoken);
       portYIELD_FROM_ISR(xHigherPriorityTaskWoken);
   }

**3. portYIELD_FROM_ISR() triggers a context switch**

If ``xHigherPriorityTaskWoken`` was set to ``pdTRUE`` by the queue send (meaning a higher-priority task is now ready), this macro tells the scheduler to switch to that task the moment the ISR exits — not at the next tick, immediately.

On ARM Cortex-M, the macro does this by writing to the **ICSR** (Interrupt Control and State Register) to pend the **PendSV** exception:

.. code-block:: c

   /* What portYIELD_FROM_ISR expands to on Cortex-M */
   portNVIC_INT_CTRL_REG = portNVIC_PENDSVSET_BIT;

PendSV is intentionally configured at the **lowest possible interrupt priority**. This means it won't fire immediately — it waits until all higher-priority ISRs have finished. Once your UART ISR returns, the CPU sees the pending PendSV and jumps straight to it (using Cortex-M **tail-chaining**, so no return to the interrupted task happens in between).

The PendSV handler is the FreeRTOS context switcher. It:

1. Saves the remaining registers of the **currently interrupted task** onto that task's stack
2. Calls the scheduler to determine the new highest-priority ready task
3. Restores the registers of the **new task** from its stack
4. Returns — which resumes the new task, not the originally interrupted task

The interrupted task is not lost — its full CPU state is saved on its own stack and it remains in the ready list. It will resume normally when it is next scheduled.

**4. The high-priority task runs**

The task that was waiting on the queue unblocks and runs right away, preempting whatever was running before the interrupt.

The pattern of deferring real work from the ISR to a task is called **Interrupt Deferred Processing**.

----

The Ready-List Bitmap
~~~~~~~~~~~~~~~~~~~~~

FreeRTOS maintains one linked list of tasks per priority level. To find the next task to run it needs to find the highest priority that has at least one ready task.

Instead of scanning from the top priority downward (O(n)), FreeRTOS maintains a single integer where each bit represents one priority level:

.. code-block:: text

   Priority:  7  6  5  4  3  2  1  0
   Bitmap:    0  0  1  0  1  1  0  0
                   ^        ^
                   |        Tasks ready at priority 2 and 3
                   Task ready at priority 5 — this one wins

To find the highest ready priority, FreeRTOS uses the **CLZ (Count Leading Zeros)** CPU instruction — a single hardware instruction on ARM Cortex-M that returns the position of the highest set bit in one cycle. Finding the next task to run is literally one instruction, regardless of how many priorities or tasks exist.

Selecting the Task Within a Priority
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Once the winning priority is known, FreeRTOS indexes into ``pxReadyTasksLists[]`` — an array of circular linked lists, one per priority. Each list has a ``pxIndex`` pointer that remembers where it left off:

.. code-block:: text

   pxReadyTasksLists[5]:  TaskA ↔ TaskB ↔ TaskC ↔ (back to TaskA)
                                    ^
                                 pxIndex — this task runs next

The scheduler advances ``pxIndex`` to the next entry and reads the **TCB (Task Control Block)** pointer stored there. That TCB becomes ``pxCurrentTCB`` — the running task. On the next scheduler invocation at the same priority, ``pxIndex`` advances again, giving each task at that priority equal time — this is the round-robin within a priority level.

If a task is blocked, suspended, or deleted it is removed from the ready list entirely (and its priority's bit is cleared in the bitmap if the list becomes empty), so ``pxIndex`` only ever lands on tasks that are actually runnable.

----

The Tick Interrupt
------------------

FreeRTOS uses a hardware timer configured to fire at a fixed rate — ``configTICK_RATE_HZ`` in ``FreeRTOSConfig.h``. Commonly 1000 Hz (every 1 ms). On ARM Cortex-M this hooks into the **SysTick** peripheral, a dedicated timer built into every Cortex-M core.

Every time the tick fires, the ISR does two things:

1. **Increments the tick count** — this is how FreeRTOS tracks time. ``vTaskDelay(100)`` means "unblock me after 100 ticks".
2. **Calls the scheduler** — checks if any blocked tasks have expired their delay, unblocks them, and decides if a context switch is needed.

.. code-block:: text

   Every 1 ms (at 1000 Hz):
     Tick ISR fires
       → increment xTickCount
       → check delayed task list — unblock any that have expired
       → if higher priority task is now ready → context switch
       → resume highest priority ready task

The tick drives time-based scheduling, but context switches also happen immediately in response to events:

- A task calls ``vTaskDelay()`` → yields immediately, doesn't wait for the next tick
- An ISR sends to a queue and calls ``portYIELD_FROM_ISR()`` → switch happens at ISR exit
- A task blocks on a semaphore that isn't available → switch happens immediately

Tickless Idle Mode
~~~~~~~~~~~~~~~~~~

FreeRTOS has a **tickless idle** mode (``configUSE_TICKLESS_IDLE``) for low-power devices. When no tasks need to run for a known period, the scheduler suppresses the tick interrupt entirely, lets the CPU sleep deeply, and then wakes on a real event or when the next task is due — correcting the tick count for the time that passed. This is how battery-powered devices achieve sleep currents in the microamp range.

----

SysTick and PendSV: Division of Responsibility
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The two interrupts have distinct roles:

**SysTick** runs on every tick and owns timekeeping and readiness decisions:

1. Increments ``xTickCount``
2. Walks the delayed-task list — any task whose timeout has expired is moved from the delayed list back to the ready list
3. Checks whether the newly-readied tasks (or round-robin within the same priority) require a context switch

If a switch *is* needed, SysTick doesn't do it directly. It pends **PendSV** — a cheap register write — and returns.

**PendSV** is configured at the lowest interrupt priority so it fires only after all other pending ISRs have exited. It owns the actual context switch:

1. Saves the remaining CPU registers of the current task onto its stack (hardware already saved a subset on interrupt entry)
2. Updates the current-task pointer to the new highest-priority ready task
3. Restores the new task's registers from its stack
4. Returns — resuming the new task

This split keeps SysTick fast (timekeeping only) and defers the expensive register save/restore to PendSV, which runs at the safest possible moment.

----

Pausing the Scheduler
----------------------

FreeRTOS provides two distinct mechanisms depending on what you need to protect against.

Suspend the Scheduler
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: c

   vTaskSuspendAll();
   /* multi-step time-critical work */
   xTaskResumeAll();

This stops task switching but — critically — **interrupts still fire normally**. The tick ISR still runs, time is still tracked, but no context switch will happen mid-way through your code. This is the lighter-weight option, preferred when your concern is another task preempting you rather than an ISR corrupting shared data.

During ``vTaskSuspendAll()``, the tick ISR will still:

- Increment the tick count
- Walk the delayed task list and unblock any tasks whose delay has expired
- Track that a context switch is **pending** (via the ``xYieldPending`` flag)

It will **not** actually perform the context switch. When ``xTaskResumeAll()`` is called, it checks ``xYieldPending`` and if a higher-priority task became ready while the scheduler was suspended, it performs the context switch at that point. Time still advances correctly and no delayed task misses its wakeup.

Disable Interrupts (Critical Section)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: c

   taskENTER_CRITICAL();
   /* very short time-critical work */
   taskEXIT_CRITICAL();

This disables interrupts up to a configurable priority threshold (``configMAX_SYSCALL_INTERRUPT_PRIORITY``). Nothing can preempt you — no task switch, no ISR. The tradeoff is that your interrupt latency directly suffers for the duration, so this must be kept very short — think microseconds, not milliseconds.

Since the scheduler is driven by the tick interrupt, disabling interrupts also stops the scheduler for the duration: no tick fires, no scheduler runs, no context switch.

Both mechanisms are nestable — you can call them multiple times and they only actually release when the nesting count returns to zero.

----

The Cortex-M Interrupt Priority Detail
---------------------------------------

On ARM Cortex-M, FreeRTOS uses the **BASEPRI** register to mask only interrupts at or below ``configMAX_SYSCALL_INTERRUPT_PRIORITY`` — not all interrupts. Interrupts above that threshold still fire unmasked:

.. code-block:: text

   Priority 0  ← never masked (hard fault, NMI)
   Priority 1  ← never masked
   Priority 2  ← never masked
   ----- configMAX_SYSCALL_INTERRUPT_PRIORITY -----
   Priority 3  ← masked during critical section
   Priority 4  ← masked (tick interrupt lives here)
   Priority 5  ← masked

This lets you have extremely high priority interrupts that can never be blocked by anything FreeRTOS does. The tradeoff: those ISRs cannot call any FreeRTOS API at all — not even the ``FromISR`` variants.

----

Memory Allocation
-----------------

FreeRTOS allocates task stacks and kernel objects (queues, semaphores, mutexes, etc.) from the
heap by default. Objects can also be allocated **statically** using the ``...Static`` API variants
(e.g. ``xTaskCreateStatic()``), passing pre-allocated buffers at creation time — FreeRTOS never
calls the heap allocator in this case.

Heap Management Schemes
~~~~~~~~~~~~~~~~~~~~~~~

FreeRTOS ships five heap implementations in ``Source/portable/MemMang/``. Choose one based on
your allocation pattern:

+----------+-------------------------------------------------------------------+
| Scheme   | Behaviour                                                         |
+==========+===================================================================+
| heap_1   | Allocate-only, no free. Fully deterministic. Suited to            |
|          | safety-critical systems where fragmentation is unacceptable.      |
+----------+-------------------------------------------------------------------+
| heap_2   | Adds ``free()`` but does not coalesce adjacent free blocks.       |
|          | Can fragment over time. Largely superseded by heap_4.             |
+----------+-------------------------------------------------------------------+
| heap_3   | Wraps the compiler's ``malloc``/``free`` with scheduler           |
|          | suspension for thread safety.                                     |
+----------+-------------------------------------------------------------------+
| heap_4   | Best-fit allocator with free-block coalescing. The most           |
|          | common choice for general embedded use.                           |
+----------+-------------------------------------------------------------------+
| heap_5   | Extends heap_4 across multiple non-contiguous memory regions      |
|          | (e.g. internal SRAM + external SDRAM).                            |
+----------+-------------------------------------------------------------------+

----

Stack Size Analysis
-------------------

Static stack analysis determines the maximum stack usage of a program without running it.
In general, this is not always possible — VLAs, ``alloca()``, function pointers, and indirect
recursion all defeat static analysis. Plain C with none of those constructs is fully analysable.

The process has two steps:

1. **Per-function frame sizes** — GCC's ``-fstack-usage`` flag emits ``.su`` files at compile
   time, labelling each function's frame as ``static``, ``dynamic``, or ``dynamic,bounded``.

2. **Call graph analysis** — a separate tool walks the call graph and sums worst-case depth.
   Open-source options include ``cflow`` and ``egypt``; commercial tools such as AbsInt
   StackAnalyzer and IAR Embedded Workbench provide certified analysis for safety-critical work
   (DO-178C, ISO 26262).

FreeRTOS requires the developer to specify each task's stack size manually in ``xTaskCreate()``.
It does not perform static analysis. The practical workflow is to monitor stack and heap headroom
at runtime, and to enable overflow detection during development.

Runtime Memory Checks
~~~~~~~~~~~~~~~~~~~~~

Two APIs expose memory headroom at runtime:

- ``uxTaskGetStackHighWaterMark(task)`` — returns the minimum free stack space (in words)
  recorded since the task started. A value close to zero means the stack is nearly exhausted
  and the allocation in ``xTaskCreate()`` should be increased.
- ``xPortGetFreeHeapSize()`` / ``xPortGetMinimumEverFreeHeapSize()`` — return the current
  and historically lowest free heap bytes, useful for confirming the heap is not dangerously
  tight.

Stack Overflow Detection
~~~~~~~~~~~~~~~~~~~~~~~~

``configCHECK_FOR_STACK_OVERFLOW`` enables checking on every context switch:

- **Mode 1** — checks that the task's stack pointer is within its allocated region at the moment
  of the switch. Cheap, but only catches overflows still present at context switch time.
- **Mode 2 (stack canary)** — fills the last few words of each stack with a known pattern at task
  creation and verifies the pattern on every context switch. If it has been overwritten,
  ``vApplicationStackOverflowHook()`` is called. More reliable than mode 1 as it catches
  overflows that occurred and partially recovered between switches.
