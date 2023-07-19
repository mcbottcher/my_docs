.. role:: bash(code)
   :language: bash


.. role:: python(code)
    :language: python

PyTest
======

PyTest is a testing framework based on Python.

Some features/advantages:

- Can run multiple tests in parallel
- Allows you to skip/run a subset of tests from the testsuite
- Free and opensource!

Running PyTest without specifying filenames will run all files of format ``test_*.py`` or ``*_test.py``
in the current directory or subdirectories.

PyTest test function names must start with ``test`` or ``test_``.

----

Basic Test Example
------------------

.. code-block:: python

    import math

    def test_sqrt():
      num = 25
      assert math.sqrt(num) == 5

    def testsquare():
      num = 7
      assert 7*7 == 40

    # Note: this won't run since it doesn't start with "test"
    def tesequality():
      assert 10 == 11

Run ``pytest`` in the same directory level.

----

Test Subsets
------------

We don't always want to specify all the tests to run/don't want all tests to run automatically.

Can run a subset of tests in two ways:

1. String matching of test name: 
   :bash:`pytest -k great -v` will only run tests with 'great' in their name

2. Test Markers:
   :python:`@pytest.mark.<markername>`
   :bash:`pytest -m <markername> -v` 

----

Test Classes
------------

You can specify a class to group tests. This also allows you share parameters between
tests, like ``value`` in the example.

.. code-block:: python

  # content of test_class_demo.py
  class TestClassDemoInstance:
      value = 0

      def test_one(self):
          self.value = 1
          assert self.value == 1

      def test_two(self):
          assert self.value == 1

Grouping in classes also allows you to apply class level fixtures and marks and
these will be implicitly added to all tests in that class.

----

Fixtures
--------

Fixtures are functions which run before each test function to which it is applied.
They can be used to feed data to a test function.

The scope is limited to the file you have created it in by default. However, if it is included
in your *conftest.py* file, you can change the scope.

You can set the scope of a fixture to ``session, module, function, class, package`` by using :python:`@pytest.fixture(scope='session')`

You can also set :python:`autouse=True` if you want it enabled for all test functions in the scope.

.. code-block:: python

  import pytest

  @pytest.fixture
  def input_value():
    input = 39
    return input

  def test_divisible_by_3(input_value):
    assert input_value % 3 == 0

  def test_divisible_by_6(input_value):
    assert input_value % 6 == 0

Instead of passing the fixture as an argument, you can also use the :python:`@pytest.mark.usefixtures('<ficture_name>')`
decorator to use the fixture in a test function.

.. note::
  You can view a list of builtin fixtures by using ``pytest --fixtures``. These are ones
  you don't have to specify but can just use the name of the fixture e.g. ``tmp_path`` 


Using fixtures for setup and teardown
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

You can use fixtures for setup and teardown functions for tests.
Using it as a setup is useful since you can pass in data to your test function.
Using the teardown fixture is useful, since on an assert inside your test function, the remaining
functionality won't be run, meaning if you have teardown logic inside the test, it won't be run on
an ``assert``.

.. code-block:: python
  :caption: Example using fixtures for setup and teardown

  @pytest.fixture(scope="function")
  def test_setup():
      print("Test Specific Setup")
      test_data = 5
      return test_data

  @pytest.fixture(scope="function")
  def test_teardown():
      yield
      print("Test Specific Teardown")

  # test_teardown doesn't provide a value so can be declared like this
  @pytest.usefixtures('test_teardown')
  def test_example(test_setup):
    assert test_setup == 3
    

It is also possible to chain fixtures:

.. code-block:: python
  :caption: Example chaining fixtures

  @pytest.fixture(scope="function")
  def test_setup():
      print("Test Specific Setup")
      test_data = 5
      return test_data

  @pytest.fixture(scope="function")
  def test_teardown(test_setup):
      yield test_setup
      print("Test Specific Teardown")

  def test_example(test_teardown):
    assert test_teardown == 3  

In this example, the setup will run first, then the teardown yields to the test.
Once the test is complete, due to the ``yield`` statement, the rest of the teardown
is run.

----

conftest.py
-----------

Can use the file ``conftest.py`` to share configurations across test files, e.g. fixtures.

.. code-block:: python

  import pytest

  @pytest.fixture
  def input_value():
    input = 39
    return input

Now this ``input_value`` can be used across all test files.

----

Running Tests in Parallel
-------------------------

To run tests in parallel, you need the ``pytest-xdist`` plugin.

:bash:`pip install pytest-xdist`

Now you can specify how many workers you want to use to run the tests in parallel:

