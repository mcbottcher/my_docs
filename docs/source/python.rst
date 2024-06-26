.. role:: python(code)
    :language: python

|:snake:| Python
================

Lambda
------

- :python:`lambda <arguments> : <expression>`: Small anonymous function
- Can only have one expression, can take multiple arguments

.. code-block:: python

  func = lambda a : a + 10
  print(func(1)) # Will output 11
 
- Can also be used inside another function

.. code-block:: python

  def myfunc(n):
    return lambda a : a * n

  # function to double input
  mydoubler = myfunc(2)
  # function to triple input
  mytripler = myfunc(3)

  print(mydoubler(11))
  print(mytripler(11))

Map
---

- :python:`map(func, iter)`: Applies func to each element of iterable
- Returns a map object, need to covert to another type to view, e.g. list()
- map object is an iterator - it doesn't store the new data, just how to data is mapped, so when extracting a value it will map the value on the fly

.. code-block:: python

  def func(a):
    return a+10
    
  # prints [11, 12, 13]
  print(list(map(func, [1,2,3])))

- Can also use with Lambda function

.. code-block:: python

  print(list(map(lambda a:a+10, [1,2,3])))

Filter
------

- :python:`filter(func, iter)`: Added each element of iterable to new iterable if func returns true

.. code-block:: python
    
  def func(a):
    return a != 0
    
  # prints [1, 2]
  print(list(filter(func, [0, 1, 2])))

- Also used with lambda

.. code-block:: python

  print(list(filter(lambda a:a!=0, [0, 1, 2])))


Set
---

- Set is a collection which is unordered, unchangable (can remove and add items still), and unindexed
- :python:`my_set = {"banana", "apple", "cherry"}`
- Sets cannot have duplicate entries - they will be ignored if there is a duplicate
- Can also use the :python:`set()` object: :python:`my_set = set(("banana", "apple", 2, True))`

String formatting
-----------------

- :python:`print(f"Hello {my_string}")`

Checking for a type
-------------------

- Use :python:`isinstance(object, class_type)`
- Don't use :python:`==`

Equality vs Identity
--------------------

- :python:`is` checks that two variables point to the same object in memory
  - Use :python:`is` when checking for :python:`None True False` - :python:`if my_var is None:`
- :python:`==` or :python:`!=` check that the value of two objects are the same

Range Length Looping
--------------------

- Better to NOT use something like :python:`for i in range(len(a))`
- Instead use :python:`for v in a:` or similar
- If you need the index, you can use enumerate to get the element and the index at the same time:

.. code-block:: python

  a = [1, 2, 3]
  for index, element in enumerate(a):
    ...

Zip
---

- Returns a zip object, which is an iterator of tuples
- Each tuple contains the elements from the same index in the given input iterators
- If given input iterators have different lengths, zip iterator will be of length of the shortest input iterator
- Cannot be accessed with indexes so need to covert to a list or similar, or use in a loop

.. code-block:: python

  a = ("John", "Charles", "Mike")
  b = ("Jenny", "Christy", "Monica")

  x = zip(a, b)

  for av, bv in x:
    ...

Timing code
-----------

- Use :python:`time.perf_counter()` to time code

.. code-block:: python

  start = time.perf_counter()
  ...
  end = time.perf_counter()
  print(end - start)

Logging
-------

- Use logging instead of print statements for debug
- Can use different levels of log, and your own formatting

.. code-block:: python

  def my_func():
    logging.debug("debug info")
    logging.info("general info")
    logging.error("not good")

  def main():
    level = logging.DEBUG
    fmt = '[%(levelname)s] %(asctime)s - %(message)s'
    logging.basicConfig(level=level, format=fmt)

Using the `logging.basicConfig` uses the root logger, which is fine for small applications,
but for larger projects it is better to use different loggers. This allows you to have multiple logging
configurations.

For each logging instance, you can specify to where the log is written. You can use `FileHandler` type to
specify that your log will be written to a file. You can use the `StreamHandler` to specify the log will be printed
to the console for example.

.. code-block:: python
  :caption: Setting up a new logger

  # This will get the logger with the specified name, and create it if not already existing
  # using __name__ is a convention to use the module name for the logger
  my_logger = logging.getLogger(__name__)


