#!perl -T

use Test::More tests => 1;

BEGIN
{
	use_ok( 'WebService::DataDog' );
}

diag( "Testing WebService::DataDog $WebService::DataDog::VERSION, Perl $], $^X" );
