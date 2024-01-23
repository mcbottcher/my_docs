Ansible
=======

Ansible is a tool used for managing infrastructure. For example, if you have a number
of machines in your test system, you might manage updates etc. on all of them with
ansible.

Ansible uses control nodes, which can be any machine with ansible installed, to send commands
and instuctions to managed nodes.

Ansible uses SSH and SFTP/SCP, so no agent needs to be added to the managed nodes. This makes
it handy for tasks such as provisioning.

Getting Started
---------------

To get started you will need one machine with ansible installed, and one which will act as the
managed node. To setup the managed node, you need to install an ssh client on it and add the 
control machine's public ssh key to the autorized keys file.

You can then produce an ansible inventory file:

.. code-block::
    :caption: Example of an ansible inventory file called "hosts"

    host1 ansible_host=172.17.0.2 ansible_user=user ansible_ssh_private_key_file=~/.ssh/id_rsa

You can then run a simple ping test on all hosts specified in the ``hosts`` file with:

.. code-block::shell
    :caption: Example pinging all hosts

    ansible -i hosts all -m ping

This is an example of an "ad-hoc" command.

----

Playbooks
---------

This is a way for ansible to automate repeating tasks. This is done using structured files written
in yaml as an ordered set of steps to run.

.. code-block::yaml
    :caption: Example of a playbook 

    - name: Intro to Ansible Playbooks
      hosts: all

      tasks:
        - name: Upgrade all apt packages
          # Ansible module used for this task
          apt:
          force_apt_get: yes
          upgrade: dist
          # This task is run with elevated privilege i.e. sudo
          become: yes

You can run this using a command like:

.. code-block::shell

    ansible-playbook intro-playbook.yml --inventory hosts --extra-vars "ansible_sudo_pass=<user_password>"

Using Variables
^^^^^^^^^^^^^^^

You can add vairables in your playbook yaml files.

.. code-block::yaml
    :caption: Example using vairables

    - name: Variables playbook
      hosts: all
      vars:
        user: bob
      tasks:
        - name: Add the user {{ user }}
          ansible.builtin.user:
            name: "{{ user }}"

Note when assigning a variable to another, you have to use the double quotes.

You can also add arguments via the command line: e.g.

.. code-block::shell
    :caption: Example with command line vars

    ansible-playbook <playbook>.yml -e "var1=hello var2=3"

Modules
-------

Modules are discrete units of code that can be used from command line or in a playbook task.
Ansible ships with a load of readily avaialble modules.

.. note::
    Use the command ``ansible-doc -l`` to list all modules. Or for documentation on a single module,
    use ``ansible-doc <module>``.

It is possible to enable a custom module by adding it to one of these locations:

1. Add path to ``ANSIBLE_LIBRARY``
2. ``~/.ansible/plugins/modules/``
3. ``/usr/share/ansible/plugins/modules/``

Follow this link for an example of creating your own module:
 ``https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_general.html#creating-a-module``