.. code-block:: python
  :caption: Example setting a FileHandler

  file_handler = logging.FileHandler(log_file)
  file_handler.setLevel(logging.DEBUG)
  file_handler.setFormatter(formatter)
  logger.addHandler(file_handler)

.. code-block:: python
  :caption: Example setting a StreamHandler

  sh = logging.StreamHandler(sys.stdout)
  formatter = logging.Formatter(my_log_format)

  logger.addHandler(sh)
  sh.setFormatter(formatter)

.. note::
  You can use the logging level `exception` if you want to print a stack trace with your log message

One way you can change the formatting behaviour of your logger is to make your own custom
logging formatter and use that (in the ``setFormatter`` function)

.. code-block:: python
  :caption: Example using custom logging formatter

  class CustomFormatter(logging.Formatter):

    def __init__(
        self,
        pre_pend_newline: bool = True,
        *args,
        **kwargs,
    ):
        self._pre_pend_newline = pre_pend_newline
        super().__init__(*args, **kwargs)

    def format(self, record: logging.LogRecord) -> str:
        multiline_formatted_output = self._get_mutliline_formatted_output(record)
        if self._pre_pend_newline:
            multiline_formatted_output = "\n" + multiline_formatted_output

        return multiline_formatted_output

    def _get_mutliline_formatted_output(self, record: logging.LogRecord) -> str:
        # Some logs are given as a list
        if isinstance(record.msg, str):
            split_msg = record.msg.splitlines()
            formatted_msgs = []
            for msg in split_msg:
                record.msg = msg
                formatted_msgs.append(super().format(record))
            return "\n".join(formatted_msgs)

        return super().format(record)

Text Attributes
^^^^^^^^^^^^^^^

You can add text attributes to your log messages to make them more colourful/stand out

.. code-block:: python
  :caption: Example using text attributes

  class TextAttribute(Enum):
      """
      Enum of Text Attributes which can be applied to prints
      """

      YELLOW = "\x1b[33;20m"
      RED = "\x1b[31;20m"
      BOLD_RED = "\x1b[31;1m"
      CYAN = "\x1b[36;20m"
      BOLD_PURPLE = "\x1b[35;1m"
      BOLD_ONLY = "\x1b[1m"
      # Inverted doesn't seem to be supported in the github actions output console
      INVERTED = "\x1b[7m"
      RESET = "\x1b[0m"


Exceptions
----------

.. code-block:: python

  try:
    ...
  except FileNotFoundError:
    ...
  except Exception as e:
    print(e)

- Used to handle errors in pieces of code you think an error could occur in
- Can use multiple except statements to catch different errors - put more generic ones like :python:`Exception` towards the bottom
- use the :python:`else` to run code if the try block finishes without raising and exception
- use :python:`finally` to run if code is successful or if exception is thrown

.. code-block:: python

  try:
    ...
  except FileNotFoundError:
    ...
  else:
    print('Try succeeded')
  finally:
    print('This always runs')

- Raise your own exceptions: :python:`raise Exception`

.. code-block:: python

  class MyCustomError(Exception):
    pass

  try:
    if 1 == 2:
      raise MyCustomError
  except MyCustomError:
    print('My custom exception was triggered')


- It is also possible to catch an exception, run some code, then re-raise the exception:

.. code-block:: python
  :caption: Example re-raising an exception

  try:
    raise MyException
  except:
    print("Exception caught")
    # raise the exception again
    raise

.. warning::
  When you don't specify a specific exception in the ``except`` block, it will also catch 
  Keyboard interrupts like CTRL+C. You can specify to catch these with ``KeyboardInterrupt``

Handling Signals
^^^^^^^^^^^^^^^^

You can set functions for handling specified signals in python:

.. code-block:: python
  :caption: Example setting a Signal Handler

  #!/usr/bin/env python
  import signal
  import sys

  def signal_handler(sig, frame):
      print('You pressed Ctrl+C!')
      sys.exit(0)

  # register a signal handler here
  signal.signal(signal.SIGINT, signal_handler)
  print('Press Ctrl+C')
  # thread is paused until a signal is recieved
  signal.pause()

List comprehension
------------------

- Create a new list where each element which passes a filter is altered by a function

.. code-block:: python

  nums = [1, 2, 3, 4]
  # For all elements in nums which are even, double them and put them in my_list
  my_list = [x*2 for x in nums if x%2 == 0]

  # my_list = [4, 8]

