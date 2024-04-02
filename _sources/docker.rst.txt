.. role:: bash(code)
   :language: bash


.. role:: docker(code)
    :language: docker

Docker
======

Docker is a tool that allows developers to develop their applications in a sandbox
(container) to run on the host operating system.

Main components of Docker:

    - Docker for Linux: Run containers on Linux
    - Docker Engine: Used to build Docker images and create Docker containers
    - Docker Hub: Registry which is used to host images
    - Docker Compose: Defines applications using multiple Docker containers

----

Useful Terms
------------

- Images: The blueprint of our application which form the basis of containers
- Containers: A running version of an image
- Docker Deamon: The background service on the host which manages building, running and distributing containers
- Docker Cliert: The command line tool that lets the user interact with the Daemon
- Docker Hub: Registry of Docker images. You can also host your own registry!

----

Commands
--------

- ``pull``: This fetches the image from the Docker registry and saves it your system

    :bash:`docker pull <image_name>`

- ``images``: Lists all images on your system

    :bash:`docker images`

- ``run``: Runs the specified container

    :bash:`docker run <image_name>`

    - This will exit immediately since no command is specified for the container to run:
        
        :bash:`docker run busybox echo "hello from busybox container"`

    - Run with an interactive environment:

        :bash:`docker run -it busybox`

    - Run with it detached from the terminal: will keep running even if terminal is closed

        :bash:`docker run -d <image_name>`

    - Set a name for your container, which you can use instead of an ID to perform actions e.g. ``stop``

        :bash:`docker run --name my_container <image_name>`


- ``rm``: Deletes a Docker container. It is good to do this after use to save memory

    .. code-block:: bash

        docker ps -a
        docker rm <id>

    .. code-block:: bash

        docker run --rm <image_name> # automatically deletes container when it exits

- ``ps``: Lists containers

    :bash:`docker ps -a`

    Use ``-q`` to only list IDs. This can be useful if you want to remove all containers e.g.

    :bash:`docker rm $(docker ps -a -q)`

- ``prune``: Deletes all exited containers

    :bash:`docker prune`

- ``cp``: Copies files from the container to the host machine

    .. code-block:: bash

        docker cp <container_id>:path_to_files host_destination

- :bash:`docker compose up`: This will run the docker compose file

- :bash:`docker compose down`: Shuts down all the containers together

----

Dockerfiles
-----------

A Dockerfile contains a list of commands that the Docker client calls when creating an image.

- ``FROM``: Specifies the base image to use

- ``WORKDIR``: Sets the working directory for any subsequent commands

.. note::
    This is the working directory inside the docker container, not the host working directory

- ``COPY``: Copies files to the container

    :docker:`COPY <src> <dest>`

    e.g.

    :docker:`COPY . /home/my_docs/`

- ``RUN``: Executes commands during the image build. Commits the results to the new image.

    :docker:`RUN pip install -r requirements.txt`

- ``CMD``: Specifies the default command to be executed when a container starts. Can be overriden by command line args.

    :docker:`CMD ["echo", "hello"]`

    It comes in three forms:

    1. :docker:`CMD ["executable","param1","param2"]` (exec form, this is the preferred form)
    2. :docker:`CMD ["param1","param2"]` (as default parameters to ENTRYPOINT)
    3. :docker:`CMD command param1 param2` (shell form)

- ``ENTRYPOINT``: Specifies the command that will be executed first by a container. Cannot be overriden by command line.

.. note::
    It could be useful to start shell, then use ``CMD`` to pass the arguments. :docker:`ENTRYPOINT["/bin/sh", "-c"]`

----

Docker Volumes
--------------

A Docker Volume is a way of including part of your host filesystem into the Docker container.
This way when you close and delete the container, you have a way of storing the data that you wanted.

There are 3 types of volumes:

1. Host Volume: Use the :bash:`docker run -v <host_dir>:<container_dir>` to specify a volume.
2. Anonymous Volumes: :bash:`docker run -v <container_dir>`. This will put the volume somewhere on your host fs that you have't specified (``/var/lib/docker/volumes/``)
3. Named Volume: :bash:`docker run -v name:<container_id>`. You can reference the host volume with a name that you specify

.. note:: 
    When specifying a volume, you should use the absolute path as to not run into issues.

----

Docker Compose
--------------

One of the best ways of making docker containers easy to maintain, is to use multiple containers
for one job, each one implementing one process (micro-service).

Docker Compose lets you run multiple docker containers at the same time.

Docker Compose uses a yaml file to configure the containers that are run.

- :bash:`docker compose up`: This will run the docker compose file
- :bash:`docker compose down`: Shuts down all the containers together

