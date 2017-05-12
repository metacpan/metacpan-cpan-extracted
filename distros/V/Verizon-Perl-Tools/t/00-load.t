#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Verizon::Cloud::Storage' ) || print "Bail out!\n";
}

