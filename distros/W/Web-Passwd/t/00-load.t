#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Web::Passwd' );
}

diag( "Testing Web::Passwd $Web::Passwd::VERSION, Perl $], $^X" );
