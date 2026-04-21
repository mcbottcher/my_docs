C++
===

Visibility and Scoping
----------------------

Classes and structs have three visibility levels: **private**, **protected**, and **public**.

- Structs have public visibility by default
- Classes have private visibility by default

For classes:

- **Private**: Only that class can access the members marked as private
- **Protected**: Only that class and subclasses can access the members marked as protected
- **Public**: That class, subclasses, and objects can access the members marked as public

**Important**: Access restrictions only apply *outside* the class. Inside a class method, you can access private data of other objects of the same class:

.. code-block:: cpp

    class String {
    private:
        std::unique_ptr<char[]> data_;
        size_t length_;
    public:
        String &operator=(const String &other) {
            // Inside String methods, can access other.data_ and other.length_ even though they're private
            length_ = other.length_;
            data_ = std::make_unique<char[]>(length_ + 1);
            return *this;
        }
    };

Inheritance Visibility
^^^^^^^^^^^^^^^^^^^^^^

When deriving a class in C++, you can provide restrictions on the visibility of the parent class members:

.. code-block:: cpp

    class DerivedClass : BaseClass {
        // Default: private inheritance
    };

    class DerivedClass : public BaseClass {
        // Public inheritance
    };

    class DerivedClass : protected BaseClass {
        // Protected inheritance
    };

By default, derivation is **private**. In the derived class, you can use members as specified in the BaseClass. However, when something else uses the DerivedClass, the extra restrictions based on the visibility mode will apply. This means an object using DerivedClass can only access the public members of BaseClass if the DerivedClass uses public visibility mode.

.. mermaid::

    graph TB
        Base["BaseClass<br/>public: my_public_var<br/>protected: my_protected_var<br/>private: my_private_var"]

        subgraph Public["Public Inheritance: class D : public Base"]
            D1["In DerivedClass:<br/>public → public<br/>protected → protected<br/>private → inaccessible<br/><br/>From outside:<br/>→ only public accessible"]
        end

        subgraph Protected["Protected Inheritance: class D : protected Base"]
            D2["In DerivedClass:<br/>public → protected<br/>protected → protected<br/>private → inaccessible<br/><br/>From outside:<br/>→ none accessible"]
        end

        subgraph Private["Private Inheritance: class D : private Base"]
            D3["In DerivedClass:<br/>public → private<br/>protected → private<br/>private → inaccessible<br/><br/>From outside:<br/>→ none accessible"]
        end

        Base --> D1
        Base --> D2
        Base --> D3

Example usage:

.. code-block:: cpp

    class BaseClass {
    public:
        int my_public_var;
    protected:
        int my_protected_var;
    private:
        int my_private_var;
    };

    class DerivedClass : public BaseClass {
    public:
        DerivedClass(){
            my_protected_var = 20;
            my_public_var = 30;
        }
    };

    class AnotherClass : public DerivedClass {
    public:
        AnotherClass(){
            my_protected_var = 40;
            my_public_var = 60;
        }
    };

    int main() {
        DerivedClass my_class = DerivedClass();
        AnotherClass my_other_class = AnotherClass();

        std::cout << my_class.my_public_var << std::endl;
        return 0;
    }

Structs vs Classes
^^^^^^^^^^^^^^^^^^

A struct is basically a class but with public members by default. Structs are commonly used for pure data "classes" (no methods) where visibility should be public for all.

Static vs Non-static
--------------------

**Static members** are fixed and shared between all instantiations of a class/subclass:

.. code-block:: cpp

    class MyClass {
        static int shared_var;
    };

**Non-static members** are instance-dependent. For non-static methods, the ``this`` pointer is automatically added so it can access class members.

The ``<<`` Operator
-------------------

In C++, you can overload operators for classes. The ``<<`` is an operator overload for ``std::cout``:

.. code-block:: cpp

    std::cout << "hello";
    // Equivalent to: std::cout.insert("hello")

Chaining works by returning the stream object:

.. code-block:: cpp

    std::cout << "hello" << " world" << std::endl;

This outputs "hello" to stdout and returns the ``std::cout`` object. Then " world" is inserted into this object and output. Finally ``std::endl`` is inserted into ``std::cout``.

Pointers and References
-----------------------

