#!perl

use strict;
use warnings;

use Test::Lib;
use Test::More;

our $PKG;

BEGIN {

    sub PKG () { 'A' }
    our $PKG = PKG;

}

BEGIN {

    use A ();

    require no_imports;
}

BEGIN {

    use A (), 'tattle';

    ::is( tattle(), 'A', q[use A (), 'tattle'] );

}

done_testing;
