#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'fastQ_brew' ) || print "Bail out!\n";
}

diag( "Testing fastQ_brew $fastQ_stats::VERSION, Perl $], $^X" );