Iterator
--------

- e.g. :python:`map()`
- A type that allows iteration but doesn't store any raw data
- Iterator stores where in sequence you are:

.. code-block:: python

  x = [1, 2, 3, 4, 5]
  y = map(lambda i: i*2, x)

  # can also use y.__next__()
  next(y)

  # This loop will start at second iteration of y .i.e. 2*2 = 4
  for i in y:
    print(y)

- use :python:`iter()` to make an iterator e.g.: :python:`x = iter(range(1, 11))`
- Exception :python:`StopIterator` will stop an interator - how a for loop stops for example

Generator
---------

.. code-block:: python

  def generator(n):
    for i in range(n):
      # pauses function and returns i to the calling function
      yield i

  for i in gen(5):
    print(i)

- Yield pauses function, saves context of function, uses the value, then comes back to continue the function
- Could also implement like this, remembering yield pauses then continues

.. code-block:: python

  def gen():
    yield 1
    yield 2
    yield 3

  for i in gen():
    # prints 1, 2, 3
    print(i)


- Can also use generator comprehensions

.. code-block:: python
  
  gen = (i for i in range(10) if i%2)

  for i in gen:
    # prints 1, 3, 5, 7, 9
    print(gen)

Pass Statement
--------------

You can use the ``pass`` keyword for avoiding errors on code you have not yet written

.. code-block:: python

  def my_function():
    # TODO
    pass

Calling C Functions from Python
-------------------------------

You can use the python ``ctypes`` module to convert data types between C and python

To call C from python, you have to load the shared library into python:

.. code-block:: python

  import ctypes

  # Load the shared library
  my_lib = ctypes.CDLL('./libmy_lib.so')

  # Define the function arguments and return type
  my_lib.add_numbers.argtypes = [ctypes.c_uint32, ctypes.c_uint32]
  my_lib.add_numbers.restype = ctypes.c_uint32

  # Call the function
  result = my_lib.add_numbers(15, 67)
  print("Result:", result)

You also have to define the python representations of the c types for the
arguments and return value, which can be done using ``ctypes``

Working with Paths
------------------

When working with paths, it is neat to use ``pathlib``

.. code-block:: python

  from pathlib import Path

  my_file = Path('<path_to_file>')

You can do a lot of useful things once your file is in a Path object:

- Get current working directory (the dir the python script is called from): :python:`my_file = Path.cwd()`
- Join paths: :python:`my_file.joinpath('<another path>')`
- chmod: :python:`my_file.chmod(self.my_file.stat().st_mode | 0o111)` -> equivilent to ``chmod +x``
- Exists: :python:`my_file.exists()`
- Get filepath of current python module: :python:`Path(__file__)`
- Get directory path of current python module: :python:`Path(__file__).parent`

Pickle - Saving objects to files
--------------------------------

You can dump an object's value to a file so it can be stored in non-volatile memory.
Maybe you want to save some things but don't have enough RAM to store everything at once

Objects need to be written in a binary format:

.. code-block:: python
  :caption: Example storing an object to memory and retreiving it

  import pickle

  my_var: list[int] = [0,1,2,2,3,3,3,4,4,4,4,5,5]

  # notice write-binary
  with open("my_python_vars.file", "wb") as f:
      pickle.dump(my_var, f, pickle.HIGHEST_PROTOCOL)

  del my_var

  # notice read-binary
  with open("my_python_vars.file", "rb") as f:

      my_other_var = pickle.load(f)

      print(f'my_other_var is {my_other_var}')

Environment variables
---------------------

You can use environment variables inside your python script.
This allows you to access variables which you might want to keep out of your
source code for example.

.. code-block:: python

  import os

  # os.environ returns a dictionary of your environment variables
  user_name = os.environ.get('MY_USER_NAME')
  password = os.environ.get('MY_PASSWORD')

Named Tuple
-----------

A named tuple allows you to use a tuple but read the elements in that tuple by name.

.. code-block:: python
  :caption: Example using named tuple

  from collections import namedtuple

  Color = namedtuple('Color', ['red', 'green', 'blue'])

  my_color = Color(red=55, green=143, blue=78)

  print(my_color.red)

.. note::
  Remember tuples are immutable so you can't write to these elements

