Time::Monotonic
===============

### Monotonically incrementing clock source for Perl

Time::Monotonic gives access to monotonic clocks on various platforms (Mac
OS X, Windows, and POSIX). A monotonic clock is a time source that won't
ever jump forward or backward (due to NTP or Daylight Savings Time updates).

Time::Monotonic uses Thomas Habets's cross platform [monotonic_clock][1]
library under the hood.


[1]: https://github.com/ThomasHabets/monotonic_clock

Installation
------------

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

Dependencies
------------

This module requires these other modules and libraries:

  * Test::More

Bugs & Patches
--------------

  [Github Project](https://github.com/caldwell/Time-Monotonic)

Copyright And Licence
---------------------

Copyright © 2015 by David Caldwell <david@porkrind.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
