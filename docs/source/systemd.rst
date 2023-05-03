SystemD
=======

Service Files
-------------

SystemD service files have 3 sections:

1. Unit: The information section - description
   and which services need to start before this one
2. Service: Contains commands for env variables, execution
   and command to gracefully shutdown service
3. Install: Which target requires this service (graphical
   target or multi-user target), can also define service alias

.. note::
    You can use the ``man systemd.service`` and ``man systemd.unit`` commands to
    view some more info

Unit Section
^^^^^^^^^^^^

- Description: This is the description that gets printed when running the service, so make it sound cool!
- After: You can specify the service runs after another service e.g. 

.. code-block::

    After=network.target auditd.service

- Documentation: Provides a link for user to view documentation on the service e.g. a https link
- Before: Specify to run before another service
- OnFailure: A space-seperated list of one or more units that are actived if this unit enters the “failed“ state
- ConditionPathExists: Only starts if file in given path exists (use the ! to do the opposite)

Service Section
^^^^^^^^^^^^^^^

- Type: simple,exec, forking, oneshot, dbus, notify, idle
- ExecStart: Commands (with their arguments) that are executed when the service is started e.g. 

.. code-block::

    ExecStart=/usr/bin/hellocmake --options

- ExecStartPre/ExecStartPost: Commands to execute before/after ExecStart. Could be same program just with different arguments passed in
- WatchdogSec: Configure a watchdog for the service, which fails if the service doesn't call *sd_notify(3)* more frequently that the specified number of seconds
- StandardOutput: Set where the standard output is sent. Set this to *tty* if you want the ouput on your terminal.
- User: Create a user for this service, means that service is not run with root privileges
- Environment: Specify environment variables for the service
- EnvironmentFile: Specify location of file containing env variables
- Restart: Lists situations where restart is triggered e.g. Restart=on-failure will restart if executable returns a non 0 value

Install Section
^^^^^^^^^^^^^^^

- WantedBy: Specifies the target that will want this service - multi-user / graphical
- Alias: another name for starting/stopping a service

----

SystemD Management
------------------

.. code-block::
    :caption: Some SystemD commands

    systemctl enable name.service
    systemctl disable name.service
    systemctl status name.service
    systemctl is-enabled name.service
    systemctl list-unit-files --type service

Systemd services are classified by targets, formally known as runlevels in sysvinit. You can change these targets with systemctl.
Examples of targets are *multi-user* and *graphical*.
To view targets available, use:

.. code-block::¨
    :caption: Viewing SystemD targets

    systemctl list-units --type target
    systemctl list-units --type target --all

If you want to edit a service file, and see the changes instantly, use:

.. code-block::
    
    systemd daemon-reload


