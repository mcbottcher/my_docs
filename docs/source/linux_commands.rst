.. role:: shell(code)
    :language: shell

Linux Commands
==============

- :shell:`cd` : Change Directory

  - :shell:`cd` itself will default to the home DIR
  - :shell:`cd -` takes you back to the previous directory you were at

- :shell:`pwd` : print the directory you are in

- :shell:`whoami` : prints current user

- :shell:`wc`: get file size info

  - :shell:`wc -c unix.md` : Get number of bytes of file
  - :shell:`wc -l unix.md` : Get number of lines of file

- :shell:`diff`: Compares two files

  - :shell:`diff -y <file1> <file2>`: Outputs diff of file1 and file2 side-by-side

- :shell:`find`: Find a file

  - :shell:`find . -name "*.py"`: Finds all .py files from current directory and down

- :shell:`tree`: Shows files in tree display

- :shell:`printenv`: Print environment variables

- :shell:`curl`: cURL lets us query URLs from the command line

  - :shell:`curl www.google.com`: Returns HTML/Scripts of google.com
  - option :shell:`-i` gives information header
  - option :shell:`-d or --data` can be used to post data to a url

    - :shell:`curl -d "first=Bob&last=Ross" http://<url>`

  - pass in username and password: :shell:`curl -u <username>:<password> <url>`
  - Download response e.g. picture: :shell:`curl -o test.jpg <url>` -> outputs response to test.jpg

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

- :shell:`uname`: prints system info