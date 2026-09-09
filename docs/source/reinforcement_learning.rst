|:brain:| Reinforcement Learning
=================================

Notes on reinforcement learning tooling, simulation, and techniques for training
policies that transfer from simulation to real hardware.

----

Environments and Libraries
----------------------------

**Gymnasium** (formerly OpenAI Gym) provides a standard interface for RL environments,
along with an interactive interpreter for trying them out.

**Stable Baselines** is a Python library of RL algorithm implementations (e.g. PPO with
a CNN policy) that plugs into Gymnasium-style environments.

----

OCR
---

OCR (Optical Character Recognition) converts an image into text.

AI models tend to perform better when given the cleanest, most relevant input data
possible — converting an image of text into pure text (rather than feeding the raw
image in) is one example of this.

See `Shaun Hymel's GitHub <https://github.com/ShawnHymel>`_ for example code.

----

Building a Simulation Model
-----------------------------

A 3D model can be built in **FreeCAD** and brought into a simulator:

1. Export an **STL** file for each rigid body in the model.
2. Describe the robot in a **URDF** or **MJCF** file — an XML format that:

   - Assigns mass and inertia values to each component.
   - Defines joints (how bodies are attached to each other).
   - Sets friction values for joints that move.

----

Simulators
----------

- **MuJoCo**
- **Gazebo**
- **Isaac Sim**

Isaac Sim in particular tends to require a GPU.

----

Training Algorithms
--------------------

**PPO** (Proximal Policy Optimization) is a commonly used RL algorithm. It works by
collecting a batch of experience under the current policy, then taking several small
gradient update steps on that batch to improve it. A "clipping" term stops any single
update from moving the policy too far away from the one that collected the data, which
keeps training stable — this is the "proximal" part of the name.

----

Curriculum Learning
--------------------

Train on incrementally harder versions of a task rather than the full task from the
start. For example, start with only one penalty coefficient set non-zero, then enable
the rest as training progresses.

----

Domain Randomization
----------------------

Add noise during training to help a policy survive the sim-to-real jump. Sources of
noise include:

- Sensor noise
- Motor control noise
- Friction noise
- Action delay — the time between an action being determined and it being enacted
- Battery droop — the drop in supply voltage under heavy load
