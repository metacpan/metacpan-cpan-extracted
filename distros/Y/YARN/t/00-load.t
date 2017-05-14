#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN { plan tests => 5 };

BEGIN {
    use_ok( 'YARN' ) || print "Failed!\n";
}

diag( "Testing YARN $YARN::VERSION, Perl $], $^X" );
