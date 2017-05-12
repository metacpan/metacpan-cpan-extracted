Widget/Meta version 0.06
========================

This class specifies simple objects that describe UI widgets. The idea is to
associate Widget::Meta objects with the attributes of a class in order to
automate the generation of UI widgets for instances of the class. At its core,
this class a very simple module that stores value and returns them on demand.
The assigning of values to its attributes and checking the validity of those
attributes happens entirely in the `new()` constructor. Its attributes are
read-only; the `options` attribute is actually a code reference, the return
value of which is returned for every call to the `options()` accessor.

Installation
------------

To install this module, type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you don't have Module::Build installed, type the following:

    perl Makefile.PL
    make
    make test
    make install

Dependencies
------------

This module requires no modules or libraries not already included with Perl.

Copyright and Licence

Copyright (c) 2004-2011 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
