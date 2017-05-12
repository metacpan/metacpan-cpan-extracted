#!perl -T

use Test::Most 'bail', tests => 1;

BEGIN
{
	use_ok( 'WebService::DataDog::Dashboard' );
}

diag( "Testing WebService::DataDog::Dashboard $WebService::DataDog::VERSION, Perl $], $^X" );
