#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::Cron::GUI::GTK' );
}

diag( "Testing ZConf::Cron::GUI::GTK $ZConf::Cron::GUI::GTK::VERSION, Perl $], $^X" );