Python Packages
---------------

A python module is simply a single ``.py`` file.
They can be imported with the ``import`` statement.

A package is a set of python modules with related functionality. These modules are 
organised in a directory hierachry. It organises modules in a single namespace.

Packages can be imported with a package manager like ``pip``.
Each package must also contain a ``__init__.py`` file.

Using a python package has an advantage in the python will add that directory to the
PATH search so it is easier to specify imports etc.

You can also declare package wide constants/vairables in the ``__init__.py`` file.

Making a package
^^^^^^^^^^^^^^^^

A more recent way to package a project is to use a ``pyproject.toml`` file.
You will want your directory structure to look something like this:

.. code-block::
  :caption: Example folder structure

  .
  ├── <package_name>
  │   ├── __init__.py
  │   ├── libraries
  │   │   └── library_one.py
  │   ├── module_one.py
  │   └── module_two.py
  └── pyproject.toml


In your pyproject.toml you'll want something like this:

.. code-block:: toml
  :caption: Example pyproject.toml using setup tools

  [build-system]
  requires = ["setuptools", "setuptools-scm"]
  build-backend = "setuptools.build_meta"

  [project]
  name = " <package name> "
  version = " <package version> "
  description = " <description> "
  license = { text = "CLOSED" }

.. code-block:: toml
  :caption: Example using poetry

  [tool.poetry]
  name = " <package name> "
  version = " <package version> "
  description = " <description> "
  license = "CLOSED"
  authors = [" <authors> "]
  readme = "README.md"
  packages = [
      { include = "<path_to_package>"}
  ]

  [tool.poetry.dependencies]
  python = ">=3.8"
  pydantic = "==2.6.3"
  PyYAML = "==6.0.1"

  [build-system]
  requires = ["poetry-core"]
  build-backend = "poetry.core.masonry.api"


Inside your ``__init__.py`` file, you'll want to include the types that you want immediately accessable in
your package. This basically runs when you first import your package into your current project.

.. code-block:: python
  :caption: Example __init__.py

  from .module_one import ObjectOne
  from .module_two import ObjectTwo

.. code-block:: python
  :caption: Example module

  from .libraries.library_one import ObjectLib

  class ObjectOne:
    ...

Once you have setup your project, you can run ``python -m pip install .`` in the same dir as your 
``pyproject.toml`` file. It seems this is a better result than ``pip install .``. It might also be
smart to do this in your project's virtual environment. You can also use the ``-e`` flag to keep the
package editable so you can use it and edit it at the same time.

Multithreading
--------------

Python has a global interpreter lock (GIL), which means that it is all run in one thread. This is one
of the reasons it is slow since it can only make use of one thread.

Mutlithreading in python allows to create mutliple threads. These threads still run on the same
interpreter and the GIL still applies. However, using mutlithreading allows the interpreter to better
manage execution time.

For example, if one thread is waiting for an IO operation to complete or is sleeping, then it makes sense
for the interpreter to do other tasks while this is happening.

Mutliprocessing in python is different and this is where a new interpreter and memory space is spawned for
each new process you make.

.. code-block:: python
  :caption: Example of a multi-threaded program

  import threading
  import time

  def func_1():
      for _ in range(10):
          print("Hello")
          time.sleep(1)

  def func_2():
      for _ in range(10):
          print("World")
          time.sleep(1) 

  t1 = threading.Thread(target=func_1)
  t2 = threading.Thread(target=func_2)

  t1.start()
  t2.start()

  # join pauses execution here until the specified thread is complete
  t1.join()
  t2.join()

  print("Finish")

.. warning::
  If an exception is raised in a thread, it is not propogated back to the main thread, so you
  need to consider how to deal with exceptions happening inside a thread you have spawned.

Obviously, mutliple threads accessing the same resource at a time could cause issues.
Threading provides a mutex lock to allow resources to be used only by one thread at a time

.. code-block:: python
  :caption: Example using mutex lock

  import threading

  lock = threading.Lock()

  # wait for lock to be availble and aquire it
  lock.aquire()

  # ... shared resource code goes here

  # allow the resource to be used by other threads
  lock.release()

  # you can also make this easier by using the with statement
  with lock:
    # ... shared resource code goes here

  # automatically released

Decorators
----------

