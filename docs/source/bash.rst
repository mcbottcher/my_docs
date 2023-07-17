.. role:: bash(code)
   :language: bash

Bash
======

Executing Scripts
-----------------

By convention, bash scripts end with the ``.sh`` file extension.
You can make a script executable using ``chmod`` e.g. :bash:`chmod u+x my_script.sh`.
You can then run the script with :bash:`./my_script.sh`, :bash:`sh my_script.sh`, :bash:`bash my_script.sh`

Add a *shebang* to let your shell know what to execute the script with.
For bash, this is the path to where bash is e.g. ``#!/bin/bash``

Comments
--------

Comments can be written using the ``#`` character

Variables
---------

Bash has no data types. A variable can store numeric values, characters, or strings.
You use the ``$`` operator to access a variable's value

.. code-block:: bash
    :caption: Assigning and accessing variables

    my_var=hello
    echo $my_var

    # also valid
    echo ${my_var}

.. note::
    Variable names are case sensitive

- You are also able to have global and local variables:

.. code-block:: bash
    :caption: Example with global and local vars

    VAR="global variable"

    function bash {
        # Define bash local variable
        # This variable is local to bash function only
        local VAR="local variable"
        echo $VAR
    }    

- Arrays:
    - 4 element array: :bash:`ARRAY=(MY NAME IS 4)`
    - Get number of elements in an array: :bash:`ELEMENTS=${#ARRAY[@]}`
    - Loop through array:

.. code-block:: bash
    :caption: Example looping through array

    for (( i=0;i<$ELEMENTS;i++)); do
        echo ${ARRAY[${i}]}
    done

Input and Output
----------------

- User input - use the ``read`` command: :bash:`read var_to_hold_input`

- Read lines of a file:

.. code-block:: bash

    while read line
    do
        echo $line
    done < input.txt

- Command line args. You can access arguments passed through the command line with ``$1, $2 ...``.
    - Can access all arguments through a special character: ``$@``
    - Could place in an array like so: ``args=("$@")``, and access them with ``args[0], args[1]...``


- Printing to the terminal: :bash:`echo "Hello World"`

- Writing to a file: :bash:`echo "Some text." > output.txt`. Can also redirect commands: :bash:`ls > output.txt`

.. note::
    The ``>`` operator overwrites a file if it already has content in it

- Appending to a file: :bash:`echo "More text." >> output.txt`

Conditional Statements
----------------------

- If and else statements take the following form:

.. code-block:: bash
    :caption: if else example

    if [ condition ]; then
        statement
    elif [ condition ]; then
        statement 
    else
        statement
    fi

- You can use logical operators in the condition check, e.g. ``-a`` (AND), ``-o`` (OR), ``-gt`` (>), ``-lt`` (<), ``-le`` (<=) etc.

.. note::
    There is a slight difference between using double ``[[]]`` and single ``[]``, but mostly can be used in a similar way

Looping and Branching
---------------------

- While loop:

.. code-block:: bash
    :caption: Example while loop

    i=1
    while [[ $i -le 10 ]] ; do
        echo "$i"
        (( i += 1 ))
    done

- For loop:

.. code-block:: bash
    :caption: Example of a for loop

    for i in {1..5}
    do
        echo $i
    done

- Until loop: works like a while loop almost

.. code-block:: bash
    :caption: Until loop example

    #!/bin/bash
    file="./file"
    if [ -e $file ]; then
        echo "File exists"
    else 
        echo "File does not exist"
    fi 

- Case statements:

.. code-block:: bash
    :caption: Example case statement

    case expression in
        pattern1)
            # code to execute if expression matches pattern1
            ;;
        pattern2)
            # code to execute if expression matches pattern2
            ;;
        pattern3)
            # code to execute if expression matches pattern3
            ;;
        *)
            # code to execute if none of the above patterns match expression
            ;;
    esac

Scheduling with cron
--------------------

Cron is a utility that allows you to schedule jobs.  on Unix-like systems

.. code-block:: bash
    :caption: Syntax for cron and some examples

    # syntax
    # represents mins, hours, days, months, weekday
    * * * * * sh /path/to/script.sh

    # midnight every day
    0 0 * * * sh /path/to/script.sh

    # every 5 minutes
    */5 * * * * sh /path/to/script.sh

    # 6am mon-fri
    0 6 * * 1-5 sh /path/to/script.sh

    # first 7 days of every month
    0 0 1-7 * * sh /path/to/script.sh

.. note::
    You can manage and edit cron jobs using ``crontab``. e.g. ``crontab -l`` lists all cron jobs for a user

- cron logs can be found at ``/var/log/syslog``

Debugging
---------

