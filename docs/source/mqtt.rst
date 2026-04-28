MQTT
====

MQTT is a lightweight publish-subscribe messaging protocol designed for IoT applications and real-time communication over unreliable networks. It operates on a broker-based architecture where clients connect to a central broker to exchange messages on named topics.

----

Overview
--------

MQTT communication involves three roles:

- **Publisher** — sends messages to the broker on a topic
- **Broker** — receives messages from publishers, processes them, and forwards them to subscribers
- **Subscriber** — receives messages on topics it has subscribed to

.. note::
   A client can act as both a publisher and subscriber simultaneously — communication is bidirectional. **A client can publish and subscribe to the same topic at the same time.** This is useful for debugging (publish a message and verify it arrives back), shared state (multiple devices watching and updating the same topic), and loopback/smoke testing. There is no built-in mechanism to filter out your own messages — if you need that, handle it in your application, typically by embedding your Client ID in the payload and checking it on receipt.

A popular open-source broker is **Mosquitto**, typically run as a standalone application on a server or computer.


.. mermaid::

   graph LR
       A["Client A<br/>(Pub/Sub)"]
       B["Broker<br/>(Mosquitto)"]
       C["Client B<br/>(Pub/Sub)"]

       A -->|PUBLISH| B
       B -->|PUBLISH| C
       C -->|SUBSCRIBE| B
       B -->|SUBSCRIBE| A

       style B fill:#e1f5ff
       style A fill:#fff9c4
       style C fill:#fff9c4

----

Packets
-------

Packet Structure
~~~~~~~~~~~~~~~~

All MQTT packets share a common structure:

.. mermaid::

   graph TD
       A["MQTT Packet"]
       B["Fixed Header"]
       C["Variable Header"]
       D["Payload"]

       A --> B
       A --> C
       A --> D

       B1["Byte 1: Control + Flags"]
       B2["Bytes 2-5: Remaining Length"]
       B --> B1
       B --> B2

       C1["Packet-specific fields"]
       C --> C1

       D1["Message data"]
       D --> D1

       style B fill:#ffcccc
       style C fill:#ccccff
       style D fill:#ccffcc

- **Fixed header** (mandatory, minimum 2 bytes):

  - Byte 1: control field — packet type (upper 4 bits) and flags (lower 4 bits)
  - Bytes 1-4: remaining length field — encodes the length of the variable header and payload using a variable-length encoding scheme

- **Variable header** (present in some packet types) — contains packet-specific fields such as packet identifiers or protocol name
- **Payload** (optional) — the message data

**Key limits:**

- Minimum packet size: **2 bytes** (fixed header only)
- Maximum packet size: **256 MB** (defined by variable-length encoding limit)
- Payload format: any binary data, but commonly ASCII-encoded **JSON**, **XML**, or plain text

----

Connecting to the Broker
------------------------

All clients must connect to the broker before doing anything else. This is a two-packet exchange.

.. mermaid::

   sequenceDiagram
       participant C as Client
       participant B as Broker

       C->>B: CONNECT
       note right of B: Validates credentials,<br/>checks Client ID,<br/>restores session if applicable
       B->>C: CONNACK (SessionPresent, ReturnCode)
       note over C,B: Session active
       C->>B: DISCONNECT (clean close — Will NOT sent)

CONNECT Packet Fields
~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 20 15 65

   * - Field
     - Type
     - Description
   * - ``ClientID``
     - string
     - Unique identifier for this client. If blank, the broker generates one — but persistent sessions are then unavailable.
   * - ``cleanSession``
     - boolean
     - ``true`` — discard all stored session state on connect/disconnect. ``false`` — broker stores subscriptions and undelivered QoS 1/2 messages, restored on reconnect (persistent session).
   * - ``keepAlive``
     - integer
     - Maximum interval in seconds between transmissions. Client must send data or a ``PINGREQ`` within this interval. Broker closes connection after **1.5×** the period with no activity. ``0`` disables it.
   * - ``username`` ``password``
     - string
     - Optional credentials. Sent in plaintext — always use TLS in production.
   * - ``Will Message``
     - message
     - Stored by broker at connect time. Published to a specified topic only on an *unclean* disconnect (crash, power loss). Used to signal device failure.

CONNACK Response
~~~~~~~~~~~~~~~~

