⚔️ OpenViking
=============

OpenViking is a database designed to make it easy for LLMs to access information in a token-efficient way.
Rather than organizing content like a traditional database, it's structured more like a filesystem, making
it more intuitive than traditional RAG (Retrieval-Augmented Generation) systems.

To run OpenViking you need access to two models: an embedding model and a VLM (a vision language model —
essentially an LLM that can also handle images).

It stores three types of things:

- **Resources** — documents like docs or code repos
- **Memory** — things the agent has learned about you and itself over time
- **Skills** — callable tools the agent can invoke

How Embedding Models Work
--------------------------

An embedding model converts a piece of text into a list of numbers called a vector. For example, the word
"dog" might become something like ``[0.2, 0.8, 0.1, ...]`` with hundreds of numbers in the list. The model
is trained on huge amounts of text, so the numbers it produces capture the *meaning* of the text — not just
the words themselves.

The key idea is that texts with similar meanings end up with similar vectors. So "dog" and "puppy" will
produce vectors that are close to each other, while "dog" and "skyscraper" will be far apart.

Cosine Similarity
^^^^^^^^^^^^^^^^^

To measure how close two vectors are, the most common method is called **cosine similarity**. You can think
of each vector as an arrow pointing in a direction in space. Cosine similarity measures the angle between
two arrows — if they point in almost the same direction, the score is close to 1 (very similar), and if
they point in completely different directions, the score is close to 0 (unrelated). This gives you a
relevance score between any two pieces of text without needing exact word matches.

For example:

- *"how do I log in"* vs *"authentication flow"* → high similarity score, even though they share no words
- *"how do I log in"* vs *"database backup schedule"* → low similarity score

This is what makes embedding-based search much more powerful than old keyword search — it understands
meaning rather than just matching words.

Document Summarization
^^^^^^^^^^^^^^^^^^^^^^

When you add a document to OpenViking, the VLM is used to generate different levels of summaries:

- **L0** — very short abstract (~100 tokens)
- **L1** — longer overview (~2k tokens)
- **L2** — full document

These summaries can be used instead of the full file sometimes, helping keep the input token cost down.

How Retrieval Works
--------------------

Say you ask: *"How does the authentication module work?"*

1. **Intent analysis** — the system analyzes what you are actually looking for, and may break it into
   multiple search conditions (e.g. "authentication", "login flow", "auth module").

2. **L0 scan** — the embedding model scores all the L0 abstracts in the database against your query. This
   is very cheap since L0s are tiny. Any folder or file that scores poorly gets dropped.

3. **Directory shortlisting** — the system identifies the highest-scoring directory, then performs a
   secondary retrieval within that directory, recursively drilling down into subdirectories. So rather
   than just finding loose matching chunks, it finds the right *folder* first, which gives the results
   much better context.

4. **Contextual boost** — content within a semantically relevant directory receives a higher score even
   if its own embedding similarity is moderate, because being in the right folder is itself a strong signal.

5. **L1 check** — for the shortlisted files, the L1 overview is loaded. This is enough to confirm
   relevance and decide what to do next, without loading the full document.

6. **L2 on demand** — only if the L1 isn't enough, the full L2 document is loaded. The agent loads L0
   first (cheap), decides if it is relevant, then drills to L2 only when needed.

7. **Answer generation** — the most relevant content (at whichever level was needed) is passed to the
   LLM as context to generate the final answer.

The result is that for simple questions you might only ever load L0s and one L1, spending very few tokens.
Only complex questions that genuinely need the full document end up loading L2. Published benchmarks suggest
token cost reductions of 80–90% compared to loading full context every time.

----

Self-Evolving Memory
---------------------

OpenViking also has a self-evolving memory feature — at the end of a session it can analyze what happened
and save useful things into long-term memory, so the agent gets smarter over time.

----

Use Cases
---------

OpenViking is useful for holding vast amounts of documents, such as:

- Large documentation bases
- Code repositories
- Knowledge bases
- Reference materials

The token-efficient retrieval makes it practical to work with repositories that would be too large to fit
in a single context window.

----

Configuration
--------------

Here's an example configuration for OpenViking:

.. code-block:: json
    :caption: Example OpenViking config

    {
      "embedding": {
        "dense": {
          "provider": "gemini",
          "api_key": "<your-gemini-api-key>",
          "model": "text-embedding-004",
          "dimension": 768
        }
      },
      "vlm": {
        "provider": "litellm",
        "api_key": "<your-anthropic-api-key>",
        "model": "anthropic/claude-haiku-4-5-20251001"
      }
    }
