#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Test::Instruction' ) || print "Bail out!\n";
}

diag( "Testing Test::Instruction $Test::Instruction::VERSION, Perl $], $^X" );
