#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::Cron' );
}

diag( "Testing ZConf::Cron $ZConf::Cron::VERSION, Perl $], $^X" );
