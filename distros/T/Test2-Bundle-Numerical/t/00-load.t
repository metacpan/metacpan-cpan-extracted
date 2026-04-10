#!perl
use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(1);

BEGIN {
    use_ok('Test2::Bundle::Numerical') || print "Bail out!\n";
}

diag( "Testing Test2::Bundle::Numerical $Test2::Bundle::Numerical::VERSION, Perl $], $^X" );
