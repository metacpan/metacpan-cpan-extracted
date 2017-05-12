#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::RSS::GUI::GTK' );
}

diag( "Testing ZConf::RSS::GUI::GTK $ZConf::RSS::GUI::GTK::VERSION, Perl $], $^X" );
