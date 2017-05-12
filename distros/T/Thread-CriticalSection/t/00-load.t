#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Thread::CriticalSection' );
}

diag( "Testing Thread::CriticalSection $Thread::CriticalSection::VERSION, Perl $], $^X" );
