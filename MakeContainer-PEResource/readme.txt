This program will help in creating special VeraCrypt / TrueCrypt containers suited for this special version:

http://reboot.pro/files/file/493-truecrypt-patched-for-supporting-arbitrary-offsets/

This program will as well as preparing a special container, also output a sample batch script with example command to load the container.

This particular program hides container inside a Portable Executable (exe, dll, sys, com, mui etc). It injects the data into the resource section. A resource of type RCData with ID randomly chosen between 1 and 2000. For some reason containers with hidden volumes, have proved tricky to work with this trick. Normal containers seems ok though.
