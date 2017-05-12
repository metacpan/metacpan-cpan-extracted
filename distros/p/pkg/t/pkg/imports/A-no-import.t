#!perl

use strict;
use warnings;

use Test::Lib;

our $PKG;

BEGIN {

sub PKG () { 'A' }
our $PKG = PKG;

}

BEGIN {

    use pkg 'A' => [];

    require no_imports;
};

BEGIN {

    # emulate use 'A' (), 'tattle';
    use pkg 'A' => [], 'tattle';

    ::is( tattle(), 'A', q[emulate use A (), 'tattle'] );

};

done_testing;
