|:pencil2:| Prompt Engineering
==============================

General Principles
------------------

Be clear and direct — avoid ambiguous language, and describe the desired output explicitly.
Use numbered lists or bullet points when order matters. Providing context and motivation behind
instructions often improves results, as the model can make better judgements when it understands
the *why*.

Use direct command words rather than polite phrasing. Don't say "could you please" — just say
what you want.

Structure prompts with XML tags to separate concerns, making it clear which part of the prompt
does what:

.. code-block:: xml
    :caption: Example prompt structure

    <role>You are an experienced software developer.</role>
    <context>Background info...</context>
    <instructions>Do X, then Y</instructions>
    <input>The actual data...</input>

Here is a more complete example combining several of these principles:

.. code-block:: xml
    :caption: Example prompt

    <role>You are a senior Python developer performing code review.</role>
    <context>
      This is a REST API service. We prioritise readability and test coverage.
    </context>
    <instructions>
      Review the function below. List any bugs, then suggest improvements.
      Quote the relevant line before each comment.
    </instructions>
    <input>
      def get_user(id):
          return db.query("SELECT * FROM users WHERE id = " + id)
    </input>

----

Examples
--------

Providing 3-5 examples significantly improves output quality. The model uses them to anchor on
the expected format and style. Always include edge cases — they are often where output quality
degrades without them.

----

Long Context Prompts
--------------------

When working with large documents, put them at the start of the prompt, above the query and
instructions. Wrap each document in XML tags with an identifying label:

.. code-block:: xml
    :caption: Structuring multiple documents

    <document id="spec">...</document>
    <document id="logs">...</document>

For document-heavy tasks, ask the model to quote the relevant parts of the documents before
carrying out its task. This focuses attention and reduces irrelevant content being considered.

----

Output Format
-------------

Specify the desired output format explicitly — JSON, markdown, XML, plain text, etc. The style
of your prompt also influences the output style, so match your prompt's format to what you want
back.

----

Performance Tips
----------------

Tools can be called in parallel — explicitly request parallel calls if you want to ensure this.

For multi-step tasks, asking the model to show intermediate steps (e.g. via git commits) lets
you review progress incrementally.

When providing images, crop them to only the relevant area. You can also give the model a crop
tool so it can focus itself on what it needs.

----

Further Reading
---------------

- `Claude Prompting Best Practices <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices>`_
