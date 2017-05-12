#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
 use_ok( 'Thread::Cleanup' );
}

diag( "Testing Thread::Cleanup $Thread::Cleanup::VERSION, Perl $], $^X" );
