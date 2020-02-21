#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Minion::Task' ) || print "Bail out!\n";
}

diag( "Testing Minion::Task $Minion::Task::VERSION, Perl $], $^X" );
