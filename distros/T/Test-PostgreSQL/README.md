# Test::PostgreSQL

Test::PostgreSQL helps you run unit tests that require a PostgreSQL database,
by starting one up for you, and automatically cleaning it up at the end of
the test.

It is designed to allow multiple tests to run in parallel, with multiple
postgresql instances, without conflict.

## Installation

### Prerequisites

#### cpanm

The cpanm utility, available from: https://github.com/miyagawa/cpanminus

#### PostgreSQL client dev libraries

This module requres the PostgreSQL client development libraries.

On Debian and Ubuntu, these can be installed by running:

`sudo apt install libpq-dev`

### Installation

Simply run:

`cpanm Test::PostgreSQL`

To install this module from source, such as a Github checkout,
type the following in the same directory as this README.

`cpanm .`

Module Dependencies
-------------------

Some additional CPAN modules are required; however they will be pulled
down automatically by `cpanm` at install/test time.

See Makefile.PL for details.

Authors
-------

Toby Corkindale, Kazuho Oku, and various contributors.

Copyright and License
---------------------

This version copyright © 2011-2018 Toby Corkindale.

Versions 0.09 and earlier were copyright (C) 2009 Cybozu Labs, Inc.

This module is free software, released under the Perl Artistic License 2.0.
See http://www.perlfoundation.org/artistic_license_2_0 for more information.


