This program will help in creating special VeraCrypt / TrueCrypt containers suited for this special version:

http://reboot.pro/files/file/493-truecrypt-patched-for-supporting-arbitrary-offsets/

This program will as well as preparing a special container, also output a sample batch script with example command to load the container.

This particular program hides container inside Authenticode signature of executables that have been signed. It takes advantage of the fact that the certificate content is not part of the executable that is part of the hash generation. Thus letting us hide data inside the signature without invalidating it.

Microsoft has put a limit on the signature size at 0x1A8008. That means for signatures above 100.000 kb (minus 8 byte header), it will simply skip the entire evaluation. This is strictly speaking not in accordance with their own Authenticode specification where it says the size field is dword (4 gigs). Anyways, that means when creating the container within VeraCrypt you can set size the outer size to 99950 kb as max to be on the safe side and making sure Windows still evaluate the signature.

