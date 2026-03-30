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

A parameter is a configuration value of a node that can be changed during runtime without restarting the node.
Parameters can be set from the command line and also by other nodes.

.. code-block:: bash

   # See parameters
   ros2 param list

You can set, get, dump, and load parameters. Loading can be done from a parameter file.

You can also load parameters on node startup using :bash:`--ros-args --params-file`.

Often a node needs to respond to changes to its own parameters or another node's parameters. The
``ParameterEventHandler`` class makes it easy to listen for parameter changes so that your code can respond to them.


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

Action interfaces are defined in ``.action`` files:

.. code-block:: text

   # Request
   ---
   # Result
   ---
   # Feedback

Feedback messages are sent periodically during processing to report the status and progress of the action.
Actions are built using the ``rosidl`` code generation pipeline.


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

Launch files can be written in Python, XML, and YAML. They can start and stop different nodes as well as
trigger and act on various events.

You can use **substitutions** in launch files — variables or parameters that are only evaluated when the
launch file is run.

In Python launch files you can register functions to run on events such as ``OnProcessStart``,
``OnProcessIO``, ``OnExecutionComplete``, ``OnProcessExit``, and ``OnShutdown``.

Launch files can also be nested: your main launch file can include and call other launch files.


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


Workspaces
----------

A workspace is a directory containing ROS2 packages.

Before building a workspace, it is good to check you have all the required dependencies:

.. code-block:: bash

   rosdep install -i --from-path src --rosdistro humble -y

``rosdep`` is a dependency management utility for identifying and installing dependencies needed to build
or install a package. It reads dependencies from your ``package.xml`` file. Different dependency types
exist for different purposes, such as build-only or test-only dependencies.

To build, use the ``colcon`` tool (replaces ``catkin``):

.. code-block:: bash

   colcon build

Useful arguments for ``colcon build``:

- ``--packages-up-to``: builds the package you want, plus all its dependencies, but not the whole workspace (saves time)
- ``--symlink-install``: saves you from having to rebuild every time you tweak Python scripts
- ``--event-handlers console_direct+``: shows console output while building (can otherwise be found in the log directory)
- ``--executor sequential``: processes the packages one by one instead of using parallelism

Sourcing overlays means your terminal can find extra ROS2 packages that you have locally on your machine,
not in the main installation. To source, open the terminal and run:

.. code-block:: bash

   source install/local_setup.bash

.. warning::
   Do not source in the same terminal session that you build a package with, as this causes issues.

.. note::
   If you are cloning a package that you intend to use, make sure you checkout the package to the ROS2
   version you are using on your machine, e.g. ``humble``.


Packages
--------

A package is an organisational unit for your ROS2 code, allowing others to install and use your code.
Packages can be CMake or Python based.

A single workspace can contain multiple packages of both types. You cannot have nested packages.
It is best practice to keep packages in your workspace in a ``src/`` folder.

Create a new package with:

.. code-block:: bash

   ros2 pkg create --build-type ament_python --license Apache-2.0 <package_name>

In C++ code, use the ``rclcpp`` library to interact with ROS2:

.. code-block:: cpp

   #include "rclcpp/rclcpp.hpp"

For Python code, use the ``rclpy`` package.


Interfacing Between Packages
-----------------------------

Two nodes interfacing with each other need some shared information, such as the names of the topics they share.
Instead of hardcoding these into each package, it is good practice to keep this information in a shared place.

One way to do this is to create a new interface package and add ``.msg`` and ``.srv`` files there, which can
be used by other packages.

It is also possible to define the interface in the package it is used, and another package can use that package
as a dependency to access the interface specification.


Composable Nodes
----------------

A Composable Node is a ROS2 node that is also compiled as a shared library (``.so`` file), so that multiple
nodes can be loaded into the same process instead of each running in their own separate process. This reduces
inter-process communication overhead. You can connect composable nodes via a launch file.


Testing
-------

Run tests using the ``colcon test`` verb:

.. code-block:: bash

   colcon test --ctest-args tests [package_selection_args]

   # View results
   colcon test-result --all --verbose

ROS2 uses ``gtest`` for C++ and ``pytest`` for Python. There are two main types of tests:

- **Unit tests** — test a function or class in isolation; no ROS2 running needed.
- **Integration tests** — spin up actual nodes and verify they communicate correctly (topics published,
  data correct, services respond, etc.). ROS2 provides ``rclpy`` helpers to write these in Python.

Integration tests can include a launch file to bring up the nodes you want to test together.


RViz
----

RViz (ROS Visualization) is a 3D visualization tool that lets you see what your robot sees and knows in
real time. It subscribes to topics and displays them visually — it does not control your robot or run any
logic.

Use URDF files to describe how your robot looks. RViz also supports custom viewers for your robot.


Debug
-----

Use ``ros2 doctor`` to run checks on your overall ROS2 environment:

.. code-block:: bash

   ros2 doctor


Plugins
-------

ROS2 plugins allow you to swap out a piece of functionality at runtime without recompiling the code that uses it.
You define a base class interface that all plugins must follow, then any number of plugin implementations can be
loaded interchangeably. The ``pluginlib`` library handles the loading behind the scenes, and you choose which
plugin to use via a config file or parameter.

A plugin is essentially a shared library that gets loaded at runtime, so you can choose which plugin you want
without recompiling.
