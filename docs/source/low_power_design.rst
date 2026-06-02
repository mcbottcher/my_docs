Low Power Design
================

Low power design is critical for battery-operated embedded systems. The goal is to extend battery life by
minimising average current consumption — choosing the right battery, using efficient power management
hardware, and keeping the MCU and peripherals in their lowest-power states as much as possible.

----

Batteries
---------

Primary (Non-Rechargeable)
~~~~~~~~~~~~~~~~~~~~~~~~~~

+------------------+-------------------+--------------------+-------------------------------+
| Battery Type     | Voltage Range     | Typical Capacity   | Notes                         |
+==================+===================+====================+===============================+
| CR2032           | 3.0 V – 2.0 V     | 220–240 mAh        | Most common coin cell         |
+------------------+-------------------+--------------------+-------------------------------+
| CR2025           | 3.0 V – 2.0 V     | 160–170 mAh        | Thinner than CR2032           |
+------------------+-------------------+--------------------+-------------------------------+
| CR2016           | 3.0 V – 2.0 V     | 90–100 mAh         | Thinnest coin cell            |
+------------------+-------------------+--------------------+-------------------------------+
| CR2450           | 3.0 V – 2.0 V     | 600–620 mAh        | High capacity coin cell       |
+------------------+-------------------+--------------------+-------------------------------+
| CR123A           | 3.0 V – 2.0 V     | 1,400–1,600 mAh    | Cylindrical lithium           |
+------------------+-------------------+--------------------+-------------------------------+
| AA Alkaline      | 1.5 V – 0.9 V     | 1,500–3,000 mAh    | Standard cylindrical          |
+------------------+-------------------+--------------------+-------------------------------+
| AAA Alkaline     | 1.5 V – 0.9 V     | 1,000–1,200 mAh    | Smaller cylindrical           |
+------------------+-------------------+--------------------+-------------------------------+
| SR44 (357/303)   | 1.55 V – 1.2 V    | 150–200 mAh        | Silver oxide button cell      |
+------------------+-------------------+--------------------+-------------------------------+
| SR41 (384/392)   | 1.55 V – 1.2 V    | 38–45 mAh          | Small silver oxide            |
+------------------+-------------------+--------------------+-------------------------------+
| SR626SW (377)    | 1.55 V – 1.2 V    | 28–32 mAh          | Compact silver oxide          |
+------------------+-------------------+--------------------+-------------------------------+

Rechargeable
~~~~~~~~~~~~

+------------------+------------------+--------------------+-------------------------------------------+
| Battery Type     | Nominal Voltage  | Typical Capacity   | Notes                                     |
+==================+==================+====================+===========================================+
| Li-ion 18650     | 3.7 V            | 2,200–3,500 mAh    | Common cylindrical cell                   |
+------------------+------------------+--------------------+-------------------------------------------+
| Li-ion 14500     | 3.7 V            | 600–800 mAh        | AA-sized Li-ion                           |
+------------------+------------------+--------------------+-------------------------------------------+
| Li-Po (small)    | 3.7 V            | 50–500 mAh         | Earbuds, small wearables                  |
+------------------+------------------+--------------------+-------------------------------------------+
| Li-Po (medium)   | 3.7 V            | 500–2,000 mAh      | Fitness bands, devices with small display |
+------------------+------------------+--------------------+-------------------------------------------+
| Li-Po (large)    | 3.7 V            | 2,000–5,000 mAh    | Devices with large display                |
+------------------+------------------+--------------------+-------------------------------------------+
| AA NiMH          | 1.2 V            | 1,900–2,850 mAh    | Rechargeable AA                           |
+------------------+------------------+--------------------+-------------------------------------------+
| AAA NiMH         | 1.2 V            | 800–1,000 mAh      | Rechargeable AAA                          |
+------------------+------------------+--------------------+-------------------------------------------+

Peak Power and Pulse Discharge
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If the system draws close to a battery's maximum output capability for a sustained period, it can
degrade the battery and reduce its effective capacity. Short high-current pulses are generally less
harmful since decoupling capacitors absorb the initial energy demand before the battery responds.

Under **pulse discharge** conditions the battery can become stressed, reducing effective capacity below
the rated figure. This is particularly relevant for wireless devices that transmit in short bursts.

----

Nordic Online Power Profiler
-----------------------------

Nordic Semiconductor offers the **Online Power Profiler (OPP)** on DevZone — a web tool that estimates
average current consumption for Nordic chips including the nRF52, nRF53, nRF54L, and nRF91 series across
various wireless protocols.

This is useful for back-of-envelope estimates before measuring real hardware, and for exploring the trade-off
between radio duty cycle, transmit power, and battery life.

