Test::Postgresql58
================

Test::Postgresql58 helps you run unit tests that require a PostgreSQL database,
by starting one up for you, and automatically destroying it later.

Installation
------------

To install this module, it's probably easiest to run this, which doens't even
require downloading the source.

   cpanm Test::Postgresql58

To install this module from source, such as a CPAN download or Github checkout,
type the following in the same directory as this README.

   perl Makefile.PL
   make
   make test
   make install

Module Dependencies
-------------------

 * Class::Accessor::Lite
 * DBI
 * DBD::Pg

This module's unit tests require:

 * Test::SharedFork

Authors
-------

Colin Newell, Toby Corkindale, Kazuho Oku, and various contributors.

Copyright and License
---------------------

Current version copyright © 2016 Colin Newell

Forked from Test::PostgreSQL at version 1.06 which was copyright © 2011-2016 Toby Corkindale.

Versions 0.09 and earlier were copyright (C) 2009 Cybozu Labs, Inc.

This module is free software, released under the Perl Artistic License 2.0.
See http://www.perlfoundation.org/artistic_license_2_0 for more information.


