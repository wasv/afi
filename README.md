# af
A Forth interpreter for ARM.

Based on the [jonesforth](http://git.annexia.org/?p=jonesforth.git;a=summary) interpreter, with some tweaks, and ported to ARM.

Written entirely in GNU Assembler. Currently only tested in a QEMU virtual machine. However, everything except serial IO should
be portable to most ARM devices.
