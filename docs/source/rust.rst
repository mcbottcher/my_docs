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

Guessing Game Example - Misc.
-----------------------------

- Rust by default has a set of items defined in the standard library that it brings into the
  program scope. This is known as the **prelude**.

  If something you want to use is not in the prelude, you must bring it into scope manually
  with the ``use`` statement. e.g. ``use std::io;``

- When printing with ``println!``, you can print the variable directly with ``{<var>}`` or you can
  print the result of evaluating an expression like this: ``println!("Your value is {}", x + 1);``

- Getting a random number:
  Rust doesn't have a random number generator in its std library, so we need to import a crate.
  *https://crates.io/crates/rand*

  The project we are building (with the executable) is known as a *binary crate*, and the random
  crate we are pulling in is known as a *library crate*.

  To include the crate, add ``rand = "0.8.5"`` to the ``[dependencies]`` section of the ``Cargo.toml``

.. code-block:: rust
    :caption: Getting a random number

    use rand::Rng;

    fn main {
        let secret_number = rand::thread_rng().gen_range(1..=100);
        println!("Secret number is {secret_number}");
    }

- Documentation: running ``cargo doc --open`` will compile documentation for the crates you are using
  and open them in a browser for you to see!

.. code-block:: rust
    :caption: Guessing Game

    use std::io;
    use std::cmp::Ordering;
    use rand::Rng;

    fn main() {
        
        let secret_number = rand::thread_rng().gen_range(1..=100);
        println!("Secret number is {secret_number}");

        loop {
            println!("Guess a number please:");

            let mut guess: String = String::new();

            io::stdin()
                .read_line(&mut guess)
                .expect("Failed to read line");

            let guess: u32 = match guess.trim().parse() {
                Ok(num) => num,
                Err(_) => continue,
            };

            println!("You guessed {}", guess);

            match guess.cmp(&secret_number){
                Ordering::Less => println!("Too small"),
                Ordering::Greater => println!("Too big"),
                Ordering::Equal => {
                    println!("Just right");
                    break;
                }
            }
        }
    }

Ownership
---------

*Basic Rules*:
1. Each value in rust has an owner
2. There can only be one owner at a time
3. When the owner goes out of scope, the value will be dropped

How does rust manage memory allocation?

For literals like a string literal ``"hello"``, this is stored on the stack and when the variable assigned
to that value goes out of scope, the data is popped from the stack.

For types which are of variable size, e.g. ``String``, these have a pointer on the stack which points to
allocated memory on the heap. When the variable assigned to the ``String`` goes out of scope, rust calls the
``drop`` function to free the heap memory.

Move
^^^^

If you allocate a new variable to a variable which has a heap component, the new variable will simply be a
pointer (and length and capacity) on the stack to the same memory in the heap.

Now we have two variables pointing to the same memory, they both can't be freed using ``drop`` since this would
be a double free. To prevent this, if you assign a variable to another in this way, the first variable will become
invalid.

.. code-block:: rust
    :caption: Example of invalid variable

    let s1 = String::from("hello");
    let s2 = s1;

    // This won't work since s1 is no longer valid
    println!("Value of string 1 is {s1}");

This type of assignment is known as a ``move``, where the pointer, length and capacity are copied to the new variable,
and the old variable being made invalid.

.. note:: 
    This is not true when assigning a variable of a fixed size to each other. e.g. ``let y: u32 = x;`` is fine
    since this doesn't use any heap memory. Therefore ``x`` will still be valid after this assignment.
    Variable types like these implement something called the ``Copy`` trait.

Clone
^^^^^

If we want to make a copy of the heap data too (similar to deep copy), we can use the ``clone`` method.
This will make a copy of the pointer, lenght and capacity on the stack, and allocate new memory on the heap
and copy the contents of the first variable's heap data. The pointer of the new variable will point to this new
heap data.

.. code-block:: rust
    :caption: Example using clone

    let s1 = String::from("hello");
    let s2 = s1.clone();

    // s1 is valid since it was not made invalid by a move
    println!("Value of string 1 is {s1}");