Decorators change the behaviour of a function without changing the function itself.

Decorators utilise a few concepts:

1. A function is an object in python, therefore it can be assigned to a variable.
2. A function can be nested within another function.
3. A function can be passed as an argument to another function.

Decorate functions
^^^^^^^^^^^^^^^^^^

.. code-block:: python
  :caption: Example using a custom decorator function

  def my_decorator(func):

    def wrapper(*args, *kwargs):
      # Do something before the function
      func(*args, *kwargs)
      # Do something after the function

    return wrapper

  
  @my_decorator
  def my_func(my_arg):

    print(f"{my_arg=}")

The above example shows the use of a custom decorator, which is able to pass on the
given arguments.

.. note::
  ``*args`` refers to an unlimited number of arguments such as ``10``, ``True`` or ``'hello'``.
  ``*kwargs`` refers to an unlimited number of keyword arguments such as ``number=10``, ``success=True`` or ``my_string='hello'``.

.. warning::
  Decorators hide the function they are decorating, so if you want to get the correct features sich as ``__name``
  you can use :python:`from functools import wraps` and decorate your wrapper function with :python:`@wraps(func)`
  where ``func`` is the function you are wrapping.

Decorate classes
^^^^^^^^^^^^^^^^

It is also possible use classes to decorate a function too.

.. code-block:: python
  :caption: Example using a Class decorator. `Source <https://www.freecodecamp.org/news/python-decorators-explained-with-examples/>`_

  class LimitQuery:

    def __init__(self, func):
        self.func = func
        self.count = 0

    def __call__(self, *args, **kwargs):
        self.limit = args[0]
        if self.count < self.limit:
            self.count += 1
            return self.func(*args, **kwargs)
        else:
            print(f'No queries left. All {self.count} queries used.')
            return

  @LimitQuery
  def get_coin_price(limit):
      '''View the Bitcoin Price Index (BPI)'''
      
      url = requests.get('https://api.coindesk.com/v1/bpi/currentprice.json')

      if url.status_code == 200:
          text = url.json()
          return f"${float(text['bpi']['USD']['rate_float']):.2f}"

  print(get_coin_price(5))
  print(get_coin_price(5))
  print(get_coin_price(5))
  print(get_coin_price(5))
  print(get_coin_price(5))
  print(get_coin_price(5))

.. code-block::
  :caption: Output

  $35968.25
  $35896.55
  $34368.14
  $35962.27
  $34058.26
  No queries left. All 5 queries used.

In the example you see using the ``__call__`` method when the function is called and the class created.

Context Managers
----------------

Context managers let you use an object within a ``with`` statement.
When it is in a ``with`` statement, it will call the ``__enter__`` method. At the end it will call
the ``__exit__`` method.

.. code-block:: python
  :caption: Example using context manager

  class MyClass:

    # called when object is created
    def __init__(self):
      pass

    # called when used in context manager
    def __enter__(self):
      pass

    # called when used in context manager
    def __exit__(self):
      pass

    # called when object is destroyed
    def __del__(self):
      pass

    def func(self):
      print("Hello")

  # __init__
  with MyClass() as myobject:
    # __enter__
    myobject.func()
    # __exit__
  # __del__

  # __init__
  myobject = MyClass()

  with myobject:
    # __enter__
    myobject.func()
    # __exit__

  # myobject still exists here (not out of scope)

You can also using a package like ``contextlib`` to create a context manager:

.. code-block:: python
  :caption: Example using contextlib

  import contextlib

  @contextlib.contextmanager
  def switch_logging(self, test_name: str):
      self._switch_to_test_logging(test_name=test_name)
      yield
      self._switch_back_logging()

Exception Handling
^^^^^^^^^^^^^^^^^^

You can handle exceptions that occur within the context in the ``__exit__`` method.
Information about the exception will be passed to the method. If it returns ``True``, then
the exception is considered handled and is not propogated further. If ``__exit__`` returns ``False``,
then the exception is propogated outside the context block.

Virtual Environment
-------------------

Python has a way to separate your environments for different projects. This is handy
if you want to install different packages only for a certain project for example.

To start a virtual environment, call ``python3 -m venv <path to venv (.venv)>``
To activate the virtual environment, call ``source .venv/bin/activate``
Activating will add a keyword ``deactivate``, which you can use to leave the environment.

