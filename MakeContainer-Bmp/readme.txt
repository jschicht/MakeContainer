This program will help in creating special VeraCrypt / TrueCrypt containers suited for this special version:

http://reboot.pro/files/file/493-truecrypt-patched-for-supporting-arbitrary-offsets/

This program will as well as preparing a special container, also output a sample batch script with example command to load the container.

This particular program hides container inside a BMP. It will adjust OffsetPixelArray in BMP header, thus letting us inject data in between the BMP header and the Pixel Array. There is 1 Legacy Compliant mode, that will let you load the inner volume from the original TrueCrypt version. Otherwise you can use the patched version on either volumes at arbitrary offsets. 
