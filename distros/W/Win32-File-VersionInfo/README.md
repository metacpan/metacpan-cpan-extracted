Win32-File-VersionInfo version 0.07
===========================

This module lets you read the version information resource from files 
in the Microsoft PE format (including programs, DLLs, fonts, etc.)

This module was originally called Win32-File-Ver, since there
used to be a module by that name that did the same thing
(albeit using Win32::API, not XS) that was written by Mike Blazer 
sometime in 1999. This seems to have vanished off the face of the 
earth, thus my rewrite from scratch.

# INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

# DEPENDENCIES

The perl module itself has no dependencies. The XS depends on winver.h 
and version.lib (included with MS Visual C++ and/or the MS Platform SDK).
As the name implies, this module is only ever meaningful on Win32. The module
will install and test OK on non-Win32 systems; using it there will result
in the module croaking.

# STATUS

[![Build Status](https://travis-ci.org/brad-mac/Win32-File-VersionInfo.svg?branch=master)](https://travis-ci.org/brad-mac/Win32-File-VersionInfo)

# COPYRIGHT AND LICENCE

Copyright (C) 2003 Alexey Toptygin <alexeyt@cpan.org>

Ongoing maintenance (C) 2016 Brad Macpherson <brad@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