----

Power Management ICs (PMICs)
-----------------------------

A PMIC manages power delivery, battery charging, and system supervision. It typically exposes several
operating modes with different trade-offs between power consumption and functionality.

Operating Modes
~~~~~~~~~~~~~~~

**Ship mode** — cuts all power rails when the product is being shipped or stored with a battery installed.
This preserves the battery so it arrives near 100% charge. Wake-up sources are configurable — typically
a button press or charger insertion event.

**Hibernate** — a deeper sleep state that can be woken by a timer or external event, retaining some
state while consuming less power than normal operation.

System Supervision
~~~~~~~~~~~~~~~~~~

PMICs can act as a system watchdog, resetting the MCU if firmware hangs or fails to check in within
a defined window. **Boot monitoring** detects hangs during startup — if the firmware does not signal
a successful boot within a timeout, the PMIC can force a reset or enter a safe state.

Fuel Gauging
~~~~~~~~~~~~~

Nordic PMICs include **fuel gauging** — an estimate of remaining battery capacity more accurate than
a simple voltage measurement or coulomb counting alone. Fuel gauging uses a model of the battery's
characteristics (internal resistance, temperature behaviour, discharge curves).

A custom battery model can be generated using the **nPM PowerUP** app when using a non-standard cell.

Power Delivery Modes
~~~~~~~~~~~~~~~~~~~~~

PMICs can switch between different output modes depending on the load:

- **PWM (fixed switching frequency)** — useful when transmitting over a radio, because the switching
  noise is at a known, predictable frequency that can be accounted for in the RF design.
- **LDO (linear regulator)** — lower noise output, suited to powering sensitive analogue sensors or
  ADC front-ends where switching noise would corrupt measurements.

----

Power Analysis
--------------

When measuring or analysing current consumption, several effects can distort the picture:

**Capacitors on the board** — decoupling caps release stored charge during load transients, hiding
instantaneous current spikes from the measurement instrument.

**Internal regulators on the SoC** — the MCU's on-chip regulator adds its own quiescent current
and transient behaviour.

**Power-on transitions** — inrush current during boot can be substantially higher than steady-state;
ensure your measurement window covers the full sequence.

**Floating GPIOs** — undriven GPIO pins can float to an indeterminate voltage, causing the input
buffer to oscillate and draw unexpected current. This is difficult to debug as it appears as
apparently random or inconsistent current draw. Always drive GPIOs to a defined level or configure
them as inputs with a pull resistor.

Shunt Resistor Measurement
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Some measurement equipment automatically switches shunt resistors to extend dynamic range. This
switching can cause a brief voltage spike on the output that is visible in the measurement trace.
Higher quality instruments compensate for this automatically; lower quality instruments may not.
Be aware of this artefact when interpreting current traces that show isolated spikes at range
transition points.

----

Peripheral Power Domains
-------------------------

To achieve low power, peripherals on the SoC are typically grouped into **power domains**. Each
domain can be powered down independently when not needed, trading off power consumption against
performance and latency.

- **Low-power domain** — slower but draws less current; suitable for peripherals that are only
  needed occasionally or can tolerate latency.
- **High-speed domain** — faster response and higher bandwidth, but requires the domain to remain
  active and draws more current.

Keeping a peripheral's power domain enabled only while needed is a key technique for reducing
average current.

----

Port Sense vs GPIOTE
---------------------

Nordic devices provide two mechanisms for GPIO-triggered events, with different power implications.

**Port Sense**

Port Sense is designed for wake-up events — button presses, sensor interrupt lines, and other
signals where timing accuracy is relaxed. The key advantage is that the peripheral power domain
for the GPIO subsystem can be disabled while Port Sense remains active, keeping current draw
very low.

Typical use cases: wake from sleep on button press, wake on sensor IRQ.

**GPIOTE (GPIO Tasks and Events)**

GPIOTE provides high-accuracy edge detection and integrates with the PPI/DPPI event system,
allowing GPIO edges to trigger other peripherals without CPU involvement. The trade-off is that
the GPIOTE peripheral (and its associated power domain) must remain active.

Typical use cases: precise signal timing, triggering peripherals on GPIO edges.

+-------------+-------------------------------+----------------------------+
| Mechanism   | Power cost                    | Use case                   |
+=============+===============================+============================+
| Port Sense  | Low — domain can be disabled  | Wake-up, relaxed timing    |
+-------------+-------------------------------+----------------------------+
| GPIOTE      | Higher — domain must be on    | Edge detection, PPI/DPPI   |
+-------------+-------------------------------+----------------------------+