:bash:`pytest -n <number_of_workers>`

----

Markers
-------

- Set a test group that can run as a subset: :python:`@pytest.mark.<markername>`

  You can register your custom marks in the ``pytest.ini`` file. Unregistered marks will trigger a warning.
  This warning can be raised to an error by passing the ``strict-markers`` argument. This avoids accidental
  mark name errors. Or add something like this to your pytest.ini

  .. code-block:: python

    [pytest]
    addopts = --strict-markers

.. note::
  You can also use the other marker names specified here to run a subset too e.g. ``xfail``

- Set a set of inputs to test for a function:

.. code-block:: python

  import pytest

  @pytest.mark.paramterize("num, ouput", [(1,11),(2,22),(3,35)])
  def test_multiplication_11(num, output):
    assert 11*num == output

- Execute a test, but don't consider its result: :python:`@pytest.mark.xfail`
- Don't execute a test: :python:`@pytest.mark.skip`

.. note::
  You can view a list of markers by using ``pytest --markers``

----

Test Execution Results
----------------------

The results from the test execution can be written to an XML file. This can be
used in a dashboard that displays test results.

:bash:`pytest test_multiplication.py -v --junitxml="results.xml"`

----

PyTest Hooks
------------

Hooks are part of PyTest's plugin system which allows you to extend the functionality of PyTest
Hooks allows you to run custom code at different stages of a pytest run.

The stage at which the code is run is defined by the name of the hook you use. These are predefined
names which point to a different stage in the pytest process.

To define a hook, create a function and decorate it with :python:`@pytest.hookimpl`.

.. note::
  It doesn't seem hooks can be declared in the test file, but work in the *conftest.py* file.

There are some main categories of hooks:

- Bootstrapping hooks

  - Called at the very beginning and end of a test run.
  - Good for setup and teardown of resources used by all tests

- Initialisation hooks

  - Called at beginning of a test run, after bootstrapping hooks.
  - Used to initialise resources before the test run

- Collection hooks

  - Called during the process of collecting the tests that will be run in the test suite
  - Can sutomise the way that tests are collected and add additional tests to the collection

- Test running (runtest) hooks

  - Customise the way tests are run and perform actions before and after a test is run

  .. code-block:: python
    :caption: Example in conftest.py

    import pytest

    @pytest.hookimpl
    def pytest_runtest_setup(item):
        print("Setting up test:", item.name)
        # Perform setup tasks here

- Reporting hooks

  - Called throughout the test process
  - Customise the way results are reported
  - Allows you perform actions based on test results

- Debugging/Interaction Hooks

  - Allows us to interact with the test session or debug issues that might arise

You can find a list of available hooks `Here <https://docs.pytest.org/en/7.1.x/reference/reference.html#hooks>`_.
These are the names you should use to target a specific part of the PyTest process.

.. note::
  Hooks should start with ``pytest_*`` otherwise it won't be recognised as a hook. 


.. code-block:: python
  :caption: Example modifing list of tests to be run after they have been collected

  @pytest.hookimpl
  def pytest_collection_modifyitems(config, items):
    # modify the collected items after they have been collected...
    items.append(items[0])

You can also make a function a *hookwrapper* so that it will wrap another hook function. In the example,
the hookwrapper function is called first. The ``yield`` statement yields to the wrapped hook function. When
that finishes, execution returns to the hookwrapper to complete:

.. code-block:: python

  @pytest.hookimpl(hookwrapper=True)
  def pytest_collection_modifyitems(config, items):
    print('Entering the collection_modifyitems hook')
    yield
    print('Finished the collection_modifyitems hook')

----

Options
-------

- ``-v``: make the output more versbose
- ``-k <substring>``: run a subset of tests based on given substring
- ``-m <markername>``: only run tests with given marker
- ``--maxfail <max_number_of_fails>``: Number of fails after which to halt test execution
- ``-n <num_of_workers>``: How many parallel workers will run the tests
- ``--junittxml=<path_to_file>``: Outputs test results to XML
- ``-s``: This will show :python:`print()` from test functions in the console 

----

Running multiple instances of pytest on the same code
-----------------------------------------------------

There might be a situation where you want to run multiple configs for pytest
on the same repo.

To avoid using the same config, use a *pytest.ini* file to root the pytest instance you are calling.

This can cause an issue with your code trying to find some libraries in higher directory levels.
One thing that might help, is to run ``python -m pytest ...`` instead of ``pytest`` directly. They
are mostly the same except the first one adds more paths than just ``pytest`` by itself.

Sources
-------

- https://www.tutorialspoint.com/pytest