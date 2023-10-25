|:mermaid:| Mermaid
===================

Mermaid allows you to insert figures and diagrams into your markdown or
re-structured text documents.

Usage
-----

- In Github markdown, you can use mermaid like you would a code block:

.. code-block::
    :caption: Example of Github Markdown 

    ```mermaid
    
    .. code goes here

    ```

- In rst files, you can setup mermaid for you sphinx build with this: `Python Package <https://pypi.org/project/sphinx-mermaid/>`_

.. code-block::
    :caption: Example using mermaid in sphinx rst file

    .. mermaid::

        graph TD
        A --> B
        B -- Label --> C

Examples
--------

Pie chart
^^^^^^^^^

.. code-block::
    :caption: Example making a Pie Chart 

    pie title Pets adopted by volunteers
        "Dogs" : 386
        "Cats" : 85
        "Rats" : 15

.. mermaid::
    pie title Pets adopted by volunteers
        "Dogs" : 386
        "Cats" : 85
        "Rats" : 15