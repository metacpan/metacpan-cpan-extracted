#!perl -T

use Test::Most 'bail', tests => 1;

BEGIN
{
	use_ok( 'WebService::DataDog::Graph' );
}

diag( "Testing WebService::DataDog::Graph $WebService::DataDog::VERSION, Perl $], $^X" );