Function Calls
^^^^^^^^^^^^^^

.. code-block:: rust
    :caption: Example of functions and variable scope

    fn main() {
        let s1 = String::from("hello");

        print_string(s1);

        let x = 5;

        print_int(x);

        // This is ok
        print_int(x);

        // s1 no longer exists, so compile error
        print_string(s1);

    }

    fn print_int(value: i32) {
        println!("The value of the int is {value}");
    } // since x is copied in, x is still valid after this, value is not

    fn print_string(s1: String) {
        println!("The value of s1 is {s1}");
    } // s1 is dropped here

As you can see from the example, different types behave differently when passed to functions.

Return values from functions can also tranfer ownership:

.. code-block:: rust
    :caption: Example of returns tranferring ownership

    fn main() {
        let s1 = get_string();
        let s2 = String::from("world");

        let s3 = mirror(s2);

        // Here s1 and s3 are valid, s2 is not
        println!("Values are {s1} {s2} {s3}");
    }

    fn mirror(my_string: String) -> String {
        my_string
    } // s2 is moved to my_string so is not valid anymore

    fn get_string() -> String {
        let some_string = String::from("hello");
        some_string
    } // some_string is moved to s1, so some_string no longer valid

References and Borrowing
^^^^^^^^^^^^^^^^^^^^^^^^

If we don't want a function to take ownership of a variable we can use the concepts of references and borrowing.

A reference is a pointer to a varaible but it does not have ownership of the variable. Therefore, when it
goes out of scope, the original variable is not dropped:

.. code-block:: rust
    :caption: Example using reference

    fn main() {

        let s2 = String::from("world");

        let s3 = mirror(&s2);

        // Values are World World
        // It seems println! can print &String too...
        println!("Values are {s2} {s3}");

    }

    fn mirror(my_string: &String) -> &String {
        my_string
    } // s2 is moved to my_string so is not valid anymore

Using references in functions is known as borrowing. The function is borrowing the variable, so it can use
it, but it does not own it. Like with borrowing the thing should be returned to the owner when finished.

References, by default, are immutable, which means you cannot change the value of the borrowed variable.

We can indicate that a borrowing function will mutate a variable by specifying a mutable reference.

.. code-block:: rust
    :caption: Example of a mutable reference

    fn main() {

        let mut s2 = 5;

        mut_value(&mut s2);

        // value is 6
        println!("Values are {s2}");

    }

    fn mut_value(value: &mut i32) -> () {
        *value = 6;
    }

You are not allowed to have more than one mutable reference to value at any one time!
This prevents data races.
In a similar fashion, we cannot have a mutable reference in existance when a immutable one
exists. The user of an immuatable value should not have it change on them.

.. note:: 
    A variable is considered out of scope after its last use, so it is possible in the same
    scope to declare a ``&mut`` after a immuatable reference if it is after the last use of the
    immutable reference.

The Slice Type
^^^^^^^^^^^^^^

Slices let you reference a contiguous sequence of elements in a collection.
It is only a reference, so does not have ownership.

.. code-block:: rust
    :caption: Example string Slice

    let s = String::from("Hello World");

    // Starts at the 6th element, and includes upto the 11th
    let world_slice = &s[6..11];

.. note:: 
    In rust's slice syntax, ``&s[0..2]`` and ``&s[..2]`` are equivilent.
    Also if you want to include everything upto the last element, use something
    like ``&s[2..]``.
    Referencing all elements can be done like so ``&s[..]``

.. note:: 
    String literals are simply string slices. The value of the string is stored
    in the compiled binary, so is immutable.

The type of a string slice is ``&str``. This means you can also use a reference to an
entire string with the same type.

Slices also work for other types, for example arrays.

.. code-block:: rust
    :caption: Example of Array Slice Operation

    let a = [1, 2, 3, 4, 5];

    let slice = &a[1..3];

    assert_eq!(slice, &[2, 3]);

Structures
----------

