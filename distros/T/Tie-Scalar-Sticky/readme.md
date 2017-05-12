Tie::Scalar::Sticky
===================
Just another scalar assignment blocker. [![CPAN Version](https://badge.fury.io/pl/Tie-Scalar-Sticky.svg)](https://metacpan.org/pod/Tie::Scalar::Sticky) [![Build Status](https://api.travis-ci.org/jeffa/Tie-Scalar-Sticky.svg?branch=master)](https://travis-ci.org/jeffa/Tie-Scalar-Sticky)

Synopsis
--------
```perl
use strict;
use Tie::Scalar::Sticky;

tie my $sticky, 'Tie::Scalar::Sticky';

$sticky = 42;
$sticky = '';       # still 42
$sticky = undef;    # still 42
$sticky = 0;        # now it's zero

tie my $sticky, 'Tie::Scalar::Sticky' => qw/ foo bar /;

$sticky = 42;
$sticky = 'foo';    # still 42
$sticky = 'bar';    # still 42
$sticky = 0;        # now it's zero
```

Installation
------------
To install this module, you should use CPAN. A good starting
place is [How to install CPAN modules](http://www.cpan.org/modules/INSTALL.html).

If you truly want to install from this github repo, then
be sure and create the manifest before you test and install:
```
perl Makefile.PL
make
make manifest
make test
make install
```

Support and Documentation
-------------------------
After installing, you can find documentation for this module with the
perldoc command.
```
perldoc Tie::Scalar::Sticky
```
You can also find documentation at [metaCPAN](https://metacpan.org/pod/Tie::Scalar::Sticky).

License and Copyright
---------------------
See [source POD](/lib/Tie/Scalar/Sticky.pm).