.. code-block:: yaml
    :caption: Example of a *docker-compose.yaml*

    version: '3'
    services:
        app:
            image: node:latest
            container_name: app_main
            restart: always
            command: sh -c "yarn install && yarn start"
            ports:
            - 8000:8000
            working_dir: /app
            volumes:
            - ./:/app
            environment:
            MYSQL_HOST: localhost
            MYSQL_USER: root
            MYSQL_PASSWORD: 
            MYSQL_DB: test
        mongo:
            image: mongo
            container_name: app_mongo
            restart: always
            ports:
            - 27017:27017
            volumes:
            - ~/mongo:/data/db
    volumes:
    mongodb:

- ``version``: This is the docker compose version we are using
- ``services``: This provides a list of the containers that we run
- ``app``: This is a custom name for one of the containers/services
- ``image``: The image that the container is based on
- ``container_name``: Name that the container will use
- ``restart``: Starts/restarts a service container
- ``port``: Defines the custom port to run the container (host_port:container_port)
- ``working_dir``: The current working directory of the service container
- ``environment``: Defines the environment variables
- ``command``: This is the command to run the service

----

Example Dockerfile
------------------

.. code-block:: dockerfile
    :caption: Example Dockerfile

    FROM ubuntu:22.04 AS base_image

    ARG USER=runner

    ARG TARGETPLATFORM
    ENV TARGETPLATFORM=$TARGETPLATFORM

    # Use bash instead of sh
    SHELL ["/bin/bash", "-c"]

    RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && \
        apt-get -y install --no-install-recommends \
        python3-dev \
        python3-pip \
        python3-venv \
        sudo

    # Configure non-root user
    RUN adduser --disabled-password --gecos "" "$USER"  && \
        echo "$USER ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${USER}" && \
        chmod 0440 "/etc/sudoers.d/${USER}" && \
        usermod -aG sudo ${USER} && \
        usermod -aG dialout ${USER}

    WORKDIR "/home/${USER}"

    USER ${USER}

    RUN python3 -m venv .venv

    RUN source .venv/bin/activate && python -m pip install --upgrade setuptools wheel
    RUN source .venv/bin/activate && python -m pip install fabric

    ##### Production Image

    FROM base_image AS production_image

    COPY --chown=${USER}:${USER} ./python-packages python-packages

    RUN source .venv/bin/activate && python -m pip install python-packages/my-package

    RUN rm -rf python-packages

    ##### Development Image

    FROM base_image AS dev_image

    COPY --chown=${USER}:${USER} ./dev_entrypoint.sh dev_entrypoint.sh

    CMD ["/bin/bash"]

    ENTRYPOINT [ "./dev_entrypoint.sh" ]

This example has a few notable things.

First, here we can build two images, production_image and dev_image. You can specify which to build
in the docker build ``--target`` argument. This way a Dockerfile can contain multiple image targets.

Also note that when copying in files from the local machine, we can specify that the files
use a specific user other than root.

.. note:: 
    To run the ``CMD`` from an entrypoint script, you should include ``exec "$@"`` in the entrypoint
    script.

----

Exporting an image to file
--------------------------

When you build an image/images, you can choose from a number of 
`Export options <https://docs.docker.com/build/exporters/>`_.

The ``docker`` option exports the build result to the local file system.
It is possible to then load this image file into your local docker image registry.
This could be on the same machine, or you could send this file to another machine and load it there.
In this way, it is possible to build on one machine and export the image to be executed on another machine
(as long as the platform that is built matches the platform where it is run).

.. code-block:: shell
    :caption: Example outputting to file

    docker buildx build --platform="linux/arm64/v8" -t my_image:latest --output type=docker,dest=my_image.tar

You can then load the image using:

.. code-block:: shell

    docker load -i my_image.tar

This will show as ``my_image:latest``, since this is what we used with the ``-t`` option in the build command.

.. note:: 
    When tested, it was not possible to do this for multi-arch builds,
    e.g. ``--platform="linux/arm64/v8,linux/amd64"``. For mutli-arch builds you will have to run the build 
    commands separately.

----

Multi-architecture Targets
--------------------------

This section will give some info on how you can build docker images for multiple architecture target platforms.

You can find some general documentation `here <https://docs.docker.com/build/building/multi-platform/>`_.

In the examples given below, we are going to be building an image for two target architectures,
*arm64* and *amd64*. This will be done from a host machine using amd64.

Building with QEMU
^^^^^^^^^^^^^^^^^^

Since we are using an amd64 machine, we can easily build images targeting amd64.
To build arm64 images on this machine, one technique is to use the QEMU feature of the docker builder,
to emulate an arm64 machine and build an image for that.

.. note:: 
    For building the multiarch images, we will be using docker buildx

First you will want to create a builder instance which is capable of building images for multiple architectures:

.. code-block:: shell

    docker buildx create --bootstrap --name qemu_builder --platform="linux/arm64,linux/amd64"

You can confirm this has been made by running:

.. code-block:: shell

    docker buildx ls

