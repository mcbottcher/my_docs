|:ninja:| Jinja
================

Jinja is a template engine, which allows you to generate text from a template.

Installation
------------

Jinja2 is the version compatible with python3. You can install using pip:

``pip install Jinja2``

Basic Usage
-----------

With Jinja you provide a template file with variables that should be filled in.
You load this file and then 'render' these varibales.

.. code-block:: python
    :caption: Basic Load and Rendering Example

    from jinja2 import Environment, FileSystemLoader

    name = "jinja"
    environment = Environment(loader=FileSystemLoader("templates/"))
    template = environment.get_template("message.txt")

    # returns rendered template as a string
    content = template.render(name=name)

    print(content)


.. code-block::
    :caption: Example template file

    Hello, my name is {{ name }}.

Comments
^^^^^^^^

.. code-block::
    :caption: Example of Jinja Comment

    {# This is a comment #}


Flow Control
------------

``if`` statements
^^^^^^^^^^^^^^^^^

.. code-block::
    :caption: Example if statement

    {% if score < 80 %}
    You FAILED
    {% else %}
    You PASSED
    {% endif %}

``for`` loops
^^^^^^^^^^^^^

.. code-block::
    :caption: Example using Jinja for loop

    {% for student in students %}
    Hello, my name is {{ student }}
    {% endfor %}

Nesting templates
-----------------

As you get more templates, you might want to keep common code in the same place.
You can use Jinja's template inhertiance.

.. code-block::
    :caption: Example base template

    Hello my name is {{ name }}.

    {% block age %} By default my age is {{ age }} {% endblock age %}

.. code-block::
    :caption: Example child template

    {% extends "base.template" %}

    {% block age %} My new age is {{ age }} {% endblock age %}

If the block age is not given in the overriding template, then the content from the default
template will be used.

Inlcuding Templates
-------------------

You are also able to include a whole other template in another template.

.. note::
    Template files which are meant to be included should be prefixed with an underscore in their name.

.. code-block::
    :caption: Example of Jinja include

    {% include "_other.template" %}

    Some more words.

Whitespace
----------

You need take care about where Jinja will add in whitespace.

.. code-block::
    :caption: Example template

    Hello
    {# Just a comment #}
    You

.. code-block::
    :caption: Produced text

    Hello

    You

There a few ways you can avoid this.

1. Enable ``trim_blocks`` and ``lstrip_blocks`` rendering options
2. Use a ``-`` at the start or end of a block. e.g. ``{% if var == "1" -%}``

Built-in Filters
----------------

You can see a list of built-in filters here: https://jinja.palletsprojects.com/en/3.1.x/templates/#builtin-filters
You can apply a filter by using the pipe symbol ``|``.

.. code-block::
    :caption: Example Jinja filter

    First name: {{ first_name | capitalize }}

.. code-block::
    :caption: Example chaining filters

    {{ scraped_acl | first | trim }}

Jinja allows you to write your own filters too. These are basically just python functions.
See https://ttl255.com/jinja2-tutorial-part-4-template-filters/#:~:text=on%20our%20list.-,Writing%20Your%20Own%20Filters,-As%20I%20already
for more info.

Macros
------

Macros are nice for creating re-usable components.

.. code-block::
    :caption: Example Macros

    {% macro banner() -%}
    ===========================================
    |   This device is property of BigCorpCo  |
    |   Unauthorized access is unauthorized   |
    |  Unless you're authorized to access it  |
    |  In which case play nice and stay safe  |
    ===========================================
    {% endmacro -%}

    {{ banner() }}

.. code-block::
    :caption: Example output

    ===========================================
    |   This device is property of BigCorpCo  |
    |   Unauthorized access is unauthorized   |
    |  Unless you're authorized to access it  |
    |  In which case play nice and stay safe  |
    ===========================================

You are also able to pass arguments to macro calls.

.. code-block::
    :caption: Example with arguments

    {% macro def_if_desc(if_role) -%}
    Unused port, dedicated to {{ if_role }} devices
    {%- endmacro -%}

Macros are similar to python function in that they also can have args and kwargs.

Macros in separate file
^^^^^^^^^^^^^^^^^^^^^^^

You can store macros in a separate file and import them into your file as needed.

For example, to import: ``{% import 'macros.file' as macros -%}``.
You can access a macro by using ``macro.<macro_name>``.

