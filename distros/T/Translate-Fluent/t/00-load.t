#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Translate::Fluent' ) || print "Bail out!\n";
}

diag( "Testing Translate::Fluent $Translate::Fluent::VERSION, Perl $], $^X" );
