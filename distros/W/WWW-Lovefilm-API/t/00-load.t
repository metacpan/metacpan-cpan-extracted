#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Lovefilm::API' );
}

diag( "Testing WWW::Lovefilm::API $WWW::Lovefilm::API::VERSION, Perl $], $^X" );
