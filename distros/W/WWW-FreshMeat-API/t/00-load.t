#!perl -T

use Test::More tests => 5;

BEGIN {
	use_ok( 'WWW::FreshMeat::API' );
	use_ok( 'WWW::FreshMeat::API::Session' );
	use_ok( 'WWW::FreshMeat::API::Pub' );
	use_ok( 'WWW::FreshMeat::API::Pub::V1_03' );
	use_ok( 'WWW::FreshMeat::API::Agent::XML::RPC' );
}

diag( "Testing WWW::FreshMeat::API $WWW::FreshMeat::API::VERSION, Perl $], $^X" );
