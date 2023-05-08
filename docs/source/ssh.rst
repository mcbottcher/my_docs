.. role:: bash(code)
    :language: bash

SSH
===

Secure SHell (SSH) is a common way of connecting to Linux servers.
When you connect with SSH, you log in using an account that exists
on the remote server.

For SSH to work the server/target needs to be running an SSH daemon/server
and the host needs to run an SSH client.

----

Authentication
--------------

Clients can be authenticated either using passwords or ssh keys.
ssh keys are more secure so are preffered.

To authenitcate using ssh keys, a user must have an SSH key pair (public and private)
on their local computer. On the remote server, the public key can be copied to: ``~/.ssh/authorized_keys``.
This file contains a list of public keys, one per line, authoirsed to login to the account.

When a client connects to a host, it first tells it which public key to use.
The client checks it has it in its list, and uses the key to encrypt a random sting.
The server can decrypt this using its private key, and generate a hash (MD5) of the decrypted
sting and a session id. The client can check this hash is the correct value, to authenticate
the connection.

Forwarding Credentials
^^^^^^^^^^^^^^^^^^^^^^

You can forward credentials from your host machine to a server, if you want to access another
server from that server. The host server will use the credentials from your local machine to access
the client server

.. code-block:: bash
    :caption: Forwarding Credentials

    $ ssh -A <username>@<remote_host>

----

SSH Keys
--------

Generating a SSH key pair
^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash
    :caption: Generate key pair

    $ ssh-keygen

You can change the name of the key pair, as well as the location on your machine.
You can also add a passphrase, which will help protect your servers if your host machine
is compromised.

This will generate two files:

- public key: e.g. *~/.ssh/id_rsa.pub*. This is key you distribute
- private key: e.g. *~/.ssh/id_rsa*. **DO NOT SHARE THIS KEY**

Key Options
^^^^^^^^^^^

.. code-block:: bash
    :caption: Generating an SSH key with 4096 bits

    $ ssh-keygen -b 4096

SSH keys are 2048 by default, but if you want a more secure key use more bits.

.. code-block:: bash
    :caption: Removing or adding new ssh key password

    $ ssh-keygen -p

.. code-block:: bash
    :caption: Displaying the SSH key fingerprint

    $ ssh-keygen -l

This is a unique fingerprint of the key that can be used to identify it.

Distributing Keys
^^^^^^^^^^^^^^^^^

1. Using ``ssh-copy-id``:

.. code-block:: bash
    :caption: Copying using ssh-copy-id

    $ ssh-copy-id <username>@<remote_host>

You will then have to use your user's password to allow the public key to be copied over.

After it is added, you can access the server using ``$ ssh <username>@<remote_host>``

2. Manually copying it over

----

Basic Connections
-----------------

.. code-block:: bash
    :caption: Connecting with same username as host username

    $ ssh <remote_host>

.. code-block:: bash
    :caption: Connecting with specifying username

    $ ssh <username>@<remote_host>

You can run just a single command over ssh, and the session will automatically close after:

.. code-block:: bash
    :caption: Running a single command

    $ ssh <username>@<remote_host> <command_to_run>

The default port of ssh is port 22, but sometimes the server might use a different port. If this is the case,
you can specify the port number:

.. code-block:: bash
    :caption: Specifying to use a different port number to connect through

    $ ssh -p <port_num> <username>@<remote_host>

----

Configurations
--------------

Client Side Configurations
^^^^^^^^^^^^^^^^^^^^^^^^^^

You can create a configuration file on your host machine that will hold the config options
for connections. This can be located in ``~/..sh/config``

.. code-block::
    :caption: Basic config file example

    Host <remote_alias>
        HostName <remote_host>
        Port <port_num>

This example allows you to log into a specific port without needing to specify it in the command line

.. note::
    Check the ``$ man ssh_config`` page to see the configuration options available

.. code-block::
    :caption: Another Basic config file example

    Host testhost
        HostName <your_domain>
        Port <4444>
        User <demo>

Here you can use ``ssh testhost`` to use the config defined in the config file.

You can also use wildcards to apply to more than one host, these can be overriden later on:

.. code-block::
    :caption: Example using Wildcard to set ForwardX11 for all hosts

    Host *
        ForwardX11 no

    Host testhost
        HostName <your_domain>
        ForwardX11 yes
        Port <4444>
        User <demo>   

You can avoid ssh sessions timing out by making the host send a packet to the client at configurable
times.

.. code-block::
    :caption: Configure *~/.ssh/config* file to send alive packet every 120s

    Host *
        ServerAliveInterval 120

If you have mutiple connections to the same client, you can multiplex your ssh connections on the same
TCP connection instead of creating new TCP connecions for each instance.

.. code-block::
    :caption: Configure *~/.ssh/config* file use TCP multiplexing

    Host *
        ControlMaster auto
        ControlPath ~/.ssh/multiplex/%r@%h:%p
        ControlPersist 1

Server Side Configurations
^^^^^^^^^^^^^^^^^^^^^^^^^^

You can configure the way your server responds to requests.

- Disabling Password Authentication:

    If you have already setup your ssh keys, it can be a good idea to disable password access, since
    this is less secure.

    Restart the ssh service for the changes to take place: :bash:`$ sudo service ssh restart`

    .. code-block::
        :caption: Configure the */etc/ssh/sshd_config* file

        PasswordAuthentication no

