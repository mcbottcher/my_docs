🔨 CMake
========

CMake is a cross-platform build system generator. It generates native build files (Makefiles, Ninja, VS project files, etc.) from a ``CMakeLists.txt`` configuration.

----

Command Reference
-----------------

- **``cmake_minimum_required``** — Specify the minimum CMake version required.

  ``cmake_minimum_required(VERSION 3.10)``

- **``project``** — Sets the name of the project.

  ``project(MyProject)``

- **``set``** — Set a variable.

  ``set(CMAKE_CXX_STANDARD 11)``

- **``add_executable``** — Add an executable target to build.

  ``add_executable(my_program my_program.cxx)``

- **``target_include_directories``** — Specifies include directories when compiling a specific target.

  ``target_include_directories(target PUBLIC "${PROJECT_BINARY_DIR}")``

- **``add_subdirectory``** — Adds a sub-directory with its own CMakeLists.txt file.

  ``add_subdirectory(MathFunctions)``

- **``target_link_libraries``** — Links a library to your target (executable/library).

  ``target_link_libraries(target PUBLIC my_library)``

- **``option``** — A boolean value the user can optionally select. You can set the value when invoking CMake: ``cmake ../ -DUSE_MYMATH=OFF``

  ``option(USE_MYMATH "User lib implementation" ON)``

- **Compiler ID Generator Expression** — A special generator expression of format ``$<COMPILE_LANG_AND_ID:language,compiler_ids>`` which returns ``1`` if the language and compiler id match.

  ``set(gcc_like_cxx "$<COMPILE_LANG_AND_ID:CXX,ARMClang,AppleClang,Clang,GNU,LCC>")``

- **Conditional Generator Expression** — Returns the given string if the expression evaluates to ``1``. Given in the form: ``$<condition:true_string>``

  ``target_compile_options(tutorial_compiler_flags INTERFACE "$<${gcc_like_cxx}:-Wall;-Wextra;-Wshadow;-Wformat=2;-Wunused>")``

- **``target_compile_options``** — Adds compile options to a target. See Conditional Generator Expression example above, where warning flags are set.

- **``target_compile_definitions``** — Adds preprocessor definitions when compiling a target. Useful for converting a CMake build flag (e.g. ``-DUSER_DEMO=BLINKY_DEMO``) into a C ``#define``. The ``$<IF:condition,true_val,false_val>`` and ``$<STREQUAL:a,b>`` generator expressions can map string values to numeric definitions:

  .. code-block:: cmake

     target_compile_definitions(posix_demo
         PRIVATE
             $<IF:$<STREQUAL:${USER_DEMO},BLINKY_DEMO>,USER_DEMO=0,>
             $<IF:$<STREQUAL:${USER_DEMO},FULL_DEMO>,USER_DEMO=1,>
     )

- **``install``** — Installs executables and libraries in the local system. Installs to ``/usr/local/<lib|bin|include>``

  .. code-block:: cmake

     install(TARGETS ${installable_libs} DESTINATION lib)
     install(TARGETS Tutorial DESTINATION bin)
     install(FILES "${PROJECT_BINARY_DIR}/TutorialConfig.h" DESTINATION include)

- **``enable_testing()``** — Enables being able to test with CTest.

- **``add_test()``** — Adds a test that can be run by CTest.

  ``add_test(NAME test1 COMMAND Tutorial 25)``

- **``set_tests_properties()``** — Allows you to set parameters for a test, e.g. expected output.

  ``set_tests_properties(test1 PROPERTIES PASS_REGULAR_EXPRESSION "Success")``

- **``include(CTest)``** — Includes the CTest module, allowing use of the CDash results Dashboard. Requires a ``CTestConfig.cmake`` file. ``include`` by itself includes a module.

  ``ctest -D Experimental``

- **``check_cxx_source_compiles``** — Checks if a specific piece of code can compile. Useful for determining if a library is available (e.g. ``std::log``). Requires including the ``CheckCXXSourceCompiles`` module.

  .. code-block:: cmake

     check_cxx_source_compiles("
       #include <cmath>
       int main() {
         std::log(1.0);
         return 0;
       }
     " HAVE_LOG)

- **``add_custom_command``** — Allows you to run a command during the build, e.g. running an executable to generate a file used in the build.

  .. code-block:: cmake

     add_custom_command(
       OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/Table.h
       COMMAND MakeTable ${CMAKE_CURRENT_BINARY_DIR}/Table.h
       DEPENDS MakeTable
     )

- **``include(MakeTable.cmake)``** — Includes a custom module located in ``MakeTable.cmake``

----

Notes
-----

.. note::

   A **PUBLIC** dependency is one that is included in the header file of a
   library. A **PRIVATE** dependency is used only in the implementation
   (.cpp or .c files). **INTERFACE** is used when the dependency is only
   used in the header file and not in the implementation.

.. note::

   ``PROJECT_BINARY_DIR`` points to the build folder, and
   ``PROJECT_SOURCE_DIR`` points to where the source files are kept.

.. note::

   When a library is in a subfolder, you can specify to include the files in
   that subfolder:

   .. code-block:: cmake

      target_include_directories(MathFunctions INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})

   ``CMAKE_CURRENT_SOURCE_DIR`` is the path to the source directory currently
   being processed.
