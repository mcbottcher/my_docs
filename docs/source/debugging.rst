Debugging
=========

General debugging techniques and tools for embedded systems.

----

RTT — Segger Real-Time Transfer
---------------------------------

RTT (Real-Time Transfer) is a debug logging transport developed by Segger. Instead of using a hardware peripheral like UART, log data is written into a small ring buffer in the target's RAM. The debug probe reads that RAM region directly over the debug interface (SWD/JTAG) without involving the CPU again.

**Why this matters:**

- Writing to the RTT buffer is non-blocking and very fast — the CPU is not stalled waiting for a byte to clock out over UART.
- No UART pins required; the same SWD connection used for flashing and debugging carries the log traffic.
- Latency and jitter of log output are decoupled from the UART baud rate.

The trade-off is that you need an active debug probe connection to read the buffer. RTT is not suitable for production logging or field diagnostics.

----

Compressed / Deferred Logging
------------------------------

Standard string logging writes a fully-formatted ASCII message to the output buffer. For constrained targets this is expensive: format strings are large, ``sprintf``-style formatting burns CPU cycles, and the byte count on the wire is high.

A more efficient pattern stores only a small integer ID on the target, with the full message string kept in a lookup table on the host. When the host receives the ID, it looks up the corresponding string and reconstructs the message.

**Benefits:**

- A log event might be 2–4 bytes on the target instead of 40–80 bytes.
- CPU time for logging drops significantly — no string formatting at all.
- The same transport (UART, RTT, USB) carries far more log events per second.
- Variables can still be included: their raw bytes are appended after the ID and substituted in by the host parser.

Segger SystemView
~~~~~~~~~~~~~~~~~

SystemView is Segger's implementation of this pattern. It captures kernel-level events — thread context switches, ISR entry and exit, semaphore operations, timer expirations — in a compact binary format and streams them over RTT to the SystemView host application.

The host displays a timeline showing exactly which thread was running at each point, when ISRs fired, and how long each operation took. This makes it straightforward to diagnose scheduling problems, measure task response times, and spot starvation or priority inversions.

SystemView supports both FreeRTOS and Zephyr via their respective integration modules.

Zephyr Dictionary Logging
~~~~~~~~~~~~~~~~~~~~~~~~~~

Zephyr provides its own implementation of this pattern called dictionary logging. See the Zephyr RTOS page for configuration and usage details.