Inside the environment you can do ``pip install`` to install packages to your local environment.

Pydantic
--------

Pydantic is a python module which can be used for input validation.
This section will look a bit into using pydantic with yaml/json file inputs.

Schemas
^^^^^^^

One cool thing pydantic can do is create schemas. This is basically a description of what a yaml
or json config file should contain. Pydantic uses this schema to validate an input from a yaml or 
json file. It can also output a schema file which you can use for type completion and error checking
on a yaml or json file.

.. code-block:: python
  :caption: Example generating schema

  import pydantic
  from pydantic.dataclasses import dataclass
  import json

  @dataclass
  class Person:
    name: str
    # age must be an int and less than 99
    age: int = pydantic.Field(lt=99) 

  schema = pydantic.TypeAdapter(Person)

  json_schema_file = Path().cwd().joinpath("schema.json")
  with open(json_schema_file, "w") as file:
    json.dump(schema.json_schema(), file)

The above example will generate a schema file.

Vscode can check yaml files against this schema and also provide tab completion.
For example, if you input an int for the ``name`` it will be shown as an error. If you
put in an ``age`` above 99, it will show an error.

The schema can be applied in Vscode to yaml files by installing the yaml extension, then going
to ``Prefernce > Settings``. Here you can modify the ``settings.json`` file (either for the User or
the workspace) with something like this:

.. code-block:: json
  :caption: Example for applying a schema to all yaml files called ``my_configs.yml``

  "yaml.schemas": {
    "./schemas/my_schema.json": "my_configs.yml"
  },

Validation
^^^^^^^^^^

Validation can be performed in a few ways:

.. code-block:: python
  :caption: Two examples of validation 

  import pydantic
  from pydantic.dataclasses import dataclass
  from enum import Enum

  class Names(Enum):
    SAM = "sam"
    BOB = "bob"

  @dataclass(frozen=True)
  class Person:
    name: Names
    age: int = pydantic.Field(lt=50)

    @pydantic.field_validator("age")
    def validate_age(age):
      if age < 0 or age > 99:
        raise ValueError("Age must be between 0 and 99")
      return age

Here we see an example where ``name`` is contrained to either ``same`` or ``bob``.
For the age field, two checks will be performed. The ``pydantic.field_validator`` will
perform a check when the config is loaded into the python object. This particular check
checks for the age being between 0 and 99. The second check method used is the ``pydantic.Field``
option. Here we specified that the age should be less than 50. This check is included when
a schema file is produced, but not the check in the ``field_validator``.

Type Management
^^^^^^^^^^^^^^^

Pydantic already supports a number of types natively.
For example, ``ipaddress.IPv4Address`` is supported and ``Enum`` types.

For more complex types, e.g. 3rd party for example, some extra steps have to be performed for
successful schema production and parsing.

Here we have an example using ``semver.Version``

.. code-block:: python
  :caption: Example using ``semver.Verison``

  import pydantic
  from pydantic.dataclasses import dataclass
  import semver
  import yaml
  from pathlib import Path
  import json
  from typing_extensions import Annotated

  @dataclass
  # These are the fields that will appear in the JSON schema
  class SchemaVersion:
    major: int
    minor: int
    patch: int

  # This will do the mapping from schema to semver.Version
  HandleAsVersion = pydantic.GetPydanticSchema(lambda _s, h: h(SchemaVersion))

  @dataclass(frozen=True)
  class Config:
    name: str
    version: Annotated[semver.Version, HandleAsVersion]

    @pydantic.field_validator("version")
    def validate_version(version: SchemaVersion):
      return semver.Version(version.major, version.minor, version.patch)

  schema = pydantic.TypeAdapter(Config)

  config_file = Path("config.yaml")
  with open(config_file) as file:
    yaml_data = yaml.safe_load(file)

  json_string = json.dumps(yaml_data)
  schema.validate_json(json_string)

  config = Config(**yaml_data)

  print(config.version)
  print(type(config.version))

In the generated ``schema.json``, a field for major, minor and patch will be required.
However, when the config file is loaded into python, these fields will be converted to
a ``semver.Version`` type, and stored as such.

The annotation on the ``version`` field has two jobs:
1. It means intellisense will see ``version`` as a ``semver.Version`` so you can tab complete with it.
2. It will make the schema produced use the ``SchemaVersion``, so you have a way to produce the third
party type that yaml will allow.

