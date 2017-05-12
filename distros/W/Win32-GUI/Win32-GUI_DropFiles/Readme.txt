Win32-GUI-DropFiles
===================

Win32::GUI::DropFiles provides integration with the windows shell
for Win32::GUI applications, allowing retrieval of the filenames
of files dragged from the shell (e.g. explorer) to the application
window.

INSTALLATION - from source

As a source distribution this module is bundled with Win32::GUI,
and will be built while makeing Win32::GUI itself. It is possible
to build and install this module stand alone:

   perl Makefile.PL
   make
   make test
   make install

INSTALLATION - binary distribution

This module will be distributed in binary form
(ActiveState PPM) as part of the Win32::GUI module.
See the Win32-GUI module README for further details.

DEPENDENCIES

This module requires these other modules and libraries:

   perl 5.6.0 or higher (5.8.6 or higher recommended)
   Win32::GUI 1.04 or higher

To fully test this module the following modules and libraries
are required.  Some tests will be skipped if these modules are
not available:

   Win32::API 0.41 or higher
   Test::Pod 1.14 or higher
   Test::Pod::Coverage 1.04 or higher
   Unicode::String

COPYRIGHT AND LICENCE

Copyright (C) 2006 by Robert May

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
----------------------------------------------------------------------
$Id: README,v 1.1 2006/04/25 21:38:18 robertemay Exp $
