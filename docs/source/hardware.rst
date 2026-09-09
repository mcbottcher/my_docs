Hardware
========

Notes on hardware design — PCB layout, RF considerations, and component selection.

----

PCB Design and Layout
----------------------

Reference Designs
~~~~~~~~~~~~~~~~~~

For schematics it is good to use development kit reference designs as a starting point or for learning.

e.g. the **nRF54L15 Tag** — comes with chip antennas, a coin cell battery holder, among other things.

----

Stitching Vias
~~~~~~~~~~~~~~

See: `Everything You Need to Know About Stitching Vias <https://resources.altium.com/p/everything-you-need-know-about-stitching-vias>`_

Stitching vias are used for three things:

- Connecting ground planes
- Providing short return paths for signals transitioning layers
- Blocking/shielding RF signals

For shielding, the rule of thumb is a pitch (distance between vias) that blocks the highest frequency of
concern, determined by being **1/8 of a wavelength**. The calculation should also take into account the
Dk (dielectric constant) value of the substrate.

----

Antenna Mounting Guidelines
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

See: `Johanson Antenna Selection Guide <https://www.johansontechnology.com/docs/4470/johanson-antenna-selection-guide_YA3dQmX.pdf>`_