Structures are a way of organising data types. They differ from tuples because
you can name each element instead of relying on the order of elements like with a
tuple.

.. code-block:: rust
    :caption: Example using a Struct

    struct User {
        active: bool,
        username: String,
        sign_in_count: u65,
    }

    let mut user1 = User {
        active: true,
        username: String::from("myusername"),
        sign_in_count: 0,
    };

    // access elements with dot notation
    user1.active = false;

.. note::
    To change an element in the struct, the whole struct needs to be mutable.
    Rust doesn't support different mutability for different fields.

.. note:: 
    We can use field initialisation shorthand. Instead of writing something like:
    ``active:active,`` in the struct initialisation with an input variable called
    ``active``, simply just write ``active``

Struct update syntax
^^^^^^^^^^^^^^^^^^^^

If we are copying over values from one struct to another, and only changing a few elements,
we can use the struct update syntax to fill the rest of the struct with the given struct's
values.

.. code-block:: rust
    :caption: Example using struct syntax update

    let user2 = User {
        active: false,
        // rest of the values copied from user 1
        ..user1
    };

.. note:: 
    If ``user2`` copies any values from ``user1`` that don't implement the ``Copy``
    trait (e.g. String), ``user1`` will become invalid.

Tuple Structs
^^^^^^^^^^^^^

A tuple sturct is where you name the tuple type, and give the types of the fields,
however, you don't name the fields.

.. code-block:: rust
    :caption: Example of tuple struct

    struct Color(i32, i32, i32);
    struct Point(i32, i32, i32);

    let black = Color(0, 0, 0);

    // access by index
    println!("Red component of Black is {}", black.0);

Example - Area of a rectangle
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: rust
    :caption: Simple example using rectangle struct

    struct Rectangle {
        width: u32,
        height: u32,
    }

    fn main() {

        let my_rect = Rectangle {
            width: 4,
            height: 8,
        };

        println!("Area of rectangle is {}", get_area(&my_rect));

    }

    fn get_area(rectangle: &Rectangle) -> u32 {
        rectangle.width * rectangle.height
    }

