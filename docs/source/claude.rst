AI tools
========

Claude Code
-----------

This is a tool which interfaces between your command line and the LLM Claude uses.

Commands
^^^^^^^^

Commands are run but using ``/<command>``. Can see a list by just typing the ``/``

- ``init``: Claude analyses your code and makes a summary in the ``claude.md`` file for future context
- ``compact``: summarises the chat for concise context 
- ``clear``: refresh the context from the chat

You can also implement custom commands in ``.claude/commands/<name.md>``, including with arguments witht eh ``@`` symbol


Shortcuts
^^^^^^^^^

- ``#``: Memory mode, give instruction of something to commit to the project memory 
- ``@<filepath>``: point to a specific file for context. Can also be in the ``CLAUDE.md`` file, where the file is pasted in place so always part of the context prompt
- escape: interrupt claude
- double escape: go back in the chat history to remove some context that is no longer needed


Instruction Files
^^^^^^^^^^^^^^^^^

You can have instruction files in 3 different places:

- Root of the repo: in version control and applies to all devs
- ``claude.local.md``: personalised instructions not in version control for the project
- ``~/.claude/CLAUDE.md``: applies to all projects on your machine

MCP server
^^^^^^^^^^

A gateway for accessing external tools, for example "playwright" for interacting with browsers.

It is an open standard for interacting with AI tools, so you can also write your own.

Hooks
^^^^^

- Allows you to run a command before or after a tool runs. For example a tool might be one to read a file to give that to the claude LLM.
- You could run a custom hook before this tool is run, perhaps to check the file is allowed to be sent to the LLM. One after might apply code formatting.
- Hooks can be defined again in the repo, both personal and repo wide, and globally on your machine.
- Other hook stages also exist, such as session start and end, and userpromt submitted.

Misc
^^^^^

- Can instruct claude to write commit messages and commit files
- claude SDK: SDK available in python which lets you progrommatically invoke claude code commands. However, not all commands are availble as using the CLI.
