MCP Servers
===========

The Model Context Protocol (MCP) is an open standard that allows AI tools to interact with
external servers. It provides a structured way to expose tools, data, and prompts to an LLM client.

You can write your own MCP server using the Python MCP SDK, and connect it to clients such as
Claude Code.

Writing a Server
----------------

Use the Python MCP SDK to define your server. Install it with:

.. code-block:: shell

    pip install mcp

A minimal server looks like:

.. code-block:: python
    :caption: Example MCP server (server.py)

    from mcp.server.fastmcp import FastMCP

    mcp = FastMCP("my-server")

    @mcp.tool()
    def greet(name: str) -> str:
        """Return a greeting for the given name."""
        return f"Hello, {name}!"

Testing a Server
^^^^^^^^^^^^^^^^

You can test your server interactively during development using the ``mcp dev`` command:

.. code-block:: shell

    uv run mcp dev server.py

This starts an inspector interface that lets you call tools directly without needing a full
client setup.

----

Clients
-------

A client connects to one or more MCP servers and manages communication with them. Its two main
responsibilities are:

- Providing the LLM with the list of available tools exposed by the servers
- Calling tools on behalf of the LLM and returning the results

A single client can connect to multiple servers simultaneously, aggregating their tools into one
interface for the model.

----

Resources
---------

Resources allow a server to expose data to a client, similar to a GET request in a REST API.
Each resource is identified by a URI that describes where the resource is located.

.. code-block:: python
    :caption: Example static resource

    @mcp.resource("config://app")
    def get_config() -> str:
        """Expose application config."""
        return "debug=true"

Templated Resources
^^^^^^^^^^^^^^^^^^^

Templated resources allow arguments to be passed in the request, making them dynamic:

.. code-block:: python
    :caption: Example templated resource

    @mcp.resource("users://{user_id}/profile")
    def get_user_profile(user_id: str) -> str:
        """Return the profile for a given user."""
        return f"Profile data for user {user_id}"

----

Prompts
-------

Servers can define reusable prompts to provide high-quality, task-specific instructions to the
model. This is useful for standardising how the LLM approaches certain tasks.

.. code-block:: python
    :caption: Example prompt definition

    @mcp.prompt()
    def summarise_file(filename: str) -> str:
        """Prompt for summarising the contents of a file."""
        return f"Please summarise the contents of the file '{filename}' concisely."

Prompts defined on a server are made available to the client and can be selected by the user or
the model as needed.

----

Sampling
--------

Sampling allows a server to ask the client to make a request to the LLM on its behalf. This means
the server does not need its own API key, which is particularly useful for public servers.

----

Logs and Progress
-----------------

Servers can emit log messages and progress notifications so the user can see that a request is
still working, which is useful for longer-running operations. In the Python SDK these are accessed
through the ``Context`` argument. On the client side they can be handled through callbacks.

----

Roots
-----

Roots grant a server access to specific files and also help the LLM find things more easily.
It is up to the server implementer to block access to anything outside the allowed paths.

----

Transports
----------

**stdio** (stdin/stdout) is the simplest transport and works well, but only when both client and
server are on the same machine.

**Streamable HTTP** is available for remote servers but has some nuances:

- On initialisation the client is given a unique ID it must use for all subsequent requests.
- The server cannot send requests to the client until the first SSE channel is opened.
- When the client sends another request, a second SSE channel is opened for the duration of that
  request. Progress notifications travel on the first SSE channel; logging goes on the second.
- For stateless server configurations, the SDK's ``stateless_http`` mode can be used — no client
  ID is assigned and no initialisation handshake occurs, but no SSE channel is opened either.
- Set ``json_response=True`` to disable streaming for a request.

.. note::

   It is recommended to develop using the same transport you plan to use in production. Switching
   transport types late can surface issues that are harder to debug once the server is deployed.
