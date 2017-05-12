#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Test2::Tools::Expressive' ) || print "Bail out!\n";
}

diag( "Testing Test2::Tools::Expressive $Test2::Tools::Expressive::VERSION, Perl $], $^X" );
