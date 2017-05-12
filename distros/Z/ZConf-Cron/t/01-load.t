#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::Cron::GUI' );
}

diag( "Testing ZConf::Cron::GUI $ZConf::Cron::GUI::VERSION, Perl $], $^X" );
