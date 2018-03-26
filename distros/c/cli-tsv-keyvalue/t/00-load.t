#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'cli::tsv::keyvalue' ) || print "Bail out!\n";
}

diag( "Testing cli::tsv::keyvalue $cli::tsv::keyvalue::VERSION, Perl $], $^X" );
