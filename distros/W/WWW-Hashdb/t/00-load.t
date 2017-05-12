#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Hashdb' );
}

diag( "Testing WWW::Hashdb $WWW::Hashdb::VERSION, Perl $], $^X" );
