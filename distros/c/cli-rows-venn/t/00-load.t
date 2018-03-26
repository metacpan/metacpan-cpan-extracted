#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'cli::rows::venn' ) || print "Bail out!\n";
}

diag( "Testing cli::rows::venn $cli::rows::venn::VERSION, Perl $], $^X" );
