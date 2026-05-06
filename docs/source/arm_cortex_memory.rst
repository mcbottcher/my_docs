🧠 ARM Cortex-M Memory Model
============================

The ARM Cortex-M memory model governs how a CPU and other bus masters (DMA controllers,
second cores) observe memory. Understanding it is essential for correct bare-metal and
RTOS code on STM32 and similar devices — particularly when sharing memory between a CPU
and a DMA peripheral, or between two cores on the STM32H7 (Cortex-M7 + Cortex-M4).

----

Volatile
--------

``volatile`` is a **compiler-only** directive. It does two things:

- Forces the compiler to re-read the variable from memory on every access,
  preventing it from holding the value in a CPU register across accesses.
- Prevents the compiler from reordering accesses to that variable relative
  to other code, since every access is treated as a visible side effect.

``volatile`` does **not** affect hardware. The CPU's own pipeline, write buffer,
and cache can still reorder or delay memory accesses independently of what
the compiler emits. For hardware ordering guarantees, memory barrier instructions
are required.

----

Hardware Features That Affect Memory Ordering
----------------------------------------------

Several hardware mechanisms can cause a CPU to observe memory in a different
order than the program's source suggests.

Write Buffer
~~~~~~~~~~~~

When the CPU executes a store instruction, the value is placed into a small
hardware queue (the write buffer) and the CPU immediately continues executing.
The write propagates to RAM in the background. From the perspective of any other
bus master (DMA controller, second CPU core), the write may not yet be visible.
``__DSB()`` drains the write buffer before proceeding.

Out-of-Order Execution
~~~~~~~~~~~~~~~~~~~~~~

The CPU pipeline may reorder independent instructions to keep execution units
busy. On Cortex-M4 this is limited; on Cortex-M7 and Cortex-A it is more
aggressive. Memory barriers prevent reordering across the barrier point.

D-Cache
~~~~~~~

A physical SRAM sitting between the CPU and main RAM. Present on Cortex-M7
(e.g. STM32F7, STM32H7) but **not** on Cortex-M4 (STM32F3, STM32F4). The CPU
reads and writes to the cache; RAM is only updated when cache lines are flushed
or evicted. Any other bus master that accesses RAM directly (DMA, second core)
will not see writes that are still in cache, and vice versa. Cache maintenance
operations are required to restore coherency.

Speculative Reads
~~~~~~~~~~~~~~~~~

The CPU may read memory ahead of time in anticipation of future instructions.
This can cause a load to happen before a preceding store has settled. Barriers
prevent the CPU from acting on speculatively fetched data across the barrier.

----

Barrier Instructions (CMSIS)
-----------------------------

Defined in ``core_cm4.h`` / ``core_cm7.h``, provided by ARM's CMSIS layer.
Each compiles to a single ARM instruction with a ``"memory"`` compiler clobber,
which simultaneously prevents hardware reordering and compiler reordering across
the barrier.

DSB — Data Synchronisation Barrier
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: c

   __DSB();

Stalls the CPU until all pending memory accesses and cache maintenance operations
have fully completed and are visible to all observers of the memory system. The
strongest of the three for data.

DMB — Data Memory Barrier
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: c

   __DMB();

Ensures that all memory accesses before the barrier are observed before any
memory accesses after it. Does **not** wait for those accesses to complete —
only enforces their relative ordering.

Reordering is a CPU-side phenomenon — it happens in the pipeline and execution
units before writes ever reach the write buffer or RAM. Once a write is in the
write buffer it will reach RAM in order; the danger is the CPU issuing writes
to the write buffer in the wrong order in the first place. DMB prevents this
by constraining the order in which the CPU commits accesses, without having to
wait for them all to drain.

ISB — Instruction Synchronisation Barrier
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: c

   __ISB();

Flushes the CPU instruction pipeline, forcing all subsequent instructions to
be re-fetched. Does not directly relate to data ordering — it ensures the CPU
is executing with a clean view of any changes that affect instruction decode
(vector table, MPU config, cache enable/disable).

----

Memory Types (ARM Memory Model)
--------------------------------

The MPU assigns a **memory type** to each address region. The memory type
determines what ordering and caching guarantees the hardware provides.

Normal Memory
~~~~~~~~~~~~~

RAM. The CPU may reorder accesses, buffer writes, and speculate reads. No
ordering guarantees without explicit barriers. Cacheable or non-cacheable
depending on MPU attributes.

Device Memory
~~~~~~~~~~~~~

Peripheral registers. No reordering, no speculation, no write merging. Accesses
complete before the next instruction proceeds. ``volatile`` (``__IO``) is
sufficient for peripheral registers because the hardware provides the ordering
guarantee that Normal memory does not.

Strongly Ordered
~~~~~~~~~~~~~~~~

Strictest. Every access is a full synchronisation point. Rarely used on Cortex-M.

----

MPU and Cache Relationship
---------------------------

The MPU and D-cache are **separate hardware blocks** inside the CPU core.
The cache controller has a direct hardwired connection to the MPU and performs
a lookup on every memory access to determine the attributes of that address.
This happens in hardware with no software involvement at runtime.

----

Cache Coherency and Shared Memory
-----------------------------------

Any scenario where RAM is written by one observer and read by another that does
not share the same cache introduces a coherency problem. Common cases:

- **DMA → CPU** — DMA writes to RAM, CPU cache holds stale values.
  Invalidate cache after the transfer completes before the CPU reads.
- **CPU → DMA** — CPU writes to cache (write-back), RAM not yet updated.
  Clean cache before starting DMA transmit.
- **Core-to-core (STM32H7 M7 + M4)** — each core has its own private cache.
  Shared buffers should be placed in a non-cacheable MPU region, or explicit
  clean/invalidate must be performed on both sides with ``__DMB()`` for ordering.

Cache maintenance functions from ``core_cm7.h`` (Cortex-M7 only):

.. code-block:: c

   SCB_CleanDCache_by_Addr((uint32_t*)buf, size);      // flush to RAM (before read by other master)
   SCB_InvalidateDCache_by_Addr((uint32_t*)buf, size); // discard cache copy (after write by other master)

- **Clean** — push dirty cache lines to RAM.
- **Invalidate** — discard the cache's copy, forcing the next read to go to RAM.

----

Non-Cacheable MPU Region
-------------------------

The cleanest solution for any shared memory (DMA buffers, inter-core buffers)
on H7/F7 is to permanently mark a dedicated RAM region as non-cacheable in the
MPU at startup. No manual cache maintenance is needed at runtime.

Some chip families formalise this in their memory map. The STM32H7 has specific
SRAM regions (e.g. SRAM4 at ``0x38000000``) commonly reserved by convention for
DMA and inter-core shared buffers. Rather than scattering DMA buffers throughout
RAM and manually managing coherency for each one, all shared data is placed in
this dedicated region and the problem is solved structurally.

Place shared buffers at this address via the linker script. ``__DSB()`` is still
required when signalling between tasks or cores, as the write buffer still applies
even without a cache.
