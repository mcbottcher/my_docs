Rust
====

Installing Rust
---------------

On linux:

.. code-block:: shell
    :caption: Command for installing rust

    curl --proto "=https" --tlsv1.3 https://sh.rustup.rs -sSf | sh

You will also need a linker/C-compiler, which you can install with for example:

.. code-block:: shell
    :caption: Install GCC on Ubuntu

    sudo apt install build-essential

Updating rust
^^^^^^^^^^^^^

.. code-block:: shell
    :caption: Updating rust

    rustup update

----

Basic Hello World
-----------------

1. Create a file called ``main.rs``
2. Enter code:

.. code-block:: rust
    :caption: Hello World program

    fn main() {
        println!("Hello World!");
    }

3. Compile with ``rustc main.rs``
4. Run with ``./main``

----

Cargo
-----

Cargo is rust's build system and package manager.

Create a new cargo project with:

.. code-block:: shell
    :caption: Creating a new cargo project

    cargo new <project_name>

This will initialise a project, and also by default creates a new git repo (unless you are 
already in a git repo).

You will have a ``Cargo.toml`` file where you keep your project configurations and dependancies,
and a ``src`` directory where your source code should live.

Build you project with ``cargo build``. This will create a few files:

1. ``Cargo.lock``: Tracks exact versions of project dependancies
2. ``target/``: Where your executable is stored.

By default cargo builds in debug mode, so your executable will be in ``target/debug``.

You can combine both building and running with just ``cargo run``. If no files have changed,
cargo will skip the build stage and just run the executable.

``cargo check`` is another command you can use. This will simply check that your code compiles
but doesn't produce an executable. This is faster than ``cargo build`` since it can miss some steps,
so it is useful when developing to check that your code still compiles.

Release build
^^^^^^^^^^^^^

When your project is ready for release, build it with ``cargo build --release`` to compile with
optimisations. This will place the executable in ``target/release``. The compilation time will be longer,
but the executable will run faster. 

Programming Concepts
--------------------

Variables and Mutability
^^^^^^^^^^^^^^^^^^^^^^^^

By default, variable in rust are immutable (cannot be changed.)
If you have a variable ``let x = 5;`` and you try to change it with ``x = 6;``, this will not compile since
you can't change an immutable type.

To make a variable mutable, add the ``mut`` keyword before the variable declaration: ``let mut x = 5;``

Constants
^^^^^^^^^

