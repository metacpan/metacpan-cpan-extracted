#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'VM::CloudAtCost' ) || print "Bail out!\n";
}

diag( "Testing VM::CloudAtCost $VM::CloudAtCost::VERSION, Perl $], $^X" );
