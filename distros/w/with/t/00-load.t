#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
	use_ok( 'with' );
}

diag( "Testing with $with::VERSION, Perl $], $^X" );