C++ has pointers like C, but also has **references**:

.. code-block:: cpp

    int i = 0;
    int &ri = i;  // ri is a reference to i

Key differences from pointers:

- References cannot be NULL (must always exist)
- Cannot change a reference once created (can't make it reference something new)
- Cannot do math on references
- No reference to reference

References are essentially pointers with compiler-induced restrictions to make them safer.

Lvalues and Rvalues
-------------------

**lvalue**: A value with a named memory location you can reference. It appears on the left-hand side of an assignment.

**rvalue**: A temporary expression or constant that produces a value but has no stable address. You cannot take its address.

.. code-block:: cpp

    int a = 5;           // a is lvalue, 5 is rvalue
    int b = a;           // b is lvalue, a is also lvalue
    int c = a + b;       // c is lvalue, (a + b) is rvalue (temporary result)

    int x = 10;
    int* p = &x;         // fine — x is an lvalue, it has an address
    int* q = &42;        // error — 42 is an rvalue, no stable address

The ``this`` Pointer
--------------------

``this`` is available inside a method and is a pointer to the current object (like ``self`` in Python):

.. code-block:: cpp

    class MyClass {
        int value;
        void setValue(int value) {
            this->value = value;  // Disambiguate member from parameter
        }
    };

You typically don't need ``this`` since the compiler can infer member access, but it's useful for naming clashes.

Move and Copy Semantics
-----------------------

A class that owns heap-allocated data can either **copy** or **move** that data:

- **Copy**: Create a duplicate of the data. A String with 1000 characters copied means two separate 1000-character allocations. Uses **lvalue references** (``&``) since the original is still needed.
- **Move**: Transfer ownership of the data. The new object takes the pointer, and the original loses it. Only pointer/metadata moves, not the data itself. Uses **rvalue references** (``&&``) since the original is discarded.

.. code-block:: cpp

    class String {
    private:
        std::unique_ptr<char[]> data_;
        size_t length_;
    public:
        // Copy constructor and assignment (lvalue reference)
        String(const String &other) : data_(nullptr), length_(0) {
            if (other.data_.get()) {
                length_ = other.length_;
                data_ = std::make_unique<char[]>(length_ + 1);
                memcpy(data_.get(), other.data_.get(), length_ + 1);
            }
        }

        String &operator=(const String &other) {
            length_ = other.length_;
            data_ = std::make_unique<char[]>(length_ + 1);
            memcpy(data_.get(), other.data_.get(), length_ + 1);
            return *this;
        }

        // Move constructor and assignment (rvalue reference)
        String(String &&other) noexcept
            : data_(std::move(other.data_)), length_(other.length_) {
            other.length_ = 0;
        }

        String &operator=(String &&other) noexcept {
            data_ = std::move(other.data_);
            length_ = other.length_;
            other.length_ = 0;
            return *this;
        }
    };

Convert an lvalue to an rvalue using ``std::move``:

.. code-block:: cpp

    my::String s("hello");
    my::String t = std::move(s);  // Move s to t, s is now empty

    std::cout << "s length: " << s.length() << std::endl;  // 0
    std::cout << "t: " << t.c_str() << std::endl;          // "hello"

A ``const T&`` reference can bind to both lvalues and rvalues, and it extends the lifetime of rvalues. Use this when you don't need to modify the referenced object.

Unique Pointers
---------------

Use ``unique_ptr`` instead of ``new`` and ``delete`` for automatic memory management. A unique pointer automatically deletes its data when it goes out of scope and only allows one owner:

.. code-block:: cpp

    std::unique_ptr<char[]> data = std::make_unique<char[]>(100);
    // Use data as normal
    // Automatically deleted when data goes out of scope

Create with ``std::make_unique``, passing arguments to the object's constructor (or array length for arrays):

.. code-block:: cpp

    auto ptr = std::make_unique<MyClass>(arg1, arg2);
    auto arr = std::make_unique<int[]>(50);

Dynamic Memory Allocation
--------------------------

Use ``new`` and ``delete`` for heap allocation (like ``malloc`` and ``free``):

.. code-block:: cpp

    int *ptr_to_int = new int;
    *ptr_to_int = 5;
    // Or: int *ptr_to_int = new int(5);
    delete ptr_to_int;

    double *array = new double[4];
    delete[] array;

Key differences from ``malloc``:

- ``new`` calls constructors for classes
- If too much space is requested, ``new`` throws an exception
- Use ``new(nothrow)`` to return NULL instead of throwing:

.. code-block:: cpp

    double *big_array = new(nothrow) double[99999999999999];

See placement new for overriding allocated memory areas.

Exceptions
----------

C++ has exception handling with try-catch blocks:

.. code-block:: cpp

    try {
        some_bad_code();
    }
    catch (std::exception& e) {
        do_error_handling();
    }

You can create custom exceptions by subclassing the exception class:

.. code-block:: cpp

    class MyException : public std::exception {
        // Custom exception
    };

You can also raise primitive types:

.. code-block:: cpp

    throw 20;
    // Caught with: catch (int code) {}

Catch all remaining exceptions with:

.. code-block:: cpp

    catch (...) {
        // Handle any exception not caught above
    }

Namespaces
----------

Namespaces prevent naming clashes. Using namespaces is confined to the scope you're in:

.. code-block:: cpp

    namespace mcb {
        class MCB {
            int x;
        };
    }

It's good practice to namespace if you're writing a library.

Const Methods
-------------

Mark methods as ``const`` to indicate they won't change the object's state (read-only):

.. code-block:: cpp

    class MyClass {
        int getValue() const {
            return value;  // Cannot modify members
        }
    };

Templates
---------

Templates allow functions or classes to work with multiple types:

.. code-block:: cpp

    template <typename T> T myMax(T x, T y) {
        return (x > y) ? x : y;
    }

    int main() {
        cout << myMax<int>(3, 7) << endl;
        return 0;
    }

Template classes:

.. code-block:: cpp

    template <typename T> class Array {
    private:
        T* ptr;
        int size;
    public:
        Array(T arr[], int s);
        void print();
    };

    template <typename T> Array<T>::Array(T arr[], int s) {
        ptr = new T[s];
        size = s;
        for (int i = 0; i < size; i++)
            ptr[i] = arr[i];
    }

    template <typename T> void Array<T>::print() {
        for (int i = 0; i < size; i++)
            cout << " " << *(ptr + i);
        cout << endl;
    }

    int main() {
        int arr[5] = { 1, 2, 3, 4, 5 };
        Array<int> a(arr, 5);
        a.print();
        return 0;
    }

Function Overloading
--------------------

Allow multiple functions with the same name but different argument types:

.. code-block:: cpp

    void add(int a, int b) {
        cout << "sum = " << (a + b);
    }

    void add(double a, double b) {
        cout << endl << "sum = " << (a + b);
    }

    int main() {
        add(10, 2);
        add(5.3, 6.2);
        return 0;
    }

This differs from **overriding**, where you replace the implementation of a method in a derived class.

Virtual Methods
---------------

Mark methods as ``virtual`` to indicate derived classes can override them:

.. code-block:: cpp

    class Base {
    public:
        virtual void timerEvent() = 0;  // Pure virtual function
    };

    class Derived : public Base {
    public:
        void timerEvent() override {
            std::cout << "Timer event triggered!" << std::endl;
        }
    };

    int main() {
        Derived d;
        d.timerEvent();
        return 0;
    }

Using ``= 0`` makes the method **purely virtual** - it must be overridden by derived classes (compiler error otherwise). This makes the class itself abstract and cannot be instantiated directly.

Strings and Characters
----------------------

Strings are objects in C++ with associated methods:

.. code-block:: cpp

    string test1 = "abcde";
    cout << "size: " << test1.size() << endl;

Common string operations:

.. code-block:: cpp

    test1[0];              // Access character: 'a'
    test1.at(0);           // Access with bounds checking
    test1 += "fgh";        // Concatenate
    test1.empty();         // Check if empty
    test1.clear();         // Make empty
    to_string(-10.5);      // Convert to string
    stod(my_string);       // Convert from string to double
    my_string.substr(2,4); // Get substring

String literals vs character arrays:

.. code-block:: cpp

    char my_arr[] = "hello world";
    // String literal copied to stack as array of characters
    // Can be modified easily

    char * my_ptr = "hello world";
    // Pointer to string literal in program memory
    // May be write-protected, could cause seg fault on write

For detailed information on `string and character literals <https://learn.microsoft.com/en-us/cpp/cpp/string-and-character-literals-cpp?view=msvc-170>`__, see Microsoft's C++ documentation.

Character grouping:

.. code-block:: none

    auto my_var = 'mik\0kel';
    // Char group treated as int. Only '\0kel' stored (int size)
    // Rest is discarded

    char * char_ptr = (char *)&my_var;
    printf("String is %s\n", char_ptr);
    // Prints until termination "\0" is found

Command Line Arguments
----------------------

Access command line arguments through ``argc`` and ``argv``:

.. code-block:: cpp

    int main(int argc, char* argv[]) {
        for (int i = 0; i < argc; i++) {
            printf("argv[%d]: %p %s\n", i, argv[i], argv[i]);
        }
        return 0;
    }

- ``argc`` is the number of arguments
- ``argv`` is an array of char pointers to strings
- The first argument is always the program name

Compilation Notes
-----------------

Example compilation with external libraries:

.. code-block:: shell

    g++ boost_program_option.cpp -I /home/mcb/boost_1_82_0/ \
        -L /home/mcb/boost_1_82_0/stage/lib/ \
        -l boost_program_options --static

**Important**: The order matters. Specify source files at the beginning.

Compiler flags:

- ``-I``: Include path for finding header files in non-standard locations
- ``-L``: Library search path where the linker looks for libraries
- ``-l``: Library name to link (without ``lib`` prefix and ``.a``/``.so`` suffix)
- ``--static``: Use static library (``.a``) instead of shared library (``.so``)

For shared libraries, set the runtime linker path:

.. code-block:: shell

    export LD_LIBRARY_PATH=/home/mcb/boost_1_82_0/stage/lib:$LD_LIBRARY_PATH

Best Practices
--------------

**Range-based for loops**

If you don't need the index, use range-based loops:

.. code-block:: cpp

    int arr[] = {1, 2, 3, 4, 5};
    for (int i : arr) {
        cout << i << " ";
    }

Values are copied by default. Use references to modify:

.. code-block:: cpp

    for (auto& i : arr) {
        i = i * 2;
    }

**Use std::array instead of C-style arrays**

C-style arrays decay to pointers when passed to functions, requiring separate size parameters. Use ``std::array<int, n>`` instead.

**constexpr for compile-time evaluation**

.. code-block:: cpp

    constexpr float SPEED_OF_LIGHT = 3000000.0;

Signals the compiler that values/functions can be evaluated at compile time instead of runtime.

**Virtual destructors**

Mark destructors as virtual in base classes and override in derived classes:

.. code-block:: cpp

    class Base {
        virtual ~Base() {}
    };

    class Derived : public Base {
        ~Derived() override {}
    };

**Member initialization order**

Class members are initialized based on their declaration order in the class, not their order in the initializer list.

**Use smart pointers instead of new/delete**

Instead of manually managing memory with ``new`` and ``delete`` (which can leak after exceptions), use smart pointers:

.. code-block:: cpp

    std::unique_ptr<MyClass> ptr(new MyClass());
    // Or better: std::unique_ptr<MyClass> ptr = std::make_unique<MyClass>();
    // Automatically deleted when ptr goes out of scope, even after exceptions

Use ``std::make_unique`` to automatically pass arguments to the constructor.

**RAII Principles**

Don't use ``new`` and ``delete`` in a class to manage resources. Use smart pointers like ``std::unique_ptr`` so you don't have to worry about cleanup. Always cleanup in destructors (RAII - Resource Acquisition Is Initialization).

**Raw pointers for non-owning references**

Use raw pointer types if the function is not in charge of the ownership of the data.

**Use std::filesystem::path**

For file paths, use ``std::filesystem::path`` instead of strings.

Pimpl Pattern
-------------

The Pimpl (Pointer to Implementation) pattern helps avoid exposing all private data in a class definition. Instead of putting all private data directly in the class, you create a separate implementation class and store only a pointer to it in the public class.

For more details, see `cpppatterns.com - Pimpl <https://cpppatterns.com/patterns/pimpl.html>`__.