You can then build using:

.. code-block:: shell

    docker build --builder qemu_builder --platform="linux/amd64,linux/arm64" -t <tag> .

For reference, a test build I did took **863 seconds**.

Building with Native machines
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Using `Docker Contexts <https://docs.docker.com/engine/context/working-with-contexts/>`_ 
it is possible to build on a remote docker builder.

This means we can build our amd64 image locally, and the arm64 image on another machine, 
using the same docker build command. If this other machine uses arm64 architecture e.g. 
RaspberryPi 5, then the build will not need to use QEMU and will be much faster since it is 
building for its native architecture.

To achieve this you will have to setup two context nodes, one on you local machine and one on the remote machine:

1. **Local machine (amd64):**

.. code-block::

    docker context create node-amd64
    
    docker context ls

    NAME         DESCRIPTION                               DOCKER ENDPOINT               ERROR
    default *    Current DOCKER_HOST based configuration   unix:///var/run/docker.sock   
    node-amd64   Current DOCKER_HOST based configuration   unix:///var/run/docker.sock

As shown a new docker context using the host machines configuration has been created.

2. **Remote Machine (RPi5 - arm64):** You will want to make sure that your remote machine has an ssh
   client and docker installed. `This Guide <https://thenewstack.io/connect-to-remote-docker-machines-with-docker-context/>`_
   can help with setting up the remote host ssh.

.. code-block:: 

    docker context create node-arm64 --docker "host=ssh://$TARGET_HOST"

    docker context ls

    NAME         DESCRIPTION                               DOCKER ENDPOINT               ERROR
    default *    Current DOCKER_HOST based configuration   unix:///var/run/docker.sock   
    node-amd64   Current DOCKER_HOST based configuration   unix:///var/run/docker.sock   
    node-arm64                                             ssh://<user_name>@<remote_host_ip_address> 

Where ``TARGET_HOST`` contains something like: ``<user_name>@<remote_host_ip_address>``.

.. note:: 
    The setup for the remote machine is still run on the main docker machine

Now you have your two contexts setup, you can incorporate them both into the same builder. 
See `this link <https://docs.docker.com/build/building/multi-platform/#multiple-native-nodes>`_ 
for documentation on how to do this.

In our case, this will look something like this:

.. code-block:: 

    docker buildx create --use --name mybuilder --platform linux/arm64 node-arm64
    docker buildx create --append --name mybuilder --platform linux/amd64 node-amd64

You can check that the builder like so:

.. code-block:: 

    docker buildx ls
    
    NAME/NODE       DRIVER/ENDPOINT             STATUS  BUILDKIT PLATFORMS
    mybuilder *     docker-container                             
    mybuilder0    node-arm64                  running v0.13.1  linux/arm64*, linux/arm/v7, linux/arm/v6
    mybuilder1    node-amd64                  running v0.13.1  linux/amd64*, linux/amd64/v2, linux/amd64/v3, linux/arm64, linux/riscv64, linux/ppc64, linux/ppc64le, linux/s390x, linux/386, linux/mips64le, linux/mips64, linux/arm/v7, linux/arm/v6
    qemu_builder    docker-container                             
    qemu_builder0 unix:///var/run/docker.sock running v0.13.1  linux/arm64*, linux/amd64*, linux/amd64/v2, linux/amd64/v3, linux/riscv64, linux/ppc64, linux/ppc64le, linux/s390x, linux/386, linux/mips64le, linux/mips64, linux/arm/v7, linux/arm/v6
    default         docker                                       
    default       default                     running v0.12.5  linux/amd64, linux/amd64/v2, linux/amd64/v3, linux/386, linux/arm64, linux/riscv64, linux/ppc64, linux/ppc64le, linux/s390x, linux/mips64le, linux/mips64, linux/arm/v7, linux/arm/v6
    node-amd64      docker                                       
    node-amd64    node-amd64                  running v0.12.5  linux/amd64, linux/amd64/v2, linux/amd64/v3, linux/386, linux/arm64, linux/riscv64, linux/ppc64, linux/ppc64le, linux/s390x, linux/mips64le, linux/mips64, linux/arm/v7, linux/arm/v6
    node-arm64      docker                                       
    node-arm64    node-arm64                  running v0.12.5  linux/arm64, linux/arm/v7, linux/arm/v6

Then to build your image, all you have to is run the build command and specify the new builder:

.. code-block:: 

    docker build --builder mybuilder --platform="linux/amd64,linux/arm64" -t <tag> .

For the same reference images as the QEMU builder, this took **295 seconds** (vs 863 seconds from the QEMU builder).

.. note:: 
    You will have to setup a push to registry if you want to keep the images, otherwise they are just kept in the cache.

----

Sources
-------

- https://docker-curriculum.com
- https://www.tutorialspoint.com/docker/index.htm