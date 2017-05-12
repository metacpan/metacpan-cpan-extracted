#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Text::Spintax' ) || print "Bail out!\n";
}

diag( "Testing Text::Spintax $Text::Spintax::VERSION, Perl $], $^X" );