The broker replies with a ``CONNACK`` containing:

- **Session Present flag** — ``1`` if stored session state was found for this Client ID (only relevant when ``cleanSession=false``)
- **Return code**:

  - ``0`` — connection accepted
  - ``1`` — unacceptable protocol version
  - ``2`` — identifier rejected
  - ``3`` — server unavailable
  - ``4`` — bad username or password
  - ``5`` — not authorised

Persistent Sessions
~~~~~~~~~~~~~~~~~~~

When ``cleanSession=false``, the broker maintains a persistent session for the client, storing:

- The client's subscriptions
- Undelivered QoS 1 and QoS 2 messages received while offline
- Partially acknowledged QoS 2 in-flight message state

On reconnect, the broker hands all of this back. The ``Session Present`` flag in ``CONNACK`` tells the client whether to re-subscribe (``0``) or trust its subscriptions are already registered (``1``).

.. note::
   QoS 0 messages are **never** stored for offline clients, even in a persistent session.
   The only way to clear stored session state is to reconnect with ``cleanSession=true``.

----

Topics and Subscriptions
------------------------

Topics are UTF-8 strings organised into a hierarchy using ``/`` as a level separator. They are case sensitive and require no pre-registration.

.. code-block:: text

   factory/line1/sensor/temperature
   home/livingroom/light/status
   vehicles/truck42/gps/location

Wildcards
~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 15 20 65

   * - Wildcard
     - Type
     - Behaviour
   * - ``+``
     - Single-level
     - Matches exactly one topic level
   * - ``#``
     - Multi-level
     - Matches all levels from that point down. Must be the last character in the filter.

**Example — ``factory/+/sensor/temperature``:**

.. code-block:: text

   ✓  factory/line1/sensor/temperature
   ✓  factory/line2/sensor/temperature
   ✗  factory/line1/motor/temperature   (wrong third level)

**Example — ``factory/line1/#``:**

.. code-block:: text

   ✓  factory/line1/sensor/temperature
   ✓  factory/line1/motor/speed/max
   ✗  factory/line2/sensor/temperature  (wrong second level)

Wildcards can be combined: ``factory/+/sensor/#`` is valid.

SUBSCRIBE / SUBACK
~~~~~~~~~~~~~~~~~~

A ``SUBSCRIBE`` packet contains one or more topic filters each paired with a requested QoS (the maximum the client wants to receive). The broker replies with ``SUBACK`` — one return code per filter: granted QoS (``0``, ``1``, or ``2``), or ``0x80`` = refused.

A client removes subscriptions with ``UNSUBSCRIBE`` → broker confirms with ``UNSUBACK``.

System Topics
~~~~~~~~~~~~~

Topics beginning with ``$`` are reserved for broker internals (e.g. ``$SYS/`` for broker statistics). The ``#`` and ``+`` wildcards do **not** match ``$`` topics — you must subscribe to ``$SYS/#`` explicitly.

Key Rules
~~~~~~~~~

- Topics are case sensitive — ``Sensor/Temp`` ≠ ``sensor/temp``
- A leading ``/`` creates an empty first level — usually a design mistake
- Overlapping subscriptions are valid; matching messages may be delivered more than once
- ``#`` alone subscribes to every non-``$`` topic on the broker

----

Quality of Service (QoS)
------------------------

QoS controls the delivery guarantee for a message. Publisher and subscriber set QoS independently on a per-message/per-topic basis (not at the client level). The delivered QoS is always ``min(publisher QoS, subscriber requested QoS)`` — the broker downgrades silently with no notification.

.. note::
   QoS is set **per-publish** (in each PUBLISH packet) and **per-topic filter** (in each SUBSCRIBE request), not at the client level. Different topics from the same client can use different QoS levels.

.. list-table::
   :header-rows: 1
   :widths: 10 20 35 15

   * - Level
     - Guarantee
     - Packet exchange
     - Duplicates?
   * - QoS 0
     - At most once
     - ``PUBLISH`` only
     - No
   * - QoS 1
     - At least once
     - ``PUBLISH`` → ``PUBACK``
     - Possible
   * - QoS 2
     - Exactly once
     - ``PUBLISH`` → ``PUBREC`` → ``PUBREL`` → ``PUBCOMP``
     - No