- Use ``set -x`` at the start of your bash script
    - This will print each command it executes to the terminal
    - You can also just pass in the flag when calling the script: :bash:`bash -x my_script.sh`

- Checking exit code: ``$?`` will give the exit code of the previous command

- Use the ``-e`` flag to make your script exit on an error, and not keep running
    - Can also do ``set -e`` at the start

Executing Shell Commands in bash
--------------------------------

- You can create a new subshell with ``$( )``

- It is then possible to use this output in other commands:

.. code-block:: bash
    :caption: Example using subshell

    echo "My current git branch is $(git branch --show-current)"

Bash Trap
---------

Bash can catch signals that you send to it, e.g. *ctrl+c*

.. code-block:: bash
    :caption: Example catching a signal interrupt

    trap bashtrap INT

    # bash trap function is executed when CTRL-C is pressed:
    # bash prints message => Executing bash trap subrutine !
    bashtrap()
    {
        echo "CTRL+C Detected !...executing bash trap !"
    }

    # rest of script

Comparison Operators
--------------------

- Arithmetic:
    - ``-lt`` (<)
    - ``-gt`` (>)
    - ``-le`` (<=)
    - ``-ge`` (>=)
    - ``-eq`` (==)
    - ``-ne`` (!=)

- String:
    - ``=``: equal
    - ``!=``: not equal
    - ``<``: less than
    - ``>``: greater than
    - ``-n s1``: string s1 is not empty
    - ``-z s1``: string s1 is empty

File Testing
------------

It is possible to test characteristics of files/directories in bash:

- ``-d dir_name``: Check if dir exists
- ``-e filename``: Check if file exists
- ``-L filename``: Symbolic link
- ``-r file``: File is readable
- ``-s file``: File is non-zero size
- ``-w file``: File is writable
- ``-x file``: File is executable

.. code-block:: bash
    :caption: Example with file testing

    #!/bin/bash
    file="./file"
    if [ -e $file ]; then
        echo "File exists"
    else 
        echo "File does not exist"
    fi

Functions
---------

.. code-block:: bash
    :caption: Example function

    function my_func {
        echo 5
    }

    function my_arg_func {
        echo $1
    }

    echo "My special number is ${my_func}"
    echo "My special number is ${my_arg_func 3}"

Select
------

Use this to promt the user to select from a number of options

.. code-block:: bash
    :caption: Example using user selection

    PS3='Choose an option: '
    select word in "Yes" "No"
    do
        echo "You chose ${word}"
        break
    done

Single and Double Quotes
------------------------

Single quotes in bash will suppress special meanings of meta characters.

Double quotes suppresses the meanings, except from ``$ \``
In this case you can use escape characters like: ``\a`` -> alert (bell)

Let keyword
-----------

``let`` is used when evaluating arithmetic expressions on shell variables

:bash:`let my_var++`

Redirecting STD streans
-----------------------

- STDOUT to STDERR:

    :bash:`echo "Redirect" 1>&2`

- STDERR to STDOUT

    :bash:`cat $1 2>&1`

exec command
------------

Bash includes a built-in command called ``exec``.
Calling this replaces the process of the current shell with a process of the command specified after the ``exec`` command.

Because the command is replacing the shell, it will cause a bash script to end after executing.

.. code-block:: bash
    :caption: Example of return

    exec echo "Hello"
    exec echo "World"

The above example only prints *"Hello"*

It can also be used for redirecting std streams to log files:

.. code-block:: bash
    :caption: Example routing stdout to log file

    exec 1>log.txt

    echo "Hello"
    echo "World"

*"Hello World"* is written to the *log.txt* file.

.. note::
    STDIN is 0, STDOUT is 1, and STDERR is 2

Bash eval statement
-------------------

The ``eval`` statement allows you to run a command based on a variable.

.. code-block:: bash
    :caption: Example using eval statement

    MY_COMMAND="git br -a"

    eval $MY_COMMAND > my_file.txt

    RETURN_CODE=$?

Print Colour to the console
---------------------------

Printing colour requires the use of escape characters. You can achieve this using ``printf`` commands, or ``echo -e``.

.. code-block:: bash
    :caption: Example printing colour

    #!/bin/bash

    # Color variables
    red='\033[0;31m'
    green='\033[0;32m'
    yellow='\033[0;33m'
    blue='\033[0;34m'
    magenta='\033[0;35m'
    cyan='\033[0;36m'
    # Clear the color after that
    clear='\033[0m'

    # Examples
    echo -e "The color is: ${red}red${clear}!"
    echo -e "The color is: ${green}green${clear}!"

.. note::
    The yellow colour given in the example looks quite nice for giving example shell commands