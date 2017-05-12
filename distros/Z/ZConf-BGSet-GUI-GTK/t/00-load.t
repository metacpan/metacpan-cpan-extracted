#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::BGSet::GUI::GTK' );
}

diag( "Testing ZConf::BGSet::GUI::GTK $ZConf::BGSet::GUI::GTK::VERSION, Perl $], $^X" );