Print trait
"""""""""""

Right now we can't print ``Rectangle`` in ``println!``. To do this, we need to implement
the ``std::fmt::Display`` trait.

It might be possible to use the ``{:?}`` or ``{:#?}```(pretty print) options inside the
print macro. Using the curly braces indicates printing in debug mode, for which you also
need the ``Debug`` trait.

.. code-block:: rust
    :caption: Updates to print struct

    #[derive(Debug)]
    struct Rectangle {
        width: u32,
        height: u32,
    }

    let my_rect = Rectangle {
        width: 4,
        height: 8,
    };

    println!("my_rect is {:?}", my_rect);

It is also possible to use the ``dbg!`` macro to print a value in debug format.
This is different from the print macro since it takes ownership of an expression
instead of taking a reference like the print macro.
``dbg!`` also prints to ``stderr`` whereas the print macro prints to ``stdout``

.. code-block:: rust
    :caption: Example using ``dbg!``

    let my_rect = Rectangle {
        // can debug individual assignments
        width: dbg!(4),
        height: 8,
    };

    dbg!(&my_rect);

Struct Methods
^^^^^^^^^^^^^^

Methods are functions that belong to a struct.
They are declared with the ``impl`` keyword.

.. code-block:: rust
    :caption: Example making struct method

    struct Rectangle {
        width: u32,
        height: u32,
    }

    impl Rectangle {
        fn area(&self) -> u32 {
            self.width * self.height
        }
    }

    fn main() {

        let my_rect = Rectangle {
            width: 4,
            height: 8,
        };

        println!("Area is {}", my_rect.area());
    }

Struct methods use the ``self`` keyword, which represents the instance of the structure.
Methods can take ownership of ``self``, borrow it immuatably or borrow it mutably.

Associated Functions
""""""""""""""""""""

You can also define functions in the ``impl`` block which don't use the ``self``
value. These are called associated functions.

These are often used as constructors that will return a new instance of the struct.

.. code-block:: rust
    :caption: Example of constructor

    impl Rectangle {
        fn square(size: u32) -> Self {
            Self {
                width: size,
                height: size,
            }
        }
    }

    let my_square = Rectangle::square(3);

.. note:: 
    It is also possible to have several ``impl`` blocks for a structure.
    They are all valid for the structure.

Enums
-----

.. code-block:: rust
    :caption: Basic Enum example

    enum IpAddrKind {
        V4,
        V6,
    }

    let ip_kind = IpAddrKind::V4;

Enums are namespaced under the identifier, so are accessed with the double colon
notation.

You can assign/associate values to enums too.
As shown from the example, these can multiple types, and also each enum member
can have different associations.

.. code-block:: rust
    :caption: Example associating values to an Enum

    enum IpAddrKind {
        V4(u8, u8, u8, u8), // Tuple struct
        V6(String), // Tuple struct
    }

It is also possible to name the associated values, e.g. ``Move { x: i32, y: i32 }``.
This is the same as associating a struct to the enum.
The fields in the above example are the same as a tuple struct, and are accessed in the
same way: ``V4.0``

Just like with structs, we can define methods on enums:

.. code-block:: rust
    :caption: Example of enum method

    enum Message {
        QUIT,
        MOVE { x: i32, y: i32 },
    }

    impl Message {
        fn call(&self){
            // method body here
        }
    }

    let message = Message::QUIT();
    message.call();

Option Enum
^^^^^^^^^^^

Rust doesn't have a NULL type, but you can still encode that a varible either has a
value or doesn't using the Option Enum.

.. code-block:: rust
    :caption: The Option Enum

    enum Option<T> {
        None,
        Some(T),
    }

    let some_number: Option<i32> = Some(5);

These are included in the prelude, so you can use ``None`` and ``Some(T)`` where you 
want without the Namespacing.

Match Control
^^^^^^^^^^^^^

Match control is a nice way to do some flow control covering all/ or some enum values.

.. code-block:: rust
    :caption: Example using match

    enum Coin {
        Penny,
        Nickel,
        Dime,
        Quarter(UsState), //UsState is another enum
    }

    match coin {
        Coin::Penny => {
            println!("Lucky Coin!");
            1
        },
        Coin::Nickel => 5,
        Coin::Quarter(state) => {
            println!("Value of state is {:?}", state);
            25
        },
        ...
    }

It is also possible to include more code in a match statement, and not just
returning a value. You can do this with the curly brackets like shown in the
example.

Accessing values from inside an enum can be seen in the example also.

.. code-block:: rust
    :caption: Example match with Option

    fn plus_one(x: Option<i32>) -> Option<i32> {
        match x {
            None => None,
            // if value is given, return + 1 to the value
            Some(i) => Some(i + 1),
        }
    }

.. note:: 
    Rust match checks are exhaustive, so you have to provide a match arm for every
    possibility.

Catch-all Patterns
^^^^^^^^^^^^^^^^^^

.. code-block:: rust
    :caption: Example handling all other options

    match dice_roll {
        1 => move_one(),
        2 => move_two(),
        // handles 3,4,5,6
        other => move_n(other),
        // alternative if we don't need to use the value:
        // _ => dont_move(),
    }

We can use the ``other`` to catch all remaining options. We can also use 
just an ``_``, which is the same but when you don't need to use the value.

If you don't want anything to happen, you can just return the empty tuple type: ``_ => (),``

if let
^^^^^^

For single checks on Option types, you can use the ``if let`` as a replacement:

.. code-block:: rust
    :caption: Example if let

    let config_max = Some(3u8);
    if let Some(max) = config_max {
        // do the thing when config_max is Some
    } else {
        // do the thing when config_max is None,
        // This else part is optional...
    }

Packages and Crates
-------------------

A crate is the smallest amount of code the rust compiler considers at a time.
A crate can be in two forms: a binary crate is one that compiles into an executable.
A library crate doesn't have a main function and are designed for functionality shared by
multiple projects.

A package is a set of crates that provide similar functionality. They come with a ``Cargo.toml``
file that describes how to build those crates.

If a crate contains a ``src/main.rs`` file, Cargo knowns that this crate is a binary crate
with a name the same as the name of the crate automatically. If there is a ``src/lib.rs``,
then it knows it is a library crate. If a package contains both these files, it has both
a binary and library crate. A package can also have multiple binary crates located in the
``src/bin`` path.

Declaring Modules
^^^^^^^^^^^^^^^^^

When you declare a module, the compiler will look in three places for the code. e.g. ``mod garden;``

1. Inline, with curly brackets that replace the semicolon
2. In the file ``src/garden.rs``
3. In the file ``src/garden/mod.rs``

Submodules
""""""""""

