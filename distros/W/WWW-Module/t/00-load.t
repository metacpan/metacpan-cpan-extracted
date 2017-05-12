#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Module' );
}

diag( "Testing WWW::Module $WWW::Module::VERSION, Perl $], $^X" );
