#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::DevTemplate' );
}

diag( "Testing ZConf::DevTemplate $ZConf::DevTemplate::VERSION, Perl $], $^X" );
