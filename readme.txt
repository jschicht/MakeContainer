This is a collection of some tools I made a few years ago for working with encrypted containers located in semi-arbitrary offsets in a host file.

The original TrueCrypt patch can be found here http://reboot.pro/topic/19690-truecrypt-patched-for-supporting-arbitrary-offsets/  In the download section you can also find the original MakeContainer tools.

The new VeraCrypt patch works similarly as the TrueCrypt patch, in that it supports an /i argument on the commandline where you can specify the offset for the encrypted container.

This set of tools was thus made to facilitate the creation of these strange containers. With some skills and a portion of creativity, you can create really fancy stuff on your own though.

It is crucial that the offset of the container is sector size aligned, 512 bytes. The tools take care of this.

The steps for creating a proper container;

#1.
Run the VeraCrypt wizard and create a container. Don't put anything inside it yet.
#2.
Run any the tools in this collection to hide the container in some other file. A bat file will be generated with an example command line for loading it later on.
#3.
Run the patched VeraCrypt with a command like the one specified in the example bat file that was generated in step 2. Now you will have to format the the volume once more after it is decrypted. This is because the physical offset changed. When the volume is formatted the second time, it is ready for use. This is the same for both standard and hidden volumes.
#4
Make sure the host file that contains the hidden container does not get modified at the offsets where the container bytes are stored. Static files are of cource safest to use, but is for instance possible to store the container inside a text based logfile as long as all new log entries are written to EOF and the logfile is not recycled.

Consider this project more of a fun type than anything else. Have fun.

