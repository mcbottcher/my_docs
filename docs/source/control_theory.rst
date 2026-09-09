Control Theory
==============

PID Controllers
---------------

A PID controller drives a system towards a setpoint by combining three terms, each acting
on the error between the setpoint and the measured output.

What Each Term Does
~~~~~~~~~~~~~~~~~~~

Example: a thermostat heating a room to 20°C.

- **P (Proportional)** — reacts to the current error (how far the room is from 20°C). A
  larger error produces a larger corrective output. With P alone, the heater might settle
  at 19.5°C forever: as the room warms, the error shrinks, so the heater output shrinks
  with it and stops pushing before the room actually reaches 20°C. This leftover gap is
  the **steady-state offset**.
- **I (Integral)** — reacts to the *accumulated* error over time. It keeps growing the
  heater output for as long as any error remains, which is what pushes the room the rest
  of the way to 20°C and eliminates the steady-state offset. Too much gain here makes the
  response sluggish or causes overshoot/oscillation.
- **D (Derivative)** — reacts to the *rate of change* of the error. It notices the room is
  heating up quickly and backs off the heater before 20°C is reached, preventing overshoot
  to, say, 22°C.

----

Tuning a PID Controller
------------------------

Manual tuning procedure:

1. Increase **Kp** from a low value until the response starts to overshoot with a
   steady-state offset.
2. Increase **Ki** until the response has no steady-state offset (it might still
   overshoot).
3. Adjust **Kd** to avoid overshoot and achieve a critically damped system.

Some systems also add a fixed offset to the final value, but this is less common.
