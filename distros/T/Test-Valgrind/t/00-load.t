#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
 use_ok( 'Test::Valgrind::Suppressions' );
}

diag( "Testing Test::Valgrind $Test::Valgrind::Suppressions::VERSION, Perl $], $^X" );
