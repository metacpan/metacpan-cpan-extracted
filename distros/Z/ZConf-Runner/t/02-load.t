#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::Runner::GUI::Curses' );
}

diag( "Testing ZConf::Runner::GUI::Curses $ZConf::Runner::GUI::Curses::VERSION, Perl $], $^X" );
