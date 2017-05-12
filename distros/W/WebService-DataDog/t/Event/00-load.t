#!perl -T

use Test::Most 'bail', tests => 1;

BEGIN
{
	use_ok( 'WebService::DataDog::Event' );
}

diag( "Testing WebService::DataDog::Event $WebService::DataDog::VERSION, Perl $], $^X" );
