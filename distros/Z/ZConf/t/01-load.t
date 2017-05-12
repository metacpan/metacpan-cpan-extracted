#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::backends::ldap' );
}

diag( "Testing ZConf::backends::ldap $ZConf::backends::ldap::VERSION, Perl $], $^X" );
