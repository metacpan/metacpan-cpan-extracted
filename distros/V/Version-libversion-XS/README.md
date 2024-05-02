[![Release](https://img.shields.io/github/release/giterlizzi/perl-Version-libversion-XS.svg)](https://github.com/giterlizzi/perl-Version-libversion-XS/releases) [![Actions Status](https://github.com/giterlizzi/perl-Version-libversion-XS/workflows/linux/badge.svg)](https://github.com/giterlizzi/perl-Version-libversion-XS/actions) [![License](https://img.shields.io/github/license/giterlizzi/perl-Version-libversion-XS.svg)](https://github.com/giterlizzi/perl-Version-libversion-XS) [![Starts](https://img.shields.io/github/stars/giterlizzi/perl-Version-libversion-XS.svg)](https://github.com/giterlizzi/perl-Version-libversion-XS) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-Version-libversion-XS.svg)](https://github.com/giterlizzi/perl-Version-libversion-XS) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-Version-libversion-XS.svg)](https://github.com/giterlizzi/perl-Version-libversion-XS/issues) [![Coverage Status](https://coveralls.io/repos/github/giterlizzi/perl-Version-libversion-XS/badge.svg)](https://coveralls.io/github/giterlizzi/perl-Version-libversion-XS)

# Version::libversion::XS - Perl binding for libversion

See [libversion](https://github.com/repology/libversion) repository for
more details on the algorithm.

## Synopsis

```.pl
use Version::libversion::XS;

# OO-interface

if ( Version::libversion::XS->new($v1) == Version::libversion::XS->new($v2) ) {
  # do stuff
}

# Sorting mixed version styles

@ordered = sort { Version::libversion::XS->new($a) <=> Version::libversion::XS->new($b) } @list;


# Functional interface

use Version::libversion::XS ':all';

say '0.99 < 1.11' if(version_compare2('0.99', '1.11') == -1);

say '1.0 == 1.0.0' if(version_compare2('1.0', '1.0.0') == 0);

say '1.0alpha1 < 1.0.rc1' if(version_compare2('1.0alpha1', '1.0.rc1') == -1);

say '1.0 > 1.0.rc1' if(version_compare2('1.0', '1.0-rc1') == 1);

say '1.2.3alpha4 is the same as 1.2.3~a4' if(version_compare2('1.2.3alpha4', '1.2.3~a4') == 0);

# by default, 'p' is treated as 'pre' ...
say '1.0p1 == 1.0pre1'  if(version_compare2('1.0p1', '1.0pre1') == 0);
say '1.0p1 < 1.0post1'  if(version_compare2('1.0p1', '1.0post1') == -1);
say '1.0p1 < 1.0patch1' if(version_compare2('1.0p1', '1.0patch1') == -1);

# ... but this is tunable: here it's handled as 'patch'
say '1.0p1 > 1.0pre1'    if(version_compare4('1.0p1', '1.0pre1', VERSIONFLAG_P_IS_PATCH, 0) == 1);
say '1.0p1 == 1.0post1'  if(version_compare4('1.0p1', '1.0post1', VERSIONFLAG_P_IS_PATCH, 0) == 0);
say '1.0p1 == 1.0patch1' if(version_compare4('1.0p1', '1.0patch1', VERSIONFLAG_P_IS_PATCH, 0) == 0);

# a way to check that the version belongs to a given release
if(
  (version_compare4('1.0alpha1', '1.0', 0, VERSIONFLAG_LOWER_BOUND) == 1) &&
  (version_compare4('1.0alpha1', '1.0', 0, VERSIONFLAG_UPPER_BOUND) == -1) &&
  (version_compare4('1.0.1', '1.0', 0, VERSIONFLAG_LOWER_BOUND) == 1) &&
  (version_compare4('1.0.1', '1.0', 0, VERSIONFLAG_UPPER_BOUND) == -1)
) {
  say '1.0alpha1 and 1.0.1 belong to 1.0 release, e.g. they lie between' .
      '(lowest possible version in 1.0) and (highest possible version in 1.0)';
}
```

## Install

Using Makefile.PL:

To install `Version::libversion::XS` distribution, run the following commands.

    perl Makefile.PL
    make
    make test
    make install

Using App::cpanminus:

    cpanm Version::libversion::XS


## Documentation

 - `perldoc Version::libversion::XS`
 - https://metacpan.org/release/Version-libversion-XS
 - https://github.com/repology/libversion


## Copyright

 - Copyright 2024 © Giuseppe Di Terlizzi
