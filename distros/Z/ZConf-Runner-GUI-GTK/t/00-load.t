#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::Runner::GUI::GTK' );
}

diag( "Testing ZConf::Runner::GUI::GTK $ZConf::Runner::GUI::GTK::VERSION, Perl $], $^X" );
