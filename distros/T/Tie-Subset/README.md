Tie-Subset
==========

This is the distribution of the Perl modules `Tie::Subset::Hash`
and `Tie::Subset::Array`.

They are Perl extensions for `tie`-ing arrays and hashes to a
subset of another array or hash, respectively.

Please see the module's documentation (POD) for details (try the
commands `perldoc lib/Tie/Subset/Hash.pm` and
`perldoc lib/Tie/Subset/Array.pm`) and the file `Changes` for
version information.

Installation
------------

To install this distribution type the following:

	perl Makefile.PL
	make
	make test
	make install

If you are running Windows, you may need to use `dmake`, `nmake`, 
or `gmake` instead of `make`.

Dependencies
------------

Requirements: Perl v5.6 or higher (a more current version is
*strongly* recommended) and several of its core modules; users of
older Perls may need to upgrade some core modules.

The full list of required modules can be found in the file
`Makefile.PL`. This module should work on any platform supported 
by these modules.

Author, Copyright and License
-----------------------------

Copyright (c) 2018 Hauke Daempfling <haukex@zero-g.net>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the Perl Artistic License,
which should have been distributed with your copy of Perl.
Try the command `perldoc perlartistic` or see
<http://perldoc.perl.org/perlartistic.html>

