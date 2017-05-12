#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WebService::JugemKey::Auth' );
}

diag( "Testing WebService::JugemKey::Auth $WebService::JugemKey::Auth::VERSION, Perl $], $^X" );