If you want to declare a module in another module, the compiler will look in the following places:
e.g. ``mod vegetable;``

1. Inline, like before
2. In ``src/garden/vegetable.rs``
3. In ``src/garden/vegetable/mod.rs``

Once a module is declared, it can be accessed from anywhere in the crate like so:
``crate::garden::vegetable::Potato``
You can make accesses easier by simply using ``use crate::garden::vegetable::Potato`` and then
just use ``Potato`` in your code.

Defining Modules
^^^^^^^^^^^^^^^^

Items inside a module are private by default. Rust lets you control the privacy of items in
modules.

.. code-block:: rust
    :caption: Example of modules

    mod front_of_house {
        mod hosting {
            fn seat_at_table();
        }

        // This module is sibling of hosting, a child of front_of_house
        // and front_of_house is this module's parent
        mod serving {
            fn bring_food();
        }
    }

This makes a module tree like this:

.. code-block:: 
    :caption: Module tree

    - crate
        - front_of_house
            - hosting
                - seat_at_table
            - serving 
                - bring_food

Crate is a module started from the crate root (``main.rs`` or ``lib.rs``)

Referencing Modules
"""""""""""""""""""

We can reference modules in our crate either with relative or absolute crate paths.
Absolute paths start with ``crate`` and relative ones use something like ``self`` / ``super``
or some other identifier (e.g. nothing also works).

.. note:: 
    It is generally better to use absolute paths since it allows you to move modules
    independently of each other.

The ``pub`` keywork
"""""""""""""""""""

As before, rust defaults to private scope for modules. To make a module public,
use the ``pub`` keyword.

.. code-block:: rust
    :caption: Example making module public

    mod front_of_house {
        pub mod hosting {
            pub fn add_to_waitlist();
        }
    }

.. note:: 
    Making a module public doesn't make its contents public, it just means it is available
    to anything that can access the parent module.

Relative path with super
""""""""""""""""""""""""

You can use ``super`` to access scope that is the parent of the current scope.
This is equivilent to using ``..`` in paths for example.
e.g. ``super::deliver_order();``

Public Structs and Enums
^^^^^^^^^^^^^^^^^^^^^^^^

You can declare a struct public with the ``pub`` keyword. This only makes the struct visible,
but the fields in the struct are still private by default, so you have to also declare them
public on a case by case basis. Note that the ``impl`` functions will have to match the
visibility of what they access.

An enum on the other hand, once declared public with ``pub``, has all of its field public.

The ``use`` keyword
^^^^^^^^^^^^^^^^^^^

The use keyword can bring paths into scope without having to declare the whole path on every
function call.

.. code-block:: rust
    :caption: Example with ``use``

    use crate::front_of_house::hosting;

    // Can access the module with the last name in the use statement
    hosting::add_to_waitlist();

.. note::
    This only creates a shortcut for the module scope you are in.
    Child module scopes will not have access to this name shortening.

We can also specify an alias for the namespace used: e.g. ``use crate::front_of_house::hosting as host;``

If you add the ``pub`` keyword infront of the ``use`` statement, then it means that other code
that uses this module will be able to use this shortened namespace too. If not defined as ``pub``,
they will not be able to.

