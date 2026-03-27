.. role:: bash(code)
   :language: bash

|:robot:| ROS2
==============

See the tutorial `here. <https://docs.ros.org/en/humble/Tutorials.html>`_

.. note::
   Make sure you pick the ROS version that is compatible with your distro version.

ROS2 uses DDS transport, which allows different logical networks to share the same physical network.
ROS nodes can only communicate with each other if they use the same domain ID. By default this is ``0``.

``ROS_DOMAIN_ID`` can be set in the environment. ``ROS_LOCALHOST_ONLY`` can also be set in the environment,
which means the transport is limited to your local machine and not the local network you are connected to.

Run these commands to see what is going on:

.. code-block:: bash

   ros2 node list
   ros2 topic list
   ros2 service list
   ros2 action list

The **ROS graph** is a network of ROS 2 elements processing data together at the same time and their connections.

You can launch an executable from a package with:

.. code-block:: bash

   ros2 run <package_name> <executable_name>

Remapping
---------

Remapping allows you to reassign default node properties, like node name, topic names, service names, etc.,
to custom values. You can do this with ``--ros-args``:

.. code-block:: bash

   ros2 run turtlesim turtlesim_node --ros-args --remap __node:=my_turtle

.. note::
   It is bad practice to have two nodes with the same name.

Check node info with:

.. code-block:: bash

   ros2 node info <node_name>


Topics
------

Topics are message pipes that can send messages between nodes. You can have multiple publishers and
subscribers on the same topic.

Running :bash:`ros2 run rqt_graph rqt_graph` will give an overview of your system.

.. code-block:: bash

   # Watch what is published on a topic
   ros2 topic echo <topic_name>

   # See more details
   ros2 topic info /turtle1/cmd_vel --verbose

   # Check what format a topic expects
   ros2 interface show geometry_msgs/msg/Twist

   # Publish to a topic (default rate: 1Hz)
   ros2 topic pub <topic_name> <msg_type> '<args>'


Services
--------

Services have a request and response, and involve a server and client(s).


Parameters
----------

A parameter is a configuration value of a node, kind of like a node setting or state.

.. code-block:: bash

   # See parameters
   ros2 param list

You can set, get, dump, and load parameters. Loading can be done from a parameter file.

You can also load parameters on node startup using :bash:`--ros-args --params-file`.


Actions
-------

Actions are a type of communication for longer running tasks, between a client and server.

1. The client requests on a service to start the action.
2. The server acknowledges with a response.
3. The server publishes periodically on a feedback topic so the client can track progress.
4. When the server has finished, the client can request the result response from the server (again via a service).

The client or server can each decide to abort the goal if they choose.

.. code-block:: bash

   ros2 action send_goal <action_name> <action_type> <values>


Logs
----

``rqt_console`` can be used to view logs:

.. code-block:: bash

   ros2 run rqt_console rqt_console

Logs have different levels, as with other logging frameworks. To set the log level for a node:

.. code-block:: bash

   --ros-args --log-level WARN


Launching Nodes
---------------

Instead of opening a terminal for each node, you can create a launch file which will start the entire
system at once:

.. code-block:: bash

   ros2 launch <package_name> <launch_file>

Launch files can be written in Python, XML, and YAML.


Recording and Playing Back Data
--------------------------------

``ros2 bag`` is a command line tool for recording data published on topics and saving it to a database.
This is useful for saving results from tests and replaying them later.

.. code-block:: bash

   # Record a single topic
   ros2 bag record <topic_name>

   # Record multiple topics
   ros2 bag record <topic1> <topic2>

.. note::
   It is also possible to record multiple topics at the same time.

----

Continue: `Colcon Tutorial <https://docs.ros.org/en/humble/Tutorials/Beginner-Client-Libraries/Colcon-Tutorial.html>`_