Another thing pydantic does is to use Enum value in the schema instead of names. This can be annoying
if you are for example using IntEnum, since you would have to use numbers which loses human readablility.

.. code-block:: python
  :caption: Example using enum values

  def HandleAsNames(handled_type: Enum):
    # Define a function to dynamically create an Enum
    def create_enum(enum_name, enum_members):
        return Enum(
            enum_name,
            {
                member_name: member_value.name
                for member_name, member_value in enum_members.items()
            },
        )

    # This basically creates a new Enum type for pydantic to use when it is generating its schema.
    # This new enum will use the names of the original enum as its values, so the user can select
    # options based on the original enum's names. (pydantic only allows selecting enums based on value).
    return pydantic.GetPydanticSchema(
        lambda _s, h: h(
            create_enum("SchemaType" + handled_type.__name__, handled_type.__members__)
        )
    )

  @pydantic.dataclasses.dataclass
  class LoggerConfig:
      level: Annotated[LogLevel, HandleAsNames(handled_type=LogLevel)] = LogLevel.WARNING

      @pydantic.field_validator("level")
      def validate_level(level: Enum) -> LogLevel:  # type: ignore
          return LogLevel[level.value]

----

dis - Disassembler
------------------

The ``dis`` module allows you to view the compiled byte code for CPython. This can be useful for a
number of things, including maybe evaluating the performance of your code.

You can use the ``dis`` module both in your python script and as a command line tool.

.. code-block::
  :caption: Example of using ``dis`` from the command line

  python -m dis <python_file>

.. code-block:: python
  :caption: Example disassembling a function in a script

  dis.dis(myfunc)

----

Argument Parsing with ``argparse``
----------------------------------

You can use the ``argparse`` package to manage passing arguments to your python script.

.. code-block:: python
  :caption: Example using argparse

  import argparse

  parser = argparse.ArgumentParser()
  parser.add_argument(
      "--age",
      type=int,
      help="The age of the person.",
      required=True
  )
  parser.add_argument(
      "--name",
      type=str,
      help="The name of the person",
      required=False,
      default="Bob",
  )

  # example of passing a flag
  parser.add_argument( 
    "--european",
    action="store_true",
    help="Flag if set indicates the person is European.",
  )
  args = parser.parse_args()

  age: int = args.age
  name: str = args.name
  is_european: bool = args.european

With this, if you run ``python <you_script> --help``, ``argparse`` will show you the command line
argument options specified in your script.

----

http Server and Client
----------------------

Client
^^^^^^

You can use the python ``requests`` package to make http requests to a server.

.. code-block:: python
  :caption: Example making a GET request

  import requests

  # Server is at IP address 10.0.0.20 and we are using port 4000
  SERVER_BASE_URL = "http://10.0.0.20:4000/people"

  def get_people_info() -> requests.Response:
      url = f"{SERVER_BASE_URL}"
      return requests.get(url=url)

It is also possible to use web endpoints:

.. code-block:: python
  :caption: Example accessing Github API

  GITHUB_API_VERSION = "2022-11-28"

  ORG_RUNNERS_BASE_URL = "https://api.github.com/orgs/<org_name>/actions/runners"

  def _construct_api_headers(org_access_token: str) -> dict:
      return {
          "Accept": "application/vnd.github+json",
          "Authorization": f"Bearer {org_access_token}",
          "X-GitHub-Api-Version": GITHUB_API_VERSION,
      }

  def set_custom_labels_for_runner(
          org_access_token: str, runner_id: int, labels: list[str]
  ) -> requests.Response:
      url = f"{ORG_RUNNERS_BASE_URL}/{runner_id}/labels"
      headers = _construct_api_headers(org_access_token)
      data = {"labels": labels}

      return requests.post(url, headers=headers, json=data)

  def get_organizational_runners_info(
          org_access_token: str,
          query_per_page: int,
          query_page: int
      ) -> requests.Response:
      headers = _construct_api_headers(org_access_token)
      params = {
          "per_page": query_per_page,
          "page": query_page,
      }

      return requests.get(ORG_RUNNERS_BASE_URL, headers=headers, params=params)

.. note:: 
  You can use the package ``http`` to get ``HTTPStatus`` enums

