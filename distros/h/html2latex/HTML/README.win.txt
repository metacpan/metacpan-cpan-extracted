Special Instructions for Windows Users:
=======================================

They only thing you really have to worry about beyond a regular UNIX
installation is:

1) Use nmake instead of make.  Or, if make is unavailable, you will
   have to copy the modules by hand. To the correct perl library
   directory. (c:\perl\site\lib if you are using ActiveState, for
   instance).

2) Change the "store" directory.  This is where all web-mirrored files
   will be stored.  The location for the store directory is found in
   the XML configuration file at the bottom of Latex.pm under
   <option><store>.  In version 0.9, this is line number 1382.  Just
   change the text in there to anything you like.
