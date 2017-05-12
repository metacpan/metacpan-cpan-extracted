#!perl -T

use Test::Most 'bail', tests => 1;

BEGIN
{
	use_ok( 'WebService::DataDog::Tag' );
}

diag( "Testing WebService::DataDog::Tag $WebService::DataDog::VERSION, Perl $], $^X" );
