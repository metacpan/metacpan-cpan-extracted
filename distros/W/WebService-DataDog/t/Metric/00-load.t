#!perl -T

use Test::Most 'bail', tests => 1;

BEGIN
{
	use_ok( 'WebService::DataDog::Metric' );
}

diag( "Testing WebService::DataDog::Metric $WebService::DataDog::VERSION, Perl $], $^X" );