Nested Paths and Globs
""""""""""""""""""""""

Nested paths and globs give you a way of cleaning up the way you use multiple items from one module.

.. code-block:: rust
    :caption: Example of Nested Paths and Globs

    use std::cmp::Ordering;
    use std::io;

    // This can be reduced to
    use std::{cmp::Ordering, io};

    use std::io;
    use std::io::Write;

    // This can be reduced to
    use std::io::{self, Write}

    // Globs are also supported
    use std::collections::*;

Modules in different files
^^^^^^^^^^^^^^^^^^^^^^^^^^

A ``mod`` declaration only needs to be perfomed once. The rest of the files in your
crate can then access the module functions using the name path. The ``mod`` keyword is not like
the ``include`` keyword in other languages.

Collections
-----------

Collections can store multiple values, and are stored on the heap.

Vectors
^^^^^^^

Vectors can only store values of the same type.

.. code-block:: rust
    :caption: Basic vector creation

    // have to specify the type since it is an empty vector
    let v: Vec<i32> = Vec::new();

    // convenience macro for creating a vector and setting its type (inferred from the data)
    let v = vec![1, 2, 3];

.. code-block:: rust
    :caption: Writing and reading elements

    let mut v = Vec::new();

    // type inferred here, adds the element 5 to the vector
    v.push(5);
    v.push(4);
    v.push(3);
    v.push(2);

    // getting a value:
    let third: &i32 = &v[2];
    let third: Option<&i32> = v.get(2); // Some(third) or None

.. code-block:: rust
    :caption: Iterating over values in a vector

    let mut v = vec![110, 32, 65];
    for i in &v {
        println!("{i}");
    }

    // This adds 50 to each vector element
    // the * is the dereference operator
    for i in &mut v {
        *i += 50;
    } 

String
^^^^^^

Strings are basically considered as a collection of bytes in rust.
String is actually created as a wrapper around the ``Vec<T>``.

They are UTF-8 encoded! Which means we can use lots of cool charaters. ``øØæÆÅå``

.. code-block:: rust
    :caption: Creation of String

    // New emtpy string
    let mut s = String::new();

    // New initialised string
    let s = "initial_contents".to_string();
    let s = String::from("initial_contents");

.. code-block:: rust
    :caption: Updating String

    let mut s = String::from("foo");

    // append using push_str -> "foobar"
    s.push_str("bar");

    // concatenation
    let s2 = String::from(" world!");
    // Note s is move here so it no longer exists after this
    let s3 = s + &s2; // results in "foobar world!"

The reason that s will no longer exist after using the ``+`` operator is that this is actually
implemented by a function call: ``fn add(self, s: &str) -> String {``

.. code-block:: rust
    :caption: Concatenating multiple Strings

    let s1 = String::from("tic");
    let s2 = String::from("tac");
    let s3 = String::from("toe");

    let s = format!("{s1}-{s2}-{s3}");

Indexing of Strings in rust doesn't work. This is because we use UTF-8, which doesn't 
have fixed size characters. Just avoid it since it causes problems.

.. code-block:: rust
    :caption: Iterating over a string

    // iterate over charaters
    for c in "øæå".chars() {
        println!("{c}");
    }

    // iterate over bytes, this will print numbers
    for b in "øæå".bytes() {
        println!("{b}");
    }

Remember, a char in rust is not the same a byte!

Hash Maps
^^^^^^^^^

The type ``HashMap<K, V>`` stores a mapping of keys of type K to values of type V.
These are known by other names in other languages like dictionary in python.

All the values must have the same type, and all the keys must have the same type.

.. code-block:: rust
    :caption: Creating HashMaps and accessing values

    use std::collections::HashMap;

    // create empty HashMap
    let mut scores = HashMap::new();

    scores.insert(String::from("Blue"), 10);
    scores.insert(String::from("Yellow"), 50);

    let team_name = String::from("Blue");
    let score = scores.get(&team_name).copied().unwrap_or(0);

.. code-block:: rust
    :caption: Iterating over HashMaps

    for (key, value) in &scores {
        println!("{key}: {value}");
    }

Ownership
"""""""""

