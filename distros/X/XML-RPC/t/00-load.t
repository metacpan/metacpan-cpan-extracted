#!perl -T

use strict;
use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::RPC' );
}

diag( "Testing XML::RPC $XML::RPC::VERSION, Perl $], $^X" );
