#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'WebService::FuncNet' );
	use_ok( 'WebService::FuncNet::Job');
	use_ok( 'WebService::FuncNet::Request');
	use_ok( 'WebService::FuncNet::Results');
}

diag( "Testing WebService::FuncNet $WebService::FuncNet::VERSION, Perl $], $^X" );
