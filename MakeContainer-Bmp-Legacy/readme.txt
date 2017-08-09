Tool to transform a VeraCrypt container into a masked bmp file. Choose desired pixel format and the tool will generate a bmp of the encrypted bytes. Since a pseudo bmp header is generated, parts of the original VeraCrypt header is overwritten for the normal volume. And in order to conform with bmp specification, the some bytes needs to be added at the end to align filesize. Because of that, it is not possible to load the normal (outer) volume. Only the hidden volume can be used.

What will the image look like?
It will look like random! That is colours with no particular pattern.

This tool is thus not made for my patched VeraCrypt, but the lagacy version.