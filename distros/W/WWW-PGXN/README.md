WWW/PGXN Module
===============

This library's module, WWW::PGXN, provides a simple Perl interface to the
[PGXN Web API]. It's designed to work with any PGXN mirror or API server.

Installation
------------

To install this module, type the following:

``` sh
perl Build.PL
./Build
./Build test
./Build install
```

Or, if you don't have Module::Build installed, type the following:

``` sh
perl Makefile.PL
make
make test
make install
```

Dependencies
------------

WWW-PGXN requires the following modules:

*   perl 5.10.0
*   HTTP::Tiny
*   JSON
*   URI::Template 0.16

Copyright and License
---------------------

Copyright (c) 2011-2024 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

  [PGXN Web API]: https://github.com/pgxn/pgxn-api/wiki "The PGXN API"
