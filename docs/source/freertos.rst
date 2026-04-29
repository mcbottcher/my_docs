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
It does not perform static analysis. The practical workflow is to enable
``configCHECK_FOR_STACK_OVERFLOW`` for safety and use ``uxTaskGetStackHighWaterMark()`` at
runtime to tune sizes empirically.
