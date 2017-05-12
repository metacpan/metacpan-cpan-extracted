#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Analytics::MultiTouch' );
}

diag( "Testing WWW::Analytics::MultiTouch $WWW::Analytics::MultiTouch::VERSION, Perl $], $^X" );