For values implementing the copy trait (e.g. ``i32``), the values will be copied into the
hashmap. For owned values like ``String``, the ownership will be transfered to the hashmap.
This applies to both keys and values.

Updating a HashMap
""""""""""""""""""

The number of key-value pairs is growable, but a unique key can only have one value associated
with it at a time.

There are several options when updating a hashmap:

- Overwriting a value: if we call the ``.insert()`` function twice on the same key, it will overwrite the value.
- Adding only if key is not present: ``scores.entry(String::from("Blue")).or_insert(50);`` -> inserts 50 if key
  "Blue" doesn't already exist.
- Updating based on old value:

.. code-block:: rust
    :caption: Example updating based on old value

    use std::collections::HashMap;

    let text = "hello world wonderful world";

    let mut map = HashMap::new();

    for word in text.split_whitespace() {
        let count = map.entry(word).or_insert(0);
        // or_insert() returns a &mut to the value
        *count += 1;
    }

.. note:: 
    Rust has available several backend hashing algorithms. Some are slower than others (improved security against DoS)
    and some are faster. It is possible to change these hash backends.

Error Handling
--------------

Rust has two types of errors, recoverable and unrecoverable.
For recoverable errors, the ``Result<T, E>`` is used. For unrecoverable, the ``panic!`` macro
stops execution.

When a rust program panics, it unwinds by going back up the call stack to cleanup.
If you don't want this e.g. you want a tiny binary, you can set ``panic = 'abort'``
under ``[profile.release]`` in your cargo project.

In order to get backtraces, we should run our program with debug symbols enabled, i.e.
running cargo without the ``--release`` flag.

Recoverable Errors
^^^^^^^^^^^^^^^^^^

For recoverable errors we use the ``Result<T, E>`` type.

.. code-block:: rust
    :caption: Matching on different errors

    use std::fs:File;
    use std::io::ErrorKind;

    fn main() {
        let greeting_file_result = File::open("hello.txt");

        let greeting_file = match greeting_file_result {
            Ok(file) => file,
            Err(error) => match error.kind() {
                ErrorKind::NotFound => {
                    match File::create("hello.txt") {
                        Ok(fc) => fc,
                        Err(e) => panic!("Problem creating file"),
                    }
                }
                other_error => {
                    panic!("Another Error");
                }
            }
        }
    }

As shown we can use a ``match`` to handle errors.
We can use other functions too such as ``unwrap_or_else`` to handle ``Result<T, E>`` types.

Using the ``unwrap()`` method will return the value on Ok, and panic if there is an error.

The ``expect()`` method does the same as ``unwrap`` but allows you to specify an error message.

Propogating errors
^^^^^^^^^^^^^^^^^^

Propogating error is when you pass an error back up the call stack to be handled else-where.
You can use a ``match`` block as before, or some shorthand.

.. code-block:: rust
    :caption: Shortcut for error propogation

    use::fs::File;
    use std::io::{self, Read};

    fn read_username_from_file () -> Result<String, io::Error> {
        let mut username_file = File::open("hello.txt")?;
        let mut username = String::new();
        username_file.read_to_string(&mut username)?;
        Ok(username)
    }

The ``?`` operator is placed after a ``Result`` value. If it is ``Ok``, we continue
execution. If there is an ``Err``, that error will be returned. Using the ``?`` will
convert the error to the error type specified in the function signature.
The ``?`` can only be used on expressions which return something that matches the 
return signatature of the function.

Custom Type for Validation
^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: rust
    :caption: Example of a custom type for Validation

    pub struct Guess {
        value: i32,
    }

    impl Guess {
        // Similar to a setter
        pub fn new(value: i32) -> Guess {
            if value < 1 || value > 100 {
                panic!("Guess must be between 1 and 100, got {}", value);
            }
            Guess { value }
        }

        // This is similar to a getter
        pub fn value(&self) -> i32 {
            self.value
        }
    }

