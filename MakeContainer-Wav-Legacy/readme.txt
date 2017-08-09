Tool to transform a VeraCrypt container into a masked wav audio file. The tool will generate a valid wav file of the encrypted bytes. Since a pseudo wav header is generated, parts of the original VeraCrypt header is overwritten for the normal volume. In order to load the normal (outer) volume, you need to open "Mount options" and select "Use backup header embedded in volume if available". The hidden volume can be used as normal.

What will the music sound like?
It will sound like random (noise)!

This tool is thus not made for my patched VeraCrypt, but the lagacy version.