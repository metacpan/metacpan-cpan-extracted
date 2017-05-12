#!perl -T

use Test::Most 'bail', tests => 1;

BEGIN
{
	use_ok( 'WebService::DataDog::Search' );
}

diag( "Testing WebService::DataDog::Search $WebService::DataDog::VERSION, Perl $], $^X" );