Server
^^^^^^

A server application can be implemented with flask.

.. code-block:: python
  :caption: Example flask app

  from flask import Flask, request
  from flasgger import Swagger
  from http import HTTPStatus

  import custom_services

  app = Flask(__name__)
  Swagger(app)

  @app.get("/people")
  def peopl_info_get():
      return custom_services.get_people_info(), HTTPStatus.OK

  @app.get("/people/<int:person_id>/name")
  def person_name_get(person_id: int):
      try:
          return custom_services.get_person_name(person_id=person_id), HTTPStatus.OK
      except Exception as e:
          return {"error_message": f"{type(e).__name__}: {e}"}, HTTPStatus.INTERNAL_SERVER_ERROR

  @app.post("/people/<int:person_id>/name")
  def person_name_post(person_id: int):
      name = request.json["name"]
      if not isinstance(name, str):
          return {"error_message": "name not in string format"}, HTTPStatus.BAD_REQUEST

      try:
          custom_services.add_name_to_person(person_id=person_id, name=name)
          return HTTPStatus.OK.phrase, HTTPStatus.OK
      except Exception as e:
          return {"error_message": f"{type(e).__name__}: {e}"}, HTTPStatus.INTERNAL_SERVER_ERROR

  @app.delete("/people/<int:person_id>/name/<string:name>")
  def person_name_delete(person_id: int, name: str):
      try:
          custom_services.delete_name_from_person(person_id=person_id, name=name)
          return HTTPStatus.OK.phrase, HTTPStatus.OK
      except Exception as e:
          return {"error_message": f"{type(e).__name__}: {e}"}, HTTPStatus.INTERNAL_SERVER_ERROR

  if __name__ == "__main__":
      app.run(host="0.0.0.0", port=4000)

With a server implemented in a flask app, it can be run in development mode
with ``python flask_server.py``.

To run in deployed mode, one should use a dedicated WSGI server. See the flask
documentation: `Flask docs <https://flask.palletsprojects.com/en/2.3.x/deploying/>`_

Using Gunicorn
""""""""""""""

One of the WSGI servers in Gunicorn. Simply intstall with pip, and then run
your flask app.

For example: ``gunicorn -b 0.0.0.0:4000 flask_server:app``

----

match
-----

``match`` was introduced in python 3.10 and is a solution for switch type statements.

.. code-block:: python
  :caption: Example of match statement

  pytest_exit_code = 2

  match pytest_exit_code:
      case 0:
          print("All tests were collected and passed successfully")
      case 1:
          print("Tests were collected and run but some of the tests failed")
      case 2:
          print("Test execution was interrupted by the user")
          exit(1)
      case 3:
          print("Internal error happened while executing tests")
          exit(1)
      case 4:
          print("pytest command line usage error")
          exit(1)
      case 5:
          print("No tests were collected")
          exit(1)
      case _:
          print(f"Unhandled exit code: {container_command_exit_code}")
          exit(1)

----

Docker package
--------------

There is a docker python package that lets you interact with docker from python.

.. code-block:: python
  :caption: Docker package example

  import docker

  client = docker.from_env()  # type: ignore

  client.login(
      username=inputs.user, password=inputs.access_token, registry=inputs.registry
  )

  pull_stream = client.api.pull(
      repository=inputs.image_name,
      tag=inputs.image_tag,
      stream=True,
  )

  for event in pull_stream:
      print(f"{event.decode('utf-8')}", end="")

  volumes = [
      f"{inputs.path_to_artifacts}:/home/user/artifacts/",
  ]

  dtf_container: Container = client.containers.run(
      image=f"{inputs.image_name}:{inputs.image_tag}",
      detach=True,
      stderr=True,
      remove=True,
      privileged=True,
      volumes=volumes,
      command=_build_command(inputs=inputs),
  )

  log_stream = dtf_container.logs(stream=True)

  for event in log_stream:
      print(f"{event.decode('utf-8')}", end="")

  exit_status = dtf_container.wait()
  container_command_exit_code = int(exit_status["StatusCode"])

----

Generating sheilds for Github
-----------------------------

You can generate shields/badges for github and other platforms by generating an svg
file.

You can construct a URL using the base of ``"https://img.shields.io/badge"`` to generate
an svg sheild.

