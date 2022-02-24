#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::UK::Parliament' ) || print "Bail out!\n";
}

diag( "Testing WebService::UK::Parliament $WebService::UK::Parliament::VERSION, Perl $], $^X" );
