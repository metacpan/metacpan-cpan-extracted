#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'ZHOUYI::ZhanPu' ) || print "Bail out!\n";
}

diag( "Testing ZHOUYI::ZhanPu $ZHOUYI::ZhanPu::VERSION, Perl $], $^X" );
