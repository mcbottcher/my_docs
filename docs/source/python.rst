.. role:: python(code)
    :language: python

Python
======

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