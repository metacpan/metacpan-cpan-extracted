#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojo::Util::Benchmark' ) || print "Bail out!\n";
}

diag( "Testing Mojo::Util::Benchmark $Mojo::Util::Benchmark::VERSION, Perl $], $^X" );
