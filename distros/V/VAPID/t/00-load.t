#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'VAPID' ) || print "Bail out!\n";
}

diag( "Testing VAPID $VAPID::VERSION, Perl $], $^X" );
