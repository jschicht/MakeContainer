This program will help in creating custom VeraCrypt / TrueCrypt containers suited for this special version:

New VerCrypt patch; 
http://reboot.pro/topic/21561-veracrypt-patch-for-arbitrary-container-offsets/

Original TrueCrypt patch; 
http://reboot.pro/files/file/493-truecrypt-patched-for-supporting-arbitrary-offsets/

This program will as well as preparing a special container, also output a sample batch script with example command to load and decrypt the container.

This particular program put the container at end of file, on target. Choose any file and container will be appended at EOF with correct alignment. Pay attention to corruption in host file format when appending.