QoS 0 — At Most Once
~~~~~~~~~~~~~~~~~~~~~

Fire and forget. No acknowledgement, no retry. Suitable for frequent sensor readings where an occasional missed message is acceptable.

.. mermaid::

   sequenceDiagram
       participant S as Sender
       participant B as Broker
       S->>B: PUBLISH
       note right of B: No reply. No retry.<br/>Message lost if dropped.

QoS 1 — At Least Once
~~~~~~~~~~~~~~~~~~~~~~

Sender retransmits until ``PUBACK`` is received. If the ``PUBACK`` is lost in transit, the message is sent again — the receiver may process a duplicate. Message handling must be **idempotent** (safe to apply twice, e.g. "set temperature to 21°C") or deduplicated in the application.

.. mermaid::

   sequenceDiagram
       participant S as Sender
       participant B as Broker
       S->>B: PUBLISH (stored by sender)
       B->>S: PUBACK
       note left of S: Sender discards copy.<br/>Retransmits if no PUBACK.

QoS 2 — Exactly Once
~~~~~~~~~~~~~~~~~~~~~

A four-packet handshake guarantees delivery with no duplicates.

.. mermaid::

   sequenceDiagram
       participant S as Sender
       participant B as Broker
       S->>B: PUBLISH (broker stores, does NOT forward yet)
       B->>S: PUBREC (broker has it safely)
       S->>B: PUBREL (sender says: now deliver it)
       note right of B: Broker forwards to subscribers HERE
       B->>S: PUBCOMP (exchange complete)

.. note::
   The message is forwarded to subscribers at the ``PUBREL`` step, not when ``PUBLISH`` arrives.
   This is what prevents duplicates: even if ``PUBLISH`` is retransmitted, the broker recognises
   the message ID and re-sends ``PUBREC`` without forwarding again.

When to Use Each Level
~~~~~~~~~~~~~~~~~~~~~~

- **QoS 0** — frequent telemetry, live sensor readings, anything where the next update arrives shortly
- **QoS 1** — most common choice; use when message loss is unacceptable and processing is idempotent
- **QoS 2** — financial events, physical actuator commands, any operation where duplicates cause real harm

----

Retained Messages
-----------------

A retained message is a normal MQTT message with ``retain=true``. The broker stores it as the last known value for that topic and delivers it instantly to any future subscriber — before any live messages arrive.

.. mermaid::

   sequenceDiagram
       participant P as Publisher
       participant B as Broker
       participant A as Subscriber A (live)
       participant N as Subscriber B (joins later)

       P->>B: PUBLISH retain=true
       note right of B: Broker stores message
       B->>A: Delivered (live)
       note over P,N: — time passes, no new publish —
       N->>B: SUBSCRIBE
       B->>N: Retained message delivered instantly

Only **one** retained message is stored per topic — each new retained publish replaces the previous one.

Clearing a Retained Message
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Publish a **zero-byte payload** with ``retain=true`` to the same topic. The broker discards the stored value and new subscribers receive nothing.

Birth and Last Will Pattern
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Combine retained messages with the Will (see Connecting section) to track device presence:

.. code-block:: text

   On connect  →  PUBLISH "online"  retain=true  →  devices/42/status
   Will msg    →  PUBLISH "offline" retain=true  →  devices/42/status

Any subscriber gets the current presence state immediately on subscribe, regardless of when they connect.

Key Rules
~~~~~~~~~

- Retained messages are **per topic** on the broker — distinct from persistent sessions which are per client
- Wildcard subscriptions receive a burst of all matching retained messages on subscribe — useful for dashboards
- QoS negotiation still applies when a retained message is delivered to a new subscriber
- Retained messages survive broker restarts if the broker is configured to persist them
- Good fit: state/status topics. Poor fit: event topics (a stale retained event delivered out of context can cause unintended behaviour)

----

