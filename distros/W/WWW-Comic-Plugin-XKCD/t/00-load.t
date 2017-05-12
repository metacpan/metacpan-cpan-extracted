#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Comic::Plugin::XKCD' );
}

diag( "Testing WWW::Comic::Plugin::XKCD $WWW::Comic::Plugin::XKCD::VERSION, Perl $], $^X" );
