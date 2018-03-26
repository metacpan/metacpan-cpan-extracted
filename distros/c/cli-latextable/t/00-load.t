#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'cli::latextable' ) || print "Bail out!\n";
}

diag( "Testing cli::latextable $cli::latextable::VERSION, Perl $], $^X" );
