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

Sources
-------

- https://docker-curriculum.com
- https://www.tutorialspoint.com/docker/index.htm