Quick Reference
---------------

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Packet
     - Purpose
   * - ``CONNECT``
     - Client → Broker. Opens a session. Contains ClientID, credentials, cleanSession, keepAlive, Will.
   * - ``CONNACK``
     - Broker → Client. Session accepted or refused. Contains SessionPresent and ReturnCode.
   * - ``PUBLISH``
     - Either direction. Carries topic, payload, QoS, retain flag.
   * - ``PUBACK``
     - QoS 1 acknowledgement.
   * - ``PUBREC``
     - QoS 2 step 1 reply — message received and stored.
   * - ``PUBREL``
     - QoS 2 step 2 — sender releases message for delivery.
   * - ``PUBCOMP``
     - QoS 2 step 3 reply — exchange complete.
   * - ``SUBSCRIBE``
     - Client → Broker. One or more topic filters with requested QoS.
   * - ``SUBACK``
     - Broker → Client. Granted QoS per filter, or 0x80 = refused.
   * - ``UNSUBSCRIBE``
     - Client → Broker. Remove topic filters.
   * - ``UNSUBACK``
     - Broker → Client. Confirms removal.
   * - ``PINGREQ``
     - Client → Broker. Keep-alive heartbeat when no data is flowing.
   * - ``PINGRESP``
     - Broker → Client. Heartbeat reply.
   * - ``DISCONNECT``
     - Client → Broker. Clean close — Will message is NOT sent.

----

MQTT 5.0
--------

MQTT 5.0 introduces several modern features for production systems.

Shared Subscriptions
~~~~~~~~~~~~~~~~~~~~

Multiple subscribers share a single subscription group. The broker distributes messages round-robin — each message goes to only ONE subscriber in the group. Essential for load-balancing consumers.

.. code-block:: text

   # Three workers all subscribe to the same group
   $share/workers/jobs/image-processing
   # Broker sends each message to only ONE of them, rotating through

Message Expiry
~~~~~~~~~~~~~~

Set a TTL on a message (in seconds). If it's still sitting in the broker undelivered after that time, it's discarded. Stops stale data reaching late-joining clients.

.. code-block:: python

   client.publish("sensors/temp", payload="22.4", properties={"MessageExpiryInterval": 30})
   # If the subscriber isn't connected within 30s, it never receives this

Reason Codes
~~~~~~~~~~~~

Every CONNACK, PUBACK, SUBACK etc. now carries a numeric reason code. Instead of a silent failure you get something specific and actionable:

.. code-block:: text

   0x00  Success
   0x87  Not Authorized
   0x97  Quota Exceeded
   0x9E  Subscription Identifiers Not Supported

User Properties
~~~~~~~~~~~~~~~

Arbitrary key-value string pairs attachable to any packet. Think HTTP headers for MQTT — useful for routing metadata, trace IDs, content-type hints without touching the payload.

.. code-block:: python

   properties = {"user_properties": [("trace-id", "abc-123"), ("region", "eu-west")]}
   client.publish("sensors/temp", payload="22.4", properties=properties)

Session and Will Improvements
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Will messages can now be delayed, so a brief disconnect doesn't immediately fire your "device offline" alert. Set ``WillDelayInterval`` to only trigger after a device has been gone for a defined period (e.g. 60 seconds).

.. note::

   Use MQTT 5.0 for any new project. v3.1.1 is still everywhere in legacy systems but 5.0 is clearly the path forward.

----

Security
--------

Plain MQTT is unauthenticated and unencrypted by default. For production you need all three layers.

Transport (TLS)
~~~~~~~~~~~~~~~

TLS (Transport Layer Security) is the same encryption that underpins HTTPS. It establishes an encrypted tunnel between client and broker: the broker presents a certificate to prove its identity, and all data flowing through the connection is encrypted so it can't be read or tampered with in transit.

Mutual TLS (mTLS) goes further — the client also presents a certificate, so the broker can verify device identity without passwords. Common in device fleets where each device is issued its own cert at manufacture.

**When to use TLS or mTLS in MQTT:**

- **One-way TLS**: Device verifies the broker's certificate. Use when the broker's identity is important but devices don't need authentication.
- **mTLS**: Both device and broker authenticate each other. Use when the broker needs to reject unknown or revoked devices.

.. code-block:: text

   Port 1883 — plaintext, avoid in production
   Port 8883 — TLS encrypted, use this

Authentication
~~~~~~~~~~~~~~

MQTT 3.x supports username/password in the CONNECT packet. Combined with TLS (which prevents credentials being intercepted) it's adequate for many cases. MQTT 5.0 adds Enhanced Authentication for SASL-style challenge/response flows (OAuth, Kerberos etc). Client certificate authentication via mTLS can replace passwords entirely — the cert *is* the identity.

