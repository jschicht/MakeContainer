This program will help in creating custom VeraCrypt / TrueCrypt containers suited for this special version:

New VerCrypt patch; 
http://reboot.pro/topic/21561-veracrypt-patch-for-arbitrary-container-offsets/

Original TrueCrypt patch; 
http://reboot.pro/files/file/493-truecrypt-patched-for-supporting-arbitrary-offsets/

This program will as well as preparing a special container, also output a sample batch script with example command to load and decrypt the container.

This particular program hides container inside a Portable Executable (exe, dll, sys etc). It modifies the Section Headers and injects data in between sections. The validity of PE format is preserved, making patched executables still working. The target section to be modifed is randomly chosen at runtime. For some reason containers with hidden volumes, have proved tricky to work with this trick. Normal containers seems ok though.
