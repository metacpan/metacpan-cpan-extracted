#!perl -T

use Test::Most tests => 1;

BEGIN
{
	use_ok( 'WebService::DataDog::Alert' );
}

diag( "Testing WebService::DataDog::Alert $WebService::DataDog::VERSION, Perl $], $^X" );
