#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'cli::rows::util' ) || print "Bail out!\n";
}

diag( "Testing cli::rows::util $cli::rows::util::VERSION, Perl $], $^X" );
