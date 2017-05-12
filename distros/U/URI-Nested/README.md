URI/Nested version 0.10
=======================

This library implements a Perl interface for nested URIs -- that is, URIs that
contain other URIs. The basic format is:

    {prefix}:{uri}
    
Some examples:

* `jdbc:oracle:scott/tiger@//myhost:1521/myservicename`
* `db:postgres://db.example.com/template1`

Implementations built on URI::Nested include
[URI::jdbc](https://metacpan.org/module/URI::jdbc) and
[URI::db](https://metacpan.org/module/URI::db).

Installation
------------

To install this module, type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Dependencies
------------

URI::Nested requires the following modules:

* [URI](https://metacpan.org/module/URI)

Copyright and Licence
---------------------

Copyright (c) 2013 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
