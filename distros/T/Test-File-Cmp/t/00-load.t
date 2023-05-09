#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Test::File::Cmp' ) || print "Bail out!\n";
}

diag( "Testing Test::File::Cmp $Test::File::Cmp::VERSION, Perl $], $^X" );
