ZXText2P v1.00
==============
Copyright 2002 Chris Cowley. <ccowley@grok.co.uk>
Based on code from zmakebas by Russell Marks


A free, open-source, ASCII text to ZX81 .P file conversion utility.

It's GPL. Read the file gpl.txt if you don't understand what
that means!


Details
-------
ZXText2P takes a plain text file containing a ZX81 BASIC program as
input and turns it into .p file suitable for use with an emulator or
for transfer to a real ZX81.

In addition to standard line-numbered input, you may optionally also
use label-based program code. See the documentation in the "doc\"
folder for full usage information.


If you're going to distribute this program, please ensure that the
following files are included without modification.

Files
-----
zxtext2p.c        The ANSI C source code. It should be fairly
                  portable.
gpl.txt           The GNU General Public Licence.
zxtext2p.exe      32-bit Windows Executable (command-line).
zxtext2p          Linux ELF binary (for Pentium-based systems).
readme.txt        This text file.
doc\zxtext2p.html Full documentation in HTML format.
doc\graphics.gif  Image file referenced by the above HTML page.
