#!perl -T

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Differences' ) || BAIL_OUT("Can't load the module!");
}

diag( "Testing Test::Differences $Test::Differences::VERSION, Perl $], $^X" );
