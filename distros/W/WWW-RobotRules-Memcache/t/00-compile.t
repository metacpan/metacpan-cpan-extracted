#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::RobotRules::Memcache' );
}

diag( "Testing WWW::RobotRules::Memcache $WWW::RobotRules::Memcache::VERSION, Perl $], $^X" );
