#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::Bookmarks' );
}

diag( "Testing ZConf::Bookmarks $ZConf::Bookmarks::VERSION, Perl $], $^X" );
