#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Thread::Subs' ) || print "Bail out!\n";
}

diag( "Testing Thread::Subs $Thread::Subs::VERSION, Perl $], $^X" );