- Changing the port the daemon runs on:

    Changing the default port can help limit the number of authentication request you get from attackers.

    Again restart the ssh server to make the change take affect

    .. code-block::
        :caption: Configure the */etc/ssh/sshd_config* file

        #Port 22
        Port <new_port_number>

- Limiting which users can be accessed with SSH:

    Edit the */etc/ssh/sshd_config* file.

    .. code-block::
        :caption: Allow users explicitly

        AllowUsers <user2> <user1>

    Or you can allow a group of users
    
    .. code-block::
        :caption: Allow ssh group

        AllowGroups <sshmembers>

    You can create a group as follows:

    .. code-block:: bash
        :caption: Creating a User group

        $ sudo groupadd -r sshmembers
        $ sudo usermod -a -G sshmembers user2
        $ sudo usermod -a -G sshmembers user1

- Disable root login:

    If you have setup an ssh user with ``sudo`` privilidges, you can disable access to the root user.

    .. code-block::
        :caption: Edit the */etc/ssh/sshd_config* file

        PermitRootLogin no

- Allowing root access for specific commands

    You might want to disable root access in general but only let certain commands run with root privilidges

    This can be achieved by adding specific commands to the root user's ``authorized_keys`` file.

    It is recommended to use a new key for each automatic process.

    .. code-block::
        :caption: Setting a ssh key for a specific command in */root/.ssh/authorized_keys*

        command="</path/to/command arg1 arg2>" ssh-rsa ...

    Then edit the *etc/ssh/sshd_config* file

    .. code-block::
        :caption: Allow SSH key logins to use root only when the command has been specified for the key

        PermitRootLogin forced-commands-only

- Forwarding X Application Displays to the Client:

    X applications are application that use the X Window display.

    These windows can be forwarded from the server to the client and displayed as long as the client has
    support for X windows.

    To enable this on the server, edit the */etc/ssh/sshd_config* file:

    .. code-block::
        :caption: Enable X Windows Forwarding

        X11Forwarding yes

    When you connect from the client, use the X windows flag:

    .. code-block:: bash
        :caption: Using X Window Forwarding

        $ ssh -X <username>@<remote_host>

----

SSH Tunnels
-----------

You can tunnel other traffic through your ssh connection. This can be a nice way to get around firewall
issues, or if you want that data to be encrypted when it otherwise wouldn't be.

Configure Local Tunnelling to a Server
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

SSH connection can be used to tunnel traffic from ports on the local host to ports on a remote host.

To establish a local tunnel, use the ``-L`` option. You also need to provide:

- The local port you wish to access the tunneled connection
- The host you want your remote host to connect to
- The port that you want your remote host to connect on

.. code-block:: bash
    :caption: Example setting up a local tunnel

    $ ssh -L <your_port>:<site_or_IP_to_access>:<site_port> <username>@<host>

    $ ssh -L 8888:<your_domain>:80 <username>@<host>

This example shows forwarding to port 80 on the remote host, and forwarding from port 8888 local machine.

.. note::
    Use the ``-f`` flag to make SSH go into the background before executing, and ``-N`` which does not open a shell or
    execute a command.

Configure Remote Tunnelling to a Server
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This is basically the same as the ``-L`` option above, but the other way around. It will forward connections
from the remote (server) side to your local host.

Instead, use the ``-R`` option.

.. code-block:: bash
    :caption: Example setting up a remote tunnel

    $ ssh -L <site_port>:<site_or_IP_to_access>:<your_port> <username>@<host>

    $ ssh -L 8888:<your_domain>:80 <username>@<host>

This example shows tunneling from remote port 8888 to your local port 80.


----

SSH Escape Codes
----------------

One useful feature of OpenSSH is that you can control the session from within the session.

Session commands start with the ``~`` character.

.. note::
    These commands have to have a newline before it, so hit [Enter] twice before executing a command.

.. code-block:: bash
    :caption: Closing the connection from the Client side

    $ ~.

.. code-block:: bash
    :caption: Placing Session into background

    $ ~[CTRL-z]

This will place the connection in the background and return you to your shell.
Reactivate the most recent backgrounded task using :bash:`$ fg`, or see your backgrounded
tasks using :bash:`$ jobs`.

.. code-block:: bash
    :caption: Opening a SSH command line interface

    $ ~C

This will enter a command shell. Type ``-h`` to see your options. You are able to change port
forwards or cancel them etc.

----

SSH Agent
---------

This is a small utility that stores your private key after you have entered the passphrase for the first time.
Then it can be used without a passphrase for the duration of the terminal session.

.. code-block:: bash
    :caption: Starting the SSH Agent, and adding a private key

    $ ssh-agent
    $ ssh-add

----

Multiple SSH Users - GitHub
---------------------------

Checkout `this <https://gist.github.com/rahularity/86da20fe3858e6b311de068201d279e3>`_ tutorial.

1. Create seperate ssh keys.
2. Make a config file in *.ssh/config*

.. code-block::
    :caption: Example config (*.ssh/config*) file

    #account1
    Host github.com-account1
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_rsa

    #account2
    Host github.com-account2
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_rsa_account2

3. When you clone the repo, make sure to clone it as a specific user:

.. code-block::
    
    git clone git@github.com<user_to_clone_with>:<repo_owner>/<repo_name>.git

----

Sources
-------

- https://www.digitalocean.com/community/tutorials/ssh-essentials-working-with-ssh-servers-clients-and-keys