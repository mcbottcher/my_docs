.. role:: shell(code)
    :language: shell

Linux Commands
==============

- :shell:`cd` : Change Directory

  - :shell:`cd` itself will default to the home DIR
  - :shell:`cd -` takes you back to the previous directory you were at

----

- :shell:`pwd` : print the directory you are in

----

- :shell:`whoami` : prints current user

----

- :shell:`wc`: get file size info

  - :shell:`wc -c unix.md` : Get number of bytes of file
  - :shell:`wc -l unix.md` : Get number of lines of file

----

- :shell:`diff`: Compares two files

  - :shell:`diff -y <file1> <file2>`: Outputs diff of file1 and file2 side-by-side

----

- :shell:`find`: Find a file

  - :shell:`find . -name "*.py"`: Finds all .py files from current directory and down

----

- :shell:`tree`: Shows files in tree display

----

- :shell:`printenv`: Print environment variables

----

- :shell:`curl`: cURL lets us query URLs from the command line

  - :shell:`curl www.google.com`: Returns HTML/Scripts of google.com
  - option :shell:`-i` gives information header
  - option :shell:`-d or --data` can be used to post data to a url

    - :shell:`curl -d "first=Bob&last=Ross" http://<url>`

  - pass in username and password: :shell:`curl -u <username>:<password> <url>`
  - Download response e.g. picture: :shell:`curl -o test.jpg <url>` -> outputs response to test.jpg

----

- :shell:`grep`: Search for word or expression in a file

  - :shell:`grep "expression" <file>`
  - Use :shell:`-i` to search for expression without being case sensitive
  - Can use it with pipe: :shell:`cat my_file.txt | grep "hello world"`
  - Use with extended regualar expressions: :shell:`grep -E 'pattern1|pattern2' fileName`
    
    - Or regular grep:
      
      - :shell:`grep 'pattern1\|pattern2' fileName`
      - :shell:`grep -e 'pattern1' -e 'pattern2' fileName`
  
  - Use :shell:`-c` to get a count of number of grep matches
  - Can also search multiple files: :shell:`grep -c 'warning\|error' /var/log/*log` -> Searches all log files...
    
    - Use the -R flag to recursivly search subdirectories too
  
  - :shell:`grep -r "pattern" *`: This will search recursivly all files in the current dir and below

  - :shell:`grep -P "(?<=hello)(.*)(?=world)"`: Use a pearl regex. This returns all
    expressions found between "hello" and "world".

----

- :shell:`uname`: prints system info

----

- :shell:`ps`: "Process Status", prints info about running processes

  - :shell:`ps -A` or :shell:`ps -e` prints all running processes

  - :shell:`ps aux` shows all running processes in BSD format

  - :shell:`ps -u <user>` allows you to filter by user

  - :shell:`ps -C process_name` searches the PID of a process by name

----

- :shell:`pidof <process_name>`: This returns the PID only of the process

  - :shell:`sudo kill $(pidof <process_name>)`

----

- :shell:`chown`: Change the owner of a file

  - :shell:`sudo chown root <my_file>`: Example changing owner to root

----

- :shell:`chmod`: Changes permissions to a file

  - Permissions are grouped in 3 sections, Owner, Group and Users.
    - Owner is the owner of the file which can be changed with `chown`
    - Users is all the users of the system

  - Setting permissions with numbers:
    - 4: read permission
    - 2: write permission
    - 1: execute permission
  - :shell:`chmod 764 <file_name>`: Sets RWX permission for owner, RW for Group and R only for users.

  - Adding with letters:
    - `chmod +x <file_name>`: This will add execute permissions for Owner, Group and Users

----

- :shell:`echo`: Prints a string to console/file

  - Use with `-e` to for formatting characters: :shell:`echo -e "\nThis is a newline"`

----

- :shell:`ctrl+R`: Reverse i search.

  - Allows you to search through previous commands.
  - Press :shell:`ctrl+R` and start typing the search string. Hit :shell:`ctrl+R` to move to the next matching
    command.
  - Use the arrow keys if you want to modify the command before running it.