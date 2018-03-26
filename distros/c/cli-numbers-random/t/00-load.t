#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'cli::numbers::random' ) || print "Bail out!\n";
}

diag( "Testing cli::numbers::random $cli::numbers::random::VERSION, Perl $], $^X" );
