#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'cli::numbers::util' ) || print "Bail out!\n";
}

diag( "Testing cli::numbers::util $cli::numbers::util::VERSION, Perl $], $^X" );
