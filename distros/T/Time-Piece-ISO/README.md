Time::Piece::ISO version 0.12
=============================

This module subclasses Matt Seargent's
[Time::Piece](http://search.cpan.org/perldoc?Time::Piece) module in order to
change its stringification and string comparison behavior to use the ISO 8601
format instead of localtime's `ctime` format. Although it does break the
backwards compatibility with the builtin `localtime` and `gmtime` functions
that Time::Piece offers, Time::Piece::ISO is designed to promote the more
standard ISO format as a new way of handling dates.

I decided to create this module for two simple reasons: First, default support
for the ISO 8601 date format seems to be the direction in which Perl 6 is
heading. And second, the ISO 8601 format tends to be more widely compatible
with RDBMS date time column type formats.

That said, the [DateTime](http://search.cpan.org/perldoc?DateTime) module has
since come to be, and it should probably be preferred to this module whenever
possible.

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

This module subclasses and requires the Time::Piece module from the CPAN.

Copyright and License

Copyright (c) 2002-2011, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
