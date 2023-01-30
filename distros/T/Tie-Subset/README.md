Tie-Subset
==========

This is the distribution of the Perl modules
[`Tie::Subset::Hash`](https://metacpan.org/pod/Tie::Subset::Hash),
[`Tie::Subset::Hash`](https://metacpan.org/pod/Tie::Subset::Hash::Masked), and
[`Tie::Subset::Array`](https://metacpan.org/pod/Tie::Subset::Array).

They are Perl extensions for `tie`-ing arrays and hashes to a
subset of another array or hash, respectively.

Please see the modules' documentation (POD) for details (try the
commands `perldoc lib/Tie/Subset/Hash.pm`, `perldoc
lib/Tie/Subset/Hash/Masked.pm`, and `perldoc lib/Tie/Subset/Array.pm`)
and the file `Changes` for version  information.

[![Travis CI Build Status](https://travis-ci.org/haukex/Tie-Subset.svg)](https://travis-ci.org/haukex/Tie-Subset)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/haukex/Tie-Subset?svg=true)](https://ci.appveyor.com/project/haukex/tie-subset)
[![Kwalitee Score](https://cpants.cpanauthors.org/dist/Tie-Subset.svg)](https://cpants.cpanauthors.org/dist/Tie-Subset)
[![CPAN Testers](https://badges.zero-g.net/cpantesters/Tie-Subset.svg)](http://matrix.cpantesters.org/?dist=Tie-Subset)

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

Copyright (c) 2018-2023 Hauke Daempfling <haukex@zero-g.net>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the Perl Artistic License,
which should have been distributed with your copy of Perl.
Try the command `perldoc perlartistic` or see
<http://perldoc.perl.org/perlartistic.html>

