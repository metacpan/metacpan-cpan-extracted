#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Comic::Plugin::LeastICouldDo' );
}

diag( "Testing WWW::Comic::Plugin::LeastICouldDo "
    . "$WWW::Comic::Plugin::LeastICouldDo::VERSION, Perl $], $^X" );