Authorisation
~~~~~~~~~~~~~

Who can publish or subscribe to what. Defined as ACLs (access control lists) per user or client ID in your broker config:

.. code-block:: text

   device123  can publish to   sensors/device123/#
   device123  can subscribe to commands/device123/#
   dashboard  can subscribe to sensors/#
   dashboard  cannot publish  anywhere

Without ACLs, any authenticated client can read or write any topic — a serious issue in multi-tenant systems.

Mosquitto: Passwords and ACLs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To disable anonymous access and enforce per-client credentials, configure Mosquitto with a password file and an ACL file.

**Step 1 — create the password file:**

.. code-block:: bash

   # Create a new file and add the first user (-c = create)
   mosquitto_passwd -c /etc/mosquitto/passwd device123

   # Add further users (omit -c to avoid overwriting the file)
   mosquitto_passwd /etc/mosquitto/passwd dashboard

**Step 2 — point mosquitto.conf at the password and ACL files:**

.. code-block:: text

   # /etc/mosquitto/mosquitto.conf
   allow_anonymous false
   password_file   /etc/mosquitto/passwd
   acl_file        /etc/mosquitto/acl

With ``allow_anonymous false`` any client that does not present valid credentials is refused at the ``CONNECT`` stage.

**Step 3 — write the ACL file:**

.. code-block:: text

   # /etc/mosquitto/acl

   # --- Global rules (apply to every authenticated client) ---
   topic read  public/#

   # --- Per-user rules ---
   user device123
   topic readwrite sensors/device123/#
   topic read      commands/device123/#

   user dashboard
   topic read      sensors/#

   # --- Pattern rules (apply to all users regardless of position) ---
   # %u = username, %c = client ID
   pattern readwrite devices/%u/#

ACL File Rules
^^^^^^^^^^^^^^

- **Default deny** — any topic not covered by an explicit ``read``, ``write``, or ``readwrite`` rule is denied. There is no need to add explicit deny-all entries.
- **Deny takes precedence** — ``deny`` rules are evaluated before permissive rules. A single ``deny`` line blocks access even when a broader ``readwrite`` or wildcard rule would otherwise allow it.
- **User scope** — a ``user <name>`` line begins a per-user block. All ``topic`` lines that follow apply *only* to that user until the next ``user`` declaration (or end of file). Topics listed before any ``user`` declaration are global and apply to every authenticated client.
- **Pattern rules** — lines beginning with ``pattern`` use ``%u`` (username) and ``%c`` (client ID) as substitution variables. Pattern rules apply to *all* users regardless of where they appear relative to ``user`` blocks.
- **Access types:**

  ==================  ===========================================
  ``read``            Subscribe and receive messages
  ``write``           Publish messages
  ``readwrite``       Both (default when type is omitted)
  ``deny``            Explicitly block — takes priority over allow
  ==================  ===========================================

Example showing deny override:

.. code-block:: text

   user ops
   topic readwrite sensors/#        # allows all sensor topics …
   topic deny      sensors/secret   # … except this one

Production Checklist
~~~~~~~~~~~~~~~~~~~~

- TLS on 8883, disable plaintext 1883
- Unique credentials per client (not one shared password)
- ACLs scoped to only what each client needs
- Rotate credentials; don't hardcode them

----

Broker Topology
---------------

One broker is the most common setup for smaller systems — all clients connect to it and it handles all routing.

Multiple brokers are used when you need:

**Scale**
   Broker clustering (supported by HiveMQ, EMQX etc.) runs multiple nodes as one logical broker. Clients connect to any node; the cluster handles internal routing.

**Bridging**
   Two separate brokers can be linked so messages on one are forwarded to the other. Common in edge/cloud architectures:

   .. code-block:: text

      [Factory devices] → [Edge broker] --bridge--> [Cloud broker] ← [Dashboard]

   The factory devices never talk directly to the cloud.

**Isolation**
   Some enterprises run separate brokers per site or business unit for security/compliance, bridging only what needs to cross boundaries.

.. note::

   The broker is always the hub — clients never talk directly to each other, even in multi-broker setups. The topology changes, but the fundamental rule (publish to broker, broker routes to subscribers) does not.
