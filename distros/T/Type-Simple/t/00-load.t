#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Type::Simple' ) || print "Bail out!\n";
}

diag( "Testing Type::Simple $Type::Simple::VERSION, Perl $], $^X" );
