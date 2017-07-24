This program will help in creating custom VeraCrypt / TrueCrypt containers suited for this special version:

New VerCrypt patch; 
http://reboot.pro/topic/21561-veracrypt-patch-for-arbitrary-container-offsets/

Original TrueCrypt patch; 
http://reboot.pro/files/file/493-truecrypt-patched-for-supporting-arbitrary-offsets/

This program will as well as preparing a special container, also output a sample batch script with example command to load and decrypt the container.

This particular program hides container inside a Portable Executable (exe, dll, sys, com, mui etc). It injects the data into the resource section. An input box is presented where user can specify ResourceType,Language as comma separated. If resource type does not exist, it will be created. The Id is randomly chosen between 1 and 2000. For some reason containers with hidden volumes, have proved tricky to work with this trick. Normal containers seems ok though.