Constants are similar to immutable variables, but they are bound to a name and always immutable (can't use mut keyword with them).
To declare a constant use the ``const`` keyword instead of the ``let`` keyword. The type of the value must also be annotated.
They can only be set with expressions at build-time, not values that are generated at run-time. They can also be declared in any scope,
including the global scope.

.. code-block:: rust
    :caption: Example of a constant

    const NUMBER_OF_SECONDS_IN_MIN: u32 = 60;
    const NUMBER_OF_MINUTES_IN_HOUR: u32 = 60;
    const NUMBER_OF_SECONDS_IN_HOUR: u32 = NUMBER_OF_MINUTES_IN_HOUR * NUMBER_OF_SECONDS_IN_MIN;

.. note::
    Constants should be given upper-case names.

Shadowing
^^^^^^^^^

It is possible to declare a new variable with the same name as an old variable. This new variable will be the one
used in the current scope.

.. code-block:: rust
    :caption: Example using variable Shadowing

    let x = 5;
    println!("The value of x is {x}");
    let x = 6;
    println!("The value of x is {x}");

    {
        let x = 7;
        println!("The value of x is {x}");
    }

    println!("The value of x is {x}");

This will end up printing:

.. code-block::

    The value of x is 5
    The value of x is 6
    The value of x is 7
    The value of x is 6

This is different from making a varibale mutable since we will get a compile time error if we 
accidentally set the value to something else without using the ``let`` keyword.

Shadowing also lets you change the type of a variable, since you are effectively creating a new variable.

.. code-block:: rust
    :caption: Changing a variable's type

    let name = "bob";
    // type is now integer
    let name = name.len();

If we try do this with a mutable type, then there will be an error since we can't change/mutate a variable's type.

.. code-block:: rust
    :caption: Example of error

    let mut x = 6;
    x = "bob";

Data Types
^^^^^^^^^^

Rust is a statically typed language. The compiler can usually infer which type something should be, but in the case
something can take many types, you have to type annotate: ``let x: u32 = "42".parse().expect("Not a number!")``

Scalar types: Represent a single value...

Integer
"""""""

Integer types can be signed or unsigned, 8 (``i8`` and ``u8``), 16, 32, 64, 128bit or arch which is the size of the
architecture you are running. arch is denoted with ``isize`` and ``usize``. Integer literals can be in several formats:

1. Decimal: ``92_010``
2. Hex: ``0xff``
3. Octal: ``0o77``
4. Binary: ``0b1110_0010``
5. Byte(u8 only): ``b'A'``

.. warning:: 
    Integer Overflow:
    If you are running rust in debug mode, if an overflow occurs the program will panic.
    Running in release mode it will not. It will wrap the value, e.g. 256 -> 0.
    You can explicitly handle overflows you can use some standard library functions:

   - ``wrapping_*`` methods
   - ``checked_*`` methods -> check if overflow occured
   - ``overflowing_*`` methods -> return a boolean
   - ``saturating_*`` methods -> saturate instead of over/under flow

floats
""""""

There are two primitive types, ``f32 f64``. ``f64`` is the default value since it is not much slower than using
the 32-bit version and it is double the size.

booleans
""""""""

Booleans (``bool``) have two options: ``true`` and ``false``. Booleans are one byte in size.

characters
""""""""""

rust's ``char`` type is 4 bytes in size. They use single quotes, as opposed to literals which use double quotes.
It represents Unicode characters (not ASCII), so it can represent emojis or chinese characters for example.

.. code-block:: rust
    :caption: Char examples

    let c = 'z';
    let cat = '🐈';

Compound Types
^^^^^^^^^^^^^^

These group mutliple values in one type.

Tuple
"""""

In a tuple you can group a number of differnt types in one compound type. Once made the size of the
tuple cannot change.

.. code-block:: rust
    :caption: Example using tuples

    let tuple: (u32, f32, char) = (500, 0.1, 'k');

    let (x, y, z) = tuple;

    let floaty = tuple.1;

    println!("The value of integer is {x}");
    println!("The value of float is {floaty}");

As seen in the example, it is possible to access a tuple's values by desructuring a tuple or by the dot
operator, using the index of the value you want.

.. note:: 
    The first index is 0 in rust.

.. note:: 
    A tuple without any values is called a ``unit``. It is denoted by ``()``, and is similar to ``None``
    in python.

Array
"""""

Unlike a tuple, every element in an array must have the same type.
Arrays in rust have fixed lengths. Because of this, array's are stored on the stack, and not the heap.

.. code-block:: rust
    :caption: Example using array

    let a = [1, 2, 3, 4, 7, 9];
    
    // Indicates a size of 5, using i32
    let b: [i32: 5] = [1, 2, 3, 4, 5];

    // Fills the array with 5 elements of value 3
    let c = [3; 5];

    // accessing array element
    let d = c[4];

If trying to access an array element which is out of range at run-time, the rust program will panic.
Rust checks the array index is in bounds before accessing the array element.
If you try access it wrong at compile time, then it will be a build time error.

Functions
^^^^^^^^^

Function use the ``fn`` keyword. Functions can be defined above or below the function you call it from,
as long as they are defined in the scope of the caller. You should also type annotate your parameters/arguments.

.. code-block:: rust
    :caption: Example using functions

    fn main() {
        my_func(4)
    }

    fn my_func(my_number: u32) {
        println!("My number is {my_number}")
    }

Statements and Expressions
^^^^^^^^^^^^^^^^^^^^^^^^^^

The basic difference: expressions evaluate to a return value, statements do something but don't return anything.

``let y = 6;`` is a statement, so does not return anything. Therefore, ``let y = (let x = 6);`` will cause an error.
In languages like C, a variable assignment will return the value of the assignment, so something like ``int a = b = 6;``
is valid, **not** in rust.

Expressions evaluate to a value. So in ``let y = 6;`` 6 is the expression.

Calling a macro, function or new scope block are all expressions.

.. code-block:: rust
    :caption: Example with scope block expression

    // scope block returns 4
    let y = {
        let x = 3;
        // note no ;
        x + 1
    }; 

    println!("Value of y is {y}");

.. note:: 
    There is no semicolon at the end of the expression. If you add a semicolon,
    this makes it a statement and no value is returned.
    If there was a semicolon, this error would show:
    `()` cannot be formatted with the default formatter - for the println macro

Function return values
^^^^^^^^^^^^^^^^^^^^^^

Return values from functions are not named, but we have to specify their type:

.. code-block:: rust
    :caption: Example return type

    fn five() -> i32 {
        5
        // also valid 
        // return 5;
        // return 5
    }

.. note:: 
    Since a function is a expression, you can "return" the result by ommitting the final
    semicolon. Alternatively specify "return"

Control Flow
^^^^^^^^^^^^

if expression
"""""""""""""

The expression in an if statement must be a boolean, otherwise we will get an error.
This doesn't even work when using a u8, the same size as a boolean.

.. code-block:: rust
    :caption: Example if statement

    let number = 5;

    if number < 6 {
        println!("True");
    } else if number < 10 {
        println!("True2");
    } else {
        println!("False");
    }

Because if is an expression, you can use it on the right side of a let statement to assign a value.

.. code-block:: rust
    :caption: Example assigning with an if statement

    let x = if true {5} else {6};

Loop
""""

The ``loop`` keyword tells rust to execute a block of code forever until you tell it to stop.
You can use the ``break`` or ``continue`` keywords to control loop execution.

.. code-block:: rust
    :caption: Example using loop

    // Loops forever
    loop{
        println!("Hello");
    }

    // breaks loop
    loop{
        println!("Hello");
        break;
    }

    // loops forever, prints nothing
    loop{
        continue;
        println!("Hello");
    }

You are also able to return values from loops:

.. code-block:: rust
    :caption: Example returning value

    let mut counter = 0;

    let result = loop {
        counter += 1;

        if counter == 10 {
            break counter * 2;
        }
    };

    println!("{result}");

It is also possible to label loops. This way you can specify if you have nested loops which one you
want to break from/continue in.

.. code-block:: rust
    :caption: Example with nested loops with names

    let mut counter = 0;
    'counting_up: loop {
        counter += 1;

        loop {
            break 'counting_up;
        }
    }
    // This only prints 1
    println!("Counter is {counter}");

While loop
""""""""""

.. code-block:: rust
    :caption: Example of a while loop

    let mut number = 5;

    while number != 0 {
        println!("{number}");
        number -= 1;
    }

for loop
""""""""

.. code-block:: rust
    :caption: Example for loops

    let a = [1, 2, 3, 4, 5];

    for element in a {
        println!("Value is {element}");
    }

    for i in (1..5){
        println!("Value is {i}");
    }

    for i in (1..5).rev(){
        println!("Value is {i}");
    }